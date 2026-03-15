import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import 'home_screen.dart';

// ==========================================
// 1. WIDGET BANTUAN (TEXT FIELD MEWAH)
// ==========================================
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E1E2C),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF5E5CE6)),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. LAYAR LOGIN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty)
      return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        if (user != null && !user.emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Color(0xFF5E5CE6),
              ),
              const SizedBox(height: 20),
              const Text(
                "Selamat Datang,\nKembali!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E2C),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Login untuk mengakses asisten keuanganmu.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 50),

              CustomTextField(
                controller: _emailController,
                hint: "Email",
                icon: Icons.email_rounded,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E5CE6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    shadowColor: const Color(0xFF5E5CE6).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Masuk",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: "Belum punya akun? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Daftar di sini",
                          style: TextStyle(
                            color: Color(0xFF5E5CE6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. LAYAR REGISTER
// ==========================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Email tidak valid atau Password kurang dari 6 karakter",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await _authService.sendEmailVerification(); // Langsung kirim email
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buat Akun\nBaru",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E2C),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Mulai atur keuanganmu bersama AI.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 50),

            CustomTextField(
              controller: _emailController,
              hint: "Email",
              icon: Icons.email_rounded,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hint: "Password (Min. 6 Karakter)",
              icon: Icons.lock_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E5CE6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  shadowColor: const Color(0xFF5E5CE6).withOpacity(0.5),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Daftar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. LAYAR VERIFIKASI EMAIL (RUANG TUNGGU)
// ==========================================
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isVerified) {
      // Auto-Polling: Mengecek status setiap 3 detik
      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    // Reload user data dari Firebase
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      _isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (_isVerified) {
      _timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          // --- PERBAIKAN DI SINI: Menambahkan SingleChildScrollView ---
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 100,
                  color: Color(0xFF5E5CE6),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Verifikasi Email Anda",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Kami telah mengirimkan tautan verifikasi ke:\n${FirebaseAuth.instance.currentUser?.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Color(0xFF5E5CE6)),
                const SizedBox(height: 20),
                const Text(
                  "Menunggu verifikasi...",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5E5CE6),
                  ),
                ),
                const SizedBox(height: 60),

                TextButton.icon(
                  onPressed: () async {
                    await AuthService().sendEmailVerification();
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email dikirim ulang!")),
                      );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  label: const Text(
                    "Kirim Ulang Email",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (mounted)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                  },
                  child: const Text(
                    "Batalkan & Logout",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // -------------------------------------------------------------
        ),
      ),
    );
  }
}
