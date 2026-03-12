/// finance_provider.dart
/// Update: support AI agent architecture
/// - triggerFollowUp untuk bubble follow-up dari dialog
/// - isWaitingDirectReply untuk auto-resolve direct reply

import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pending_request_helper.dart';

class FinanceProvider extends ChangeNotifier {
  int totalIn = 0;
  int totalOut = 0;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> chatHistory = [];
  bool isAiThinking = false;

  int pendingCount = 0;
  PendingRequest? activeResolvingPending;

  /// True = AI baru tanya, menunggu direct reply (1 pesan berikutnya saja)
  bool isWaitingDirectReply = false;

  /// Trigger dari tombol "Lengkapi" di dialog → inject bubble follow-up ke chat
  PendingRequest? pendingToFollowUp;

  // ==========================================
  // HELPER
  // ==========================================

  Future<void> _syncPendingCount() async {
    pendingCount = await PendingRequestHelper.instance.countPending();
  }

  // ==========================================
  // REFRESH
  // ==========================================

  Future<void> refreshData() async {
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

    debugPrint("PROVIDER: In=$totalIn Out=$totalOut Pending=$pendingCount");
    notifyListeners();
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  Future<void> addTransaction(
    int amount,
    String note,
    String type,
    String category,
  ) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('transactions', {
      'amount': amount,
      'note': note,
      'type': type.toUpperCase().trim(),
      'category': category,
      'date': DateTime.now().toIso8601String(),
    });
    debugPrint("TX_INSERTED: $note | Rp $amount | $type | $category");
  }

  // ==========================================
  // MESSAGES
  // ==========================================

  Future<void> addMessage(String text, bool isAi) async {
    await DatabaseHelper.instance.insertMessage(text, isAi);
    await refreshData();
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
  }

  // ==========================================
  // PENDING
  // ==========================================

  Future<void> savePendingRequest({
    required String originalInput,
    required List<String> missingFields,
    required Map<String, dynamic> partialData,
    required String aiQuestion,
    required String reason,
  }) async {
    await PendingRequestHelper.instance.savePending(
      originalInput: originalInput,
      missingFields: missingFields,
      partialData: partialData,
      aiQuestion: aiQuestion,
      reason: reason,
    );
    await _syncPendingCount();
    notifyListeners();
    debugPrint("PENDING_SAVED: '$originalInput' | Count=$pendingCount");
  }

  Future<List<PendingRequest>> getAllPending() =>
      PendingRequestHelper.instance.getAllPending();

  Future<PendingRequest?> getOldestPending() =>
      PendingRequestHelper.instance.getOldestPending();

  Future<void> completePending(int pendingId) async {
    await PendingRequestHelper.instance.markDone(pendingId);
    if (activeResolvingPending?.id == pendingId) activeResolvingPending = null;
    if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await _syncPendingCount();
    notifyListeners();
    debugPrint("PENDING_DONE: ID=$pendingId | Count=$pendingCount");
  }

  Future<void> cancelPending(int pendingId) async {
    await PendingRequestHelper.instance.cancelPending(pendingId);
    if (activeResolvingPending?.id == pendingId) activeResolvingPending = null;
    if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await _syncPendingCount();
    notifyListeners();
    debugPrint("PENDING_CANCELLED: ID=$pendingId | Count=$pendingCount");
  }

  void setActiveResolvingPending(PendingRequest? pending) {
    activeResolvingPending = pending;
    notifyListeners();
  }

  void setWaitingDirectReply(bool value) {
    isWaitingDirectReply = value;
    notifyListeners();
  }

  /// Dipanggil di awal setiap pesan user — reset flag direct reply
  void consumeDirectReply() {
    isWaitingDirectReply = false;
  }

  /// Tombol "Lengkapi" dari dialog → inject bubble ke chat
  void triggerFollowUp(PendingRequest pending) {
    pendingToFollowUp = pending;
    activeResolvingPending = pending;
    notifyListeners();
  }

  /// Dipanggil setelah bubble ditampilkan
  void consumeFollowUp() {
    pendingToFollowUp = null;
    notifyListeners();
  }

  /// State untuk follow-up confirm bubble (Ya/Nanti)
  bool isWaitingFollowUpConfirm = false;
  List<PendingRequest> pendingFollowUpList = [];

  /// Set follow-up question bubble di chat
  void setPendingFollowUpQuestion(String message, List<PendingRequest> list) {
    pendingFollowUpList = list;
    isWaitingFollowUpConfirm = true;
    chatHistory.add({'text': message, 'isAi': 1, 'isFollowUp': true});
    notifyListeners();
  }

  void setWaitingFollowUpConfirm(bool value) {
    isWaitingFollowUpConfirm = value;
    notifyListeners();
  }

  /// savePendingRequest versi baru dengan field nama, nominal, quantity
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
    debugPrint(
      "PROVIDER: PendingNew saved nama=$nama nominal=$nominal Count=$pendingCount",
    );
  }

  // ==========================================
  // QUERY
  // ==========================================

  Future<RawQueryResult> executeQuery(String validatedSql) =>
      DatabaseHelper.instance.rawSelect(validatedSql);

  // ==========================================
  // MISC
  // ==========================================

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
  }

  Future<void> deleteTx(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await refreshData();
  }
}
