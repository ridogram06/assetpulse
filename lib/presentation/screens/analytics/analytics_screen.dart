import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/asset_model.dart';
import '../../providers/asset_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('বিশ্লেষণ', style: AppTextStyles.titleLarge),
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
        data: (assets) {
          final active = assets.where((a) =>
              a.isDeterministic && a.status != 'expired').toList();
          final monthly =
              active.fold<double>(0, (s, a) => s + a.cost);
          final annual = monthly * 12;
          final mostExpensive = active.isEmpty
              ? null
              : active.reduce((a, b) => a.cost > b.cost ? a : b);

          final byCategory = <String, double>{};
          for (final a in active) {
            final cat = a.category ?? 'অন্যান্য';
            byCategory[cat] = (byCategory[cat] ?? 0) + a.cost;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryRow(monthly: monthly, annual: annual),
              const SizedBox(height: 16),
              if (mostExpensive != null) _MostExpensiveCard(asset: mostExpensive),
              const SizedBox(height: 16),
              if (byCategory.isNotEmpty) _PieChartCard(data: byCategory),
              const SizedBox(height: 16),
              _CostPerDayList(assets: active),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double monthly, annual;
  const _SummaryRow({required this.monthly, required this.annual});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'এই মাসে',
          value: '৳${monthly.toStringAsFixed(0)}',
          color: AppColors.accent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'বার্ষিক (প্রজেক্টেড)',
          value: '৳${annual.toStringAsFixed(0)}',
          color: AppColors.blue,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.cost.copyWith(color: color, fontSize: 20)),
        ],
      ),
    );
  }
}

class _MostExpensiveCard extends StatelessWidget {
  final AssetModel asset;
  const _MostExpensiveCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(asset.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('সবচেয়ে বেশি খরচ', style: AppTextStyles.bodySmall),
                Text(asset.name, style: AppTextStyles.titleMedium),
              ],
            ),
          ),
          Text('৳${asset.cost.toStringAsFixed(0)}/মাস',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.critical)),
        ],
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final Map<String, double> data;
  const _PieChartCard({required this.data});

  static const _colors = [
    AppColors.accent, AppColors.blue, AppColors.active,
    AppColors.warning, AppColors.critical, AppColors.suspended,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('বিভাগ অনুযায়ী খরচ', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final pct = (e.value / total * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    color: _colors[i % _colors.length],
                    value: e.value,
                    title: '$pct%',
                    radius: 70,
                    titleStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(entries.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(entries[i].key, style: AppTextStyles.bodySmall),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CostPerDayList extends StatelessWidget {
  final List<AssetModel> assets;
  const _CostPerDayList({required this.assets});

  @override
  Widget build(BuildContext context) {
    final sorted = assets.toList()
      ..sort((a, b) {
        final aDays = a.endDate?.difference(a.startDate).inDays ?? 30;
        final bDays = b.endDate?.difference(b.startDate).inDays ?? 30;
        final aRate = aDays > 0 ? a.cost / aDays : 0;
        final bRate = bDays > 0 ? b.cost / bDays : 0;
        return bRate.compareTo(aRate);
      });
    final top3 = sorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('সর্বোচ্চ দৈনিক খরচ (টপ ৩)',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...top3.asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            final days = a.endDate?.difference(a.startDate).inDays ?? 30;
            final rate = days > 0 ? a.cost / days : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text('${i + 1}. ', style: AppTextStyles.bodySmall),
                  Text(a.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.name, style: AppTextStyles.bodyMedium)),
                  Text('৳${rate.toStringAsFixed(2)}/দিন',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.warning)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
