import 'bl_printer_platform_interface.dart';
import 'model/bluetooth_device.dart';
import 'model/bluetooth_state.dart';

class BlPrinter {
  Future<String?> getPlatformVersion() {
    return BlPrinterPlatform.instance.getPlatformVersion();
  }

  Future<bool> get isBluetoothEnable {
    return BlPrinterPlatform.instance.isBluetoothEnable;
  }

  Future<List<BluetoothDevice>> get devices {
    return BlPrinterPlatform.instance.devices;
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

  Stream<BluetoothState> getBluetoothStatus() {
    return BlPrinterPlatform.instance.getBluetoothStatus();
  }

  Future<void> disconnect(BluetoothDevice device) {
    return BlPrinterPlatform.instance.disconnect(device);
  }

  Future<void> cancel(){
    return BlPrinterPlatform.instance.cancel();
  }

  Future<void> printByteData(List<int> data) {
    return BlPrinterPlatform.instance.printByteData(data);
  }
}
