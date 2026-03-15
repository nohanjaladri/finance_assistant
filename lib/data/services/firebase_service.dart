import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<DatabaseEvent>? _syncSubscription;

  String get currentUserUid => _auth.currentUser?.uid ?? 'unknown_user';

  Future<String> getMyRoomCode() async {
    final uid = currentUserUid;
    final userRef = _db.ref('users/$uid/room_code');
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      return snapshot.value.toString();
    } else {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      Random rnd = Random();
      String newCode = String.fromCharCodes(
        Iterable.generate(
          5,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
        ),
      );

      await _db.ref('room_codes/$newCode').set(uid);
      await userRef.set(newCode);
      return newCode;
    }
  }

  Future<String?> resolveRoomCode(String code) async {
    final snapshot = await _db.ref('room_codes/${code.toUpperCase()}').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    }
    return null;
  }

  DatabaseReference _getDbReference(bool isSharedMode, String activeSharedUid) {
    if (isSharedMode) {
      return _db.ref('workspaces/$activeSharedUid');
    } else {
      return _db.ref('users/$currentUserUid/personal');
    }
  }

  // ---------------------------------------------------------
  // FITUR BARU: RESET DATABASE TOTAL (BAKAR SAMPAI AKAR)
  // ---------------------------------------------------------
  Future<void> wipeEntireWorkspace({
    required bool isSharedMode,
    required String activeSharedUid,
  }) async {
    if (_auth.currentUser == null) throw "Belum login";

    // PENGAMAN: Mencegah pengguna menghapus data ruangan milik teman
    if (isSharedMode && activeSharedUid != currentUserUid) {
      throw "Akses Ditolak: Anda tidak dapat menghapus total data di ruangan teman. Silakan 'Keluar Ruangan' terlebih dahulu.";
    }

    // Eksekusi penghapusan seluruh folder (transactions, messages, pending_requests) di cloud
    final targetRef = _getDbReference(isSharedMode, activeSharedUid);
    await targetRef.remove();
  }
  // ---------------------------------------------------------

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
    if (_auth.currentUser == null) throw "Belum login";

    final localDb = await DatabaseHelper.instance.database;
    final targetRef = _getDbReference(isSharedMode, activeSharedUid);

    final pendingTxs = await localDb.query(
      'transactions',
      where: "sync_status LIKE 'pending_%'",
    );
    for (var tx in pendingTxs) {
      final status = tx['sync_status'] as String;
      final fbKey = "tx_${tx['id']}";
      final txRef = targetRef.child('transactions/$fbKey');

      if (status == 'pending_insert' || status == 'pending_update') {
        Map<String, dynamic> data = Map<String, dynamic>.from(tx);
        data.remove('sync_status');
        await txRef.set(data);
        await localDb.update(
          'transactions',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [tx['id']],
        );
      } else if (status == 'pending_delete') {
        await txRef.remove();
        await localDb.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [tx['id']],
        );
      }
    }

    final pendingMsgs = await localDb.query(
      'messages',
      where: "sync_status LIKE 'pending_%'",
    );
    for (var msg in pendingMsgs) {
      final status = msg['sync_status'] as String;
      final fbKey = "msg_${msg['id']}";
      final msgRef = targetRef.child('messages/$fbKey');

      if (status == 'pending_insert' || status == 'pending_update') {
        Map<String, dynamic> data = Map<String, dynamic>.from(msg);
        data.remove('sync_status');
        await msgRef.set(data);
        await localDb.update(
          'messages',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [msg['id']],
        );
      } else if (status == 'pending_delete') {
        await msgRef.remove();
        await localDb.delete(
          'messages',
          where: 'id = ?',
          whereArgs: [msg['id']],
        );
      }
    }

    final pendingReqs = await localDb.query(
      'pending_requests',
      where: "sync_status LIKE 'pending_%'",
    );
    for (var req in pendingReqs) {
      final status = req['sync_status'] as String;
      final fbKey = "req_${req['id']}";
      final reqRef = targetRef.child('pending_requests/$fbKey');

      if (status == 'pending_insert' || status == 'pending_update') {
        Map<String, dynamic> data = Map<String, dynamic>.from(req);
        data.remove('sync_status');
        await reqRef.set(data);
        await localDb.update(
          'pending_requests',
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [req['id']],
        );
      } else if (status == 'pending_delete') {
        await reqRef.remove();
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
    if (_auth.currentUser == null) return;

    _syncSubscription?.cancel();
    final targetRef = _getDbReference(isSharedMode, activeSharedUid);

    _syncSubscription = targetRef.child('transactions').onValue.listen((
      event,
    ) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final localDb = await DatabaseHelper.instance.database;

      for (var key in data.keys) {
        final txData = Map<String, dynamic>.from(data[key]);
        txData['sync_status'] = 'synced';

        final idStr = key.toString().replaceAll('tx_', '');
        final id = int.tryParse(idStr);
        if (id != null) {
          txData['id'] = id;
          await localDb.insert(
            'transactions',
            txData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      onDataUpdated();
    });
  }
}
