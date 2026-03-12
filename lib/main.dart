import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- IMPORT DENGAN STRUKTUR CLEAN ARCHITECTURE ---
import 'data/services/voice_service.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/screens/home_screen.dart';
// -------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      // Aplikasi dimulai dari SplashScreen
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Muat API Key dari .env
      await dotenv.load(fileName: ".env");

      // 2. Inisialisasi Voice Service
      await context.read<VoiceService>().init();

      // 3. Muat Data Keuangan awal
      await context.read<FinanceProvider>().refreshData();

      // Beri sedikit delay agar transisi tidak terlalu kaget (optional)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Pindah ke HomeScreen dan hapus tumpukan navigasi (tidak bisa back ke splash)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
      // Jika error, tampilkan pesan di layar splash
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal memuat sistem. Periksa file .env"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "AI Financier",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 30),
            const Text(
              "Menyiapkan asisten keuanganmu...",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
