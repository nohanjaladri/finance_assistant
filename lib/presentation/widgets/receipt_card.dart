import 'dart:convert';
import 'package:flutter/material.dart';

class ReceiptCard extends StatelessWidget {
  final String receiptJson;

  const ReceiptCard({super.key, required this.receiptJson});

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
    List<dynamic> items = [];
    try {
      items = jsonDecode(receiptJson);
    } catch (_) {}

    if (items.isEmpty) return const SizedBox.shrink();

    int totalIn = 0;
    int totalOut = 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 16,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Rincian Transaksi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          ...items.map((item) {
            final note = item['note'] ?? 'Item';
            final amount = item['amount'] as int? ?? 0;
            final type = item['type'] ?? 'OUT';
            final isIn = type == 'IN';

            if (isIn) {
              totalIn += amount;
            } else {
              totalOut += amount;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Rp ${_formatRupiah(amount)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isIn
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: isIn ? Colors.green : Colors.red,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),

          if (totalIn > 0 && totalOut > 0) ...[
            _buildSummaryRow("Total Pemasukan", totalIn, Colors.green),
            const SizedBox(height: 4),
            _buildSummaryRow("Total Pengeluaran", totalOut, Colors.red),
            const SizedBox(height: 8),
          ],

          _buildNettoRow(totalIn - totalOut),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          "Rp ${_formatRupiah(amount)}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNettoRow(int netto) {
    final isPositive = netto >= 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "TOTAL",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          Row(
            children: [
              Text(
                "Rp ${_formatRupiah(netto.abs())}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPositive
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
