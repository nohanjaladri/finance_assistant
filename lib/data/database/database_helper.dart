import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _personalDb;
  static Database? _sharedDb;
  bool _isSharedMode = false;

  DatabaseHelper._init();

  void setMode(bool isShared) {
    _isSharedMode = isShared;
  }

  Future<Database> get database async {
    if (_isSharedMode) {
      if (_sharedDb != null) return _sharedDb!;
      _sharedDb = await _initDB('shared_finance_v2.db');
      return _sharedDb!;
    } else {
      if (_personalDb != null) return _personalDb!;
      _personalDb = await _initDB('finance_v2.db');
      return _personalDb!;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        nama_kategori TEXT NOT NULL,
        icon        TEXT NOT NULL,
        type        TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending_insert'
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        amount      INTEGER NOT NULL,
        note        TEXT NOT NULL,
        type        TEXT NOT NULL,
        date        TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending_insert'
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        text        TEXT NOT NULL,
        isAi        INTEGER NOT NULL,
        confirmMsg  TEXT,
        confirmCmd  TEXT,
        receiptData TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending_insert'
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_requests (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        original_input  TEXT    NOT NULL,
        nama            TEXT,
        nominal         INTEGER,
        quantity        INTEGER NOT NULL DEFAULT 1,
        input_datetime  TEXT,
        missing_fields  TEXT    NOT NULL DEFAULT '[]',
        partial_data    TEXT    NOT NULL DEFAULT '{}',
        ai_question     TEXT    NOT NULL DEFAULT '',
        reason          TEXT    NOT NULL DEFAULT '',
        category        TEXT    NOT NULL DEFAULT 'Other',
        type            TEXT    NOT NULL DEFAULT 'OUT',
        created_at      TEXT,
        status          TEXT    NOT NULL DEFAULT 'pending',
        follow_up_shown INTEGER,
        sync_status     TEXT    NOT NULL DEFAULT 'pending_insert'
      )
    ''');

    await db.execute('''
      CREATE VIEW v_transactions_full AS
      SELECT 
        t.id, 
        t.amount, 
        t.note, 
        t.type, 
        t.date, 
        c.nama_kategori AS category_name, 
        c.icon AS category_icon
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.deleted_at IS NULL AND c.deleted_at IS NULL
    ''');

    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultCats = [
      {
        'id': 'cat_food',
        'nama_kategori': 'Makanan & Minuman',
        'icon': 'restaurant',
        'type': 'OUT',
      },
      {
        'id': 'cat_transport',
        'nama_kategori': 'Transportasi',
        'icon': 'two_wheeler',
        'type': 'OUT',
      },
      {
        'id': 'cat_shopping',
        'nama_kategori': 'Belanja',
        'icon': 'shopping_bag',
        'type': 'OUT',
      },
      {
        'id': 'cat_salary',
        'nama_kategori': 'Gaji',
        'icon': 'payments',
        'type': 'IN',
      },
      {
        'id': 'cat_other_out',
        'nama_kategori': 'Lainnya (Keluar)',
        'icon': 'receipt_long',
        'type': 'OUT',
      },
      {
        'id': 'cat_other_in',
        'nama_kategori': 'Lainnya (Masuk)',
        'icon': 'account_balance_wallet',
        'type': 'IN',
      },
    ];

    for (var cat in defaultCats) {
      await db.insert('categories', {
        ...cat,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'pending_insert',
      });
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactionsView() async {
    final db = await instance.database;
    return await db.query('v_transactions_full', orderBy: 'date DESC');
  }

  Future<int> addTransactionV2(
    int amount,
    String note,
    String type,
    String categoryId,
  ) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('transactions', {
      'amount': amount,
      'note': note,
      'type': type.toUpperCase().trim(),
      'category_id': categoryId,
      'date': now,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending_insert',
    });
  }

  // ===============================================
  // PERBAIKAN ERROR 1: Fungsi updateTransaction ditambahkan kembali
  // ===============================================
  Future<int> updateTransaction(int id, int amount, String? note) async {
    final db = await instance.database;

    final current = await db.query(
      'transactions',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );
    String newStatus = 'pending_update';

    if (current.isNotEmpty &&
        current.first['sync_status'] == 'pending_insert') {
      newStatus = 'pending_insert';
    }

    final Map<String, dynamic> data = {
      'amount': amount,
      'sync_status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (note != null && note.isNotEmpty) data['note'] = note;

    return await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'transactions',
      {'deleted_at': now, 'sync_status': 'pending_update'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertMessage(
    String text,
    bool isAi, {
    String? receiptData,
  }) async {
    final db = await instance.database;
    return await db.insert('messages', {
      'text': text,
      'isAi': isAi ? 1 : 0,
      'receiptData': receiptData,
      'sync_status': 'pending_insert',
    });
  }

  Future<List<Map<String, dynamic>>> getMessages({int limit = 30}) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: "sync_status != 'pending_delete'",
      orderBy: 'id DESC',
      limit: limit,
    );
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
    await db.delete('categories');
    await db.delete('messages');
    await db.delete('pending_requests');
    await _seedDefaultCategories(db);
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

  // ===============================================
  // PERBAIKAN ERROR 2 & 3: Getter ini ditambahkan kembali
  // ===============================================
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
