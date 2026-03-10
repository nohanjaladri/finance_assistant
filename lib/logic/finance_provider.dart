import 'package:flutter/material.dart';
import 'database_helper.dart';

class FinanceProvider extends ChangeNotifier {
  int totalIn = 0;
  int totalOut = 0;
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> chatHistory = [];
  bool isAiThinking = false;

  Future<void> refreshData() async {
    final txs = await DatabaseHelper.instance.getAllTransactions();
    final msgs = await DatabaseHelper.instance.getMessages(limit: 20);

    int tempIn = 0;
    int tempOut = 0;

    for (var tx in txs) {
      final amt = tx['amount'] as int;
      // Gunakan pembersihan string yang ekstra kuat
      final String type = tx['type'].toString().trim().toUpperCase();

      if (type == 'IN') {
        tempIn += amt;
      } else if (type == 'OUT') {
        tempOut += amt;
      }
    }

    totalIn = tempIn;
    totalOut = tempOut;
    history = List.from(txs);
    chatHistory = msgs.reversed.toList();

    debugPrint("PROVIDER_LOG: In($totalIn) Out($totalOut)");
    notifyListeners();
  }

  Future<void> addTransaction(
    int amount,
    String note,
    String type,
    String category,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('transactions', {
      'amount': amount,
      'note': note,
      'type': type.toUpperCase().trim(), // Tambah .trim()
      'category': category,
      'date': DateTime.now().toIso8601String(),
    });
    // LOG UNTUK DEBUGGING
    print(
      "DB_LOG: Berhasil simpan ke SQL dengan ID: $id | Amount: $amount | Type: $type",
    );
  }

  Future<void> addMessage(String text, bool isAi) async {
    await DatabaseHelper.instance.insertMessage(text, isAi);
    await refreshData();
  }

  void setAiThinking(bool value) {
    isAiThinking = value;
    notifyListeners();
  }

  Future<void> clearAll() async {
    await DatabaseHelper.instance.clearAllData();
    await refreshData();
  }

  Future<void> deleteTx(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await refreshData();
  }
}
