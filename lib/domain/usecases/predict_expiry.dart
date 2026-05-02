import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/prediction_engine.dart';

class PredictExpiry {
  final SupabaseClient _client;
  PredictExpiry(this._client);

  Future<_PredictionResult?> execute(
      String userId, String assetName, DateTime startDate) async {
    final result = await _client.rpc('predict_next_expiry', params: {
      'p_user_id': userId,
      'p_asset_name': assetName,
      'p_start_date': startDate.toIso8601String().split('T').first,
    });

    if (result == null || (result as List).isEmpty) return null;
    final row = (result as List).first as Map<String, dynamic>;
    final algorithm = row['algorithm_used'] as String?;

    if (algorithm == 'insufficient_data') return null;

    var meanDays = (row['mean_days'] as num?)?.toDouble() ?? 30.0;

    // For 10+ samples: apply Dart-side exp smoothing
    if (algorithm == 'wma_exp_ready') {
      final historyData = await _client
          .from('asset_history')
          .select('lifespan_days')
          .eq('user_id', userId)
          .ilike('asset_name', assetName)
          .order('finished_at', ascending: false)
          .limit(20);

      final values = (historyData as List)
          .map((r) => (r['lifespan_days'] as num).toDouble())
          .toList();

      if (values.isNotEmpty) {
        meanDays = PredictionEngine.applyExpSmoothing(values);
      }
    }

    final predictedDate = startDate.add(Duration(days: meanDays.ceil()));
    final confidence = (row['confidence'] as num?)?.toDouble();

    return _PredictionResult(
      predictedDate: predictedDate,
      confidence: confidence,
      algorithmUsed: algorithm ?? 'mean',
      sampleCount: row['sample_count'] as int? ?? 0,
    );
  }
}

class _PredictionResult {
  final DateTime predictedDate;
  final double? confidence;
  final String algorithmUsed;
  final int sampleCount;

  const _PredictionResult({
    required this.predictedDate,
    required this.confidence,
    required this.algorithmUsed,
    required this.sampleCount,
  });
}
