import 'dart:typed_data';

import 'package:bl_printer/bl_printer.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bl_printer_method_channel.dart';

abstract class BlPrinterPlatform extends PlatformInterface {
  /// Constructs a BlPrinterPlatform.
  BlPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BlPrinterPlatform _instance = MethodChannelBlPrinter();

  /// The default instance of [BlPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBlPrinter].
  static BlPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BlPrinterPlatform] when
  /// they register themselves.
  static set instance(BlPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> get isBluetoothEnable {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  Future<void> start(){
    throw UnimplementedError("devices has not been implemented");
  }
  Stream<BluetoothDevice> discoverDevice([
    Duration timeout = const Duration(seconds: 7),
  ]) {
    throw UnimplementedError("devices has not been implemented");
  }

  Future<List<BluetoothDevice>> get devices {
    throw UnimplementedError("devices has not been implemented");
  }

  Stream<BluetoothState> getBluetoothStatus() {
    throw UnimplementedError(
        'getServiceStatusStream() has not been implemented.');
  }

  Future<void> connect(BluetoothDevice device) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<void> printTest() {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<void> disconnect(BluetoothDevice device) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<void> printData(List<String> data) {
    throw UnimplementedError('printData() has not been implemented.');
  }

  Future<void> openSetting() {
    throw UnimplementedError('printData() has not been implemented.');
  }

  Future<void> enableBluetooth() {
    throw UnimplementedError('printData() has not been implemented.');
  }

  Future<void> printByteData(Uint8List data) {
    throw UnimplementedError('printByteData() has not been implemented.');
  }

  Future<void> cancel() {
    throw UnimplementedError('printByteData() has not been implemented.');
  }
}
