import 'dart:isolate';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database.dart';
import '../../data/models/asset_model.dart';

class SyncService {
  final SupabaseClient _supabase;
  final AppDatabase _localDb;

  SyncService(this._supabase, this._localDb);

  Future<void> massSyncFromServer() async {
    final rawData = await _supabase
        .from('assets')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id);

    final parsedAssets = await Isolate.run(() {
      return (rawData as List)
          .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });

    await _localDb.transaction(() async {
      await _localDb.assetsDao
          .deleteAllForUser(_supabase.auth.currentUser!.id);
      await _localDb.assetsDao.batchInsert(parsedAssets);
    });
  }

  Future<void> syncSingleAsset(AssetModel localAsset) async {
    try {
      final response = await _supabase
          .from('assets')
          .select('id, updated_at, client_updated_at')
          .eq('id', localAsset.id)
          .maybeSingle();

      if (response == null) {
        await _supabase.from('assets').insert(localAsset.toJson());
        return;
      }

      final serverTime =
          DateTime.tryParse(response['client_updated_at'] as String? ?? '') ??
          DateTime.tryParse(response['updated_at'] as String? ?? '') ??
          DateTime(2000);

      if (localAsset.clientUpdatedAt.isAfter(serverTime)) {
        await _supabase.from('assets').upsert({
          ...localAsset.toJson(),
          'client_updated_at': localAsset.clientUpdatedAt.toIso8601String(),
        });
      } else {
        final fullRemote = await _supabase
            .from('assets')
            .select()
            .eq('id', localAsset.id)
            .single();
        await _localDb.assetsDao.upsert(AssetModel.fromJson(fullRemote));
      }
    } catch (_) {
      await _localDb.pendingSyncDao.enqueue(localAsset.id);
    }
  }

  Future<void> retryPendingSync() async {
    final pending = await _localDb.pendingSyncDao.getAll();
    for (final item in pending) {
      final local = await _localDb.assetsDao.getById(item.assetId);
      if (local == null) {
        await _localDb.pendingSyncDao.remove(item.assetId);
        continue;
      }
      try {
        final asset = AssetModel.fromJson({
          'id': local.id, 'user_id': local.userId,
          'vault_id': local.vaultId, 'payment_method_id': local.paymentMethodId,
          'name': local.name, 'category': local.category,
          'icon': local.icon, 'color': local.color, 'notes': local.notes,
          'asset_type': local.assetType, 'cost': local.cost,
          'currency': local.currency,
          'start_date': local.startDate.toIso8601String().split('T').first,
          'end_date': local.endDate?.toIso8601String().split('T').first,
          'billing_cycle': local.billingCycle, 'auto_renew': local.autoRenew,
          'notify_days_before': local.notifyDaysBefore,
          'suspended_at': local.suspendedAt?.toIso8601String(),
          'suspended_until': local.suspendedUntil?.toIso8601String(),
          'finished_at': local.finishedAt?.toIso8601String(),
          'predicted_end_date': local.predictedEndDate?.toIso8601String().split('T').first,
          'prediction_confidence': local.predictionConfidence,
          'status': local.status,
          'client_updated_at': local.clientUpdatedAt.toIso8601String(),
          'created_at': local.createdAt.toIso8601String(),
          'updated_at': local.updatedAt.toIso8601String(),
        });
        await syncSingleAsset(asset);
        await _localDb.pendingSyncDao.remove(item.assetId);
      } catch (_) {}
    }
  }
}
