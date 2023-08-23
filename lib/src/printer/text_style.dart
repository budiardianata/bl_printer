import 'enum.dart';

typedef PrintTextStyle = TextStyle;

class TextStyle {
  final bool wide;
  final PrintAlign align;
  final PrintSize size;
  final Set<PrintFormat> formats;

  const TextStyle.defaults({
    this.wide = false,
    this.align = PrintAlign.start,
    this.size = PrintSize.normal,
    this.formats = const {},
  });

  TextStyle({
    this.wide = false,
    this.align = PrintAlign.start,
    this.size = PrintSize.normal,
    this.formats = const {},
  });

  StringBuffer get code {
    final StringBuffer buffer = StringBuffer("{reset}");
    if (wide) {
      buffer.write("{w}");
    }
    buffer.write(align.code);
    buffer.write(size.code);
    final data = formats.map((e) => e.code);
    buffer.writeAll(data);
    return buffer;
  }

  @override
  String toString() {
    return '$code';
  }

  TextStyle copyWith({
    bool? wide,
    PrintAlign? align,
    PrintSize? size,
    Set<PrintFormat>? formats,
  }) {
    return TextStyle(
      wide: wide ?? this.wide,
      align: align ?? this.align,
      size: size ?? this.size,
      formats: formats ?? this.formats,
    );
  }
}
