import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/asset_model.dart';

/// Lightweight static actions for asset CRUD/state changes.
/// All methods return the prediction map (when applicable) or void.
class AssetActions {
  static SupabaseClient get _c => Supabase.instance.client;

  static Future<void> delete(String assetId) async {
    await _c.from('assets').delete().eq('id', assetId);
  }

  static Future<void> suspend(String assetId) async {
    final now = DateTime.now().toIso8601String();
    await _c.from('assets').update({
      'status': 'suspended',
      'suspended_at': now,
      'client_updated_at': now,
    }).eq('id', assetId);
  }

  static Future<void> resume(String assetId) async {
    final now = DateTime.now().toIso8601String();
    await _c.from('assets').update({
      'status': 'active',
      'suspended_at': null,
      'suspended_until': null,
      'client_updated_at': now,
    }).eq('id', assetId);
  }

  /// Steps 2-4 of Mark As Finished flow (atomic-ish).
  /// Returns the prediction result map (may be null).
  static Future<Map<String, dynamic>?> markFinished(AssetModel asset) async {
    final finishedAt = DateTime.now();

    // Step 3: history insert (FIX-3: tag with canonical_asset_id so prediction
    // history survives renames/deletes of the source asset row).
    await _c.from('asset_history').insert({
      'id': const Uuid().v4(),
      'user_id': asset.userId,
      'asset_id': asset.id,
      'canonical_asset_id': asset.id,
      'asset_name': asset.name,
      'category': asset.category,
      'cost': asset.cost,
      'currency': asset.currency,
      'start_date': asset.startDate.toIso8601String().split('T').first,
      'finished_at': finishedAt.toIso8601String(),
      'created_at': finishedAt.toIso8601String(),
    });

    // Step 4: update asset
    await _c.from('assets').update({
      'status': 'finished',
      'finished_at': finishedAt.toIso8601String(),
      'client_updated_at': finishedAt.toIso8601String(),
    }).eq('id', asset.id);

    // Call prediction RPC for next time
    try {
      final res = await _c.rpc('predict_next_expiry', params: {
        'p_user_id': asset.userId,
        'p_asset_name': asset.name,
        'p_start_date': finishedAt.toIso8601String().split('T').first,
        'p_canonical_id': asset.id, // FIX-3: rename-safe history match
      });
      if (res is List && res.isNotEmpty) {
        return Map<String, dynamic>.from(res.first as Map);
      }
    } catch (_) {
      // RPC failure is non-fatal — prediction just won't be available
    }
    return null;
  }

  /// Fetch last 2 history entries for comparison panel.
  /// FIX-3: Prefer canonical_asset_id match; fall back to name if none found.
  static Future<List<Map<String, dynamic>>> recentHistory(
      String userId, String assetName,
      {String? canonicalId}) async {
    if (canonicalId != null) {
      final byCanonical = await _c
          .from('asset_history')
          .select()
          .eq('user_id', userId)
          .eq('canonical_asset_id', canonicalId)
          .order('finished_at', ascending: false)
          .limit(2);
      final list = List<Map<String, dynamic>>.from(byCanonical as List);
      if (list.isNotEmpty) return list;
    }
    final data = await _c
        .from('asset_history')
        .select()
        .eq('user_id', userId)
        .ilike('asset_name', assetName)
        .order('finished_at', ascending: false)
        .limit(2);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
