/// pending_request_helper.dart
/// Struktur pending baru:
/// WAJIB user  : nama, nominal
/// OPSIONAL    : quantity (default 1), input_datetime (default now)
/// AUTO sistem : id, original_input, ai_question, reason, status, category, type
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class PendingRequestHelper {
  static final PendingRequestHelper instance = PendingRequestHelper._init();
  PendingRequestHelper._init();

  // ==========================================
  // CREATE
  // ==========================================

  Future<int> savePending({
    required String originalInput,
    // 2 wajib dari user (null = belum diisi)
    String? nama,
    int? nominal,
    // 2 opsional (default otomatis)
    int quantity = 1,
    DateTime? inputDatetime,
    // auto dari AI
    required String aiQuestion,
    required String reason,
    String category = 'Other',
    String type = 'OUT',
    // turunan
    List<String> missingFields = const [],
    Map<String, dynamic> partialData = const {},
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    // Hitung missing fields otomatis
    final missing = <String>[...missingFields];
    if (nama == null && !missing.contains('nama')) missing.add('nama');
    if (nominal == null && !missing.contains('nominal')) missing.add('nominal');

    final id = await db.insert('pending_requests', {
      'original_input': originalInput,
      'nama': nama,
      'nominal': nominal,
      'quantity': quantity,
      'input_datetime': (inputDatetime ?? now).toIso8601String(),
      'missing_fields': jsonEncode(missing),
      'partial_data': jsonEncode(partialData),
      'ai_question': aiQuestion,
      'reason': reason,
      'category': category,
      'type': type,
      'created_at': now.toIso8601String(),
      'status': 'pending',
      'follow_up_shown': 0,
    });

    debugPrint(
      "PENDING_SAVED: ID=$id nama=$nama nominal=$nominal missing=$missing",
    );
    return id;
  }

  // ==========================================
  // READ
  // ==========================================

  Future<List<PendingRequest>> getAllPending() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'pending_requests',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => PendingRequest.fromMap(r)).toList();
  }

  Future<PendingRequest?> getOldestPending() async {
    final all = await getAllPending();
    return all.isNotEmpty ? all.first : null;
  }

  Future<int> countPending() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM pending_requests WHERE status = 'pending'",
    );
    return result.first['count'] as int;
  }

  // ==========================================
  // UPDATE
  // ==========================================

  Future<void> markDone(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pending_requests',
      {'status': 'done'},
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint("PENDING_DONE: ID=$id");
  }

  Future<void> cancelPending(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pending_requests',
      {'status': 'cancelled'},
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint("PENDING_CANCELLED: ID=$id");
  }

  /// Update data yang sudah terkumpul (nama/nominal/quantity)
  Future<void> updatePendingData(
    int id, {
    String? nama,
    int? nominal,
    int? quantity,
    List<String>? missingFields,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final updates = <String, dynamic>{};
    if (nama != null) updates['nama'] = nama;
    if (nominal != null) updates['nominal'] = nominal;
    if (quantity != null) updates['quantity'] = quantity;
    if (missingFields != null) {
      updates['missing_fields'] = jsonEncode(missingFields);
    }
    if (updates.isEmpty) return;
    await db.update(
      'pending_requests',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tandai follow-up sudah ditampilkan
  Future<void> markFollowUpShown(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pending_requests',
      {'follow_up_shown': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ==========================================
// MODEL
// ==========================================

class PendingRequest {
  final int id;
  final String originalInput;
  // 2 wajib user
  final String? nama;
  final int? nominal;
  // 2 opsional
  final int quantity;
  final DateTime inputDatetime;
  // auto sistem
  final List<String> missingFields;
  final Map<String, dynamic> partialData;
  final String aiQuestion;
  final String reason;
  final String category;
  final String type;
  // status
  final String createdAt;
  final String status;
  final bool followUpShown;

  PendingRequest({
    required this.id,
    required this.originalInput,
    this.nama,
    this.nominal,
    this.quantity = 1,
    required this.inputDatetime,
    required this.missingFields,
    required this.partialData,
    required this.aiQuestion,
    required this.reason,
    this.category = 'Other',
    this.type = 'OUT',
    required this.createdAt,
    required this.status,
    this.followUpShown = false,
  });

  factory PendingRequest.fromMap(Map<String, dynamic> map) {
    return PendingRequest(
      id: map['id'] as int,
      originalInput: map['original_input'] as String,
      nama: map['nama'] as String?,
      nominal: map['nominal'] as int?,
      quantity: (map['quantity'] as int?) ?? 1,
      inputDatetime:
          DateTime.tryParse(
            map['input_datetime'] as String? ??
                map['created_at'] as String? ??
                '',
          ) ??
          DateTime.now(),
      missingFields: List<String>.from(
        jsonDecode(map['missing_fields'] as String? ?? '[]'),
      ),
      partialData: Map<String, dynamic>.from(
        jsonDecode(map['partial_data'] as String? ?? '{}'),
      ),
      aiQuestion: map['ai_question'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      type: map['type'] as String? ?? 'OUT',
      createdAt: map['created_at'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      followUpShown: (map['follow_up_shown'] as int? ?? 0) == 1,
    );
  }

  /// Label field yang masih kurang
  String get missingFieldsLabel {
    if (missingFields.isEmpty) return '-';
    const labels = {
      'nama': 'nama item',
      'nominal': 'harga/nominal',
      'quantity': 'jumlah',
    };
    return missingFields.map((f) => labels[f] ?? f).join(', ');
  }

  /// Waktu input dalam format human-readable
  String get formattedInputTime {
    final now = DateTime.now();
    final diff = now.difference(inputDatetime);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'kemarin';
    return '${diff.inDays} hari lalu';
  }

  /// Format waktu lengkap untuk ditampilkan di follow-up
  String get formattedInputDatetime {
    final dt = inputDatetime;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$minute';
  }

  /// Ringkasan untuk follow-up message
  /// Contoh: "bakso (baru saja) — kurang: harga"
  String get followUpSummary {
    final namaPart = nama ?? '"$originalInput"';
    final timePart = formattedInputTime;
    final missingPart = missingFieldsLabel;
    final qtyPart = quantity > 1 ? ' x$quantity' : '';
    return '$namaPart$qtyPart ($timePart) — kurang: $missingPart';
  }

  /// Konteks untuk dikirim ke AI sebagai memori
  String get contextSummary =>
      'ID $id: "$originalInput" | nama=$nama | nominal=$nominal | '
      'qty=$quantity | waktu=$formattedInputDatetime | kurang=$missingFieldsLabel';
}
