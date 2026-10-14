import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';

/// Chat-safe Markdown renderer for assistant and user messages.
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
    final base = style ?? DefaultTextStyle.of(context).style;
    final headingColor = base.color ?? AppColors.textPrimary;
    return MarkdownBody(
      data: data,
      softLineBreak: true,
      fitContent: true,
      styleSheet: MarkdownStyleSheet(
        p: base,
        strong: const TextStyle(fontWeight: FontWeight.w800),
        em: const TextStyle(fontStyle: FontStyle.italic),
        h1: base.copyWith(
          color: headingColor,
          fontSize: (base.fontSize ?? 14) + 6,
          fontWeight: FontWeight.w900,
        ),
        h2: base.copyWith(
          color: headingColor,
          fontSize: (base.fontSize ?? 14) + 4,
          fontWeight: FontWeight.w900,
        ),
        h3: base.copyWith(
          color: headingColor,
          fontSize: (base.fontSize ?? 14) + 2,
          fontWeight: FontWeight.w800,
        ),
        listBullet: base,
        code: base.copyWith(
          fontFamily: 'monospace',
          fontSize: (base.fontSize ?? 14) - 1,
          backgroundColor: Colors.transparent,
        ),
        codeblockPadding: const EdgeInsets.all(10),
        codeblockDecoration: BoxDecoration(
          color: _codeBackground(base.color),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: _codeBorder(base.color)),
        ),
        blockSpacing: 8,
        listIndent: 20,
        textAlign: _align(textAlign),
      ),
    );
  }

  WrapAlignment _align(TextAlign? value) {
    return switch (value) {
      TextAlign.center => WrapAlignment.center,
      TextAlign.right || TextAlign.end => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
  }

  Color _codeBackground(Color? textColor) {
    final color = textColor ?? AppColors.textPrimary;
    return color.computeLuminance() > .65
        ? Colors.white.withValues(alpha: .12)
        : AppColors.primaryDark.withValues(alpha: .06);
  }

  Color _codeBorder(Color? textColor) {
    final color = textColor ?? AppColors.textPrimary;
    return color.computeLuminance() > .65
        ? Colors.white.withValues(alpha: .16)
        : AppColors.border;
  }
}
