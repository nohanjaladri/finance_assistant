/// pending_model.dart
/// Model untuk transaksi yang belum lengkap (pending dari AI)
library;

import 'dart:convert';
import 'transaction_model.dart';

class PendingModel {
  final int? id;
  final String userId;
  final String? roomId;
  final String originalInput;
  final String? nama;
  final int? nominal;
  final int quantity;
  final List<String> missingFields;
  final Map<String, dynamic> partialData;
  final String aiQuestion;
  final String reason;
  final String category;
  final TransactionType type;
  final PaymentMethod paymentMethod;
  final String status; // 'pending' | 'done' | 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingModel({
    this.id,
    required this.userId,
    this.roomId,
    required this.originalInput,
    this.nama,
    this.nominal,
    this.quantity = 1,
    this.missingFields = const [],
    this.partialData = const {},
    required this.aiQuestion,
    required this.reason,
    this.category = 'Other',
    this.type = TransactionType.expense,
    this.paymentMethod = PaymentMethod.tunai,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isResolvable =>
      nama != null && nama!.isNotEmpty && nominal != null && nominal! > 0;

  String get missingFieldsLabel {
    if (missingFields.isEmpty) return '-';
    const labels = {
      'nama': 'nama item',
      'nominal': 'harga/nominal',
      'quantity': 'jumlah',
    };
    return missingFields.map((f) => labels[f] ?? f).join(', ');
  }

  String get formattedInputTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'kemarin';
    return '${diff.inDays} hari lalu';
  }

  factory PendingModel.fromJson(Map<String, dynamic> json) {
    List<String> missing = [];
    try {
      final raw = json['missing_fields'];
      if (raw is String) missing = (jsonDecode(raw) as List).cast<String>();
      if (raw is List) missing = raw.cast<String>();
    } catch (_) {}

    Map<String, dynamic> partial = {};
    try {
      final raw = json['partial_data'];
      if (raw is String) partial = jsonDecode(raw) as Map<String, dynamic>;
      if (raw is Map) partial = Map<String, dynamic>.from(raw);
    } catch (_) {}

    return PendingModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String? ?? '',
      roomId: json['room_id'] as String?,
      originalInput: json['original_input'] as String? ?? '',
      nama: json['nama'] as String?,
      nominal: json['nominal'] as int?,
      quantity: json['quantity'] as int? ?? 1,
      missingFields: missing,
      partialData: partial,
      aiQuestion: json['ai_question'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      type: TransactionTypeExt.fromString(json['type'] as String?),
      paymentMethod: PaymentMethodExt.fromString(
        json['payment_method'] as String?,
      ),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    if (roomId != null) 'room_id': roomId,
    'original_input': originalInput,
    'nama': nama,
    'nominal': nominal,
    'quantity': quantity,
    'missing_fields': missingFields,
    'partial_data': partialData,
    'ai_question': aiQuestion,
    'reason': reason,
    'category': category,
    'type': type.value,
    'payment_method': paymentMethod.value,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  PendingModel copyWith({
    int? id,
    String? userId,
    String? roomId,
    String? originalInput,
    String? nama,
    int? nominal,
    int? quantity,
    List<String>? missingFields,
    Map<String, dynamic>? partialData,
    String? aiQuestion,
    String? reason,
    String? category,
    TransactionType? type,
    PaymentMethod? paymentMethod,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PendingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      originalInput: originalInput ?? this.originalInput,
      nama: nama ?? this.nama,
      nominal: nominal ?? this.nominal,
      quantity: quantity ?? this.quantity,
      missingFields: missingFields ?? this.missingFields,
      partialData: partialData ?? this.partialData,
      aiQuestion: aiQuestion ?? this.aiQuestion,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
