import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/asset_model.dart';

final assetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('assets')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return (data as List)
      .map((json) => AssetModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

final singleAssetProvider =
    FutureProvider.family<AssetModel?, String>((ref, id) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('assets')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return AssetModel.fromJson(data);
});
