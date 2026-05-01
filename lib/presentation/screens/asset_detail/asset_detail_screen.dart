import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/asset_provider.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;
  const AssetDetailScreen({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAsync = ref.watch(singleAssetProvider(assetId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('বিস্তারিত', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: assetAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (asset) {
          if (asset == null) {
            return const Center(child: Text('Asset not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text(asset.icon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.name, style: AppTextStyles.headlineMedium),
                        Text(asset.category ?? '',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoCard(children: [
                _Row('ধরন', asset.isDeterministic ? 'নির্ধারিত' : 'সম্ভাব্য'),
                _Row('খরচ', '৳${asset.cost.toStringAsFixed(2)}'),
                _Row('মুদ্রা', asset.currency),
                _Row('স্ট্যাটাস', asset.status),
                _Row('শুরু',
                    '${asset.startDate.day}/${asset.startDate.month}/${asset.startDate.year}'),
                if (asset.endDate != null)
                  _Row('শেষ',
                      '${asset.endDate!.day}/${asset.endDate!.month}/${asset.endDate!.year}'),
                if (asset.billingCycle != null)
                  _Row('বিলিং চক্র', asset.billingCycle!),
                _Row('স্বয়ংক্রিয় নবায়ন', asset.autoRenew ? 'হ্যাঁ' : 'না'),
              ]),
              if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoCard(children: [
                  const Text('নোট', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(asset.notes!, style: AppTextStyles.bodyLarge),
                ]),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.critical,
                  side: const BorderSide(color: AppColors.critical),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('মুছুন'),
                onPressed: () => _confirmDelete(context, ref, asset.id),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('মুছবেন?', style: AppTextStyles.titleMedium),
        content: const Text('এই সম্পদটি স্থায়ীভাবে মুছে যাবে।',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('বাতিল')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('মুছুন',
                  style: TextStyle(color: AppColors.critical))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
