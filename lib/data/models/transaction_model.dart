import 'package:flutter/foundation.dart';


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

class TransactionItemModel {
  final int? id;
  final int transactionId;
  final String note;
  final int amount;
  final int quantity;

  const TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.note,
    required this.amount,
    required this.quantity,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num?)?.toInt(),
      transactionId: json['transaction_id'] is int ? json['transaction_id'] as int : (json['transaction_id'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      amount: json['amount'] is int ? json['amount'] as int : (json['amount'] as num?)?.toInt() ?? 0,
      quantity: json['quantity'] is int ? json['quantity'] as int : (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'transaction_id': transactionId,
    'note': note,
    'amount': amount,
    'quantity': quantity,
  };

  TransactionItemModel copyWith({
    int? id,
    int? transactionId,
    String? note,
    int? amount,
    int? quantity,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
    );
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
  final List<TransactionItemModel> items;

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
    this.items = const [],
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
    debugPrint('TransactionModel.fromJson: id=${json['id']}, note="${json['note']}", keys=${json.keys.toList()}');
    if (json['transaction_items'] != null) {
      debugPrint('transaction_items type: ${json['transaction_items'].runtimeType}, data: ${json['transaction_items']}');
    } else {
      debugPrint('transaction_items is NULL for transaction id=${json['id']}');
    }
    
    var itemsList = <TransactionItemModel>[];
    if (json['transaction_items'] != null) {
      try {
        final list = json['transaction_items'] as List;
        itemsList = list
            .map((i) => TransactionItemModel.fromJson(i as Map<String, dynamic>))
            .toList();
      } catch (e, stack) {
        debugPrint('Error parsing transaction_items list in TransactionModel.fromJson: $e\n$stack');
      }
    }
    return TransactionModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String? ?? '',
      roomId: json['room_id'] as String?,
      amount: json['amount'] is int ? json['amount'] as int : (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      type: TransactionTypeExt.fromString(json['type'] as String?),
      category: json['category'] as String? ?? 'Other',
      paymentMethod: PaymentMethodExt.fromString(
        json['payment_method'] as String?,
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      items: itemsList,
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
    'transaction_items': items.map((i) => i.toJson()).toList(),
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
    List<TransactionItemModel>? items,
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
      items: items ?? this.items,
    );
  }
}

