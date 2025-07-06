import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          );
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

    Future<List<Map<String, dynamic>>> rawQuery(String query, List<dynamic> args) async {
    final db = await database;
    return await db.rawQuery(query, args);
    } 

  Future<int> update(String table, Map<String, dynamic> values, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
  

  Future<List<Map<String, dynamic>>> queryExpensesByCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.name AS category_name, SUM(e.amount) AS total_amount
      FROM expenses e
      INNER JOIN categories c ON e.category_id = c.id
      GROUP BY e.category_id;
    ''');
  }

  Future<double> queryTotalExpenses(String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) AS total_amount
      FROM expenses
      WHERE date BETWEEN ? AND ?
    ''', [startDate, endDate]);

    
    return (result.first['total_amount'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> queryExpensesByDate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    var whereClause = '';
    final args = <dynamic>[];
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE date(date) BETWEEN date(?) AND date(?)';
      args.addAll([
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);
    }
    return await db.rawQuery('''
      SELECT date(date) AS date, SUM(amount) AS total_amount
      FROM expenses
      $whereClause
      GROUP BY date(date)
      ORDER BY date(date)
    ''', args);
  }
}
