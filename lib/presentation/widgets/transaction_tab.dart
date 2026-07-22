import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/models/transaction_model.dart';
import '../../core/utils/amount_parser.dart';
import '../providers/finance_provider.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/transaction_history_screen.dart';
import 'transaction_tile.dart';

class TunaiTab extends StatelessWidget {
  final FinanceProvider finance;
  const TunaiTab({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    return TransactionTab(
      transactions: finance.tunaiTransactions,
      totalIn: finance.tunaiIn,
      totalOut: finance.tunaiOut,
      label: "Tunai",
      color: const Color(0xFF27AE60),
      emptyIcon: Icons.payments_outlined,
      emptyMsg:
          "Belum ada transaksi tunai.\nCoba ucapkan ke AI: \"beli makan 20rb\"",
    );
  }
}

class NonTunaiTab extends StatelessWidget {
  final FinanceProvider finance;
  const NonTunaiTab({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    return TransactionTab(
      transactions: finance.nonTunaiTransactions,
      totalIn: finance.nonTunaiIn,
      totalOut: finance.nonTunaiOut,
      label: "Non Tunai",
      color: const Color(0xFF2980B9),
      emptyIcon: Icons.credit_card_outlined,
      emptyMsg:
          "Belum ada transaksi non tunai.\nCoba: \"bayar listrik via gopay 150rb\"",
    );
  }
}

class SharingTab extends StatelessWidget {
  final FinanceProvider finance;
  const SharingTab({super.key, required this.finance});

  @override
  Widget build(BuildContext context) {
    return TransactionTab(
      transactions: finance.sharedTransactions,
      totalIn: finance.sharedTotalIn,
      totalOut: finance.sharedTotalOut,
      label: "Bersama",
      color: const Color(0xFF009688),
      emptyIcon: Icons.group_outlined,
      emptyMsg:
          "Belum ada transaksi bersama.\nAjak teman untuk mencatat bersama!",
    );
  }
}

class TransactionTab extends StatefulWidget {
  final List<TransactionModel> transactions;
  final int totalIn;
  final int totalOut;
  final String label;
  final Color color;
  final IconData emptyIcon;
  final String emptyMsg;

  const TransactionTab({
    super.key,
    required this.transactions,
    required this.totalIn,
    required this.totalOut,
    required this.label,
    required this.color,
    required this.emptyIcon,
    required this.emptyMsg,
  });

