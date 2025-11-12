import 'supabase_client.dart';

class AuthService {
  /// Custom login (phone OR email OR id) + password
  Future<Map<String, dynamic>?> login({
    required String input,
    required String password,
  }) async {
    final user = await supa
        .from('users')
        .select()
        .or('phone.eq.$input,email.eq.$input,id.eq.$input')
        .eq('password', password)
        .maybeSingle();

    return user;
  }

  /// Logout (not needed if using custom auth, but safe)
  Future<void> signOut() async {
    await supa.auth.signOut(); // optional, does nothing for custom auth
  }
}
