import 'package:bl_printer/src/printer/column.dart';
import 'package:bl_printer/src/printer/enum.dart';
import 'package:bl_printer/src/printer/print_builder.dart';
import 'package:bl_printer/src/printer/text_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test generator', () async {
    final PrintBuilder generator = PrintBuilder(PaperSize.mm58);
    generator.row(cols: [
      ColumnPrint(text: "Batch", width: 5),
      ColumnPrint(text: "Tipe", width: 2,style: TextStyle(align: PrintAlign.center)),
      ColumnPrint(
        text: "Bedeng",
        width: 3,
      ),
      ColumnPrint(
        text: "Clone",
        width: 2,
        style: TextStyle(align: PrintAlign.center),
      ),
      ColumnPrint(
        text: "Qty",
        width: 2,
        style: TextStyle(align: PrintAlign.end),
      )
    ], size: PrintSize.small);
    final res = generator.result.first.replaceAll('{br}', '');
    print(res);
    print(res.length);
    expect(res.length, 42);
  });

  test('test table generator', () async {
    final PrintBuilder generator = PrintBuilder(PaperSize.mm58);
    generator.table(
      headers: [
        ColumnPrint(text: "Batch", width: 4),
        ColumnPrint(text: "Tipe", width: 2,style: TextStyle(align: PrintAlign.center)),
        ColumnPrint(
          text: "Bedeng",
          width: 3,
        ),
        ColumnPrint(
          text: "Clone",
          width: 2,
          style: TextStyle(align: PrintAlign.center),
        ),
        ColumnPrint(
          text: "Qty(PKK)",
          width: 3,
          style: TextStyle(align: PrintAlign.end),
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

    print(generator.result);
    expect(generator.result, [
      '{reset}{s}budi ardianata                {reset}{s}{b}{i}bagus deh{reset}{s}{b}{i}{u}bag{br}'
    ]);
  });
}
