/// pending_reminder_card.dart
/// Update: tombol Lengkapi sekarang inject bubble follow-up ke chat
/// bukan snackbar lagi
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../../data/database/pending_request_helper.dart';

// ==========================================
// BADGE
// ==========================================

class PendingBadge extends StatelessWidget {
  const PendingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final count = finance.pendingCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.pending_actions),
              tooltip: 'Transaksi Tertunda ($count)',
              onPressed: () => _showPendingDialog(context),
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FinanceProvider>(),
        child: const _PendingDialog(),
      ),
    );
  }
}

// ==========================================
// DIALOG
// ==========================================

class _PendingDialog extends StatefulWidget {
  const _PendingDialog();

  @override
  State<_PendingDialog> createState() => _PendingDialogState();
}

class _PendingDialogState extends State<_PendingDialog> {
  List<PendingRequest> _pendingList = [];
  bool _isLoading = true;
  int _lastKnownCount = -1;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCount = context.watch<FinanceProvider>().pendingCount;
    if (currentCount != _lastKnownCount && _lastKnownCount != -1) {
      _loadPending();
    }
    _lastKnownCount = currentCount;
  }

  Future<void> _loadPending() async {
    if (!mounted) return;
    final list = await context.read<FinanceProvider>().getAllPending();
    if (mounted) {
      setState(() {
        _pendingList = list;
        _isLoading = false;
        _lastKnownCount = context.read<FinanceProvider>().pendingCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        if (finance.pendingCount != _lastKnownCount && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadPending());
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.indigo],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pending_actions,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transaksi Tertunda (${finance.pendingCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        )
                      : _pendingList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Semua transaksi sudah lengkap!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) => _PendingItem(
                            pending: _pendingList[i],
                            onComplete: () => _onComplete(_pendingList[i]),
                            onCancel: () => _onCancel(_pendingList[i], i),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Lengkapi: tutup dialog + inject bubble follow-up ke chat
  void _onComplete(PendingRequest pending) {
    context.read<FinanceProvider>().triggerFollowUp(pending);
    Navigator.pop(context);
  }

  Future<void> _onCancel(PendingRequest pending, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: Text('Yakin batalkan "${pending.originalInput}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<FinanceProvider>().cancelPending(pending.id);
    }
  }
}

// ==========================================
// ITEM CARD
// ==========================================

class _PendingItem extends StatelessWidget {
  final PendingRequest pending;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _PendingItem({
    required this.pending,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input asli
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.receipt_long,
                size: 16,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"${pending.originalInput}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Alasan pending
          if (pending.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 4),
              child: Text(
                pending.reason,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          Row(
            children: [
              const SizedBox(width: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Kurang: ${pending.missingFieldsLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                pending.missingFieldsLabel,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const SizedBox(width: 22),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('Lengkapi', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Batalkan', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
