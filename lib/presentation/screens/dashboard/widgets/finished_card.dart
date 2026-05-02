import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/asset_model.dart';

class FinishedCard extends StatelessWidget {
  final AssetModel asset;
  const FinishedCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final duration = asset.finishedAt != null
        ? asset.finishedAt!.difference(asset.startDate)
        : null;
    final days = duration?.inDays ?? 0;
    final costPerDay = days > 0 ? asset.cost / days : 0.0;

    return GestureDetector(
      onTap: () => context.push('/dashboard/asset/${asset.id}'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(asset.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.name, style: AppTextStyles.titleMedium),
                      Text('শেষ হয়েছে',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text('✓ শেষ',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(
                  label: 'মোট আয়ু',
                  value: '$days দিন',
                  color: AppColors.textPrimary,
                ),
                _Stat(
                  label: 'প্রতিদিন',
                  value: '৳${costPerDay.toStringAsFixed(2)}',
                  color: AppColors.textSecondary,
                ),
                _Stat(
                  label: 'মোট খরচ',
                  value: '৳${asset.cost.toStringAsFixed(0)}',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
