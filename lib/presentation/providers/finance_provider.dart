import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/pending_request_helper.dart';
import '../../data/services/firebase_service.dart';

enum SyncStatus { synced, syncing, offline }

class FinanceProvider extends ChangeNotifier {
  int totalIn = 0;
  int totalOut = 0;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> chatHistory = [];
  bool isAiThinking = false;

  int pendingCount = 0;
  PendingRequest? activeResolvingPending;
  bool isWaitingDirectReply = false;
  PendingRequest? pendingToFollowUp;

  bool isSharedMode = false;
  SyncStatus syncStatus = SyncStatus.synced;

  final FirebaseService _firebaseService = FirebaseService();
  bool _isFirebaseInitialized = false;

  String activeSharedUid = '';
  String myRoomCode = 'MEMUAT...';
  bool isJoiningOtherRoom = false;

  Future<void> _initSharingState() async {
    final prefs = await SharedPreferences.getInstance();
    final joinedUid = prefs.getString('joined_room_uid');

    if (joinedUid != null && joinedUid.isNotEmpty) {
      activeSharedUid = joinedUid;
      isJoiningOtherRoom = true;
    } else {
      activeSharedUid = _firebaseService.currentUserUid;
      isJoiningOtherRoom = false;
    }

    myRoomCode = await _firebaseService.getMyRoomCode();
    notifyListeners();
  }

  void toggleWorkspace() async {
    isSharedMode = !isSharedMode;
    DatabaseHelper.instance.setMode(isSharedMode);

    if (isSharedMode && activeSharedUid.isEmpty) {
      await _initSharingState();
    }

    notifyListeners();
    await refreshData();

    _firebaseService.listenToWorkspace(
      isSharedMode: isSharedMode,
      activeSharedUid: activeSharedUid,
      onDataUpdated: () {
        refreshData();
      },
    );

    _syncWithFirebase();
  }

