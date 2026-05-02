import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/global_time_provider.dart';
import '../../../../data/models/asset_model.dart';
import '../../../providers/asset_provider.dart';

class ProbabilisticCard extends ConsumerWidget {
  final AssetModel asset;
  const ProbabilisticCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/dashboard/asset/${asset.id}'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildLiveClockPanel(),
                if (asset.predictionConfidence != null &&
                    (asset.predictionConfidence ?? 0) > 0) ...[
                  const SizedBox(height: 10),
                  _buildPredictionBadge(),
                ],
                const SizedBox(height: 12),
                _buildMarkFinishedButton(context),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    final elapsed = DateTime.now().difference(asset.createdAt);
    final costPerDay = elapsed.inDays > 0
        ? asset.cost / elapsed.inDays
        : asset.cost;

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
              Text(
                '৳${costPerDay.toStringAsFixed(2)}/দিন · মোট ৳${asset.cost.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ONLY this widget rebuilds every second
  Widget _buildLiveClockPanel() {
    return Consumer(
      builder: (context, ref, child) {
        final now = ref.watch(globalTimeProvider).value ?? DateTime.now();
        final delta = now.difference(asset.createdAt);

        return RepaintBoundary(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Segment(value: delta.inDays,           label: 'দিন'),
              _Segment(value: delta.inHours % 24,     label: 'ঘণ্টা'),
              _Segment(value: delta.inMinutes % 60,   label: 'মিনিট'),
              _Segment(value: delta.inSeconds % 60,   label: 'সেকেন্ড'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPredictionBadge() {
    final conf = asset.predictionConfidence!.toStringAsFixed(0);
    final predictedDate = asset.predictedEndDate;

    if (predictedDate == null || predictedDate.isBefore(DateTime.now())) {
      return const SizedBox.shrink();
    }

    final daysLeft = predictedDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blueDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            'AI পূর্বাভাস: আরও ~$daysLeft দিন',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.blue),
          ),
          const Spacer(),
          Text('$conf%', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildMarkFinishedButton(BuildContext context) {
    // Need ref for invalidation — use Consumer
    return Consumer(builder: (context, ref, _) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.active.withOpacity(0.15),
          foregroundColor: AppColors.active,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.active.withOpacity(0.4)),
          ),
          elevation: 0,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showMarkFinishedSheet(context, ref);
        },
        child: const Text('✅ শেষ হয়েছে',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
    });
  }

  void _showMarkFinishedSheet(BuildContext context, WidgetRef ref) {
    final elapsed = DateTime.now().difference(asset.startDate);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('মোট আয়ু নিশ্চিত করুন',
                style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${elapsed.inDays} দিন ${elapsed.inHours % 24} ঘণ্টা',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.active),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('বাতিল'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.active,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final client = Supabase.instance.client;
                      final now = DateTime.now();
                      final lifespanDays = now.difference(asset.startDate).inDays;

                      // Insert history entry
                      await client.from('asset_history').insert({
                        'id': const Uuid().v4(),
                        'user_id': asset.userId,
                        'asset_id': asset.id,
                        'asset_name': asset.name,
                        'category': asset.category,
                        'cost': asset.cost,
                        'currency': asset.currency,
                        'start_date': asset.startDate.toIso8601String().split('T').first,
                        'finished_at': now.toIso8601String(),
                        'notes': null,
                        'created_at': now.toIso8601String(),
                      });

                      // Mark asset as finished
                      await client.from('assets').update({
                        'status': 'finished',
                        'finished_at': now.toIso8601String(),
                      }).eq('id', asset.id);

                      ref.invalidate(assetsProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('নিশ্চিত'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final int value;
  final String label;
  const _Segment({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: AppTextStyles.clockDigit,
        ),
        Text(label, style: AppTextStyles.clockLabel),
      ],
    );
  }
}
