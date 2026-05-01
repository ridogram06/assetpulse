import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/asset_model.dart';

class WarningBanner extends StatelessWidget {
  final List<AssetModel> assets;
  const WarningBanner({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    final critical = assets.where((a) => a.status == 'critical').toList();
    final hasCritical = critical.isNotEmpty;
    final color = hasCritical ? AppColors.critical : AppColors.warning;
    final bgColor = hasCritical ? AppColors.criticalDim : AppColors.warningDim;

    final names = (hasCritical ? critical : assets).take(2).map((a) => a.name).join(', ');
    final count = (hasCritical ? critical : assets).length;
    final suffix = count > 2 ? ' +${count - 2} আরও' : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(hasCritical ? Icons.error_outline : Icons.warning_amber_outlined,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${hasCritical ? "জরুরি" : "সতর্কতা"}: $names$suffix — মেয়াদ শেষ হচ্ছে!',
              style: AppTextStyles.bodyMedium.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
