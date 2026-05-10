import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../data/models/asset_model.dart';

class SummaryStrip extends ConsumerWidget {
  final List<AssetModel> assets;
  const SummaryStrip({super.key, required this.assets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencyProvider).symbol;
    final active = assets.where((a) =>
        a.status == 'active' || a.status == 'warning' || a.status == 'critical').length;
    final warnings = assets.where((a) =>
        a.status == 'warning' || a.status == 'critical').length;
    final monthly = assets
        .where((a) => a.isDeterministic && a.status != 'expired' && a.status != 'finished')
        .fold<double>(0, (sum, a) => sum + a.cost);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _Stat(label: 'মাসিক খরচ', value: '$symbol${monthly.toStringAsFixed(0)}',
              color: AppColors.accent),
          _divider(),
          _Stat(label: 'সক্রিয়', value: '$active',
              color: AppColors.active),
          _divider(),
          _Stat(label: 'সতর্কতা', value: '$warnings',
              color: warnings > 0 ? AppColors.warning : AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 12),
    color: AppColors.cardBorder,
  );
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: AppTextStyles.cost.copyWith(color: color, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
