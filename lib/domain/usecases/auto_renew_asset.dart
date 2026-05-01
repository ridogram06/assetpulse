import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/asset_model.dart';

class AutoRenewAsset {
  final SupabaseClient _client;
  AutoRenewAsset(this._client);

  Future<void> renew(AssetModel asset) async {
    if (!asset.autoRenew || asset.endDate == null) return;

    final newStart = asset.endDate!.add(const Duration(days: 1));
    final newEnd = _computeEnd(newStart, asset.billingCycle, asset.endDate!);
    final now = DateTime.now();

    await _client.from('assets').insert({
      'id':                 const Uuid().v4(),
      'user_id':            asset.userId,
      'vault_id':           asset.vaultId,
      'payment_method_id':  asset.paymentMethodId,
      'name':               asset.name,
      'category':           asset.category,
      'icon':               asset.icon,
      'color':              asset.color,
      'notes':              asset.notes,
      'asset_type':         'deterministic',
      'cost':               asset.cost,
      'currency':           asset.currency,
      'start_date':         newStart.toIso8601String().split('T').first,
      'end_date':           newEnd.toIso8601String().split('T').first,
      'billing_cycle':      asset.billingCycle,
      'auto_renew':         true,
      'notify_days_before': asset.notifyDaysBefore,
      'status':             'active',
      'client_updated_at':  now.toIso8601String(),
      'created_at':         now.toIso8601String(),
      'updated_at':         now.toIso8601String(),
    });

    // Log to audit
    await _client.from('audit_log').insert({
      'user_id':  asset.userId,
      'asset_id': asset.id,
      'action':   'renewed',
      'new_data': {'new_start': newStart.toIso8601String()},
      'created_at': now.toIso8601String(),
    });
  }

  DateTime _computeEnd(DateTime start, String? cycle, DateTime prevEnd) {
    final diff = prevEnd.difference(
        prevEnd.subtract(Duration(days: _cycleDays(cycle))));
    return start.add(Duration(days: _cycleDays(cycle)));
  }

  int _cycleDays(String? cycle) {
    switch (cycle) {
      case 'quarterly': return 90;
      case 'annually':  return 365;
      case 'monthly':
      default:          return 30;
    }
  }
}
