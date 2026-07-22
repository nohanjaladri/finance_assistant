import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final Color accentColor;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.accentColor,
    this.onTap,
  });

  IconData _getCategoryIcon(String category, bool isIn) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'groceries':
        return Icons.shopping_basket_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'transfer_in':
      case 'transfer_out':
        return Icons.swap_horiz_rounded;
      case 'entertainment':
        return Icons.movie_filter_rounded;
      default:
        return isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    }
  }

  Color _getCategoryColor(String category, bool isIn) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF9F0A); // Apple Orange
      case 'groceries':
        return const Color(0xFF30D158); // Apple Green
      case 'transport':
        return const Color(0xFF5E5CE6); // Apple Indigo
      case 'shopping':
        return const Color(0xFFBF5AF2); // Apple Purple
      case 'salary':
        return const Color(0xFF34C759); // Apple Money Green
      case 'bills':
      case 'utilities':
        return const Color(0xFFFF453A); // Apple Red
      case 'transfer_in':
      case 'transfer_out':
        return const Color(0xFF64D2FF); // Apple Sky Blue
      case 'entertainment':
        return const Color(0xFFFF375F); // Apple Pink
      default:
        return isIn ? const Color(0xFF34C759) : const Color(0xFFFF453A);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return "${dt.day} ${months[dt.month - 1]} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isIn = tx.type == TransactionType.income;
    final amt = tx.amount;
    final iconColor = _getCategoryColor(tx.category, isIn);
    final iconData = _getCategoryIcon(tx.category, isIn);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon Stack with Payment Method Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.15), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                ),
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
                      size: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(tx.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              "${isIn ? '+' : '-'}Rp ${_formatAmt(amt)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isIn ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
