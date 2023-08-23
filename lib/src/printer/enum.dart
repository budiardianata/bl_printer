enum PaperSize { mm58, mm80, mm116 }

enum PrintSize {
  small('{s}'),
  normal(''),
  large('{h}');

  const PrintSize(this.code);

  final String code;
}

enum PrintFormat {
  bold('{b}'),
  italic('{i}'),
  underline('{u}');

  const PrintFormat(this.code);

  final String code;
}

enum PrintAlign {
  start(''),
  center('{center}'),
  end('{right}');

  const PrintAlign(this.code);

  final String code;
}
