import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../../core/utils/amount_parser.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  String _formatTimeOnly(String isoDate) {
    if (isoDate.isEmpty) return "";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      return "$hh:$mm";
    } catch (_) {
      return "";
    }
  }

  IconData _getCategoryIcon(String category, String note) {
    final text = note.toLowerCase();

    if (text.contains('gojek') ||
        text.contains('grab') ||
        text.contains('ojek') ||
        text.contains('parkir') ||
        text.contains('bensin') ||
        text.contains('maxim') ||
        text.contains('tol'))
      return Icons.two_wheeler;
    if (text.contains('listrik') ||
        text.contains('pln') ||
        text.contains('token') ||
        text.contains('air') ||
        text.contains('wifi') ||
        text.contains('internet') ||
        text.contains('indihome'))
      return Icons.receipt;
    if (text.contains('dana') ||
        text.contains('gopay') ||
        text.contains('ovo') ||
        text.contains('shopeepay') ||
        text.contains('topup') ||
        text.contains('top up'))
      return Icons.account_balance_wallet;
    if (text.contains('sayur') ||
        text.contains('buah') ||
        text.contains('beras') ||
        text.contains('pasar') ||
        text.contains('indomaret') ||
        text.contains('alfamart'))
      return Icons.local_grocery_store;
    if (text.contains('makan') ||
        text.contains('minum') ||
        text.contains('kopi') ||
        text.contains('bakso') ||
        text.contains('ayam') ||
        text.contains('warteg'))
      return Icons.restaurant;
    if (text.contains('gaji') ||
        text.contains('bonus') ||
        text.contains('thr') ||
        text.contains('upah'))
      return Icons.payments;
    if (text.contains('pulsa') ||
        text.contains('kuota') ||
        text.contains('paket') ||
        text.contains('axis') ||
        text.contains('telkomsel'))
      return Icons.phone_android;
    if (text.contains('transfer') ||
        text.contains('tf') ||
        text.contains('kirim') ||
        text.contains('terima'))
      return Icons.swap_horiz;
    if (text.contains('qris') || text.contains('scan')) return Icons.qr_code_2;
    if (text.contains('obat') ||
        text.contains('rs') ||
        text.contains('dokter') ||
        text.contains('apotek') ||
        text.contains('klinik'))
      return Icons.medical_services;

    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Transport':
        return Icons.two_wheeler;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.medical_services;
      case 'Entertainment':
        return Icons.sports_esports;
      case 'Bills':
        return Icons.receipt;
      case 'EWallet':
        return Icons.account_balance_wallet;
      case 'Education':
        return Icons.school;
      case 'Charity':
        return Icons.volunteer_activism;
      case 'Investment':
        return Icons.trending_up;
      case 'Salary':
        return Icons.payments;
      case 'Business':
        return Icons.store;
      case 'Transfer_In':
        return Icons.south_west;
      case 'Transfer_Out':
        return Icons.north_east;
      default:
        return Icons.receipt_long;
    }
  }

  List<dynamic> _buildGroupedList(List<Map<String, dynamic>> transactions) {
    List<dynamic> grouped = [];
    String currentGroup = "";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var tx in transactions) {
      final dateStr = tx['date'] as String? ?? '';
      DateTime txDate;
      try {
        txDate = DateTime.parse(dateStr).toLocal();
      } catch (_) {
        txDate = now;
      }

      final justTx = DateTime(txDate.year, txDate.month, txDate.day);
      final diff = today.difference(justTx).inDays;

      String groupName = "";
      if (diff == 0) {
        groupName = "Hari Ini";
      } else if (diff == 1) {
        groupName = "Kemarin";
      } else if (diff > 1 && diff <= 7) {
        groupName = "Minggu Ini";
      } else if (diff > 7 && diff <= 14) {
        groupName = "Minggu Lalu";
      } else {
        final months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        groupName = "${months[txDate.month - 1]} ${txDate.year}";
      }

      if (groupName != currentGroup) {
        grouped.add(groupName);
        currentGroup = groupName;
      }
      grouped.add(tx);
    }
    return grouped;
  }

  Widget _buildHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FC),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFFA0A5BA),
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ==========================================
  // FITUR MANUAL UPDATE & DELETE (MODAL)
  // ==========================================
  void _showActionModal(BuildContext context, Map<String, dynamic> item) {
    final finance = context.read<FinanceProvider>();
    final int id = item['id'] as int;
    final String currentNote = item['note']?.toString() ?? '';
    final int currentAmount = item['amount'] as int? ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(
            bottom: 30,
            top: 12,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Opsi Transaksi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E2C),
                ),
              ),
              const SizedBox(height: 24),

              // TOMBOL EDIT
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(
                    context,
                    finance,
                    id,
                    currentNote,
                    currentAmount,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.edit_rounded, color: Color(0xFF5E5CE6)),
                      SizedBox(width: 16),
                      Text(
                        "Edit Transaksi",
                        style: TextStyle(
                          color: Color(0xFF5E5CE6),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // TOMBOL HAPUS
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, finance, id, currentNote);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF647C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.delete_rounded, color: Color(0xFFFF647C)),
                      SizedBox(width: 16),
                      Text(
                        "Hapus Transaksi",
                        style: TextStyle(
                          color: Color(0xFFFF647C),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FinanceProvider finance,
    int id,
    String note,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Hapus Transaksi?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus '$note' secara permanen?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF647C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              finance.deleteTransactionManual(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Transaksi dihapus"),
                  backgroundColor: Color(0xFFFF647C),
                ),
              );
            },
            child: const Text(
              "Hapus",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    FinanceProvider finance,
    int id,
    String oldNote,
    int oldAmount,
  ) {
    final noteCtrl = TextEditingController(text: oldNote);
    final amountCtrl = TextEditingController(text: oldAmount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit Transaksi",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: "Nama Transaksi",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal (Rp)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E5CE6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final newNote = noteCtrl.text.trim();
              final newAmt =
                  int.tryParse(
                    AmountParser.cleanNumberString(amountCtrl.text),
                  ) ??
                  0;
              if (newNote.isNotEmpty && newAmt > 0) {
                finance.updateTransactionManual(id, newAmt, newNote);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data diperbarui"),
                    backgroundColor: Color(0xFF00C48C),
                  ),
                );
              }
            },
            child: const Text(
              "Simpan",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ==========================================

  Widget _buildTransactionTile(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final isIn = item['type'] == 'IN';
    final amountColor = isIn
        ? const Color(0xFF00C48C)
        : const Color(0xFFFF647C);
    final amountPrefix = isIn ? "Rp" : "-Rp";
    final arrowIcon = isIn ? Icons.arrow_upward : Icons.arrow_downward;
    final note = item['note']?.toString() ?? 'Transaksi';
    final category = item['category']?.toString() ?? 'Other';
    final dateStr = item['date']?.toString() ?? '';
    final amount = item['amount'] as int? ?? 0;

    return InkWell(
      onTap: () => _showActionModal(context, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getCategoryIcon(category, note),
                color: const Color(0xFF1E1E2C),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1E1E2C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeOnly(dateStr),
                    style: const TextStyle(
                      color: Color(0xFFA0A5BA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$amountPrefix${_formatRupiah(amount)}",
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(arrowIcon, color: amountColor, size: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final transactions = finance.history;
    final groupedItems = _buildGroupedList(transactions);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Aktivitas Histori",
          style: TextStyle(
            color: Color(0xFF1E1E2C),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: groupedItems.isEmpty
          ? const Center(
              child: Text(
                "Belum ada transaksi merekam.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];
                if (item is String) {
                  return _buildHeader(item);
                } else {
                  return _buildTransactionTile(
                    context,
                    item as Map<String, dynamic>,
                  );
                }
              },
            ),
    );
  }
}
