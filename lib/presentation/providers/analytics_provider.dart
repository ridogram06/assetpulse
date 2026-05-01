import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/asset_history_model.dart';

final historyProvider =
    FutureProvider.family<List<AssetHistoryModel>, String>((ref, assetName) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('asset_history')
      .select()
      .eq('user_id', userId)
      .ilike('asset_name', assetName)
      .order('finished_at', ascending: false);

  return (data as List)
      .map((j) => AssetHistoryModel.fromJson(j as Map<String, dynamic>))
      .toList();
});

final monthlySpendProvider = FutureProvider<Map<String, double>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {};

  final now = DateTime.now();
  final sixMonthsAgo = DateTime(now.year, now.month - 5);

  final data = await client
      .from('asset_history')
      .select('finished_at, cost')
      .eq('user_id', userId)
      .gte('finished_at', sixMonthsAgo.toIso8601String());

  final result = <String, double>{};
  for (final row in (data as List)) {
    final dt = DateTime.parse(row['finished_at'] as String);
    final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    result[key] = (result[key] ?? 0) + ((row['cost'] as num?)?.toDouble() ?? 0);
  }
  return result;
});
