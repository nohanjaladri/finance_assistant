/// finance_provider.dart (v2)
/// State management utama — menggantikan Firebase dengan Supabase
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/pending_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/utils/query_validator.dart';

enum SyncStatus { synced, syncing, error }

class FinanceProvider extends ChangeNotifier {
  // ============================================================
  // STATE
  // ============================================================
  SupabaseService get _db => dbOverride ?? SupabaseService.instance;
  @visibleForTesting
  SupabaseService? dbOverride;

  // Transaksi & summary
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> tunaiTransactions = [];
  List<TransactionModel> nonTunaiTransactions = [];
  int totalIn = 0;
  int totalOut = 0;
  int tunaiIn = 0;
  int nonTunaiIn = 0;
  int tunaiOut = 0;
  int nonTunaiOut = 0;

  // Chat
  // Chat
  List<Map<String, dynamic>> tunaiChatHistory = [];
  List<Map<String, dynamic>> nonTunaiChatHistory = [];
  List<Map<String, dynamic>> sharedChatHistory = [];
  String _activeChatType = 'tunai';

  String get activeChatType => _activeChatType;

  void setActiveChatType(String type) {
    if (_activeChatType != type) {
      _activeChatType = type;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get chatHistory {
    if (isSharingConnected && _activeChatType == 'sharing') {
      return sharedChatHistory;
    } else if (_activeChatType == 'non_tunai') {
      return nonTunaiChatHistory;
    } else {
      return tunaiChatHistory;
    }
  }

  // Debug Console Logs
  final List<String> debugLogs = [];

  void addDebugLog(String log) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    debugLogs.add("[$timestamp] $log");
    notifyListeners();
  }

  void clearDebugLogs() {
    debugLogs.clear();
    notifyListeners();
  }

  // AI state
  bool isAiThinking = false;
  int pendingCount = 0;

  // Sharing / Room
  bool isSharingEnabled = false; // toggle dari settings
  bool isSharingConnected = false; // sudah join room
  RoomModel? activeRoom;
  List<TransactionModel> sharedTransactions = [];
  int sharedTotalIn = 0;
  int sharedTotalOut = 0;

  // Profile info
  String myRoomCode = '';

  // Sync
  SyncStatus syncStatus = SyncStatus.synced;

  // Context for AI
  Map<String, dynamic> financialSummary = {};

  // ============================================================
  // INIT & REFRESH
  // ============================================================

  Future<void> initialize() async {
    await _loadSharingPrefs();
    await refreshAll();
  }

  Future<void> refreshAll() async {
    try {
      syncStatus = SyncStatus.syncing;
      notifyListeners();

      await Future.wait([
        _loadPersonalTransactions(),
        _loadChatMessages(),
        _loadPendingCount(),
        _loadProfile(),
        _loadFinancialSummary(),
      ]);

      if (isSharingConnected && activeRoom != null) {
        await _loadSharedTransactions();
      }

      syncStatus = SyncStatus.synced;
    } catch (e) {
      debugPrint('refreshAll error: $e');
      syncStatus = SyncStatus.error;
    }
    notifyListeners();
  }

  Future<void> _loadPersonalTransactions() async {
    final txs = await _db.getPersonalTransactions(limit: 100);
    allTransactions = txs;
    tunaiTransactions = txs
        .where((t) => t.paymentMethod == PaymentMethod.tunai)
        .toList();
    nonTunaiTransactions = txs
        .where((t) => t.paymentMethod == PaymentMethod.nonTunai)
        .toList();

    int tempIn = 0, tempOut = 0, tempTunai = 0, tempNonTunai = 0;
    int tempTunaiIn = 0, tempNonTunaiIn = 0;
    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        tempIn += tx.amount;
        if (tx.paymentMethod == PaymentMethod.tunai) {
          tempTunaiIn += tx.amount;
        } else {
          tempNonTunaiIn += tx.amount;
        }
      } else {
        tempOut += tx.amount;
        if (tx.paymentMethod == PaymentMethod.tunai) {
          tempTunai += tx.amount;
        } else {
          tempNonTunai += tx.amount;
        }
      }
    }
    totalIn = tempIn;
    totalOut = tempOut;
    tunaiIn = tempTunaiIn;
    nonTunaiIn = tempNonTunaiIn;
    tunaiOut = tempTunai;
    nonTunaiOut = tempNonTunai;
  }

  Future<void> _loadSharedTransactions() async {
    if (activeRoom == null) return;
    final txs = await _db.getSharedTransactions(
      roomId: activeRoom!.id,
      limit: 100,
    );
    sharedTransactions = txs;
    int tempIn = 0, tempOut = 0;
    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        tempIn += tx.amount;
      } else {
        tempOut += tx.amount;
      }
    }
    sharedTotalIn = tempIn;
    sharedTotalOut = tempOut;
  }

  Future<void> _loadChatMessages() async {
    final tunaiMsgs = await _db.getChatMessages(chatType: 'tunai', limit: 30);
    tunaiChatHistory = tunaiMsgs.reversed.toList();

    final nonTunaiMsgs = await _db.getChatMessages(chatType: 'non_tunai', limit: 30);
    nonTunaiChatHistory = nonTunaiMsgs.reversed.toList();

    if (isSharingConnected && activeRoom != null) {
      final sharedMsgs = await _db.getChatMessages(roomId: activeRoom!.id, limit: 30);
      sharedChatHistory = sharedMsgs.reversed.toList();
    } else {
      sharedChatHistory = [];
    }
  }

  Future<void> _loadPendingCount() async {
    pendingCount = await _db.getPendingCount();
  }

  Future<void> _loadProfile() async {
    myRoomCode = await _db.getMyRoomCode();
  }

  Future<void> _loadFinancialSummary() async {
    financialSummary = await _db.getFinancialSummary();
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Future<TransactionModel?> addTransaction({
    required int amount,
    required String note,
    required String type,
    required String category,
    required PaymentMethod paymentMethod,
  }) async {
    final roomId = (isSharingConnected && _activeChatType == 'sharing') ? activeRoom?.id : null;
    final tx = await _db.addTransaction(
      amount: amount,
      note: note,
      type: type,
      category: category,
      paymentMethod: paymentMethod,
      roomId: roomId,
    );
    await refreshAll();
    return tx;
  }

  Future<bool> updateTransaction(
    int id, {
    int? amount,
    String? note,
    PaymentMethod? paymentMethod,
  }) async {
    final ok = await _db.updateTransaction(
      id,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
    );
    if (ok) await refreshAll();
    return ok;
  }

  Future<bool> updateTransactionItemManual({
    required int transactionId,
    required int itemId,
    required String note,
    required int amount,
    required int quantity,
  }) async {
    final okItem = await _db.updateTransactionItem(
      itemId,
      note: note,
      amount: amount,
      quantity: quantity,
    );
    if (!okItem) return false;

    final txIndex = allTransactions.indexWhere((t) => t.id == transactionId);
    if (txIndex != -1) {
      final tx = allTransactions[txIndex];
      final updatedItems = tx.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(note: note, amount: amount, quantity: quantity);
        }
        return item;
      }).toList();

      final newTotal = updatedItems.fold<int>(0, (sum, it) => sum + (it.amount * it.quantity));
      final newNoteSummary = updatedItems.map((it) => "${it.note} (x${it.quantity})").join(", ");

      await _db.updateTransaction(
        transactionId,
        amount: newTotal,
        note: newNoteSummary,
      );
    }
    
    await refreshAll();
    return true;
  }


  Future<bool> deleteTransaction(int id) async {
    final ok = await _db.deleteTransaction(id);
    if (ok) await refreshAll();
    return ok;
  }

  // ============================================================
  // CHAT MESSAGES
  // ============================================================

  Future<void> addMessage(
    String text,
    bool isAi, {
    Map<String, dynamic>? receiptData,
    Map<String, dynamic>? queryResult,
    String? vizType,
    List<String>? logs,
  }) async {
    debugPrint('FinanceProvider.addMessage: text=$text, isAi=$isAi, activeChatType=$_activeChatType');
    
    final roomId = (isSharingConnected && _activeChatType == 'sharing') ? activeRoom?.id : null;
    final chatType = roomId != null ? null : _activeChatType;

    await _db.addChatMessage(
      text: text,
      isAi: isAi,
      receiptData: receiptData,
      queryResult: queryResult,
      vizType: vizType,
      roomId: roomId,
      chatType: chatType,
    );

    // Tambahkan ke local state langsung (tanpa reload penuh)
    final msgMap = {
      'text': text,
      'is_ai': isAi,
      'receipt_data': receiptData,
      'query_result': queryResult,
      'viz_type': vizType,
      'logs': logs,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (roomId != null) {
      sharedChatHistory.add(msgMap);
    } else if (chatType == 'non_tunai') {
      nonTunaiChatHistory.add(msgMap);
    } else {
      tunaiChatHistory.add(msgMap);
    }

    notifyListeners();
  }

  void setAiThinking(bool value) {
    isAiThinking = value;
    notifyListeners();
  }

  // ============================================================
  // PENDING REQUESTS
  // ============================================================

  Future<List<PendingModel>> getAllPending() async {
    return await _db.getPendingRequests();
  }

  Future<PendingModel?> savePending({
    required String originalInput,
    String? nama,
    int? nominal,
    int quantity = 1,
    required String aiQuestion,
    required String reason,
    String category = 'Other',
    String type = 'OUT',
    PaymentMethod paymentMethod = PaymentMethod.tunai,
    List<String> missingFields = const [],
    Map<String, dynamic> partialData = const {},
  }) async {
    final pending = PendingModel(
      userId: _db.currentUserId,
      originalInput: originalInput,
      nama: nama,
      nominal: nominal,
      quantity: quantity,
      aiQuestion: aiQuestion,
      reason: reason,
      category: category,
      type: TransactionTypeExt.fromString(type),
      paymentMethod: paymentMethod,
      missingFields: missingFields,
      partialData: partialData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final saved = await _db.addPendingRequest(pending);
    await _loadPendingCount();
    notifyListeners();
    return saved;
  }

  Future<bool> updatePending(
    int id, {
    String? nama,
    int? nominal,
    List<String>? missingFields,
    String? aiQuestion,
    String? status,
  }) async {
    final ok = await _db.updatePendingRequest(
      id,
      nama: nama,
      nominal: nominal,
      missingFields: missingFields,
      aiQuestion: aiQuestion,
      status: status,
    );
    await _loadPendingCount();
    notifyListeners();
    return ok;
  }

  Future<bool> deletePending(int id) async {
    final ok = await _db.deletePendingRequest(id);
    await _loadPendingCount();
    notifyListeners();
    return ok;
  }

  Future<bool> completePending(int id) async {
    return deletePending(id);
  }

  Future<bool> cancelPending(int id) async {
    return deletePending(id);
  }

  // ============================================================
  // QUERY (AI Analytics)
  // ============================================================

  Future<List<Map<String, dynamic>>> executeQuery(String sql) async {
    return await _db.rawQuery(sql);
  }

  QueryValidationResult validateQuery(String sql) {
    return QueryValidator.validate(sql);
  }

  // ============================================================
  // SHARING / ROOM
  // ============================================================

  Future<void> _loadSharingPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isSharingEnabled = prefs.getBool('sharing_enabled') ?? false;
    final savedRoomId = prefs.getString('active_room_id');
    if (savedRoomId != null && isSharingEnabled) {
      final room = await _db.getMyRoom();
      if (room != null && room.id == savedRoomId) {
        activeRoom = room;
        isSharingConnected = true;
        
        _db.listenToSharedTransactions(
          roomId: room.id,
          onUpdate: () => refreshAll(),
        );
      }
    }
  }

  Future<void> setSharingEnabled(bool enabled) async {
    isSharingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sharing_enabled', enabled);

    if (!enabled) {
      await leaveCurrentRoom();
    }
    notifyListeners();
  }

  Future<RoomModel?> joinRoom(String code) async {
    final room = await _db.joinRoomByCode(code);
    if (room != null) {
      activeRoom = room;
      isSharingConnected = true;
      isSharingEnabled = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sharing_enabled', true);
      await prefs.setString('active_room_id', room.id);

      // Start realtime listener
      _db.listenToSharedTransactions(
        roomId: room.id,
        onUpdate: () => refreshAll(),
      );

      await _loadSharedTransactions();
      notifyListeners();
    }
    return room;
  }

  Future<void> leaveCurrentRoom() async {
    if (activeRoom != null) {
      await _db.leaveRoom(activeRoom!.id);
    }
    activeRoom = null;
    isSharingConnected = false;
    sharedTransactions = [];
    _db.stopListeningToShared();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_room_id');

    notifyListeners();
  }

  // ============================================================
  // DATA MANAGEMENT
  // ============================================================

  Future<void> wipeAllData() async {
    final ok = await _db.wipePersonalData();
    if (ok) {
      allTransactions = [];
      tunaiTransactions = [];
      nonTunaiTransactions = [];
      tunaiChatHistory = [];
      nonTunaiChatHistory = [];
      sharedChatHistory = [];
      totalIn = 0;
      totalOut = 0;
      pendingCount = 0;
      notifyListeners();
    }
  }

  // === COMPATIBILITY METHODS FOR WIDGETS ===

  void triggerFollowUp(PendingModel pending) {
    // Inject follow-up question to chat
    addMessage(pending.aiQuestion, true);
  }

  Future<bool> updateTransactionManual(int id, int amount, String note) async {
    final ok = await updateTransaction(id, amount: amount, note: note);
    return ok;
  }

  Future<bool> deleteTransactionManual(int id) async {
    final ok = await deleteTransaction(id);
    return ok;
  }

  List<TransactionModel> get history => allTransactions;
}
