import '../../data/models/asset_model.dart';

/// FEAT-7 — Asset Health Score (0..100).
/// Pure-function scoring + per-factor breakdown for the bottom-sheet view.
class HealthFactor {
  final String label;
  final int delta; // positive = bonus, negative = penalty
  const HealthFactor(this.label, this.delta);
}

class HealthBreakdown {
  final int score; // 0..100, clamped
  final List<HealthFactor> factors;
  const HealthBreakdown({required this.score, required this.factors});

  /// Color tier:
  ///   80-100 => green ("good")
  ///   50-79  => yellow ("watch")
  ///   0-49   => red ("bad")
  String get tier {
    if (score >= 80) return 'good';
    if (score >= 50) return 'watch';
    return 'bad';
  }
}

class AssetHealth {
  /// Compute health for a single asset.
  /// Optional [historyCount] is used by the probabilistic branch.
  static HealthBreakdown compute(
    AssetModel a, {
    int historyCount = 0,
    bool overBudgetThisMonth = false,
  }) {
    if (a.isFinished) {
      return const HealthBreakdown(score: 100, factors: [
        HealthFactor('শেষ হয়েছে', 0),
      ]);
    }
    if (a.isSuspended) {
      return const HealthBreakdown(score: 60, factors: [
        HealthFactor('স্থগিত', -40),
      ]);
    }

    final factors = <HealthFactor>[];
    int base = 100;

    if (a.isDeterministic) {
      // Days until expiry
      if (a.endDate != null) {
        final daysLeft =
            a.endDate!.difference(DateTime.now()).inDays;
        if (daysLeft < 0) {
          factors.add(const HealthFactor('মেয়াদ পেরিয়ে গেছে', -80));
          base -= 80;
        } else if (daysLeft < 3) {
          factors.add(const HealthFactor('৩ দিনের কম সময়', -50));
          base -= 50;
        } else if (daysLeft < 7) {
          factors.add(const HealthFactor('৭ দিনের কম সময়', -30));
          base -= 30;
        }
      }

      if (overBudgetThisMonth) {
        factors.add(const HealthFactor('বাজেট ছাড়িয়ে গেছে', -20));
        base -= 20;
      }

      if (a.paymentMethodId == null) {
        factors.add(const HealthFactor('পেমেন্ট method সেট নাই', -10));
        base -= 10;
      }

      // auto_renew off + expiring soon
      final daysLeft =
          a.endDate?.difference(DateTime.now()).inDays ?? 999;
      if (!a.autoRenew && daysLeft < 7 && daysLeft >= 0) {
        factors.add(const HealthFactor('Auto-renew বন্ধ', -10));
        base -= 10;
      }

      // Bonus: notifications enabled (proxy: notifyDaysBefore > 0)
      if (a.notifyDaysBefore > 0) {
        factors.add(const HealthFactor('Notification on', 10));
        base += 10;
      }
    } else {
      // Probabilistic
      final conf = a.predictionConfidence ?? 0;
      if (conf > 0 && conf < 50) {
        factors.add(HealthFactor(
            'নিশ্চিততা কম (${conf.toStringAsFixed(0)}%)', -20));
        base -= 20;
      }

      // Running longer than predicted by >10%?
      if (a.predictedEndDate != null) {
        final predicted = a.predictedEndDate!;
        final now = DateTime.now();
        if (now.isAfter(predicted)) {
          final overshoot = now.difference(predicted).inDays;
          final span = predicted.difference(a.startDate).inDays;
          if (span > 0 && overshoot / span > 0.10) {
            factors.add(const HealthFactor('পূর্বাভাস ছাড়িয়ে চলছে', -10));
            base -= 10;
          }
        }
      }

      // Bonus: rich history
      if (historyCount >= 5) {
        factors.add(HealthFactor('${historyCount}টি past entries', 15));
        base += 15;
      }
    }

    final score = base.clamp(0, 100);
    if (factors.isEmpty) {
      factors.add(const HealthFactor('সব ঠিক আছে', 0));
    }
    return HealthBreakdown(score: score, factors: factors);
  }
}
