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
  List<TransactionItemModel> _displayItems = [];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note);
    _paymentMethod = widget.transaction.paymentMethod;

    // Dynamically parse note if transaction_items is empty in DB
    _displayItems = List.from(widget.transaction.items);
    if (_displayItems.isEmpty && widget.transaction.note.contains(',')) {
      final parts = widget.transaction.note.split(',');
      for (final part in parts) {
        final cleanPart = part.trim();
        if (cleanPart.isEmpty) continue;
        
        String name = cleanPart;
        int qty = 1;
        int price = widget.transaction.amount ~/ parts.length; // rough split estimation

        // Parse quantity if format is "(x2)" or "(2)"
        final qtyMatch = RegExp(r'\((?:x|X)?(\d+)\)').firstMatch(cleanPart);
        if (qtyMatch != null) {
          qty = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
          name = cleanPart.replaceAll(qtyMatch.group(0)!, '').trim();
        }

        _displayItems.add(TransactionItemModel(
          transactionId: widget.transaction.id ?? 0,
          note: name,
          amount: price,
          quantity: qty,
        ));
      }
    }

    // Initialize controllers for display items
    if (_displayItems.isNotEmpty) {
      for (final item in _displayItems) {
        final noteCtrl = TextEditingController(text: item.note);
        final amountCtrl = TextEditingController(text: item.amount.toString());
        final qtyCtrl = TextEditingController(text: item.quantity.toString());
        
        amountCtrl.addListener(_recalculateTotal);
        qtyCtrl.addListener(_recalculateTotal);

        _itemNoteControllers.add(noteCtrl);
        _itemAmountControllers.add(amountCtrl);
        _itemQtyControllers.add(qtyCtrl);
      }
    } else {
      // Single item fallback
      _noteController.addListener(_recalculateTotal);
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
      total = int.tryParse(_noteController.text) ?? widget.transaction.amount;
    }
    setState(() {
      _liveTotal = total;
    });
  }

  @override
  void dispose() {
    _noteController.removeListener(_recalculateTotal);
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
      // 1. Save items
      if (_displayItems.isNotEmpty) {
        for (int i = 0; i < _displayItems.length; i++) {
          final item = _displayItems[i];
          final newNote = _itemNoteControllers[i].text.trim();
          final newAmount = int.tryParse(_itemAmountControllers[i].text) ?? item.amount;
          final newQty = int.tryParse(_itemQtyControllers[i].text) ?? item.quantity;

          if (item.id != null) {
            await finance.updateTransactionItemManual(
              transactionId: widget.transaction.id!,
              itemId: item.id!,
              note: newNote,
              amount: newAmount,
              quantity: newQty,
            );
          }
        }
      }

      // 2. Save main transaction fields (do not include quantity suffix in note summary at all)
      final ok = await finance.updateTransaction(
        widget.transaction.id!,
        note: _displayItems.isNotEmpty 
            ? _itemNoteControllers.map((c) => c.text.trim()).join(", ")
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
    final isIncome = widget.transaction.type == TransactionType.income;
    final typeColor = isIncome ? const Color(0xFF00C48C) : const Color(0xFFFF647C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "E-Receipt",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF647C)),
            onPressed: _isSaving ? null : _deleteTx,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Digital Header Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isIncome ? "Pemasukan Digital" : "Pengeluaran Digital",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatRupiah(_liveTotal),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: typeColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F3F9)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Waktu Transaksi", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        DateFormat('dd MMMM yyyy • HH:mm', 'id_ID').format(widget.transaction.createdAt),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Modern Settings Info block
            const Text(
              "METODE PEMBAYARAN",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Pilih Penyimpanan",
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  DropdownButton<PaymentMethod>(
                    value: _paymentMethod,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
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
            ),
            const SizedBox(height: 16),

            // E-INVOICE / DIGITAL SLIP
            if (isIncome) ...[
              // --- NOTA TRANSFER MASUK (INCOME) ---
              const Text(
                "BUKTI TRANSFER MASUK",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5ECF2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF00C48C), size: 20),
                          const SizedBox(width: 6),
                          const Text(
                            "STATUS: BERHASIL",
                            style: TextStyle(
                              color: Color(0xFF00C48C),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFF1F3F9)),
                      const SizedBox(height: 12),

                      // Sumber/Pemberi (Editable)
                      const Text(
                        "PENGIRIM / SUMBER",
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _displayItems.isNotEmpty ? _itemNoteControllers[0] : _noteController,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Sumber pemasukan",
                          filled: true,
                          fillColor: const Color(0xFFF8F9FD),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      // Nominal
                      const Text(
                        "NOMINAL",
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_liveTotal),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF00C48C)),
                      ),
                      const SizedBox(height: 16),

                      // Storage Target
                      const Text(
                        "TUJUAN PENYIMPANAN",
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _paymentMethod == PaymentMethod.tunai 
                                  ? Icons.account_balance_wallet_rounded
                                  : Icons.credit_card_rounded,
                              size: 16,
                              color: const Color(0xFF5E5CE6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _paymentMethod == PaymentMethod.tunai ? "Masuk ke Dompet" : "Masuk ke E-Wallet",
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // --- E-INVOICE / MODERN DIGITAL EXPENSE ---
              const Text(
                "RINCIAN BELANJA DIGITAL",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5ECF2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              "NAMA ITEM",
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "QTY",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "HARGA (RP)",
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFF1F3F9)),
                      
                      // List of Editable Items
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _displayItems.length,
                        itemBuilder: (ctx, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                // Editable Name Field
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _itemNoteControllers[index],
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: "Nama item",
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Editable Qty Field
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: _itemQtyControllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: "1",
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Editable Price Field
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _itemAmountControllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: "0",
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FD),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F3F9)),
                      
                      // Dynamic Live Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL TAGIHAN",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black54, letterSpacing: 0.5),
                          ),
                          Text(
                            _formatRupiah(_liveTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
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
