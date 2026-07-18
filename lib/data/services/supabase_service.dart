/// supabase_service.dart
/// Service utama untuk semua operasi Supabase:
/// Auth, Database CRUD, dan Realtime subscriptions
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/pending_model.dart';
import '../models/room_model.dart';
import '../../core/constants/app_config.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  String get currentUserId => currentUser?.id ?? '';
  bool get isLoggedIn => currentUser != null;

  // ========================================================
  // AUTH
  // ========================================================

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final email = currentUser?.email;
    if (email != null) {
      await _client.auth.resend(type: OtpType.signup, email: email);
    }
  }

  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  Future<void> refreshSession() async {
    await _client.auth.refreshSession();
  }

  // ========================================================
  // PROFILE
  // ========================================================

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await _client
          .schema(AppConfig.schema)
          .from('profiles')
          .select()
          .eq('id', currentUserId)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  Future<String> getMyRoomCode() async {
    try {
      final profile = await getProfile();
      return profile?['room_code'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  // ========================================================
  // TRANSACTIONS - PERSONAL
  // ========================================================

  Future<List<TransactionModel>> getPersonalTransactions({
    PaymentMethod? paymentMethod,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .schema(AppConfig.schema)
          .from('transactions')
          .select()
          .eq('user_id', currentUserId)
          .isFilter('room_id', null);

      if (paymentMethod != null) {
        query = query.eq('payment_method', paymentMethod.value);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return data.map((j) => TransactionModel.fromJson(j)).toList();
    } catch (e) {
      debugPrint('getPersonalTransactions error: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getSharedTransactions({
    required String roomId,
    PaymentMethod? paymentMethod,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .schema(AppConfig.schema)
          .from('transactions')
          .select()
          .eq('room_id', roomId);

      if (paymentMethod != null) {
        query = query.eq('payment_method', paymentMethod.value);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return data.map((j) => TransactionModel.fromJson(j)).toList();
    } catch (e) {
      debugPrint('getSharedTransactions error: $e');
      return [];
    }
  }

  Future<TransactionModel?> addTransaction({
    required int amount,
    required String note,
    required String type,
    required String category,
    required PaymentMethod paymentMethod,
    String? roomId,
  }) async {
    debugPrint(
      'SupabaseService.addTransaction called: amount=$amount, note=$note, type=$type, category=$category, paymentMethod=${paymentMethod.value}, roomId=$roomId',
    );
    try {
      final data = await _client
          .schema(AppConfig.schema)
          .from('transactions')
          .insert({
            'user_id': currentUserId,
            'amount': amount,
            'note': note,
            'type': type.toUpperCase(),
            'category': category,
            'payment_method': paymentMethod.value,
            'room_id': roomId,
          })
          .select()
          .single();
      debugPrint('SupabaseService.addTransaction success: ${jsonEncode(data)}');
      return TransactionModel.fromJson(data);
    } catch (e, stack) {
      debugPrint('SupabaseService.addTransaction error: $e\n$stack');
      return null;
    }
  }

  Future<bool> updateTransaction(
    int id, {
    int? amount,
    String? note,
    PaymentMethod? paymentMethod,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (amount != null) updates['amount'] = amount;
      if (note != null) updates['note'] = note;
      if (paymentMethod != null) {
        updates['payment_method'] = paymentMethod.value;
      }

      await _client
          .schema(AppConfig.schema)
          .from('transactions')
          .update(updates)
          .eq('id', id)
          .eq('user_id', currentUserId);
      return true;
    } catch (e) {
      debugPrint('updateTransaction error: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _client
          .schema(AppConfig.schema)
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId);
      return true;
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
      return false;
    }
  }

  /// Eksekusi query SQL langsung (HANYA SELECT - sudah divalidasi oleh QueryValidator)
  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
    try {
      // Mengarahkan query ke rpc function pada schema kustom jika didefinisikan
      final res = await _client.rpc('exec_select', params: {'query': sql});
      if (res is List) return res.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('rawQuery error: $e');
      return [];
    }
  }

  // ========================================================
  // PENDING REQUESTS
  // ========================================================

  Future<List<PendingModel>> getPendingRequests({String? roomId}) async {
    try {
      var query = _client
          .schema(AppConfig.schema)
          .from('pending_requests')
          .select()
          .eq('user_id', currentUserId)
          .eq('status', 'pending');

      if (roomId != null) {
        query = query.eq('room_id', roomId);
      } else {
        query = query.isFilter('room_id', null);
      }

      final data = await query.order('created_at', ascending: true);
      return data.map((j) => PendingModel.fromJson(j)).toList();
    } catch (e) {
      debugPrint('getPendingRequests error: $e');
      return [];
    }
  }

  Future<PendingModel?> addPendingRequest(PendingModel pending) async {
    try {
      final data = await _client
          .schema(AppConfig.schema)
          .from('pending_requests')
          .insert(pending.toJson())
          .select()
          .single();
      return PendingModel.fromJson(data);
    } catch (e) {
      debugPrint('addPendingRequest error: $e');
      return null;
    }
  }

  Future<bool> updatePendingRequest(
    int id, {
    String? nama,
    int? nominal,
    List<String>? missingFields,
    String? aiQuestion,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (nama != null) updates['nama'] = nama;
      if (nominal != null) updates['nominal'] = nominal;
      if (missingFields != null) updates['missing_fields'] = missingFields;
      if (aiQuestion != null) updates['ai_question'] = aiQuestion;
      if (status != null) updates['status'] = status;

      await _client
          .schema(AppConfig.schema)
          .from('pending_requests')
          .update(updates)
          .eq('id', id)
          .eq('user_id', currentUserId);
      return true;
    } catch (e) {
      debugPrint('updatePendingRequest error: $e');
      return false;
    }
  }

  Future<bool> deletePendingRequest(int id) async {
    debugPrint('SupabaseService.deletePendingRequest called: id=$id');
    try {
      await _client
          .schema(AppConfig.schema)
          .from('pending_requests')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId);
      debugPrint('SupabaseService.deletePendingRequest success');
      return true;
    } catch (e, stack) {
      debugPrint('SupabaseService.deletePendingRequest error: $e\n$stack');
      return false;
    }
  }

  Future<int> getPendingCount({String? roomId}) async {
    try {
      final count = await _client
          .schema(AppConfig.schema)
          .from('pending_requests')
          .select()
          .eq('user_id', currentUserId)
          .eq('status', 'pending')
          .count(CountOption.exact);
      return count.count;
    } catch (e) {
      return 0;
    }
  }

  // ========================================================
  // CHAT MESSAGES
  // ========================================================

  Future<List<Map<String, dynamic>>> getChatMessages({
    String? roomId,
    String? chatType,
    int limit = 30,
  }) async {
    debugPrint(
      'SupabaseService.getChatMessages called: roomId=$roomId, chatType=$chatType',
    );
    try {
      var query = _client
          .schema(AppConfig.schema)
          .from('chat_messages')
          .select()
          .eq('user_id', currentUserId);

      if (roomId != null) {
        query = query.eq('room_id', roomId);
      } else {
        query = query.isFilter('room_id', null);
        if (chatType != null) {
          query = query.eq('chat_type', chatType);
        }
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('getChatMessages error: $e');
      return [];
    }
  }

  Future<void> addChatMessage({
    required String text,
    required bool isAi,
    String? confirmMsg,
    String? confirmCmd,
    Map<String, dynamic>? receiptData,
    Map<String, dynamic>? queryResult,
    String? vizType,
    String? roomId,
    String? chatType,
  }) async {
    debugPrint(
      'SupabaseService.addChatMessage called: text=$text, isAi=$isAi, confirmMsg=$confirmMsg, confirmCmd=$confirmCmd, hasReceipt=${receiptData != null}, hasQueryResult=${queryResult != null}, vizType=$vizType, roomId=$roomId, chatType=$chatType',
    );
    try {
      await _client.schema(AppConfig.schema).from('chat_messages').insert({
        'user_id': currentUserId,
        'text': text,
        'is_ai': isAi,
        'confirm_msg': confirmMsg,
        'confirm_cmd': confirmCmd,
        'receipt_data': receiptData,
        'query_result': queryResult,
        'viz_type': vizType,
        'room_id': roomId,
        'chat_type': ?chatType,
      });
      debugPrint('SupabaseService.addChatMessage success');
    } catch (e, stack) {
      debugPrint('SupabaseService.addChatMessage error: $e\n$stack');
    }
  }

  // ========================================================
  // ROOM (SHARING)
  // ========================================================

  Future<RoomModel?> getMyRoom() async {
    try {
      final roomCode = await getMyRoomCode();
      if (roomCode.isEmpty) return null;

      final data = await _client
          .schema(AppConfig.schema)
          .from('rooms')
          .select('*, room_members(*, profiles(email))')
          .eq('room_code', roomCode)
          .maybeSingle();

      if (data == null) return null;
      return RoomModel.fromJson(data);
    } catch (e) {
      debugPrint('getMyRoom error: $e');
      return null;
    }
  }

  Future<RoomModel?> joinRoomByCode(String code) async {
    try {
      // Cari room berdasarkan kode
      final roomData = await _client
          .schema(AppConfig.schema)
          .from('rooms')
          .select()
          .eq('room_code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (roomData == null) return null;

      final roomId = roomData['id'] as String;

      // Cek apakah sudah jadi anggota
      final existing = await _client
          .schema(AppConfig.schema)
          .from('room_members')
          .select()
          .eq('room_id', roomId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing == null) {
        // Tambahkan sebagai anggota
        await _client.schema(AppConfig.schema).from('room_members').insert({
          'room_id': roomId,
          'user_id': currentUserId,
          'role': 'member',
        });
      }

      return RoomModel.fromJson(roomData);
    } catch (e) {
      debugPrint('joinRoomByCode error: $e');
      return null;
    }
  }

  Future<bool> leaveRoom(String roomId) async {
    try {
      await _client
          .schema(AppConfig.schema)
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', currentUserId);
      return true;
    } catch (e) {
      debugPrint('leaveRoom error: $e');
      return false;
    }
  }

  Future<List<RoomModel>> getJoinedRooms() async {
    try {
      final memberData = await _client
          .schema(AppConfig.schema)
          .from('room_members')
          .select('room_id, rooms(*)')
          .eq('user_id', currentUserId);

      return (memberData as List)
          .map((m) => RoomModel.fromJson(m['rooms'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getJoinedRooms error: $e');
      return [];
    }
  }

  Future<bool> wipePersonalData() async {
    try {
      await _client
          .schema(AppConfig.schema)
          .from('transactions')
          .delete()
          .eq('user_id', currentUserId)
          .isFilter('room_id', null);
      await _client
          .schema(AppConfig.schema)
          .from('chat_messages')
          .delete()
          .eq('user_id', currentUserId);
      await _client
          .schema(AppConfig.schema)
          .from('pending_requests')
          .delete()
          .eq('user_id', currentUserId);
      return true;
    } catch (e) {
      debugPrint('wipePersonalData error: $e');
      return false;
    }
  }

  // ========================================================
  // REALTIME SUBSCRIPTIONS
  // ========================================================

  RealtimeChannel? _sharedTxChannel;

  void listenToSharedTransactions({
    required String roomId,
    required VoidCallback onUpdate,
  }) {
    _sharedTxChannel?.unsubscribe();
    _sharedTxChannel = _client
        .channel('shared_tx_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: AppConfig.schema,
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  void stopListeningToShared() {
    _sharedTxChannel?.unsubscribe();
    _sharedTxChannel = null;
  }

  // ========================================================
  // SUMMARY & ANALYTICS (untuk AI context)
  // ========================================================

  /// Ambil ringkasan keuangan user untuk konteks AI
  Future<Map<String, dynamic>> getFinancialSummary({
    String? roomId,
    int daysBack = 30,
  }) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: daysBack))
          .toIso8601String();

      var query = _client
          .schema(AppConfig.schema)
          .from('transactions')
          .select()
          .eq('user_id', currentUserId)
          .gte('created_at', since);

      if (roomId != null) {
        query = query.eq('room_id', roomId);
      } else {
        query = query.isFilter('room_id', null);
      }

      final txs = await query;
      int totalIn = 0, totalOut = 0;
      int tunaiOut = 0, nonTunaiOut = 0;

      for (final tx in txs) {
        final amt = tx['amount'] as int? ?? 0;
        final type = tx['type'] as String? ?? 'OUT';
        final pm = tx['payment_method'] as String? ?? 'tunai';

        if (type == 'IN') {
          totalIn += amt;
        } else {
          totalOut += amt;
          if (pm == 'tunai') {
            tunaiOut += amt;
          } else {
            nonTunaiOut += amt;
          }
        }
      }

      return {
        'period_days': daysBack,
        'total_in': totalIn,
        'total_out': totalOut,
        'saldo': totalIn - totalOut,
        'tunai_out': tunaiOut,
        'non_tunai_out': nonTunaiOut,
        'transaction_count': txs.length,
      };
    } catch (e) {
      debugPrint('getFinancialSummary error: $e');
      return {};
    }
  }
}

extension UserExt on User {
  String get uid => id;
}
