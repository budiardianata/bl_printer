import 'package:bl_printer/bl_printer.dart';
import 'package:bl_printer/src/bl_printer_method_channel.dart';
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

  test('test BluetoothDevice', () async {
    final selected = BluetoothDevice(name: 'budi', address: 'AA:BB:CC:DD:EE');
    final paired = BluetoothDevice(name: 'budi', address: 'AA:BB:CC:DD:EE');
    final isEqual = selected == paired;
    expect(isEqual, true);
  });


  int daysInMonth(int year, int month) {
    if (month == 2) {
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29; // Leap year
      } else {
        return 28; // Non-leap year
      }
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
    }
  }

  DateTime subtractMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month - months;

    while (month <= 0) {
      month += 12;
      year--;
    }

    int day = date.day;

    // Adjust day to last day of new month if original day is not valid for the new month
    int lastDayOfMonth = daysInMonth(year, month);
    if (day > lastDayOfMonth) {
      day = lastDayOfMonth;
    }

    return DateTime(year, month, day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
  }


  test('test BluetoothDevice2', () async {
    DateTime originalDate =
        DateTime(2023,2,28); // Replace this with your actual date

    // Subtract 9 months from the original date
    DateTime newDate = subtractMonths(originalDate,1); // Approximating 9 months as 30 days per month

    print('Original Date: $originalDate');
    print('New Date after subtracting 9 months: $newDate');
  });

}