  @override
  State<TransactionTab> createState() => _TransactionTabState();
}

class _TransactionTabState extends State<TransactionTab> {
  bool _showChartAnim = false;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showChartAnim = true);
    });
  }

  @override
  void didUpdateWidget(covariant TransactionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions.length != widget.transactions.length ||
        oldWidget.totalIn != widget.totalIn ||
        oldWidget.totalOut != widget.totalOut) {
      _refreshKey++;
      _showChartAnim = false;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _showChartAnim = true);
      });
    }
  }

  String _formatRupiah(int amount) {
    final isNegative = amount < 0;
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return "${isNegative ? '-' : ''}Rp ${buf.toString()}";
  }

  String _compactAmount(int amount) {
    if (amount >= 1000000) {
      return "Rp ${(amount / 1000000).toStringAsFixed(1)}jt";
    } else if (amount >= 1000) {
      return "Rp ${(amount ~/ 1000)}rb";
    }
    return "Rp $amount";
  }

  String _compactNumber(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}jt";
    } else if (value >= 1000) {
      return "${(value ~/ 1000)}rb";
    }
    return value.toInt().toString();
  }

  List<dynamic> _buildGroupedList(List<TransactionModel> transactions) {
    List<dynamic> grouped = [];
    String currentGroup = "";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var tx in transactions) {
      final txDate = tx.createdAt.toLocal();
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFFA0A5BA),
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showActionModal(BuildContext context, TransactionModel item) {
    final finance = context.read<FinanceProvider>();
    final int id = item.id ?? -1;
    if (id == -1) return;
    final String currentNote = item.note;
    final int currentAmount = item.amount;

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
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E2C),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF5E5CE6),
                  ),
                ),
                title: const Text(
                  "Edit Transaksi",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF647C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFFF647C),
                  ),
                ),
                title: const Text(
                  "Hapus Transaksi",
                  style: TextStyle(
                    color: Color(0xFFFF647C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, finance, id, currentNote);
                },
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

  Widget _buildChart() {
    if (widget.transactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "Belum ada data 7 hari terakhir",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final justToday = DateTime(now.year, now.month, now.day);

    List<double> inData = List.filled(7, 0.0);
    List<double> outData = List.filled(7, 0.0);
    List<String> xLabels = List.filled(7, '');

    final List<String> hariIndo = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];

    for (int i = 0; i < 7; i++) {
      final targetDate = justToday.subtract(Duration(days: 6 - i));
      xLabels[i] = hariIndo[targetDate.weekday - 1];
    }

    double maxY = 0;

    for (var tx in widget.transactions) {
      final txDate = tx.createdAt;
      final justTx = DateTime(txDate.year, txDate.month, txDate.day);
      final diff = justToday.difference(justTx).inDays;

      if (diff >= 0 && diff <= 6) {
        final index = 6 - diff;
        final amt = tx.amount.toDouble();
        if (tx.type.value == 'OUT') {
          outData[index] += amt;
        } else {
          inData[index] += amt;
        }
      }
    }

    for (var val in inData) {
      if (val > maxY) maxY = val;
    }
    for (var val in outData) {
      if (val > maxY) maxY = val;
    }

    maxY = maxY > 0 ? maxY * 1.2 : 1000;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6,
          barRods: [
            BarChartRodData(
              toY: _showChartAnim ? inData[i] : 0,
              color: const Color(0xFF00C48C),
              width: 10,
              borderRadius: BorderRadius.circular(6),
            ),
            BarChartRodData(
              toY: _showChartAnim ? outData[i] : 0,
              color: const Color(0xFFFF647C),
              width: 10,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 20, right: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF1E1E2C),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                final color = isIncome
                    ? const Color(0xFF00C48C)
                    : const Color(0xFFFF647C);
                final prefix = isIncome ? "+" : "-";
                return BarTooltipItem(
                  '$prefix Rp ${_formatRupiah(rod.toY.toInt())}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        xLabels[idx],
                        style: const TextStyle(
                          color: Color(0xFFA0A5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: maxY / 4 == 0 ? 1 : maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      _compactNumber(value),
                      style: const TextStyle(
                        color: Color(0xFFA0A5BA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade100,
              strokeWidth: 1.5,
              dashArray: [5, 5],
            ),
          ),
          barGroups: barGroups,
        ),
        swapAnimationDuration: const Duration(milliseconds: 1000),
        swapAnimationCurve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saldo = widget.totalIn - widget.totalOut;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Saldo ${widget.label}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                key: ValueKey<int>(_refreshKey),
                tween: Tween<double>(begin: 0, end: saldo.toDouble()),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  final isMinus = saldo < 0;
                  return Text(
                    _formatRupiah(value.toInt()),
                    style: TextStyle(
                      color: isMinus ? const Color(0xFFFF8A8A) : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Masuk",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                key: ValueKey<int>(_refreshKey),
                                tween: Tween<double>(
                                  begin: 0,
                                  end: widget.totalIn.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, child) {
                                  return Text(
                                    _compactAmount(value.toInt()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Keluar",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                key: ValueKey<int>(_refreshKey),
                                tween: Tween<double>(
                                  begin: 0,
                                  end: widget.totalOut.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, child) {
                                  return Text(
                                    _compactAmount(value.toInt()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Chart Section
        Text(
          "Analisis 7 Hari Terakhir",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildChart(),
        const SizedBox(height: 24),
        // Transaction list
        if (widget.transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(widget.emptyIcon, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    widget.emptyMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaksi Terakhir",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                "${widget.transactions.length} transaksi",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildGroupedList(widget.transactions.take(5).toList()).asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final list = _buildGroupedList(widget.transactions.take(5).toList());

                if (item is String) {
                  return _buildHeader(item);
                } else {
                  final tx = item as TransactionModel;
                  final tile = TransactionTile(
                    tx: tx,
                    accentColor: widget.color,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transaction: tx),
                        ),
                      );
                    },
                  );

                  if (index < list.length - 1) {
                    return Column(
                      children: [
                        tile,
                        const Divider(
                          indent: 74,
                          height: 1,
                          color: Color(0xFFF2F4F7),
                        ),
                      ],
                    );
                  }
                  return tile;
                }
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Lihat Riwayat Lainnya",
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: widget.color),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
