import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORT AUTH
import 'firebase_options.dart';

import 'data/services/voice_service.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/auth_screens.dart'; // IMPORT LAYAR LOGIN BARU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5E5CE6),
      ),
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
      // 1. Muat Environment & Data Lokal
      await dotenv.load(fileName: ".env");
      await context.read<VoiceService>().init();
      await context.read<FinanceProvider>().refreshData();

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // 2. POLISI LALU LINTAS: Cek Status Login Firebase
        final user = FirebaseAuth.instance.currentUser;
        Widget nextScreen;

        if (user == null) {
          // Belum Login -> Lempar ke Layar Login
          nextScreen = const LoginScreen();
        } else if (!user.emailVerified) {
          // Sudah Login tapi belum di-verifikasi emailnya
          nextScreen = const VerifyEmailScreen();
        } else {
          // Aman! Masuk ke Dasbor
          nextScreen = const HomeScreen();
        }

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
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
            colors: [Color(0xFF5E5CE6), Color(0xFF8C52FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Dompetku AI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 30),
            Text(
              "Mengamankan sistem...",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
