import 'dart:async';

import 'package:bl_printer/src/model/bluetooth_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'bl_printer_platform_interface.dart';
import 'bluetooth_status.dart';
import 'model/bluetooth_device.dart';

const String namespace = "com.dipa.bl_printer";

/// An implementation of [BlPrinterPlatform] that uses method channels.
class MethodChannelBlPrinter extends BlPrinterPlatform {
  MethodChannelBlPrinter() {
    methodChannel.setMethodCallHandler((MethodCall call) {
      _methodStreamController.add(call);
      return Future(() => null);
    });
  }

  final _methodStreamController = StreamController<MethodCall>.broadcast();

  Stream<MethodCall> get _methodStream => _methodStreamController.stream;

  @visibleForTesting
  final methodChannel = const MethodChannel(namespace);

  final _stateChannel = const EventChannel('$namespace/states');

  final _stopScanPill = PublishSubject();

  Stream<BluetoothState>? _serviceStatusStream;

  @override
  Future<void> start() async {
    await methodChannel.invokeMethod('start');
  }

  @override
  Stream<BluetoothDevice> discoverDevice([
    Duration timeout = const Duration(seconds: 60),
  ]) async* {
    final killStreams = <Stream>[];
    killStreams.add(_stopScanPill);
    killStreams.add(Rx.timer(null, timeout));
    final stream = _methodStream
        .takeWhile((m) => m.method == "ScanResult" && m.arguments is String)
        .map((m) => _toDevice(m.arguments as String))
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(_stopScan);
    final tempDevice = <BluetoothDevice>[];
    await for (BluetoothDevice device in stream) {
      if (tempDevice.contains(device)) continue;
      tempDevice.add(device);
      yield device;
    }
  }

  BluetoothDevice _toDevice(String data){
    List<String> info = data.split("#");
    return BluetoothDevice(name: info[0], address: info[1]);
  }

  FutureOr<void> _stopScan() async {
    _stopScanPill.add(null);
  }

  @override
  Future<void> openSetting(){
    return methodChannel.invokeMethod('openSetting');
  }

  @override
  Future<void> enableBluetooth() {
    return methodChannel.invokeMethod('enableBluetooth');
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> get isBluetoothEnable async {
    return await methodChannel.invokeMethod<bool>('isBluetoothEnable') ?? false;
  }

  @override
  Future<List<BluetoothDevice>> get devices async {
    List<BluetoothDevice> items = [];
    try {
      final List result = await methodChannel.invokeMethod('devices');
      await Future.forEach(result, (element) {
        String item = element as String;
        List<String> info = item.split("#");
        String name = info[0];
        String address = info[1];
        items.add(BluetoothDevice(name: name, address: address));
      });
    } on PlatformException {
      rethrow;
    }
    return items;
  }

  @override
  Future<void> connect(BluetoothDevice device) async {
    try {
      await methodChannel.invokeMethod('connect', {"address": device.address});
    } on PlatformException {
      rethrow;
    }
    return;
  }

  @override
  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await methodChannel.invokeMethod('disconnect');
    } on PlatformException {
      rethrow;
    }
    return;
  }

  @override
  Future<void> printData(List<String> data) async {
    try {
      await methodChannel.invokeMethod('print', {"data": data});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> printByteData(Uint8List data) async {
    try {
      await methodChannel.invokeMethod('printBytes', {
        "data": data,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> printTest() async {
    await methodChannel.invokeMethod('printTest');
  }

  @override
  Stream<BluetoothState> getBluetoothStatus() {
    if (_serviceStatusStream != null) {
      return _serviceStatusStream!;
    }
    var serviceStatusStream = _stateChannel.receiveBroadcastStream();
    _serviceStatusStream = serviceStatusStream.map((event) {
      final Map<dynamic, dynamic> data = event;
      if (!data.containsKey('status')) {
        throw Exception('Data Not valid');
      }
      final int index = data['status'];
      BluetoothDevice? device;
      if (data.containsKey('devices')) {
        final deviceString = (data['devices'] as String).split('#');
        device =
            BluetoothDevice(name: deviceString.first, address: deviceString[1]);
      }
      return BluetoothState(
          status: BluetoothStatus.values[index], device: device);
    }).handleError((error) {
      _serviceStatusStream = null;
      throw error;
    });

    return _serviceStatusStream!;
  }

  @override
  Future<void> cancel() async {
    await methodChannel.invokeMethod('close');
    _methodStreamController.close();
  }
}
