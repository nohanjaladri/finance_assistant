import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

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

  // --- PEMETAAN 16 IKON KATEGORI CERDAS ---
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Transport':
        return Icons.two_wheeler; // Ikon Motor untuk Ojek/Transport
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.medical_services;
      case 'Entertainment':
        return Icons.sports_esports; // Ikon Gamepad
      case 'Bills':
        return Icons.receipt; // Tagihan/Token
      case 'EWallet':
        return Icons.account_balance_wallet;
      case 'Education':
        return Icons.school;
      case 'Charity':
        return Icons.volunteer_activism; // Ikon Hati/Tangan
      case 'Investment':
        return Icons.trending_up;
      case 'Salary':
        return Icons.payments;
      case 'Business':
        return Icons.store;
      case 'Transfer_In':
        return Icons.south_west; // Panah masuk
      case 'Transfer_Out':
        return Icons.north_east; // Panah keluar
      default:
        return Icons.category; // Default
    }
  }

  // --- ALGORITMA PENGELOMPOKAN WAKTU (GROUPING) ---
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
        grouped.add(groupName); // Masukkan String (Sebagai Header)
        currentGroup = groupName;
      }
      grouped.add(tx); // Masukkan Map (Sebagai Transaksi)
    }
    return grouped;
  }

  // --- BUILDER HEADER ---
  Widget _buildHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      color: Colors.grey.shade100,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          fontSize: 13,
        ),
      ),
    );
  }

  // --- BUILDER TRANSAKSI ---
  Widget _buildTransactionTile(Map<String, dynamic> item) {
    final isIn = item['type'] == 'IN';
    final amountColor = isIn ? Colors.green : Colors.red;
    final amountPrefix = isIn ? "Rp" : "-Rp";
    final arrowIcon = isIn ? Icons.arrow_upward : Icons.arrow_downward;
    final note = item['note']?.toString() ?? 'Transaksi';
    final category = item['category']?.toString() ?? 'Other';
    final dateStr = item['date']?.toString() ?? '';
    final amount = item['amount'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kotak Ikon Kategori
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),

          // Judul dan Waktu (Hanya Jam)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTimeOnly(
                    dateStr,
                  ), // Hanya menampilkan Jam karena tanggal ada di Header
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Nominal dan Panah Indikator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$amountPrefix${_formatRupiah(amount)}",
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
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
                child: Icon(arrowIcon, color: amountColor, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final transactions = finance.history;

    // Konversi daftar flat menjadi daftar yang sudah dikelompokkan
    final groupedItems = _buildGroupedList(transactions);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: const Text(
          "Aktivitas",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: groupedItems.isEmpty
          ? const Center(
              child: Text(
                "Belum ada transaksi merekam.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];

                // Jika item berupa String, itu adalah Header Pembatas Waktu
                if (item is String) {
                  return _buildHeader(item);
                }
                // Jika berupa Map, itu adalah Transaksi
                else {
                  return _buildTransactionTile(item as Map<String, dynamic>);
                }
              },
            ),
    );
  }
}
