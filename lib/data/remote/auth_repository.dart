import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(
      String email, String password, String displayName) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

  Future<bool> signInWithOAuth() async {
    final res = await _client.auth.signInWithOAuth(OAuthProvider.google);
    return res;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> updateFcmToken(String userId, String token) async {
    await _client
        .from('profiles')
        .update({'fcm_token': token}).eq('id', userId);
  }
}
