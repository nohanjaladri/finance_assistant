import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _syncSubscription;

  String get currentUserUid => _supabase.auth.currentUser?.id ?? 'unknown_user';

  Future<String> getMyRoomCode() async {
    final uid = currentUserUid;

    final response = await _supabase
        .from('room_codes')
        .select('code')
        .eq('owner_uid', uid)
        .maybeSingle();

    if (response != null && response['code'] != null) {
      return response['code'].toString();
    } else {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      Random rnd = Random();
      String newCode = String.fromCharCodes(
        Iterable.generate(
          5,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
        ),
      );

      await _supabase.from('room_codes').insert({
        'code': newCode,
        'owner_uid': uid,
      });
      return newCode;
    }
  }

  Future<String?> resolveRoomCode(String code) async {
    final response = await _supabase
        .from('room_codes')
        .select('owner_uid')
        .eq('code', code.toUpperCase())
        .maybeSingle();
    if (response != null && response['owner_uid'] != null) {
      return response['owner_uid'].toString();
    }
    return null;
  }

  Future<void> wipeEntireWorkspace({
    required bool isSharedMode,
    required String activeSharedUid,
  }) async {
    if (_supabase.auth.currentUser == null) throw "Belum login";
    if (isSharedMode && activeSharedUid != currentUserUid) {
      throw "Akses Ditolak: Anda tidak dapat menghapus total data di ruangan teman.";
    }

    final isPersonal = !isSharedMode;

    await _supabase.from('transactions').delete().match({
      'workspace_id': activeSharedUid,
      'is_personal': isPersonal,
    });
    await _supabase.from('messages').delete().match({
      'workspace_id': activeSharedUid,
      'is_personal': isPersonal,
    });
    await _supabase.from('pending_requests').delete().match({
      'workspace_id': activeSharedUid,
      'is_personal': isPersonal,
    });
  }

  Future<int> getPendingCount() async {
    final localDb = await DatabaseHelper.instance.database;
    final t = await localDb.query(
      'transactions',
      where: "sync_status LIKE 'pending_%'",
    );
    final m = await localDb.query(
      'messages',
      where: "sync_status LIKE 'pending_%'",
    );
    final p = await localDb.query(
      'pending_requests',
      where: "sync_status LIKE 'pending_%'",
    );
    return t.length + m.length + p.length;
  }

  Future<void> pushPendingData({
    required bool isSharedMode,
    required String activeSharedUid,
  }) async {
    if (_supabase.auth.currentUser == null) throw "Belum login";

    final localDb = await DatabaseHelper.instance.database;
    final isPersonal = !isSharedMode;

    // --- A. DORONG TRANSAKSI ---
    final pendingTxs = await localDb.query(
      'transactions',
      where: "sync_status LIKE 'pending_%'",
    );
    for (var tx in pendingTxs) {
      final status = tx['sync_status'] as String;
      Map<String, dynamic> data = Map<String, dynamic>.from(tx);
      data.remove('sync_status');
      data['workspace_id'] = activeSharedUid;
      data['is_personal'] = isPersonal;

      if (status == 'pending_insert' || status == 'pending_update') {
        await _supabase.from('transactions').upsert(data);
        await localDb.update(
          'transactions',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [tx['id']],
        );
      } else if (status == 'pending_delete') {
        // PERBAIKAN ERROR: Casting tipe data explicitly menjadi Object
        await _supabase.from('transactions').delete().match({
          'id': tx['id'] as Object,
          'workspace_id': activeSharedUid,
          'is_personal': isPersonal,
        });
        await localDb.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [tx['id']],
        );
      }
    }

    // --- B. DORONG CHAT AI ---
    final pendingMsgs = await localDb.query(
      'messages',
      where: "sync_status LIKE 'pending_%'",
    );
    for (var msg in pendingMsgs) {
      final status = msg['sync_status'] as String;
      Map<String, dynamic> data = Map<String, dynamic>.from(msg);
      data.remove('sync_status');
      data['workspace_id'] = activeSharedUid;
      data['is_personal'] = isPersonal;

      if (status == 'pending_insert' || status == 'pending_update') {
        await _supabase.from('messages').upsert(data);
        await localDb.update(
          'messages',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [msg['id']],
        );
      } else if (status == 'pending_delete') {
        // PERBAIKAN ERROR: Casting tipe data explicitly menjadi Object
        await _supabase.from('messages').delete().match({
          'id': msg['id'] as Object,
          'workspace_id': activeSharedUid,
          'is_personal': isPersonal,
        });
        await localDb.delete(
          'messages',
          where: 'id = ?',
          whereArgs: [msg['id']],
        );
      }
    }

    // --- C. DORONG REQUEST PENDING ---
    final pendingReqs = await localDb.query(
      'pending_requests',
      where: "sync_status LIKE 'pending_%'",
    );
    for (var req in pendingReqs) {
      final status = req['sync_status'] as String;
      Map<String, dynamic> data = Map<String, dynamic>.from(req);
      data.remove('sync_status');
      data['workspace_id'] = activeSharedUid;
      data['is_personal'] = isPersonal;

      if (status == 'pending_insert' || status == 'pending_update') {
        await _supabase.from('pending_requests').upsert(data);
        await localDb.update(
          'pending_requests',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [req['id']],
        );
      } else if (status == 'pending_delete') {
        // PERBAIKAN ERROR: Casting tipe data explicitly menjadi Object
        await _supabase.from('pending_requests').delete().match({
          'id': req['id'] as Object,
          'workspace_id': activeSharedUid,
          'is_personal': isPersonal,
        });
        await localDb.delete(
          'pending_requests',
          where: 'id = ?',
          whereArgs: [req['id']],
        );
      }
    }
  }

  void listenToWorkspace({
    required bool isSharedMode,
    required String activeSharedUid,
    required Function onDataUpdated,
  }) {
    if (_supabase.auth.currentUser == null) return;

    final isPersonal = !isSharedMode;

    _syncSubscription?.unsubscribe();

    // PERBAIKAN ERROR: Sintaks Realtime Subscription Supabase Terbaru (v2)
    _syncSubscription = _supabase
        .channel('public:transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'workspace_id',
            value: activeSharedUid,
          ),
          callback: (PostgresChangePayload payload) async {
            final newRecord = payload.newRecord;
            final eventType = payload.eventType;

            if (eventType == PostgresChangeEvent.insert ||
                eventType == PostgresChangeEvent.update) {
              if (newRecord.isNotEmpty &&
                  newRecord['is_personal'] == isPersonal) {
                final localDb = await DatabaseHelper.instance.database;

                Map<String, dynamic> txData = Map<String, dynamic>.from(
                  newRecord,
                );
                txData.remove('workspace_id');
                txData.remove('is_personal');
                txData['sync_status'] = 'synced';

                await localDb.insert(
                  'transactions',
                  txData,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                onDataUpdated();
              }
            } else if (eventType == PostgresChangeEvent.delete) {
              final oldRecord = payload.oldRecord;
              if (oldRecord.isNotEmpty) {
                final localDb = await DatabaseHelper.instance.database;
                await localDb.delete(
                  'transactions',
                  where: 'id = ?',
                  whereArgs: [oldRecord['id']],
                );
                onDataUpdated();
              }
            }
          },
        )
        .subscribe(); // Method subscribe sekarang kosong, data di-handle oleh callback di atas
  }
}
