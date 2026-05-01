import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final unreadNotifCountProvider = FutureProvider<int>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0;

  final data = await client
      .from('notification_log')
      .select('id')
      .eq('user_id', userId)
      .isFilter('read_at', null);

  return (data as List).length;
});

final notifPrefsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  return await client
      .from('notification_preferences')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
});
