import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserUid => _supabase.auth.currentUser?.id;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> sendEmailVerification({required String email}) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
