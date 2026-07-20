import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../../data/models/transaction_model.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = "";
  String? _selectedMonth; // format: "MMMM yyyy" e.g., "Mei 2026"
  final TextEditingController _searchController = TextEditingController();

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  // Get month name in Indonesian
  String _getMonthName(DateTime date) {
    return DateFormat('MMMM', 'id_ID').format(date);
  }

  String _getMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Determine icons based on note/metadata
  Widget _buildLeftIcon(TransactionModel tx) {
    IconData iconData = Icons.receipt_long_rounded;
    Color iconColor = const Color(0xFF108EE9);

    final isIn = tx.type == TransactionType.income;
    switch (tx.category.toLowerCase()) {
      case 'food':
        iconData = Icons.restaurant_rounded;
        iconColor = const Color(0xFFFF9F0A);
        break;
      case 'groceries':
        iconData = Icons.shopping_basket_rounded;
        iconColor = const Color(0xFF30D158);
        break;
      case 'transport':
        iconData = Icons.directions_car_rounded;
        iconColor = const Color(0xFF5E5CE6);
        break;
      case 'shopping':
        iconData = Icons.shopping_bag_rounded;
        iconColor = const Color(0xFFBF5AF2);
        break;
      case 'salary':
        iconData = Icons.payments_rounded;
        iconColor = const Color(0xFF34C759);
        break;
      case 'bills':
      case 'utilities':
        iconData = Icons.receipt_long_rounded;
        iconColor = const Color(0xFFFF453A);
        break;
      case 'transfer_in':
      case 'transfer_out':
        iconData = Icons.swap_horiz_rounded;
        iconColor = const Color(0xFF64D2FF);
        break;
      case 'entertainment':
        iconData = Icons.movie_filter_rounded;
        iconColor = const Color(0xFFFF375F);
        break;
      default:
        iconData = isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
        iconColor = isIn ? const Color(0xFF34C759) : const Color(0xFFFF453A);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final allTxs = finance.allTransactions;

    // 1. Filter based on Search Query
    var filteredTxs = allTxs.where((tx) {
      final matchesSearch = tx.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // 2. Extract available months for filter tabs (e.g. Maret, April, Mei, Juni)
    final allMonths = allTxs.map((tx) => _getMonthYear(tx.createdAt)).toSet().toList();
    // Sort months descending
    allMonths.sort((a, b) {
      try {
        final dateA = DateFormat('MMMM yyyy', 'id_ID').parse(a);
        final dateB = DateFormat('MMMM yyyy', 'id_ID').parse(b);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    // 3. Filter based on Selected Month Tab
    if (_selectedMonth != null) {
      filteredTxs = filteredTxs.where((tx) => _getMonthYear(tx.createdAt) == _selectedMonth).toList();
    }

    // 4. Group remaining transactions by Month Year
    final Map<String, List<TransactionModel>> groupedTxs = {};
    for (final tx in filteredTxs) {
      final key = _getMonthYear(tx.createdAt);
      groupedTxs.putIfAbsent(key, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // DANA Style Blue Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF108EE9), Color(0xFF1A9EF2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "Aktivitas",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Statement/Export icon
                        const Icon(Icons.file_upload_outlined, color: Colors.white, size: 24),
                      ],
                    ),
                  ),

                  // Search Bar "Cari DANA"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        decoration: const InputDecoration(
                          hintText: "Cari transaksi...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF108EE9)),
                          suffixIcon: Icon(Icons.tune_rounded, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  // Month Filter Tab Row
                  if (allMonths.isNotEmpty)
                    Container(
                      height: 48,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allMonths.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final monthLabel = isAll ? "Semua" : allMonths[index - 1].split(' ').first;
                          final monthValue = isAll ? null : allMonths[index - 1];
                          final isSelected = _selectedMonth == monthValue;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedMonth = monthValue);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  monthLabel,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: filteredTxs.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada transaksi ditemukan",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: groupedTxs.keys.length,
                    itemBuilder: (context, groupIndex) {
                      final monthKey = groupedTxs.keys.elementAt(groupIndex);
                      final txList = groupedTxs[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header (e.g. Mei 2026) with Statement link
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  monthKey,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Text(
                                        "Statement",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_circle_right_rounded, size: 16, color: Colors.blue.shade700),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Transactions inside this month group
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: txList.length,
                            separatorBuilder: (_, __) => const Divider(
                              indent: 80,
                              height: 1,
                              color: Color(0xFFF2F4F7),
                            ),
                            itemBuilder: (context, index) {
                              final tx = txList[index];
                              final isIncome = tx.type == TransactionType.income;
                              final sign = isIncome ? "" : "-";
                              final amountStr = "$sign${_formatRupiah(tx.amount)}";
                              final dateSub = "${tx.createdAt.day} ${_getMonthName(tx.createdAt)} ${tx.createdAt.year} • ${DateFormat('HH:mm').format(tx.createdAt)}";

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildLeftIcon(tx),
                                    // Tiny payment method badge bottom-right
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          tx.paymentMethod == PaymentMethod.tunai
                                              ? Icons.money_rounded
                                              : Icons.credit_card_rounded,
                                          size: 12,
                                          color: const Color(0xFF108EE9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  tx.note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    dateSub,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ),
                                trailing: Text(
                                  amountStr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isIncome ? Colors.green : Colors.black87,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransactionDetailScreen(transaction: tx),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
