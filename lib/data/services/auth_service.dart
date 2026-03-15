import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan data user yang sedang login saat ini
  User? get currentUser => _auth.currentUser;

  // Stream untuk mendengarkan perubahan status login (logout/login otomatis)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. REGISTER EMAIL & PASSWORD
  Future<UserCredential?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "Terjadi kesalahan yang tidak diketahui.";
    }
  }

  // 2. LOGIN EMAIL & PASSWORD
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "Terjadi kesalahan yang tidak diketahui.";
    }
  }

  // 3. KIRIM EMAIL VERIFIKASI
  Future<void> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
      }
    } catch (e) {
      throw "Gagal mengirim email verifikasi. Coba lagi nanti.";
    }
  }

  // 4. LOGOUT / KELUAR
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Translasi Error Firebase ke Bahasa Indonesia
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan langsung Login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Email tidak ditemukan. Silakan Register terlebih dahulu.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau Password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      default:
        return 'Gagal melakukan autentikasi: ${e.message}';
    }
  }
}
