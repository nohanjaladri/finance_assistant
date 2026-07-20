import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../providers/finance_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _noteController;
  late PaymentMethod _paymentMethod;
  bool _isSaving = false;

  final List<TextEditingController> _itemNoteControllers = [];
  final List<TextEditingController> _itemAmountControllers = [];
  final List<TextEditingController> _itemQtyControllers = [];
  
  // Track dynamically computed total
  int _liveTotal = 0;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note);
    _paymentMethod = widget.transaction.paymentMethod;

    for (final item in widget.transaction.items) {
      final noteCtrl = TextEditingController(text: item.note);
      final amountCtrl = TextEditingController(text: item.amount.toString());
      final qtyCtrl = TextEditingController(text: item.quantity.toString());
      
      // Update live total when any amount or quantity changes
      amountCtrl.addListener(_recalculateTotal);
      qtyCtrl.addListener(_recalculateTotal);

      _itemNoteControllers.add(noteCtrl);
      _itemAmountControllers.add(amountCtrl);
      _itemQtyControllers.add(qtyCtrl);
    }
    _recalculateTotal();
  }

  void _recalculateTotal() {
    int total = 0;
    if (_itemAmountControllers.isNotEmpty) {
      for (int i = 0; i < _itemAmountControllers.length; i++) {
        final price = int.tryParse(_itemAmountControllers[i].text) ?? 0;
        final qty = int.tryParse(_itemQtyControllers[i].text) ?? 1;
        total += (price * qty);
      }
    } else {
      total = widget.transaction.amount;
    }
    setState(() {
      _liveTotal = total;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final c in _itemNoteControllers) {
      c.dispose();
    }
    for (final c in _itemAmountControllers) {
      c.removeListener(_recalculateTotal);
      c.dispose();
    }
    for (final c in _itemQtyControllers) {
      c.removeListener(_recalculateTotal);
      c.dispose();
    }
    super.dispose();
  }

  String _formatRupiah(int val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(val);
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    final finance = context.read<FinanceProvider>();

    try {
      // 1. Save all updated items
      if (widget.transaction.items.isNotEmpty) {
        for (int i = 0; i < widget.transaction.items.length; i++) {
          final item = widget.transaction.items[i];
          final newNote = _itemNoteControllers[i].text.trim();
          final newAmount = int.tryParse(_itemAmountControllers[i].text) ?? item.amount;
          final newQty = int.tryParse(_itemQtyControllers[i].text) ?? item.quantity;

          await finance.updateTransactionItemManual(
            transactionId: widget.transaction.id!,
            itemId: item.id!,
            note: newNote,
            amount: newAmount,
            quantity: newQty,
          );
        }
      }

      // 2. Save main transaction fields
      final ok = await finance.updateTransaction(
        widget.transaction.id!,
        note: widget.transaction.items.isNotEmpty 
            ? _itemNoteControllers.asMap().entries.map((e) {
                final noteText = e.value.text.trim();
                final qtyText = _itemQtyControllers[e.key].text.trim();
                return "$noteText (x$qtyText)";
              }).join(", ")
            : _noteController.text.trim(),
        paymentMethod: _paymentMethod,
        amount: _liveTotal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? "Transaksi berhasil diperbarui!" : "Gagal memperbarui transaksi."),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        if (ok) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTx() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transaksi"),
        content: const Text("Apakah Anda yakin ingin menghapus transaksi ini permanen?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final finance = context.read<FinanceProvider>();
      final ok = await finance.deleteTransaction(widget.transaction.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? "Transaksi berhasil dihapus" : "Gagal menghapus transaksi"),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        if (ok) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.transaction.type == TransactionType.income ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        title: const Text(
          "Detail Transaksi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _isSaving ? null : _deleteTx,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      widget.transaction.type == TransactionType.income ? "Pemasukan" : "Pengeluaran",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: typeColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(_liveTotal),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tanggal", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(
                          DateFormat('dd MMMM yyyy • HH:mm', 'id_ID').format(widget.transaction.createdAt),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form Fields
            const Text(
              "INFORMASI TRANSAKSI",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (widget.transaction.items.isEmpty) ...[
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: "Catatan Transaksi",
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Divider(),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Metode Pembayaran", style: TextStyle(color: Colors.black54)),
                        DropdownButton<PaymentMethod>(
                          value: _paymentMethod,
                          underline: const SizedBox(),
                          items: PaymentMethod.values.map((pm) {
                            return DropdownMenuItem(
                              value: pm,
                              child: Text(pm.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Spreadsheet-style aligned Table Editor
            if (widget.transaction.items.isNotEmpty) ...[
              const Text(
                "RINCIAN ITEM BELANJA",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Perfect Spreadsheet Table
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4), // Nama
                          1: FlexColumnWidth(1.5), // Qty
                          2: FlexColumnWidth(2.5), // Harga
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          // Table Header
                          const TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "Nama",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "qty",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "harga",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          
                          // Table Rows representing editable inputs
                          ...List.generate(widget.transaction.items.length, (index) {
                            return TableRow(
                              children: [
                                // Nama Item Field
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: TextField(
                                    controller: _itemNoteControllers[index],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                                      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5ECF2))),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5E5CE6))),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                                
                                // Qty Field
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: TextField(
                                    controller: _itemQtyControllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                                      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5ECF2))),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5E5CE6))),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                                
                                // Harga Field
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: TextField(
                                    controller: _itemAmountControllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                                      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5ECF2))),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5E5CE6))),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 24, thickness: 1.5),
                      
                      // Dynamic Live Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                          ),
                          Text(
                            _formatRupiah(_liveTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E5CE6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Simpan Perubahan",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
