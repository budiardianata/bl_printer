class BluetoothDevice {
  final String name;
  final String address;

  BluetoothDevice({required this.name, required this.address});

  @override
  bool operator == (Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDevice && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() {
    return address;
  }
}
