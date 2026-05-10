import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/asset_model.dart';
import 'asset_provider.dart';

enum SortMode {
  alphabetical,
  expirySoonest,
  mostExpensive,
  cheapest,
  highestCostPerDay,
  lowestCostPerDay,
  newest,
  oldest,
  warningPriority,
}

class FilterState {
  final Set<String> statuses;       // 'active','warning','critical','expired','suspended','finished'
  final Set<String> types;          // 'deterministic','probabilistic'
  final Set<String> categories;
  final Set<String> paymentMethods;
  final Set<String> vaultIds;
  final SortMode sortMode;
  final bool reverse;

  const FilterState({
    this.statuses = const {},
    this.types = const {},
    this.categories = const {},
    this.paymentMethods = const {},
    this.vaultIds = const {},
    this.sortMode = SortMode.newest,
    this.reverse = false,
  });

  int get activeCount =>
      statuses.length +
      types.length +
      categories.length +
      paymentMethods.length +
      vaultIds.length;

  FilterState copyWith({
    Set<String>? statuses,
    Set<String>? types,
    Set<String>? categories,
    Set<String>? paymentMethods,
    Set<String>? vaultIds,
    SortMode? sortMode,
    bool? reverse,
  }) =>
      FilterState(
        statuses: statuses ?? this.statuses,
        types: types ?? this.types,
        categories: categories ?? this.categories,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        vaultIds: vaultIds ?? this.vaultIds,
        sortMode: sortMode ?? this.sortMode,
        reverse: reverse ?? this.reverse,
      );
}

class FilterController extends StateNotifier<FilterState> {
  FilterController() : super(const FilterState());

  void toggleStatus(String s) {
    final next = Set<String>.from(state.statuses);
    next.contains(s) ? next.remove(s) : next.add(s);
    state = state.copyWith(statuses: next);
  }

  void toggleType(String t) {
    final next = Set<String>.from(state.types);
    next.contains(t) ? next.remove(t) : next.add(t);
    state = state.copyWith(types: next);
  }

  void toggleCategory(String c) {
    final next = Set<String>.from(state.categories);
    next.contains(c) ? next.remove(c) : next.add(c);
    state = state.copyWith(categories: next);
  }

  void togglePayment(String p) {
    final next = Set<String>.from(state.paymentMethods);
    next.contains(p) ? next.remove(p) : next.add(p);
    state = state.copyWith(paymentMethods: next);
  }

  void toggleVault(String v) {
    final next = Set<String>.from(state.vaultIds);
    next.contains(v) ? next.remove(v) : next.add(v);
    state = state.copyWith(vaultIds: next);
  }

  void setSort(SortMode m) => state = state.copyWith(sortMode: m);
  void toggleReverse() => state = state.copyWith(reverse: !state.reverse);
  void clearAll() => state = const FilterState();
}

final filterControllerProvider =
    StateNotifierProvider<FilterController, FilterState>(
        (ref) => FilterController());

/// Derived: assets filtered + sorted based on current FilterState
final filteredAssetsProvider = Provider<AsyncValue<List<AssetModel>>>((ref) {
  final base = ref.watch(assetsProvider);
  final f = ref.watch(filterControllerProvider);

  return base.whenData((assets) {
    var list = assets.where((a) {
      if (f.statuses.isNotEmpty && !f.statuses.contains(a.status)) return false;
      if (f.types.isNotEmpty && !f.types.contains(a.assetType)) return false;
      if (f.categories.isNotEmpty &&
          (a.category == null || !f.categories.contains(a.category))) {
        return false;
      }
      if (f.paymentMethods.isNotEmpty &&
          (a.paymentMethodId == null ||
              !f.paymentMethods.contains(a.paymentMethodId))) {
        return false;
      }
      if (f.vaultIds.isNotEmpty &&
          (a.vaultId == null || !f.vaultIds.contains(a.vaultId))) {
        return false;
      }
      return true;
    }).toList();

    int statusRank(String s) => switch (s) {
          'critical' => 0,
          'warning' => 1,
          'active' => 2,
          'suspended' => 3,
          'expired' => 4,
          'finished' => 5,
          _ => 6,
        };

    double cpd(AssetModel a) {
      if (a.endDate != null) {
        final d = a.endDate!.difference(a.startDate).inDays;
        return d > 0 ? a.cost / d : a.cost;
      }
      final d = DateTime.now().difference(a.createdAt).inDays;
      return d > 0 ? a.cost / d : a.cost;
    }

    list.sort((a, b) {
      switch (f.sortMode) {
        case SortMode.alphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortMode.expirySoonest:
          final ae = a.endDate ?? a.predictedEndDate ?? DateTime(2999);
          final be = b.endDate ?? b.predictedEndDate ?? DateTime(2999);
          return ae.compareTo(be);
        case SortMode.mostExpensive:
          return b.cost.compareTo(a.cost);
        case SortMode.cheapest:
          return a.cost.compareTo(b.cost);
        case SortMode.highestCostPerDay:
          return cpd(b).compareTo(cpd(a));
        case SortMode.lowestCostPerDay:
          return cpd(a).compareTo(cpd(b));
        case SortMode.newest:
          return b.createdAt.compareTo(a.createdAt);
        case SortMode.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case SortMode.warningPriority:
          return statusRank(a.status).compareTo(statusRank(b.status));
      }
    });

    if (f.reverse) list = list.reversed.toList();
    return list;
  });
});
