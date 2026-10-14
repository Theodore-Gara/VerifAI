import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifai/shared/widgets/inline_markdown_text.dart';

void main() {
  testWidgets('renders double-asterisk bold without showing markers',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: InlineMarkdownText('Make **this** bold'),
    ));

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Make this bold'), findsOneWidget);
  });

  testWidgets('supports headings, lists, and code blocks', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: InlineMarkdownText(
            '# Heading\n\n- one\n- two\n\n```dart\nfinal ok = true;\n```'),
      ),
    ));

    expect(find.text('Heading'), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.textContaining('final ok = true;'), findsOneWidget);
  });
}
