import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/asset_model.dart';
import '../../../../domain/usecases/asset_actions.dart';
import '../../../providers/asset_provider.dart';
import 'package:go_router/go_router.dart';
import 'deterministic_card.dart';
import 'probabilistic_card.dart';
import 'finished_card.dart';
import 'mark_finished_sheet.dart';

class AssetList extends ConsumerWidget {
  final List<AssetModel> assets;
  const AssetList({super.key, required this.assets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final card = asset.isFinished
            ? FinishedCard(asset: asset)
            : asset.isDeterministic
                ? DeterministicCard(asset: asset)
                : ProbabilisticCard(asset: asset);

        // Finished cards: no swipe/long-press — just show
        if (asset.isFinished) return card;

        return GestureDetector(
          onLongPress: () => _showQuickActions(context, ref, asset),
          child: Dismissible(
            key: ValueKey('asset_${asset.id}'),
            background: _SwipeBg(
              alignment: Alignment.centerLeft,
              color: asset.isDeterministic && !asset.isSuspended
                  ? AppColors.warning
                  : AppColors.cardBorder,
              icon: asset.isDeterministic && !asset.isSuspended
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              label: asset.isSuspended
                  ? 'চালু করুন'
                  : asset.isDeterministic
                      ? 'স্থগিত'
                      : '',
            ),
            secondaryBackground: const _SwipeBg(
              alignment: Alignment.centerRight,
              color: AppColors.critical,
              icon: Icons.delete_outline,
              label: 'মুছুন',
            ),
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.endToStart) {
                return await _confirmDelete(context);
              } else {
                // Right-swipe: suspend (deterministic only) or resume
                try {
                  if (asset.isSuspended) {
                    await AssetActions.resume(asset.id);
                  } else if (asset.isDeterministic) {
                    await AssetActions.suspend(asset.id);
                  }
                  ref.invalidate(assetsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('অ্যাকশন ব্যর্থ: $e')),
                    );
                  }
                }
                return false; // never dismiss for right-swipe
              }
            },
            onDismissed: (_) async {
              try {
                await AssetActions.delete(asset.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${asset.name} মুছে ফেলা হয়েছে')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('মুছতে ব্যর্থ: $e')),
                  );
                }
              } finally {
                ref.invalidate(assetsProvider);
              }
            },
            child: card,
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('মুছে ফেলবেন?', style: AppTextStyles.titleMedium),
        content: const Text('এই সম্পদ স্থায়ীভাবে মুছে যাবে।',
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
    return ok ?? false;
  }

  void _showQuickActions(BuildContext context, WidgetRef ref, AssetModel asset) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(children: [
                Text(asset.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(asset.name, style: AppTextStyles.titleMedium)),
              ]),
            ),
            const Divider(color: AppColors.cardBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
              title: const Text('বিস্তারিত', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                context.push('/dashboard/asset/${asset.id}');
              },
            ),
            if (asset.isProbabilistic)
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.active),
                title: const Text('শেষ হয়েছে', style: AppTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => MarkFinishedSheet(asset: asset),
                  );
                },
              ),
            if (asset.isDeterministic && !asset.isSuspended)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline, color: AppColors.warning),
                title: const Text('স্থগিত করুন', style: AppTextStyles.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await AssetActions.suspend(asset.id);
                    ref.invalidate(assetsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('স্থগিত ব্যর্থ: $e')),
                      );
                    }
                  }
                },
              ),
            if (asset.isSuspended)
              ListTile(
                leading: const Icon(Icons.play_circle_outline, color: AppColors.active),
                title: const Text('চালু করুন', style: AppTextStyles.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await AssetActions.resume(asset.id);
                    ref.invalidate(assetsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('চালু করা ব্যর্থ: $e')),
                      );
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.critical),
              title: const Text('মুছুন',
                  style: TextStyle(color: AppColors.critical, fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmDelete(context);
                if (!ok) return;
                try {
                  await AssetActions.delete(asset.id);
                  ref.invalidate(assetsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('মুছতে ব্যর্থ: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ] else ...[
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(icon, color: color),
          ],
        ],
      ),
    );
  }
}
