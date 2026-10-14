import 'package:flutter/material.dart';

/// Tiny chat renderer for the Markdown style the assistants already emit.
class InlineMarkdownText extends StatelessWidget {
  const InlineMarkdownText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: style, children: _spans(data)),
      textAlign: textAlign,
    );
  }

  List<TextSpan> _spans(String text) {
    final spans = <TextSpan>[];
    var index = 0;
    while (index < text.length) {
      final start = text.indexOf('**', index);
      if (start < 0) {
        spans.add(TextSpan(text: text.substring(index)));
        break;
      }
      final end = text.indexOf('**', start + 2);
      if (end < 0) {
        spans.add(TextSpan(text: text.substring(index)));
        break;
      }
      if (start > index) {
        spans.add(TextSpan(text: text.substring(index, start)));
      }
      final bold = text.substring(start + 2, end);
      spans.add(TextSpan(
        text: bold,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ));
      index = end + 2;
    }
    return spans;
  }
}
