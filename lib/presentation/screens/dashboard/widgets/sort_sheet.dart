import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../providers/filter_sort_provider.dart';

const _sortLabels = <SortMode, String>{
  SortMode.alphabetical: 'অক্ষর অনুযায়ী (A→Z)',
  SortMode.expirySoonest: 'মেয়াদ (আগে যেটি)',
  SortMode.mostExpensive: 'সবচেয়ে দামী',
  SortMode.cheapest: 'সবচেয়ে সস্তা',
  SortMode.highestCostPerDay: 'প্রতিদিন বেশি খরচ',
  SortMode.lowestCostPerDay: 'প্রতিদিন কম খরচ',
  SortMode.newest: 'নতুন আগে',
  SortMode.oldest: 'পুরানো আগে',
  SortMode.warningPriority: 'অগ্রাধিকার (জরুরি আগে)',
};

class SortSheet extends ConsumerWidget {
  const SortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(filterControllerProvider);
    final c = ref.read(filterControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const Text('সাজান', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          ..._sortLabels.entries.map((e) => RadioListTile<SortMode>(
                value: e.key,
                groupValue: f.sortMode,
                onChanged: (v) {
                  if (v == null) return;
                  HapticFeedback.selectionClick();
                  c.setSort(v);
                },
                title: Text(e.value, style: AppTextStyles.bodyMedium),
                activeColor: AppColors.accent,
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
          const Divider(color: AppColors.cardBorder),
          SwitchListTile(
            value: f.reverse,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              c.toggleReverse();
            },
            title: const Text('উল্টো ক্রম', style: AppTextStyles.bodyMedium),
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('প্রয়োগ করুন'),
          ),
        ],
      ),
    );
  }
}
