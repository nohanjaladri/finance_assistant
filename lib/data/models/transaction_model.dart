/// transaction_model.dart
/// Model utama untuk transaksi keuangan
library;

enum PaymentMethod { tunai, nonTunai }

extension PaymentMethodExt on PaymentMethod {
  String get value => this == PaymentMethod.tunai ? 'tunai' : 'non_tunai';
  String get label => this == PaymentMethod.tunai ? 'Tunai' : 'Non Tunai';

  static PaymentMethod fromString(String? s) {
    if (s == 'non_tunai') return PaymentMethod.nonTunai;
    return PaymentMethod.tunai;
  }
}

enum TransactionType { income, expense }

extension TransactionTypeExt on TransactionType {
  String get value => this == TransactionType.income ? 'IN' : 'OUT';
  static TransactionType fromString(String? s) {
    if (s?.toUpperCase() == 'IN') return TransactionType.income;
    return TransactionType.expense;
  }
}

class TransactionModel {
  final int? id;
  final String userId;
  final String? roomId;
  final int amount;
  final String note;
  final TransactionType type;
  final String category;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.userId,
    this.roomId,
    required this.amount,
    required this.note,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.createdAt,
  });

  /// Klasifikasi otomatis payment method berdasarkan kategori
  static PaymentMethod classifyPaymentMethod(String category) {
    const nonTunaiCategories = {
      'EWallet',
      'Transfer_In',
      'Transfer_Out',
      'Bills',
    };
    return nonTunaiCategories.contains(category)
        ? PaymentMethod.nonTunai
        : PaymentMethod.tunai;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String? ?? '',
      roomId: json['room_id'] as String?,
      amount: json['amount'] as int? ?? 0,
      note: json['note'] as String? ?? '',
      type: TransactionTypeExt.fromString(json['type'] as String?),
      category: json['category'] as String? ?? 'Other',
      paymentMethod: PaymentMethodExt.fromString(
        json['payment_method'] as String?,
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    if (roomId != null) 'room_id': roomId,
    'amount': amount,
    'note': note,
    'type': type.value,
    'category': category,
    'payment_method': paymentMethod.value,
    'created_at': createdAt.toIso8601String(),
  };

  TransactionModel copyWith({
    int? id,
    String? userId,
    String? roomId,
    int? amount,
    String? note,
    TransactionType? type,
    String? category,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
