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
      debugPrint(
        "[FinanceProvider] _syncPendingCount: Sukses (Count: $pendingCount)",
      );
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di _syncPendingCount: $e");
    }
  }

  Future<void> refreshData() async {
    try {
      debugPrint("[FinanceProvider] refreshData: Memulai refresh data...");
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

      debugPrint(
        "[FinanceProvider] refreshData: Sukses (In=$totalIn, Out=$totalOut, Pending=$pendingCount)",
      );
      notifyListeners();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di refreshData: $e");
      // Tidak di-rethrow agar UI tidak langsung crash, cukup log error.
    }
  }

  Future<void> addTransaction(
    int amount,
    String note,
    String type,
    String category,
  ) async {
    try {
      debugPrint(
        "[FinanceProvider] addTransaction: Menyimpan transaksi (Note: $note, Amt: $amount, Type: $type)",
      );
      await DatabaseHelper.instance.addTransaction(
        amount,
        note,
        type,
        category,
      );

      // AUTO REFRESH: Memastikan histori UI langsung sinkron setelah data masuk
      await refreshData();
      debugPrint(
        "[FinanceProvider] addTransaction: Sukses menyimpan dan merefresh UI",
      );
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di addTransaction: $e");
      rethrow;
    }
  }

  Future<void> addMessage(String text, bool isAi) async {
    try {
      debugPrint("[FinanceProvider] addMessage: isAi=$isAi, Text=$text");
      await DatabaseHelper.instance.insertMessage(text, isAi);
      await refreshData();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di addMessage: $e");
      rethrow;
    }
  }

  Future<void> addQueryResultMessage({
    required String aiSummary,
    required RawQueryResult queryResult,
    required String vizType,
    required String originalQuestion,
  }) async {
    try {
      debugPrint(
        "[FinanceProvider] addQueryResultMessage: Menyimpan hasil query",
      );
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
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di addQueryResultMessage: $e");
      rethrow;
    }
  }

  Future<void> savePendingRequest({
    required String originalInput,
    required List<String> missingFields,
    required Map<String, dynamic> partialData,
    required String aiQuestion,
    required String reason,
  }) async {
    try {
      debugPrint("[FinanceProvider] savePendingRequest: $originalInput");
      await PendingRequestHelper.instance.savePending(
        originalInput: originalInput,
        missingFields: missingFields,
        partialData: partialData,
        aiQuestion: aiQuestion,
        reason: reason,
      );
      await _syncPendingCount();
      notifyListeners();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di savePendingRequest: $e");
      rethrow;
    }
  }

  Future<List<PendingRequest>> getAllPending() async {
    debugPrint("[FinanceProvider] getAllPending: Memanggil data pending");
    return PendingRequestHelper.instance.getAllPending();
  }

  Future<PendingRequest?> getOldestPending() async {
    debugPrint("[FinanceProvider] getOldestPending: Memanggil data tertua");
    return PendingRequestHelper.instance.getOldestPending();
  }

  Future<void> completePending(int pendingId) async {
    try {
      debugPrint(
        "[FinanceProvider] completePending: Menyelesaikan pending ID $pendingId",
      );
      await PendingRequestHelper.instance.markDone(pendingId);
      if (activeResolvingPending?.id == pendingId)
        activeResolvingPending = null;
      if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
      isWaitingDirectReply = false;
      await _syncPendingCount();
      notifyListeners();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di completePending: $e");
      rethrow;
    }
  }

  Future<void> cancelPending(int pendingId) async {
    try {
      debugPrint(
        "[FinanceProvider] cancelPending: Membatalkan pending ID $pendingId",
      );
      await PendingRequestHelper.instance.cancelPending(pendingId);
      if (activeResolvingPending?.id == pendingId)
        activeResolvingPending = null;
      if (pendingToFollowUp?.id == pendingId) pendingToFollowUp = null;
      isWaitingDirectReply = false;
      await _syncPendingCount();
      notifyListeners();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di cancelPending: $e");
      rethrow;
    }
  }

  void setActiveResolvingPending(PendingRequest? pending) {
    debugPrint(
      "[FinanceProvider] setActiveResolvingPending: ${pending?.originalInput}",
    );
    activeResolvingPending = pending;
    notifyListeners();
  }

  void setWaitingDirectReply(bool value) {
    debugPrint("[FinanceProvider] setWaitingDirectReply: $value");
    isWaitingDirectReply = value;
    notifyListeners();
  }

  void consumeDirectReply() {
    debugPrint(
      "[FinanceProvider] consumeDirectReply: Reset state direct reply",
    );
    isWaitingDirectReply = false;
  }

  void triggerFollowUp(PendingRequest pending) {
    debugPrint("[FinanceProvider] triggerFollowUp: ID ${pending.id}");
    pendingToFollowUp = pending;
    activeResolvingPending = pending;
    notifyListeners();
  }

  void consumeFollowUp() {
    debugPrint("[FinanceProvider] consumeFollowUp: Reset state follow up");
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
    try {
      debugPrint(
        "[FinanceProvider] savePendingRequestNew: Nama=$nama, Nominal=$nominal",
      );
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
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di savePendingRequestNew: $e");
      rethrow;
    }
  }

  Future<RawQueryResult> executeQuery(String validatedSql) {
    debugPrint("[FinanceProvider] executeQuery: $validatedSql");
    return DatabaseHelper.instance.rawSelect(validatedSql);
  }

  void setAiThinking(bool value) {
    isAiThinking = value;
    notifyListeners();
  }

  Future<void> clearAll() async {
    try {
      debugPrint("[FinanceProvider] clearAll: Mengosongkan database");
      await DatabaseHelper.instance.clearAllData();
      activeResolvingPending = null;
      pendingToFollowUp = null;
      isWaitingDirectReply = false;
      await refreshData();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di clearAll: $e");
      rethrow;
    }
  }

  Future<void> deleteTx(int id) async {
    try {
      debugPrint("[FinanceProvider] deleteTx: Menghapus TX ID $id");
      await DatabaseHelper.instance.deleteTransaction(id);
      await refreshData();
    } catch (e) {
      debugPrint("[FinanceProvider] ERROR di deleteTx: $e");
      rethrow;
    }
  }
}
