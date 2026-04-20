import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../providers/finance_provider.dart';
import '../../data/services/voice_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 💡 MAGIC FIX: Tunggu sampai UI selesai digambar (frame pertama muncul),
    // baru jalankan fungsi loading yang berat agar tidak nge-freeze!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataAndMove();
    });
  }

  Future<void> _loadDataAndMove() async {
    // 1. Tahan layar di Splash minimal 1.5 detik agar logonya terlihat
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 2. Inisialisasi Mikrofon (StT) secara diam-diam
    await context.read<VoiceService>().init();

    // 3. Load semua data transaksi secara sempurna dari SQLite/Supabase
    await context.read<FinanceProvider>().refreshData();

    // 4. Lempar ke pintu masuk (AuthWrapper)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5E5CE6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "Dompet Cerdas",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Menyiapkan Data Keuanganmu...",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