  Future<bool> joinSharedRoom(String code) async {
    try {
      final targetUid = await _firebaseService.resolveRoomCode(code);
      if (targetUid == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('joined_room_uid', targetUid);

      activeSharedUid = targetUid;
      isJoiningOtherRoom = true;

      if (!isSharedMode) {
        isSharedMode = true;
        DatabaseHelper.instance.setMode(true);
      }

      await DatabaseHelper.instance.clearAllData();

      _firebaseService.listenToWorkspace(
        isSharedMode: isSharedMode,
        activeSharedUid: activeSharedUid,
        onDataUpdated: () {
          refreshData();
        },
      );

      await refreshData();
      _syncWithFirebase();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> leaveSharedRoom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('joined_room_uid');

    activeSharedUid = _firebaseService.currentUserUid;
    isJoiningOtherRoom = false;

    await DatabaseHelper.instance.clearAllData();

    _firebaseService.listenToWorkspace(
      isSharedMode: isSharedMode,
      activeSharedUid: activeSharedUid,
      onDataUpdated: () {
        refreshData();
      },
    );

    await refreshData();
    _syncWithFirebase();
  }

  // ========================================================
  // JEMBATAN RESET DATABASE TOTAL
  // ========================================================
  Future<void> wipeEntireDatabase() async {
    // 1. Serang Server Firebase Dahulu
    await _firebaseService.wipeEntireWorkspace(
      isSharedMode: isSharedMode,
      activeSharedUid: activeSharedUid,
    );

    // 2. Jika Firebase sukses, serang SQLite Lokal
    await DatabaseHelper.instance.clearAllData();

    // 3. Reset state Provider
    activeResolvingPending = null;
    pendingToFollowUp = null;
    isWaitingDirectReply = false;

    // 4. Perbarui UI
    await refreshData();
    _syncWithFirebase();
  }
  // ========================================================

  Future<void> _syncWithFirebase() async {
    syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      await _firebaseService.pushPendingData(
        isSharedMode: isSharedMode,
        activeSharedUid: activeSharedUid,
      );

      int sisaAntrean = await _firebaseService.getPendingCount();
      if (sisaAntrean == 0) {
        syncStatus = SyncStatus.synced;
      } else {
        syncStatus = SyncStatus.offline;
      }
    } catch (e) {
      syncStatus = SyncStatus.offline;
    }

    notifyListeners();
  }

  Future<void> _syncPendingCount() async {
    try {
      pendingCount = await PendingRequestHelper.instance.countPending();
    } catch (_) {}
  }

  Future<void> refreshData() async {
    try {
      final txs = await DatabaseHelper.instance.getAllTransactions();
      final msgs = await DatabaseHelper.instance.getMessages(limit: 30);

      int tempIn = 0, tempOut = 0;
      for (var tx in txs) {
        final amt = tx['amount'] as int;
        final type = tx['type'].toString().trim().toUpperCase();
        if (type == 'IN')
          tempIn += amt;
        else if (type == 'OUT')
          tempOut += amt;
      }

      totalIn = tempIn;
      totalOut = tempOut;
      history = List.from(txs);
      chatHistory = msgs.reversed.toList();
      await _syncPendingCount();

      if (!_isFirebaseInitialized) {
        _isFirebaseInitialized = true;
        await _initSharingState();
        _firebaseService.listenToWorkspace(
          isSharedMode: isSharedMode,
          activeSharedUid: activeSharedUid,
          onDataUpdated: () {
            refreshData();
          },
        );
        _syncWithFirebase();
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> addTransaction(
    int amount,
    String note,
    String type,
    String category,
  ) async {
    await DatabaseHelper.instance.addTransaction(amount, note, type, category);
    await refreshData();
    _syncWithFirebase();
  }

  Future<void> deleteTransactionManual(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await refreshData();
    _syncWithFirebase();
  }

  Future<void> updateTransactionManual(int id, int amount, String note) async {
    await DatabaseHelper.instance.updateTransaction(id, amount, note);
    await refreshData();
    _syncWithFirebase();
  }

  Future<void> addMessage(String text, bool isAi, {String? receiptData}) async {
    await DatabaseHelper.instance.insertMessage(
      text,
      isAi,
      receiptData: receiptData,
    );
    await refreshData();
    _syncWithFirebase();
  }

  Future<void> addQueryResultMessage({
    required String aiSummary,
    required RawQueryResult queryResult,
    required String vizType,
    required String originalQuestion,
  }) async {
    await DatabaseHelper.instance.insertMessage(aiSummary, true);
    chatHistory.add({
      'text': aiSummary,
      'isAi': 1,
      'queryResult': queryResult,
      'vizType': vizType,
      'originalQuestion': originalQuestion,
    });
    await _syncPendingCount();
    notifyListeners();
    _syncWithFirebase();
  }

  Future<List<PendingRequest>> getAllPending() async {
    return PendingRequestHelper.instance.getAllPending();
  }

  Future<void> completePending(int pendingId) async {
    await PendingRequestHelper.instance.markDone(pendingId);
    if (activeResolvingPending?.id == pendingId) activeResolvingPending = null;
    if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await _syncPendingCount();
    notifyListeners();
    _syncWithFirebase();
  }

  Future<void> cancelPending(int pendingId) async {
    await PendingRequestHelper.instance.cancelPending(pendingId);
    if (activeResolvingPending?.id == pendingId) activeResolvingPending = null;
    if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await _syncPendingCount();
    notifyListeners();
    _syncWithFirebase();
  }

  void setActiveResolvingPending(PendingRequest? pending) {
    activeResolvingPending = pending;
    notifyListeners();
  }

  void setWaitingDirectReply(bool value) {
    isWaitingDirectReply = value;
    notifyListeners();
  }

  void consumeDirectReply() {
    isWaitingDirectReply = false;
  }

  void triggerFollowUp(PendingRequest pending) {
    pendingToFollowUp = pending;
    activeResolvingPending = pending;
    notifyListeners();
  }

  void consumeFollowUp() {
    pendingToFollowUp = null;
  }

  Future<void> savePendingRequestNew({
    required String originalInput,
    String? nama,
    int? nominal,
    int quantity = 1,
    required String aiQuestion,
    required String reason,
    String category = 'Other',
    String type = 'OUT',
    List<String> missingFields = const [],
    Map<String, dynamic> partialData = const {},
  }) async {
    await PendingRequestHelper.instance.savePending(
      originalInput: originalInput,
      nama: nama,
      nominal: nominal,
      quantity: quantity,
      aiQuestion: aiQuestion,
      reason: reason,
      category: category,
      type: type,
      missingFields: missingFields,
      partialData: partialData,
    );
    await _syncPendingCount();
    notifyListeners();
    _syncWithFirebase();
  }

  Future<void> updatePendingState(
    int id,
    String? nama,
    int? nominal,
    String missingFieldsJson,
    String aiQuestion,
  ) async {
    final db = await DatabaseHelper.instance.database;
    Map<String, dynamic> data = {
      'missing_fields': missingFieldsJson,
      'ai_question': aiQuestion,
      'sync_status': 'pending_update',
    };
    if (nama != null && nama.isNotEmpty) data['nama'] = nama;
    if (nominal != null && nominal > 0) data['nominal'] = nominal;

    await db.update('pending_requests', data, where: 'id = ?', whereArgs: [id]);
    await _syncPendingCount();
    notifyListeners();
    _syncWithFirebase();
  }

  Future<RawQueryResult> executeQuery(String validatedSql) {
    return DatabaseHelper.instance.rawSelect(validatedSql);
  }

  void setAiThinking(bool value) {
    isAiThinking = value;
    notifyListeners();
  }

  Future<void> clearAll() async {
    await DatabaseHelper.instance.clearAllData();
    activeResolvingPending = null;
    pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await refreshData();
    _syncWithFirebase();
  }
}
