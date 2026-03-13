import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/pending_request_helper.dart';

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
  }

  // UPDATE FUNGSI INI
  Future<void> addMessage(String text, bool isAi, {String? receiptData}) async {
    await DatabaseHelper.instance.insertMessage(
      text,
      isAi,
      receiptData: receiptData,
    );
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
  }

  Future<List<PendingRequest>> getAllPending() async {
    return PendingRequestHelper.instance.getAllPending();
  }

  Future<PendingRequest?> getOldestPending() async {
    return PendingRequestHelper.instance.getOldestPending();
  }

  Future<void> completePending(int pendingId) async {
    await PendingRequestHelper.instance.markDone(pendingId);
    if (activeResolvingPending?.id == pendingId) activeResolvingPending = null;
    if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await _syncPendingCount();
    notifyListeners();
  }

  Future<void> cancelPending(int pendingId) async {
    await PendingRequestHelper.instance.cancelPending(pendingId);
    if (activeResolvingPending?.id == pendingId) activeResolvingPending = null;
    if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
    isWaitingDirectReply = false;
    await _syncPendingCount();
    notifyListeners();
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
  }

  Future<void> deleteTx(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await refreshData();
  }
}
