import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/services/supabase_service.dart';
import '../providers/finance_provider.dart';

// ============================================================
// PROFIL SCREEN
// ============================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _primaryColor = Color(0xFF5E5CE6);

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? "pengguna@email.com";
    final uid = user?.id ?? "-";

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
              backgroundColor: _primaryColor.withOpacity(0.15),
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : "D",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Dompetku AI",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              "Email Terdaftar",
              email,
              Icons.email_rounded,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              "Kode Ruangan Saya",
              finance.myRoomCode.isEmpty ? "Memuat..." : finance.myRoomCode,
              Icons.vpn_key_rounded,
              copyable: true,
              context: context,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              "User ID",
              uid,
              Icons.fingerprint_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon, {
    bool copyable = false,
    BuildContext? context,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor),
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
          if (copyable && context != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: _primaryColor),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Kode disalin!"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS SCREEN — Termasuk Dompet Bersama (Sharing)
// ============================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _primaryColor = Color(0xFF5E5CE6);
  final _joinCodeCtrl = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // SHARING SECTION — Join atau Leave Room
  // ============================================================
  Future<void> _joinRoom(FinanceProvider finance) async {
    final code = _joinCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kode ruangan terlebih dahulu")),
      );
      return;
    }

    setState(() => _isJoining = true);
    try {
      final room = await finance.joinRoom(code);
      if (mounted) {
        if (room != null) {
          _joinCodeCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil bergabung ke: ${room.name} 🎉"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kode tidak valid atau ruangan tidak ditemukan."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveRoom(FinanceProvider finance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Keluar dari Ruangan?"),
        content: const Text(
          "Anda akan keluar dari ruangan bersama. Data bersama tidak akan hilang, tapi Anda tidak bisa mengaksesnya lagi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await finance.leaveCurrentRoom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil keluar dari ruangan bersama."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ────────────── DOMPET BERSAMA SECTION ──────────────
            _sectionTitle("🤝 Dompet Bersama (Sharing)"),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  // Kode Ruangan Saya
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: _iconBox(
                      Icons.vpn_key_rounded,
                      const Color(0xFF5E5CE6),
                    ),
                    title: const Text(
                      "Kode Ruangan Saya",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      finance.myRoomCode.isEmpty
                          ? "Memuat..."
                          : finance.myRoomCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: finance.myRoomCode.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: _primaryColor,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: finance.myRoomCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Kode disalin! Bagikan ke teman Anda."),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  if (finance.isSharingConnected && finance.activeRoom != null)
                    // SUDAH TERHUBUNG
                    Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: _iconBox(
                            Icons.group_rounded,
                            const Color(0xFF009688),
                          ),
                          title: Text(
                            finance.activeRoom!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "${finance.activeRoom!.members.length} anggota",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009688),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "AKTIF",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.exit_to_app_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              label: const Text(
                                "Keluar dari Ruangan",
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _leaveRoom(finance),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // BELUM TERHUBUNG — Form join
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bergabung ke Ruangan:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E2C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _joinCodeCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: "Masukkan kode teman",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed:
                                      _isJoining ? null : () => _joinRoom(finance),
                                  child: _isJoining
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text("Join"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "💡 Minta kode ruangan dari teman/pasangan Anda, atau bagikan kode Anda di atas.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ────────────── MANAJEMEN DATA ──────────────
            _sectionTitle("⚠️ Manajemen Data"),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecoration(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                leading: _iconBox(Icons.delete_forever_rounded, Colors.red),
                title: const Text(
                  "Hapus Semua Data",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: const Text(
                  "Menghapus semua transaksi dan chat dari Supabase. Aksi ini tidak dapat dibatalkan.",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () => _confirmWipe(context, finance),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E1E2C),
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _iconBox(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      );

  void _confirmWipe(BuildContext context, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Hapus Semua?", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          "Data transaksi dan chat akan dihapus permanen dari Supabase. Aksi ini TIDAK BISA dibatalkan.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await finance.wipeAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Semua data berhasil dihapus."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              "Ya, Hapus!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
