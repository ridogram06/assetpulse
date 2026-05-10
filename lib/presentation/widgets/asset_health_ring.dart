import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/asset_health_score.dart';
import '../../data/models/asset_model.dart';

/// FEAT-7 — Compact circular health ring (32 px) for asset cards.
/// Tap → bottom sheet with per-factor breakdown.
class AssetHealthRing extends StatelessWidget {
  final AssetModel asset;
  final int historyCount;
  final bool overBudgetThisMonth;
  final double size;

  const AssetHealthRing({
    super.key,
    required this.asset,
    this.historyCount = 0,
    this.overBudgetThisMonth = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final h = AssetHealth.compute(
      asset,
      historyCount: historyCount,
      overBudgetThisMonth: overBudgetThisMonth,
    );
    final color = _tierColor(h.tier);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showSheet(context, h, color);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: h.score / 100.0,
            color: color,
            track: AppColors.cardBorder,
          ),
          child: Center(
            child: Text(
              '${h.score}',
              style: TextStyle(
                color: color,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'good':
        return AppColors.active;
      case 'watch':
        return AppColors.warning;
      default:
        return AppColors.critical;
    }
  }

  void _showSheet(BuildContext context, HealthBreakdown h, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: h.score / 100.0,
                        color: color,
                        track: AppColors.cardBorder,
                        strokeWidth: 6,
                      ),
                      child: Center(
                        child: Text('${h.score}',
                            style: TextStyle(
                                color: color,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('স্বাস্থ্য বিবরণ',
                            style: AppTextStyles.titleLarge),
                        const SizedBox(height: 4),
                        Text(asset.name, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 8),
              ...h.factors.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          f.delta > 0
                              ? Icons.add_circle
                              : f.delta < 0
                                  ? Icons.remove_circle
                                  : Icons.circle_outlined,
                          size: 16,
                          color: f.delta > 0
                              ? AppColors.active
                              : f.delta < 0
                                  ? AppColors.critical
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f.label,
                              style: AppTextStyles.bodyMedium),
                        ),
                        if (f.delta != 0)
                          Text(
                            (f.delta > 0 ? '+' : '') + '${f.delta}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: f.delta > 0
                                  ? AppColors.active
                                  : AppColors.critical,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final Color track;
  final double strokeWidth;
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final progPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
