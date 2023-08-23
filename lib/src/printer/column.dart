import 'text_style.dart';

class ColumnPrint {
  final String text;
  final int width;
  final TextStyle style;

  ColumnPrint({
    required this.text,
    required this.width,
    this.style = const TextStyle.defaults(),
  });

  ColumnPrint copyWith({
    String? text,
    int? width,
    TextStyle? style,
  }) {
    return ColumnPrint(
      text: text ?? this.text,
      width: width ?? this.width,
      style: style ?? this.style,
    );
  }
}
