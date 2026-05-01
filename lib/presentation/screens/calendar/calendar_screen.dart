import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/asset_model.dart';
import '../../providers/asset_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('ক্যালেন্ডার', style: AppTextStyles.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: assetsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('$e')),
        data: (assets) => Column(
          children: [
            _MonthHeader(
              month: _month,
              onPrev: () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1)),
              onNext: () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1)),
            ),
            _CalendarGrid(
              month: _month,
              assets: assets,
              selected: _selected,
              onSelect: (d) => setState(() => _selected = d),
            ),
            const Divider(color: AppColors.cardBorder),
            Expanded(
              child: _selected == null
                  ? const Center(
                      child: Text('তারিখ বেছে নিন', style: AppTextStyles.bodyMedium))
                  : _DayDetail(date: _selected!, assets: assets),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev, onNext;
  const _MonthHeader(
      {required this.month, required this.onPrev, required this.onNext});

  static const _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left,
                  color: AppColors.textPrimary)),
          Text('${_months[month.month - 1]} ${month.year}',
              style: AppTextStyles.titleMedium),
          IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<AssetModel> assets;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  const _CalendarGrid(
      {required this.month, required this.assets,
       required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: startOffset + daysInMonth,
        itemBuilder: (_, i) {
          if (i < startOffset) return const SizedBox.shrink();
          final day = i - startOffset + 1;
          final date = DateTime(month.year, month.month, day);
          final isToday = date.year == today.year &&
              date.month == today.month && date.day == today.day;
          final isSelected = selected?.year == date.year &&
              selected?.month == date.month && selected?.day == date.day;

          final dayAssets = assets.where((a) {
            if (a.isDeterministic && a.endDate != null) {
              return a.endDate!.year == date.year &&
                  a.endDate!.month == date.month &&
                  a.endDate!.day == date.day;
            }
            if (a.isProbabilistic && a.predictedEndDate != null) {
              return a.predictedEndDate!.year == date.year &&
                  a.predictedEndDate!.month == date.month &&
                  a.predictedEndDate!.day == date.day;
            }
            return false;
          }).toList();

          final hasWarning = dayAssets.any((a) =>
              a.status == 'warning' || a.status == 'critical');
          final dotColor = hasWarning ? AppColors.warning : AppColors.active;

          return GestureDetector(
            onTap: () => onSelect(date),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.2)
                    : isToday
                        ? AppColors.accent.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: AppColors.accent, width: 1.5)
                    : isSelected
                        ? Border.all(color: AppColors.accent)
                        : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text('$day',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: isToday || isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary)),
                  if (dayAssets.isNotEmpty)
                    Positioned(
                      bottom: 3,
                      child: Text(
                        dayAssets.first.icon,
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  final DateTime date;
  final List<AssetModel> assets;
  const _DayDetail({required this.date, required this.assets});

  @override
  Widget build(BuildContext context) {
    final dayAssets = assets.where((a) {
      if (a.isDeterministic && a.endDate != null) {
        return a.endDate!.year == date.year && a.endDate!.month == date.month &&
            a.endDate!.day == date.day;
      }
      if (a.isProbabilistic && a.predictedEndDate != null) {
        return a.predictedEndDate!.year == date.year &&
            a.predictedEndDate!.month == date.month &&
            a.predictedEndDate!.day == date.day;
      }
      return false;
    }).toList();

    if (dayAssets.isEmpty) {
      return Center(
        child: Text(
          '${date.day}/${date.month}/${date.year} — কোনো সম্পদ নেই',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayAssets.length,
      itemBuilder: (_, i) {
        final a = dayAssets[i];
        return ListTile(
          leading: Text(a.icon, style: const TextStyle(fontSize: 28)),
          title: Text(a.name, style: AppTextStyles.bodyLarge),
          subtitle: Text(
            a.isProbabilistic ? '🤖 পূর্বাভাস' : 'মেয়াদ শেষ',
            style: AppTextStyles.bodySmall,
          ),
          trailing: Text('৳${a.cost.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium),
        );
      },
    );
  }
}
