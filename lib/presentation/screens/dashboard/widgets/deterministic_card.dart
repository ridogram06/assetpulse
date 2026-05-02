import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/global_time_provider.dart';
import '../../../../data/models/asset_model.dart';

class DeterministicCard extends StatelessWidget {
  final AssetModel asset;
  const DeterministicCard({super.key, required this.asset});

  Color get _statusColor {
    switch (asset.status) {
      case 'critical':  return AppColors.critical;
      case 'warning':   return AppColors.warning;
      case 'expired':   return AppColors.textMuted;
      case 'suspended': return AppColors.suspended;
      default:          return AppColors.active;
    }
  }

  Color get _statusBg {
    switch (asset.status) {
      case 'critical':  return AppColors.criticalDim;
      case 'warning':   return AppColors.warningDim;
      case 'suspended': return AppColors.surface;
      default:          return AppColors.activeDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dashboard/asset/${asset.id}'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: asset.status == 'critical'
              ? AppColors.critical.withOpacity(0.5)
              : asset.status == 'warning'
                  ? AppColors.warning.withOpacity(0.4)
                  : AppColors.cardBorder,
        ),
        boxShadow: asset.status == 'critical'
            ? [BoxShadow(color: AppColors.critical.withOpacity(0.2), blurRadius: 12)]
            : asset.status == 'warning'
                ? [BoxShadow(color: AppColors.warning.withOpacity(0.15), blurRadius: 10)]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildDualTimePanel(),
                const SizedBox(height: 12),
                _buildProgressBar(),
                const SizedBox(height: 12),
                _buildActionRow(context),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(asset.icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asset.name, style: AppTextStyles.titleMedium),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      asset.status == 'active' ? '● সক্রিয়'
                          : asset.status == 'warning' ? '⚠ সতর্কতা'
                          : asset.status == 'critical' ? '● জরুরি'
                          : asset.status == 'suspended' ? '⏸ স্থগিত'
                          : '● মেয়াদোত্তীর্ণ',
                      style: AppTextStyles.bodySmall.copyWith(color: _statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('৳${asset.cost.toStringAsFixed(0)}/মাস',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDualTimePanel() {
    if (asset.endDate == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final elapsed = now.difference(asset.startDate).inDays;
    final total = asset.endDate!.difference(asset.startDate).inDays;
    final remaining = asset.endDate!.difference(now).inDays;

    return Consumer(
      builder: (context, ref, _) {
        final liveNow = ref.watch(globalTimeProvider).value ?? DateTime.now();
        final liveRemaining = asset.endDate!.difference(liveNow);
        final hrs = liveRemaining.inHours % 24;
        final mins = liveRemaining.inMinutes % 60;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TimePanel(
                    value: '$elapsed',
                    label: 'দিন ব্যবহার হয়েছে',
                    color: AppColors.blue,
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.cardBorder),
                Expanded(
                  child: _TimePanel(
                    value: '$remaining দিন $hrs ঘণ্টা $mins মিনিট',
                    label: 'বাকি আছে',
                    color: _statusColor,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar() {
    if (asset.endDate == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final elapsed = now.difference(asset.startDate).inDays;
    final total = asset.endDate!.difference(asset.startDate).inDays;
    final ratio = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            minHeight: 8,
          ),
        ),
        // Tick marks at 25%, 50%, 75%
        for (final tick in [0.25, 0.5, 0.75])
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment(-1.0 + 2.0 * tick, 0),
              widthFactor: null,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 1, height: 8, color: AppColors.bg),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.notifications_outlined,
          label: 'রিমাইন্ডার',
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('রিমাইন্ডার সেট হয়েছে ✓'), duration: Duration(seconds: 1)),
            );
          },
        ),
        const SizedBox(width: 8),
        _ActionBtn(
          icon: Icons.edit_outlined,
          label: 'বিস্তারিত',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/dashboard/asset/${asset.id}');
          },
        ),
        const SizedBox(width: 8),
        _ActionBtn(
          icon: Icons.bar_chart_outlined,
          label: 'ইতিহাস',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/dashboard/asset/${asset.id}');
          },
        ),
      ],
    );
  }
}

class _TimePanel extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool alignEnd;
  const _TimePanel({
    required this.value, required this.label,
    required this.color, this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
                color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
