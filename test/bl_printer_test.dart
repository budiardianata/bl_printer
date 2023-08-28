import 'package:bl_printer/src/bl_printer_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bl_printer/bl_printer.dart';
import 'package:bl_printer/src/bl_printer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBlPrinterPlatform with MockPlatformInterfaceMixin
    implements BlPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  // TODO: implement isBluetoothEnable
  Future<bool> get isBluetoothEnable => throw UnimplementedError();

  @override
  // TODO: implement hasBluetoothPermission
  Future<bool> get hasBluetoothPermission => throw UnimplementedError();

  @override
  Stream<BluetoothState> getBluetoothStatus() {
    // TODO: implement getBluetoothStatus
    throw UnimplementedError();
  }

  @override
  // TODO: implement devices
  Future<List<BluetoothDevice>> get devices => throw UnimplementedError();

  @override
  Future<void> connect(BluetoothDevice device) {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future<void> printTest() {
    // TODO: implement printTest
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect(BluetoothDevice device) {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future<void> printData(List<String> data) {
    // TODO: implement printData
    throw UnimplementedError();
  }

  @override
  Future<void> printByteData(List<int> data) {
    // TODO: implement printByteData
    throw UnimplementedError();
  }

  @override
  Future<void> cancel() {
    // TODO: implement cancel
    throw UnimplementedError();
  }

  @override
  Stream<BluetoothDevice> discoverDevice([Duration timeout = const Duration(seconds: 7)]) {
    // TODO: implement discoverDevice
    throw UnimplementedError();
  }

  @override
  Future<void> start() {
    // TODO: implement start
    throw UnimplementedError();
  }

  @override
  Future<void> enableBluetooth() {
    // TODO: implement enableBluetooth
    throw UnimplementedError();
  }

  @override
  Future<void> openSetting() {
    // TODO: implement openSetting
    throw UnimplementedError();
  }
}

void main() {
  final BlPrinterPlatform initialPlatform = BlPrinterPlatform.instance;

  test('$MethodChannelBlPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBlPrinter>());
  });

  test('getPlatformVersion', () async {
    BlPrinter blPrinterPlugin = BlPrinter();
    MockBlPrinterPlatform fakePlatform = MockBlPrinterPlatform();
    BlPrinterPlatform.instance = fakePlatform;

    expect(await blPrinterPlugin.getPlatformVersion(), '42');
  });
}
