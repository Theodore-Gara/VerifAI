import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/shared/widgets/inline_markdown_text.dart';

void main() {
  testWidgets('renders double-asterisk bold without showing markers',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InlineMarkdownText('Make **this** bold'),
    ));

    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .singleWhere((widget) => widget.text.toPlainText() == 'Make this bold');
    final plain = rich.text.toPlainText();
    expect(plain, 'Make this bold');

    final bold = _flatten(rich.text as TextSpan)
        .singleWhere((span) => span.text == 'this');
    expect(bold.style?.fontWeight, FontWeight.w800);
  });

  testWidgets('leaves unmatched markers visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InlineMarkdownText('Keep **unfinished text'),
    ));

    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.toPlainText(), 'Keep **unfinished text');
  });
}

Iterable<TextSpan> _flatten(TextSpan span) sync* {
  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) yield* _flatten(child);
  }
}
