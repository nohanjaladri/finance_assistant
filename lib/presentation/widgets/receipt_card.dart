import 'dart:convert';
import 'package:flutter/material.dart';

class ReceiptCard extends StatelessWidget {
  final dynamic receiptData;

  const ReceiptCard({super.key, required this.receiptData});

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    if (receiptData is String) {
      try {
        data = jsonDecode(receiptData) as Map<String, dynamic>;
      } catch (_) {}
    } else if (receiptData is Map) {
      data = Map<String, dynamic>.from(receiptData);
    }
    List<dynamic> items = [];
    try {
      items = data['transactions'] as List<dynamic>? ??
          data['items'] as List<dynamic>? ??
          data['extracted_items'] as List<dynamic>? ??
          [];
    } catch (_) {}

    if (items.isEmpty) return const SizedBox.shrink();

    int totalIn = 0;
    int totalOut = 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.82,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E5CE6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: Color(0xFF5E5CE6),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Detail Transaksi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E1E2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          ...items.map((item) {
            final note = item['note'] ?? 'Item';
            final amount = item['amount'] as int? ?? 0;
            final quantity = item['quantity'] as int? ?? item['qty'] as int? ?? 1;
            final type = item['type'] ?? 'OUT';
            final isIn = type == 'IN';
            final itemTotal = amount * quantity;

            if (isIn) {
              totalIn += itemTotal;
            } else {
              totalOut += itemTotal;
            }

            final textColor = isIn ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$quantity",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _formatRupiah(itemTotal),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          _buildTotalRow(totalIn, totalOut),
        ],
      ),
    );
  }

  Widget _buildTotalRow(int totalIn, int totalOut) {
    final isIncome = totalIn >= totalOut;
    final netto = (totalIn - totalOut).abs();
    final mainColor = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final bgColor = isIncome ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "total",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: mainColor,
            ),
          ),
          Text(
            _formatRupiah(netto),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: mainColor,
            ),
          ),
        ],
      ),
    );
  }
}
