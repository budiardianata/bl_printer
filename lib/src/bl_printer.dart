import 'dart:typed_data';

import 'bl_printer_platform_interface.dart';
import 'model/bluetooth_device.dart';
import 'model/bluetooth_state.dart';

class BlPrinter {
  Future<String?> getPlatformVersion() {
    return BlPrinterPlatform.instance.getPlatformVersion();
  }

  Stream<BluetoothDevice> discoverDevices([
    Duration timeout = const Duration(seconds: 60),
  ]){
    return BlPrinterPlatform.instance.discoverDevice(timeout);
  }

  Future<bool> get isBluetoothEnable {
    return BlPrinterPlatform.instance.isBluetoothEnable;
  }

  Future<List<BluetoothDevice>> get devices {
    return BlPrinterPlatform.instance.devices;
  }

  Future<void> openSetting() {
    return BlPrinterPlatform.instance.openSetting();
  }

  Future<void> enableBluetooth() {
    return BlPrinterPlatform.instance.enableBluetooth();
  }

  Future<void> connect(BluetoothDevice device) {
    return BlPrinterPlatform.instance.connect(device);
  }

  Future<void> printData(List<String> data) {
    return BlPrinterPlatform.instance.printData(data);
  }

  Future<void> printTest() {
    return BlPrinterPlatform.instance.printTest();
  }

  Stream<BluetoothState> bluetoothState() {
    return BlPrinterPlatform.instance.getBluetoothStatus();
  }

  Future<void> disconnect(BluetoothDevice device) {
    return BlPrinterPlatform.instance.disconnect(device);
  }

  Future<void> cancel(){
    return BlPrinterPlatform.instance.cancel();
  }

  Future<void> printByteData(Uint8List data) {
    return BlPrinterPlatform.instance.printByteData(data);
  }
}
