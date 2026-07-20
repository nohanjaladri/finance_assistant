import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../providers/finance_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _noteController;
  late PaymentMethod _paymentMethod;
  bool _isSaving = false;
  bool _isEditing = false;

  final List<TextEditingController> _itemNoteControllers = [];
  final List<TextEditingController> _itemAmountControllers = [];
  final List<TextEditingController> _itemQtyControllers = [];

  int _liveTotal = 0;

  late AnimationController _editAnimController;
  late Animation<double> _editFadeAnim;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note);
    _paymentMethod = widget.transaction.paymentMethod;

    _editAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _editFadeAnim = CurvedAnimation(
      parent: _editAnimController,
      curve: Curves.easeInOut,
    );

    for (final item in widget.transaction.items) {
      final noteCtrl = TextEditingController(text: item.note);
      final amountCtrl = TextEditingController(text: item.amount.toString());
      final qtyCtrl = TextEditingController(text: item.quantity.toString());

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

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (_isEditing) {
      _editAnimController.forward();
    } else {
      _editAnimController.reverse();
    }
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _editAnimController.dispose();
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
      if (widget.transaction.items.isNotEmpty) {
        for (int i = 0; i < widget.transaction.items.length; i++) {
          final item = widget.transaction.items[i];
          final newNote = _itemNoteControllers[i].text.trim();
          final newAmount =
              int.tryParse(_itemAmountControllers[i].text) ?? item.amount;
          final newQty =
              int.tryParse(_itemQtyControllers[i].text) ?? item.quantity;

          await finance.updateTransactionItemManual(
            transactionId: widget.transaction.id!,
            itemId: item.id!,
            note: newNote,
            amount: newAmount,
            quantity: newQty,
          );
        }
      }

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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(ok
                    ? "Transaksi berhasil diperbarui!"
                    : "Gagal memperbarui transaksi."),
              ],
            ),
            backgroundColor: ok
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
          ),
        );
        if (ok) {
          setState(() => _isEditing = false);
          _editAnimController.reverse();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text("Error: $e"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTx() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Hapus Transaksi?",
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Transaksi ini akan dihapus secara permanen dan tidak dapat dikembalikan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Batal",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Hapus",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final finance = context.read<FinanceProvider>();
      final ok = await finance.deleteTransaction(widget.transaction.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(ok
                ? "Transaksi berhasil dihapus"
                : "Gagal menghapus transaksi"),
            backgroundColor:
                ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          ),
        );
        if (ok) Navigator.pop(context);
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIncome =
        widget.transaction.type == TransactionType.income;

    // Gradient colours per type
    final gradientColors = isIncome
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFF6366F1), const Color(0xFF4F46E5)];

    final accentColor = isIncome
        ? const Color(0xFF10B981)
        : const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Gradient App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: gradientColors[1],
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _isSaving ? null : _deleteTx,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Icon circle
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isIncome ? "Pemasukan" : "Pengeluaran",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_liveTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('dd MMMM yyyy • HH:mm', 'id_ID')
                              .format(widget.transaction.createdAt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Informasi Card ─────────────────────────────────
                  _SectionLabel(label: "INFORMASI TRANSAKSI"),
                  const SizedBox(height: 10),
                  _PremiumCard(
                    child: Column(
                      children: [
                        if (widget.transaction.items.isEmpty) ...[
                          _InfoRow(
                            icon: Icons.notes_rounded,
                            label: "Catatan",
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _Divider(),
                        ],
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: "Kategori",
                          child: _Badge(
                            label: widget.transaction.category,
                            color: accentColor,
                          ),
                        ),
                        _Divider(),
                        _InfoRow(
                          icon: Icons.payment_rounded,
                          label: "Metode Pembayaran",
                          child: widget.transaction.items.isNotEmpty &&
                                  !_isEditing
                              ? _Badge(
                                  label: _paymentMethod.label,
                                  color: Colors.blueGrey,
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<PaymentMethod>(
                                    value: _paymentMethod,
                                    isDense: true,
                                    items: PaymentMethod.values.map((pm) {
                                      return DropdownMenuItem(
                                        value: pm,
                                        child: Text(
                                          pm.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _paymentMethod = val);
                                      }
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // ── Rincian Item ────────────────────────────────────
                  if (widget.transaction.items.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SectionLabel(label: "RINCIAN ITEM BELANJA"),
                        // Edit / Batal toggle pill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: _isEditing
                                ? const Color(0xFFFEE2E2)
                                : accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: _toggleEdit,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isEditing
                                        ? Icons.close_rounded
                                        : Icons.edit_outlined,
                                    size: 14,
                                    color: _isEditing
                                        ? const Color(0xFFEF4444)
                                        : accentColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isEditing ? "Batal" : "Edit",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _isEditing
                                          ? const Color(0xFFEF4444)
                                          : accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Items card
                    _PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header ────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text("Nama", style: _headerStyle()),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 44,
                                child: Text("Qty",
                                    textAlign: TextAlign.center,
                                    style: _headerStyle()),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: Text("Harga/pcs",
                                    textAlign: TextAlign.right,
                                    style: _headerStyle()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 1),

                          // ── Item Rows ─────────────────────────────────
                          ...List.generate(widget.transaction.items.length, (i) {
                            final subtotal =
                                (int.tryParse(_itemAmountControllers[i].text) ?? 0) *
                                (int.tryParse(_itemQtyControllers[i].text) ?? 1);

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Nama kolom
                                      Expanded(
                                        flex: 5,
                                        child: _isEditing
                                            ? _InlineField(
                                                controller: _itemNoteControllers[i],
                                                hint: "Nama item",
                                                accentColor: accentColor,
                                              )
                                            : Text(
                                                _itemNoteControllers[i].text,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Qty kolom
                                      SizedBox(
                                        width: 44,
                                        child: _isEditing
                                            ? _InlineField(
                                                controller: _itemQtyControllers[i],
                                                hint: "Qty",
                                                textAlign: TextAlign.center,
                                                keyboardType: TextInputType.number,
                                                accentColor: accentColor,
                                              )
                                            : Text(
                                                "×${_itemQtyControllers[i].text}",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Harga kolom
                                      Expanded(
                                        flex: 4,
                                        child: _isEditing
                                            ? _InlineField(
                                                controller: _itemAmountControllers[i],
                                                hint: "Harga",
                                                textAlign: TextAlign.right,
                                                keyboardType: TextInputType.number,
                                                accentColor: accentColor,
                                              )
                                            : Text(
                                                _formatRupiah(subtotal),
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: accentColor,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < widget.transaction.items.length - 1)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.withOpacity(0.08),
                                  ),
                              ],
                            );
                          }),

                          // ── Total Row ─────────────────────────────────
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Divider(height: 1, thickness: 1.5),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  _formatRupiah(_liveTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: accentColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],

                  // ── Save Button ──────────────────────────────────────
                  if (widget.transaction.items.isEmpty || _isEditing) ...[
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      opacity: (widget.transaction.items.isEmpty || _isEditing)
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor:
                                accentColor.withOpacity(0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Simpan Perubahan",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.black38,
        letterSpacing: 0.5,
      );
}

// ─── Reusable small widgets ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.black38,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  const _PremiumCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.black45),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.withOpacity(0.1));
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextAlign textAlign;
  final TextInputType keyboardType;
  final Color accentColor;

  const _InlineField({
    required this.controller,
    required this.hint,
    this.textAlign = TextAlign.start,
    this.keyboardType = TextInputType.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
      ),
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    );
  }
}
