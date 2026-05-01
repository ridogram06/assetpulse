/// Dart-side exponential smoothing (α=0.3) applied on top of WMA
/// Called when algorithm_used = 'wma_exp_ready' (10+ samples)
class PredictionEngine {
  static const double _alpha = 0.3;

  /// Apply exponential smoothing to a list of lifespan values (newest first)
  static double applyExpSmoothing(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;

    // values[0] = most recent, values[n-1] = oldest
    double smoothed = values.last; // start from oldest
    for (int i = values.length - 2; i >= 0; i--) {
      smoothed = _alpha * values[i] + (1 - _alpha) * smoothed;
    }
    return smoothed;
  }

  /// Compute confidence display string
  static String confidenceLabel(double? confidence) {
    if (confidence == null || confidence <= 0) return '';
    if (confidence < 50) return '${confidence.toStringAsFixed(0)}% ⚠';
    return '${confidence.toStringAsFixed(0)}%';
  }

  /// Predict days remaining text
  static String predictedDaysText(DateTime? predictedDate) {
    if (predictedDate == null) return '';
    if (predictedDate.isBefore(DateTime.now())) return '';
    final days = predictedDate.difference(DateTime.now()).inDays;
    return '~$days দিন';
  }
}
