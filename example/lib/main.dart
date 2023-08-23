import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bl_printer/bl_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  List<BluetoothDevice> devices = [];
  final _blPrinterPlugin = BlPrinter();
  bool _isEnable = false;
  bool _hasPermission = false;
  BluetoothState status = BluetoothState(status: BluetoothStatus.disable);

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool enable = false;
    bool permission = false;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    _blPrinterPlugin.getBluetoothStatus().listen((event) async {
      if (event.status != BluetoothStatus.disable) {
        final devices = await _blPrinterPlugin.devices;
        setState(() {
          this.devices
            ..clear()
            ..addAll(devices);
        });
      }
      setState(() {
        status = event;
      });
    }).onError((e) {});
    try {
      platformVersion = await _blPrinterPlugin.getPlatformVersion() ??
          'Unknown platform version';
      enable = await _blPrinterPlugin.isBluetoothEnable;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isEnable = enable;
      _hasPermission = permission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Text('Running on: $_platformVersion '
                '\nEnable: $_isEnable'
                '\nStatus: $status'
                '\nPermisson: $_hasPermission'),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final item = devices[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.address),
                    selected: status.device?.address == item.address,
                    onTap: () {
                      if (status.status == BluetoothStatus.connected) {
                        _blPrinterPlugin.disconnect(item);
                      } else {
                        _blPrinterPlugin.connect(item);
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: devices.length,
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final data = await getTicket(withImage: true);
                    _blPrinterPlugin.printData(data);
                  },
                  child: const Text('print'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final data = await printQrSampe(withImage: true);
                    _blPrinterPlugin.printData(data);
                  },
                  child: const Text('print Sample QR'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _blPrinterPlugin.printTest();
                  },
                  child: const Text('print test'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<List<String>> getTicket({bool withImage = false}) async {
    final builder = PrintBuilder(PaperSize.mm58);

    if (withImage) {
      ByteData bytes = await rootBundle.load('assets/logo.png');
      var buffer = bytes.buffer;
      var m = base64Encode(Uint8List.view(buffer));
      builder.image(m, align: PrintAlign.center, width: 100, height: 100);
    }
    builder.feed(1);
    builder.text(
      "PT. Ivo Mas Tunggal",
      style: PrintTextStyle(
        align: PrintAlign.center,
        size: PrintSize.large,
        formats: {PrintFormat.bold},
      ),
    );
    builder.text(
      "Sungai Rokan Estate",
      style: PrintTextStyle(
        align: PrintAlign.center,
      ),
    );
    builder.text(
      "Pangkalan Rokan Mill",
      style: PrintTextStyle(align: PrintAlign.center, size: PrintSize.small),
    );

    builder.feed(1);
    builder.text(
      'SURAT PENGANTAR BIBIT ',
      style: PrintTextStyle(
        align: PrintAlign.center,
        size: PrintSize.large,
        formats: {PrintFormat.bold},
      ),
    );
    builder.text(
      'SRKE/BBT/05/23/AA001',
      style: PrintTextStyle(
        align: PrintAlign.center,
        formats: {PrintFormat.bold},
      ),
    );
    builder.hr();
    builder.feed(1);
    builder.row(
      cols: [
        ColumnPrint(text: "NoPol Kendaraan", width: 5),
        ColumnPrint(text: "NoPol Kendaraan", width: 3),
      ],
    );
    builder.row(
      cols: [
        ColumnPrint(text: "Nama Sopir", width: 5),
        ColumnPrint(text: "Jono", width: 3),
      ],
    );
    builder.row(
      cols: [
        ColumnPrint(text: "Tujuan", width: 5),
        ColumnPrint(text: "Kadista Estate", width: 3),
      ],
    );

    builder.feed(1);
    builder.feed(2);
    builder.table(
      headers: [
        ColumnPrint(text: "Batch", width: 5),
        ColumnPrint(
          text: "Tipe",
          width: 2,
          style: PrintTextStyle(align: PrintAlign.center),
        ),
        ColumnPrint(
          text: "Bedeng",
          width: 3,
        ),
        ColumnPrint(
          text: "Clone",
          width: 2,
          style: PrintTextStyle(align: PrintAlign.center),
        ),
        ColumnPrint(
          text: "Qty",
          width: 2,
          style: PrintTextStyle(align: PrintAlign.end),
        )
      ],
      bodies: [
        ['202201D122', 'D', 'PL-001', '-', '1000'],
        ['202201R122', 'R', 'PL-002', '1234', '500'],
        ['202201R122', 'R', 'PL-002', '1211', '500'],
        ['202201R122', 'R', 'PL-002', '1211', '500'],
        ['202201R122', 'R', 'PL-002', '1211', '500'],
      ],
      size: PrintSize.small,
    );

    builder.feed(5);
    final qrBytes = await QrPainter(
            data:
                "hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==",
            version: QrVersions.max,
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
            emptyColor: Colors.white)
        .toImageData(300);
    if (qrBytes != null) {
      var buffer = await convertImageToBitmap(qrBytes.buffer);
      var m = base64Encode(buffer);
      builder.image(m, align: PrintAlign.center, width: 300, height: 300);
    }

    builder.hr();
    builder.hr();
    builder.hr();
    builder.hr();
    builder.qrCode(
        'hRdqrGTtB52kKZKcna2+RUO4zs4V5Z7Reh7TYrXbQ7cCdkB6Vbe0JGYsz7mU44FITqMeY5R5QOJItE6KYkgqRUNQC8vIFIyYMrXrd/a3SbM8ZVyqhkOI8zJfhQa/rbM87CRhFr/1YdCWelx1MdvSnFm98zSZKgmsrliK+Sfel2El67m4tQ6aLOU7aM1nbRT4fkcV9MUfQH9VuBWwmWf673up+eFDp8Ba27rSD13hxWvssxadWyCUCIuo2Eh58Wr8mRo5SrwfSwBf266WEiPa3T6Ce60kYPfI6bgXO/xux6ZvxXeYI57KTJER7f9BsyBuA2QigLp/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==/Qve+PC4UDdRzSVOadzURC1Pr3FmA15KXi1UewaspvUrU9jP4D9OMqMaQetYKcb6rq7EiY4t+orVE0g==');
    builder.hr();
    builder.hr();

    return builder.result;
  }

  Future<List<String>> printQrSampe({bool withImage = false}) async {
    final builder = PrintBuilder(PaperSize.mm58);
    builder.hr();
    builder.feed(1);
    builder.image(
      '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',
      align: PrintAlign.center,
      width: 350,
      height: 350,
    );
    builder.feed(1);
    builder.hr();

    return builder.result;
  }

  Future<Uint8List> convertImageToBitmap(ByteBuffer image) async {
    final pngBytes = image.asUint8List();
    img.Image imgBitmap = img.decodeImage(Uint8List.fromList(pngBytes))!;
    img.Image resizedBitmap =
        img.copyResize(imgBitmap, width: 300); // Adjust the width as needed

    return Uint8List.fromList(img.encodePng(resizedBitmap));
  }
}
