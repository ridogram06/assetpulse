import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset_model.dart';
import '../models/asset_history_model.dart';

class AssetRepository {
  final SupabaseClient _client;
  AssetRepository(this._client);

  Future<List<AssetModel>> fetchAll(String userId) async {
    final data = await _client
        .from('assets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((j) => AssetModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<AssetModel?> fetchById(String id) async {
    final data = await _client
        .from('assets')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return AssetModel.fromJson(data);
  }

  Future<void> upsert(AssetModel asset) async {
    await _client.from('assets').upsert(asset.toJson());
  }

  Future<void> delete(String id) async {
    await _client.from('assets').delete().eq('id', id);
  }

  Future<void> markFinished(String id) async {
    await _client.from('assets').update({
      'status': 'finished',
      'finished_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<Map<String, dynamic>?> predictExpiry(
      String userId, String assetName, DateTime startDate) async {
    final result = await _client.rpc('predict_next_expiry', params: {
      'p_user_id': userId,
      'p_asset_name': assetName,
      'p_start_date': startDate.toIso8601String().split('T').first,
    });
    if (result == null || (result as List).isEmpty) return null;
    return (result as List).first as Map<String, dynamic>;
  }

  Future<void> insertHistory(AssetHistoryModel h) async {
    await _client.from('asset_history').insert(h.toJson());
  }

  Future<List<AssetHistoryModel>> fetchHistory(
      String userId, String assetName) async {
    final data = await _client
        .from('asset_history')
        .select()
        .eq('user_id', userId)
        .eq('asset_name', assetName)
        .order('finished_at', ascending: false);
    return (data as List)
        .map((j) => AssetHistoryModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
