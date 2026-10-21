import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_typography.dart';

class ScoreRing extends StatelessWidget {
  final int score;
  final int maxScore;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? trackColor;
  final Widget? child;
  final String? tierLabel;

  const ScoreRing({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.size = 140,
    this.strokeWidth = 12,
    this.progressColor,
    this.trackColor,
    this.child,
    this.tierLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (score / maxScore).clamp(0.0, 1.0);
    final color = progressColor ?? _getScoreColor(score);
    final track = trackColor ?? AppColors.border.withValues(alpha: 0.5);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ModernScoreRingPainter(
              progress: progress,
              trackColor: track,
              strokeWidth: strokeWidth,
            ),
          ),
          child ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // The tier pill only shows when the caller supplies a real
                  // tier; feedback scores are just a number, not a tier.
                  if (tierLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color: color.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Text(
                        tierLabel!,
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return AppColors.accentCyan;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class _ModernScoreRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final double strokeWidth;

  _ModernScoreRingPainter({
    required this.progress,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Subtle ambient glow
    final glowPaint = Paint()
      ..color = AppColors.accentGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Solid themed arc using the Luxe Green accent.
    final progressPaint = Paint()
      ..color = AppColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Tip Accent Dot
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    final tipCenter = Offset(tipX, tipY);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tipCenter, strokeWidth * 0.22, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}
