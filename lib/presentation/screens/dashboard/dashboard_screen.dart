import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/asset_provider.dart';
import '../../providers/filter_sort_provider.dart';
import 'widgets/summary_strip.dart';
import 'widgets/warning_banner.dart';
import 'widgets/asset_list.dart';
import 'widgets/budget_gauge.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/sort_sheet.dart';
import '../add_asset/add_asset_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider);
    final filteredAsync = ref.watch(filteredAssetsProvider);
    final filterCount = ref.watch(filterControllerProvider).activeCount;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('AssetPulse', style: AppTextStyles.titleLarge),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                tooltip: 'ফিল্টার',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const FilterSheet(),
                  );
                },
              ),
              if (filterCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$filterCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: AppColors.textSecondary),
            tooltip: 'সাজান',
            onPressed: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const SortSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textSecondary),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textSecondary),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.cardBorder),
        ),
      ),
      body: assetsAsync.when(
        loading: () => const _SkeletonLoading(),
        error: (e, _) => Center(
          child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
        data: (allAssets) {
          // Summary/banner/budget always reflect ALL assets;
          // only the list itself is filtered/sorted.
          final criticalAssets = allAssets
              .where((a) => a.status == 'critical' || a.status == 'warning')
              .toList();
          final filtered = filteredAsync.value ?? allAssets;

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.refresh(assetsProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (criticalAssets.isNotEmpty)
                        WarningBanner(assets: criticalAssets),
                      SummaryStrip(assets: allAssets),
                      BudgetGauge(assets: allAssets),
                    ],
                  ),
                ),
                if (allAssets.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else if (filtered.isEmpty)
                  const SliverFillRemaining(child: _NoMatchState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: AssetList(assets: filtered),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddAssetSheet(),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.15),
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 1: context.push('/calendar'); break;
            case 2: context.push('/analytics'); break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
            label: 'ড্যাশবোর্ড',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.accent),
            label: 'ক্যালেন্ডার',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.accent),
            label: 'বিশ্লেষণ',
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _NoMatchState extends ConsumerWidget {
  const _NoMatchState();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('কোনো ফলাফল নেই', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          const Text('ফিল্টার পরিবর্তন করুন', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(filterControllerProvider.notifier).clearAll(),
            child: const Text('সব মুছুন'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📦', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(AppStrings.noAssets, style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          const Text(AppStrings.addFirstAsset,
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
