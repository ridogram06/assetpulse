import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/asset_model.dart';
import '../../../providers/auth_provider.dart';

class BudgetGauge extends ConsumerWidget {
  final List<AssetModel> assets;
  const BudgetGauge({super.key, required this.assets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = assets
        .where((a) => a.isDeterministic && a.status != 'expired')
        .fold<double>(0, (s, a) => s + a.cost);
    final profile = ref.watch(profileProvider).valueOrNull;
    final budget = (profile?['monthly_budget'] as num?)?.toDouble() ?? 5000.0;
    final ratio = (spent / budget).clamp(0.0, 1.0);
    final color = ratio > 1.0
        ? AppColors.critical
        : ratio > 0.8
            ? AppColors.warning
            : AppColors.active;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('বাজেট ব্যবহার', style: AppTextStyles.bodySmall),
              Text('৳${spent.toStringAsFixed(0)} / ৳${budget.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
