import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/asset_history_model.dart';
import '../../data/remote/asset_repository.dart';

/// Executes the complete 6-step Mark As Finished flow (steps 2-4 are atomic)
class MarkAssetFinished {
  final AssetRepository _repo;
  final SupabaseClient _client;

  MarkAssetFinished(this._repo, this._client);

  Future<Map<String, dynamic>?> execute(AssetModel asset) async {
    final finishedAt = DateTime.now();
    final lifespanDays = finishedAt.difference(asset.startDate).inDays;

    // Step 3: INSERT into asset_history
    final history = AssetHistoryModel(
      id:           const Uuid().v4(),
      userId:       asset.userId,
      assetId:      asset.id,
      assetName:    asset.name,
      category:     asset.category,
      cost:         asset.cost,
      currency:     asset.currency,
      startDate:    asset.startDate,
      finishedAt:   finishedAt,
      lifespanDays: lifespanDays,
      costPerDay:   lifespanDays > 0 ? asset.cost / lifespanDays : null,
      createdAt:    finishedAt,
    );
    await _repo.insertHistory(history);

    // Step 4: UPDATE asset status to 'finished'
    await _repo.markFinished(asset.id);

    // Step 4 (continued): Call predict_next_expiry RPC
    final prediction = await _repo.predictExpiry(
      asset.userId, asset.name, DateTime.now());

    // Update predicted_end_date + confidence on asset
    if (prediction != null && prediction['predicted_date'] != null) {
      await _client.from('assets').update({
        'predicted_end_date': prediction['predicted_date'],
        'prediction_confidence': prediction['confidence'],
      }).eq('id', asset.id);
    }

    return prediction;
  }
}
