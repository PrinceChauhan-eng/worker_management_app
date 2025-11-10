import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  /// Email/Password sign up (creates auth user). Optionally also create a row in users table after sign up.
  Future<AuthResponse> signUpWithEmail({required String email, required String password}) async {
    final res = await supa.auth.signUp(email: email, password: password);
    return res;
  }

  /// Email/Password login
  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    final res = await supa.auth.signInWithPassword(email: email, password: password);
    return res;
  }

  /// Send OTP magic link to email (passwordless)
  Future<void> sendEmailOtp({required String email, required String redirectTo}) async {
    await supa.auth.signInWithOtp(email: email, emailRedirectTo: redirectTo);
  }

  /// Sign out
  Future<void> signOut() async {
    await supa.auth.signOut();
  }

  /// Current user (auth)
  User? get currentUser => supa.auth.currentUser;
}