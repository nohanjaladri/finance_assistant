import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        note TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        isAi INTEGER NOT NULL,
        confirmMsg TEXT,
        confirmCmd TEXT
      )
    ''');
  }

  // CREATE
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
      'date': DateTime.now().toIso8601String(), // Simpan ISO String lengkap
    });
    print(
      "DB_LOG: Berhasil simpan ke SQL dengan ID: $id | Amount: $amount | Type: $type",
    );
    return id;
  }

  // READ
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    // Urutkan berdasarkan tanggal terbaru
    return await db.query('transactions', orderBy: 'date DESC');
  }

  // DELETE
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // MESSAGES
  Future<int> insertMessage(
    String text,
    bool isAi, {
    String? confirmMsg,
    String? confirmCmd,
  }) async {
    final db = await instance.database;
    return await db.insert('messages', {
      'text': text,
      'isAi': isAi ? 1 : 0,
      'confirmMsg': confirmMsg,
      'confirmCmd': confirmCmd,
    });
  }

  Future<List<Map<String, dynamic>>> getMessages({int limit = 50}) async {
    final db = await instance.database;
    return await db.query('messages', orderBy: 'id DESC', limit: limit);
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('transactions');
    await db.delete('messages');
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) await db.close();
  }
}
