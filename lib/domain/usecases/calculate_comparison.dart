import '../../data/models/asset_history_model.dart';

class ComparisonResult {
  final int currentDays;
  final int? previousDays;
  final int? diffDays;
  final double currentCostPerDay;
  final double? previousCostPerDay;
  final String insight;

  const ComparisonResult({
    required this.currentDays,
    this.previousDays,
    this.diffDays,
    required this.currentCostPerDay,
    this.previousCostPerDay,
    required this.insight,
  });
}

class CalculateComparison {
  ComparisonResult? execute(List<AssetHistoryModel> history) {
    if (history.isEmpty) return null;

    final current = history.first;
    final previous = history.length > 1 ? history[1] : null;

    final diff = previous != null
        ? current.lifespanDays - previous.lifespanDays
        : null;

    String insight = '';
    if (diff != null) {
      if (diff > 0) {
        insight = 'আগেরটির চেয়ে $diff দিন বেশি চলেছে ✅';
      } else if (diff < 0) {
        insight = 'আগেরটির চেয়ে ${diff.abs()} দিন কম চলেছে ⚠';
      } else {
        insight = 'আগেরটির মতোই চলেছে';
      }
    }

    return ComparisonResult(
      currentDays:      current.lifespanDays,
      previousDays:     previous?.lifespanDays,
      diffDays:         diff,
      currentCostPerDay: current.costPerDay ?? 0,
      previousCostPerDay: previous?.costPerDay,
      insight:          insight,
    );
  }
}
