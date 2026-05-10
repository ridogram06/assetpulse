import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../providers/filter_sort_provider.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(filterControllerProvider);
    final c = ref.read(filterControllerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                const Text('ফিল্টার', style: AppTextStyles.titleLarge),
                const Spacer(),
                if (f.activeCount > 0)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      c.clearAll();
                    },
                    child: const Text('সব মুছুন',
                        style: TextStyle(color: AppColors.critical)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(title: 'স্ট্যাটাস', children: [
              for (final s in const [
                ['active', 'সক্রিয়'],
                ['warning', 'সতর্কতা'],
                ['critical', 'জরুরি'],
                ['expired', 'মেয়াদোত্তীর্ণ'],
                ['suspended', 'স্থগিত'],
                ['finished', 'শেষ'],
              ])
                _Chip(
                  label: s[1],
                  selected: f.statuses.contains(s[0]),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    c.toggleStatus(s[0]);
                  },
                ),
            ]),
            _Section(title: 'টাইপ', children: [
              _Chip(
                label: 'নির্ধারিত',
                selected: f.types.contains('deterministic'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  c.toggleType('deterministic');
                },
              ),
              _Chip(
                label: 'সম্ভাব্য',
                selected: f.types.contains('probabilistic'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  c.toggleType('probabilistic');
                },
              ),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(f.activeCount > 0
                  ? 'প্রয়োগ করুন (${f.activeCount})'
                  : 'বন্ধ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}
