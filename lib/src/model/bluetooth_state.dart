import 'package:bl_printer/bl_printer.dart';

class BluetoothState {
  final BluetoothStatus status;
  final BluetoothDevice? device;

  BluetoothState({required this.status, this.device});
}
