import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenience wrapper — use Supabase.instance.client directly
/// where possible; this class provides typed helper methods.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static String? get userId => client.auth.currentUser?.id;

  static bool get isSignedIn => client.auth.currentSession != null;

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final id = userId;
    if (id == null) return null;
    return await client.from('profiles').select().eq('id', id).maybeSingle();
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final id = userId;
    if (id == null) return;
    await client.from('profiles').update(data).eq('id', id);
  }
}
