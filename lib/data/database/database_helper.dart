import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5, // UPGRADE VERSION
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        amount   INTEGER NOT NULL,
        note     TEXT NOT NULL,
        type     TEXT NOT NULL,
        category TEXT NOT NULL,
        date     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        text        TEXT NOT NULL,
        isAi        INTEGER NOT NULL,
        confirmMsg  TEXT,
        confirmCmd  TEXT,
        receiptData TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_requests (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        original_input TEXT    NOT NULL,
        nama           TEXT,
        nominal        INTEGER,
        quantity       INTEGER NOT NULL DEFAULT 1,
        input_datetime TEXT    NOT NULL,
        missing_fields TEXT    NOT NULL DEFAULT '[]',
        partial_data   TEXT    NOT NULL DEFAULT '{}',
        ai_question    TEXT    NOT NULL DEFAULT '',
        reason         TEXT    NOT NULL DEFAULT '',
        category       TEXT    NOT NULL DEFAULT 'Other',
        type           TEXT    NOT NULL DEFAULT 'OUT',
        created_at     TEXT    NOT NULL,
        status         TEXT    NOT NULL DEFAULT 'pending',
        follow_up_shown INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_requests (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          original_input TEXT    NOT NULL,
          nama           TEXT,
          nominal        INTEGER,
          quantity       INTEGER NOT NULL DEFAULT 1,
          input_datetime TEXT    NOT NULL,
          missing_fields TEXT    NOT NULL DEFAULT '[]',
          partial_data   TEXT    NOT NULL DEFAULT '{}',
          ai_question    TEXT    NOT NULL DEFAULT '',
          reason         TEXT    NOT NULL DEFAULT '',
          category       TEXT    NOT NULL DEFAULT 'Other',
          type           TEXT    NOT NULL DEFAULT 'OUT',
          created_at     TEXT    NOT NULL,
          status         TEXT    NOT NULL DEFAULT 'pending',
          follow_up_shown INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          "ALTER TABLE pending_requests ADD COLUMN reason TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {}
    }
    if (oldVersion < 4) {
      final cols = [
        "ALTER TABLE pending_requests ADD COLUMN nama TEXT",
        "ALTER TABLE pending_requests ADD COLUMN nominal INTEGER",
        "ALTER TABLE pending_requests ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1",
        "ALTER TABLE pending_requests ADD COLUMN input_datetime TEXT",
        "ALTER TABLE pending_requests ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'",
        "ALTER TABLE pending_requests ADD COLUMN type TEXT NOT NULL DEFAULT 'OUT'",
        "ALTER TABLE pending_requests ADD COLUMN follow_up_shown INTEGER NOT NULL DEFAULT 0",
      ];
      for (final sql in cols) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
      await db.execute(
        "UPDATE pending_requests SET input_datetime = created_at WHERE input_datetime IS NULL",
      );
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE messages ADD COLUMN receiptData TEXT");
      } catch (_) {}
    }
  }

  Future<int> addTransaction(
    int amount,
    String note,
    String type,
    String category,
  ) async {
    final db = await instance.database;
    final id = await db.insert('transactions', {
      'amount': amount,
      'note': note,
      'type': type.toUpperCase().trim(),
      'category': category,
      'date': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<int> updateTransaction(int id, int amount, String? note) async {
    final db = await instance.database;
    final Map<String, dynamic> data = {'amount': amount};
    if (note != null && note.isNotEmpty) data['note'] = note;
    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // UPDATE FUNGSI INI: Menambahkan parameter receiptData
  Future<int> insertMessage(
    String text,
    bool isAi, {
    String? confirmMsg,
    String? confirmCmd,
    String? receiptData,
  }) async {
    final db = await instance.database;
    return await db.insert('messages', {
      'text': text,
      'isAi': isAi ? 1 : 0,
      'confirmMsg': confirmMsg,
      'confirmCmd': confirmCmd,
      'receiptData': receiptData,
    });
  }

  Future<List<Map<String, dynamic>>> getMessages({int limit = 30}) async {
    final db = await instance.database;
    return await db.query('messages', orderBy: 'id DESC', limit: limit);
  }

  Future<RawQueryResult> rawSelect(String validatedSql) async {
    final db = await instance.database;
    try {
      final rows = await db.rawQuery(validatedSql);
      final columns = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
      return RawQueryResult(
        columns: columns.cast<String>(),
        rows: rows,
        error: null,
      );
    } catch (e) {
      return RawQueryResult(columns: [], rows: [], error: e.toString());
    }
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('transactions');
    await db.delete('messages');
    await db.delete('pending_requests');
  }
}

class RawQueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? error;

  RawQueryResult({
    required this.columns,
    required this.rows,
    required this.error,
  });

  bool get isSuccess => error == null;
  bool get isEmpty => rows.isEmpty;
  int get rowCount => rows.length;

  bool get isEffectivelyEmpty {
    if (rows.isEmpty) return true;
    for (final row in rows) {
      for (final val in row.values) {
        if (val != null && val != 0 && val != '0') return false;
      }
    }
    return true;
  }
}
