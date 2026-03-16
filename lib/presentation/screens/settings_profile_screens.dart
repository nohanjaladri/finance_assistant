import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/finance_provider.dart';
import '../../data/services/voice_service.dart'; // IMPORT VOICE SERVICE

// ==========================================
// 1. LAYAR PROFIL
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "pengguna@email.com";
    final uid = user?.uid ?? "-";
    final finance = context.watch<FinanceProvider>();
    final primaryColor = finance.isSharedMode
        ? const Color(0xFF009688)
        : const Color(0xFF5E5CE6);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        title: const Text(
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Text(
                email[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Dompetku AI User",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _buildInfoCard(
              "Email Terdaftar",
              email,
              Icons.email_rounded,
              primaryColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              "Kode Ruangan Utama",
              finance.myRoomCode,
              Icons.vpn_key_rounded,
              primaryColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              "User ID (UID)",
              uid,
              Icons.fingerprint_rounded,
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. LAYAR PENGATURAN
// ==========================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final voice = context.watch<VoiceService>(); // BACA STATUS VOICE
    final primaryColor = finance.isSharedMode
        ? const Color(0xFF009688)
        : const Color(0xFF5E5CE6);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FITUR BARU: PENGATURAN SUARA
            const Text(
              "Preferensi Aplikasi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: const Text(
                  "Suara Asisten (TTS)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2C),
                  ),
                ),
                subtitle: const Text(
                  "Asisten akan membacakan jawaban dengan suara.",
                  style: TextStyle(fontSize: 12),
                ),
                value: voice.isTtsEnabled,
                activeColor: primaryColor,
                onChanged: (val) => voice.toggleTts(val),
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    voice.isTtsEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // PENGATURAN DATA
            const Text(
              "Manajemen Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  "Hapus Semua Data",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: const Text(
                  "Aksi ini tidak dapat dibatalkan.",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () =>
                    _showWipeConfirmation(context, finance, primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWipeConfirmation(
    BuildContext context,
    FinanceProvider finance,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
            SizedBox(width: 10),
            Text(
              "Peringatan Keras",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus SELURUH data transaksi dan chat di Mode ${finance.isSharedMode ? 'Bersama' : 'Pribadi'} ini?\n\nData akan dihapus dari HP Anda maupun dari Server (Firebase).",
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await finance.wipeEntireDatabase();
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Seluruh data berhasil dihapus bersih!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Ya, Hapus Semua!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
