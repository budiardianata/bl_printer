import 'column.dart' show ColumnPrint;
import 'enum.dart' show PrintAlign, PaperSize, PrintFormat, PrintSize;
import 'text_style.dart' show PrintTextStyle;

class PrintBuilder {
  PrintBuilder(this._paper);

  final PaperSize _paper;
  final _args = <String>[];

  List<String> get result => _args;

  int _maxCharsPerLine([PrintSize size = PrintSize.normal]) {
    final isSmall = size == PrintSize.small;
    if (_paper == PaperSize.mm58) {
      return isSmall ? 42 : 32;
    } else if (_paper == PaperSize.mm116) {
      return 68;
    } else {
      return 48;
    }
  }

  int _maxColPerLine([PrintSize size = PrintSize.normal]) {
    final isSmallText = size == PrintSize.small;

    if (_paper == PaperSize.mm58) {
      return isSmallText ? 14 : 8;
    } else {
      return 12;
    }
  }

  String get _newLineCode => '{br}';

  String _createAlignedText(
    String givenText,
    int length,
    PrintAlign alignment, {
    String fillChar = ' ',
  }) {
    final textLength = givenText.length;
    final maxLength = length - 1;
    if (textLength >= length) {
      return givenText.substring(0, length);
    }

    final spaceCount = maxLength - textLength;
    final spaces = fillChar * spaceCount;
    switch (alignment) {
      case PrintAlign.start:
        return '$givenText$spaces$fillChar';
      case PrintAlign.center:
        final adjustSpace = spaceCount + 1;
        final leftSpaces = adjustSpace ~/ 2;
        final rightSpaces = adjustSpace - leftSpaces;
        return (fillChar * leftSpaces) + givenText + (fillChar * rightSpaces);
      case PrintAlign.end:
        return '$fillChar$spaces$givenText';
    }
  }

  String _formatText(
    String text,
    PrintTextStyle style, [
    int? maxLength,
  ]) {
    final buffer = style.code;
    if (maxLength == null) {
      return '$buffer$text';
    }

    final alignText = _createAlignedText(text, maxLength, style.align);
    return '$buffer$alignText';
  }

  void feed(int i) {
    _args.add('{br}' * i);
  }

  void hr({String char = '-', PrintSize size = PrintSize.normal}) {
    _args.add("${char * _maxCharsPerLine(size)}$_newLineCode");
  }

  void text(
    String text, {
    PrintTextStyle style = const PrintTextStyle.defaults(),
    bool newLine = true,
  }) {
    String formattedText = _formatText(text, style);
    if (newLine) {
      formattedText += _newLineCode;
    }
    _args.add(formattedText);
  }

  int _maxRowCol(List<ColumnPrint> items, PrintSize size) {
    final maxRowCol = _maxColPerLine(size);
    final validCols = items.fold(0, (sum, col) => sum + col.width) == maxRowCol;
    if (!validCols) {
      throw Exception('Total columns width must be equal to $maxRowCol');
    }
    return maxRowCol;
  }

  List<String> _createRowTexts(
    List<ColumnPrint> cols,
    PrintSize size,
    int maxChar,
    int maxCol, [
    bool underline = false,
  ]) {
    final result = <String>[];
    for (final item in cols) {
      final maxCharPerCol = ((maxChar / maxCol) * item.width).floor();
      final formats = Set<PrintFormat>.from(item.style.formats);
      if (underline) {
        formats.add(PrintFormat.underline);
      }
      final style = item.style.copyWith(
        wide: false,
        size: size,
        formats: formats,
      );
      final formattedText = _formatText(item.text, style, maxCharPerCol);
      result.add(formattedText);
    }
    return result;
  }

  void row({
    required List<ColumnPrint> cols,
    PrintSize size = PrintSize.normal,
  }) {
    final maxCol = _maxRowCol(cols, size);
    final maxChar = _maxCharsPerLine(size);
    final buffer = StringBuffer();
    final texts = _createRowTexts(cols, size, maxChar, maxCol);
    buffer.writeAll(texts);
    _args.add('$buffer$_newLineCode');
  }

  void table({
    required List<ColumnPrint> headers,
    required List<List<String>> bodies,
    PrintSize size = PrintSize.normal,
  }) {
    final maxCol = _maxRowCol(headers, size);
    final validBodies = bodies.every((list) => list.length == headers.length);
    if (!validBodies) {
      throw Exception(
          'bodies item length must be equal with header length (${bodies.length})');
    }
    int maxChar = _maxCharsPerLine(size);
    final headerText = _createRowTexts(headers, size, maxChar, maxCol, true);
    StringBuffer buffer = StringBuffer();
    buffer.writeAll(headerText);
    buffer.write(_newLineCode);
    for (int i = 0; i < bodies.length; ++i) {
      final body = bodies[i];
      final isLast = i == (bodies.length - 1);
      for (int j = 0; j < body.length; ++j) {
        final header = headers[j];
        final item = body[j];
        int maxCharPerCol = ((maxChar / maxCol) * header.width).floor();
        final formats = Set<PrintFormat>.from(header.style.formats);
        if (isLast) {
          formats.add(PrintFormat.underline);
        }
        final style = header.style.copyWith(
          wide: false,
          size: size,
          formats: formats,
        );
        String formattedText = _formatText(item, style, maxCharPerCol);
        buffer.write(formattedText);
      }
      buffer.write(_newLineCode);
    }
    _args.add('$buffer');
  }

  void image(
    String base64, {
    PrintAlign align = PrintAlign.start,
    int width = 300,
    int height = 300,
  }) {
    _args.add("bitmap#$base64#${align.index}#$width#$height");
  }

  void qrCode(
    String text, {
    PrintAlign align = PrintAlign.center,
    int size = 27,
  }) {
    _args.add("qrCode#$text#${align.index}#$size");
  }
}
