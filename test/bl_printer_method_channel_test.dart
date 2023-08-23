import 'package:bl_printer/src/bl_printer_method_channel.dart';
import 'package:bl_printer/src/printer/column.dart';
import 'package:bl_printer/src/printer/enum.dart';
import 'package:bl_printer/src/printer/print_builder.dart';
import 'package:bl_printer/src/printer/text_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelBlPrinter platform = MethodChannelBlPrinter();
  const MethodChannel channel = MethodChannel('bl_printer');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('test generator', () async {
    final PrintBuilder generator = PrintBuilder(PaperSize.mm58);
    generator.row(cols: [
      ColumnPrint(text: "budi ardianata", width: 10),
      ColumnPrint(
        text: "bagus deh",
        width: 2,
        style: TextStyle(formats: {PrintFormat.bold, PrintFormat.italic}),
      )
    ], size: PrintSize.small);
    expect(await platform.getPlatformVersion(), '42');
  });
}
