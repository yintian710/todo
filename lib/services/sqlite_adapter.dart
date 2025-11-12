import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/board.dart';
import '../models/task.dart';
import 'database_adapter.dart';

/// SQLite 数据库适配器
class SQLiteAdapter implements DatabaseAdapter {
  final String path;
  Database? _database;

  SQLiteAdapter(this.path);

  @override
  Future<void> initialize() async {
    // 初始化 FFI (用于桌面平台)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @override
  Future<bool> testConnection() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      await db.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建工作板表
    await db.execute('''
      CREATE TABLE boards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建任务表
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        board_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL,
        deadline TEXT,
        created_at TEXT NOT NULL,
        first_completed_at TEXT,
        completed_at TEXT,
        FOREIGN KEY (board_id) REFERENCES boards (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_tasks_board_id ON tasks (board_id)');
    await db.execute('CREATE INDEX idx_tasks_is_completed ON tasks (is_completed)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
  }

  Database get _db {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  // ==================== 工作板操作 ====================

  @override
  Future<List<Board>> getAllBoards() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'boards',
      orderBy: 'sort_order ASC',
    );
    return maps.map((map) => Board.fromMap(map)).toList();
  }

  @override
  Future<int> createBoard(Board board) async {
    return await _db.insert('boards', board.toMap());
  }

  @override
  Future<void> updateBoard(Board board) async {
    await _db.update(
      'boards',
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  @override
  Future<void> deleteBoard(int boardId) async {
    await _db.delete(
      'boards',
      where: 'id = ?',
      whereArgs: [boardId],
    );
  }

  @override
  Future<void> updateBoardsOrder(List<Board> boards) async {
    final batch = _db.batch();
    for (final board in boards) {
      batch.update(
        'boards',
        {'sort_order': board.sortOrder},
        where: 'id = ?',
        whereArgs: [board.id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ==================== 任务操作 ====================

  @override
  Future<List<Task>> getTasksByBoard(int boardId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<int> createTask(Task task) async {
    return await _db.insert('tasks', task.toMap());
  }

  @override
  Future<void> updateTask(Task task) async {
    await _db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<void> toggleTaskCompletion(Task task) async {
    final now = DateTime.now().toIso8601String();
    final isCompleted = !task.isCompleted;

    await _db.update(
      'tasks',
      {
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? now : null,
        'first_completed_at': task.firstCompletedAt?.toIso8601String() ??
            (isCompleted ? now : null),
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> updateTasksOrder(List<Task> tasks) async {
    final batch = _db.batch();
    for (final task in tasks) {
      batch.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Task>> filterTasks({
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? completedAfter,
    DateTime? completedBefore,
    List<int>? boardIds,
  }) async {
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (createdAfter != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(createdAfter.toIso8601String());
    }

    if (createdBefore != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(createdBefore.toIso8601String());
    }

    if (completedAfter != null) {
      where += ' AND completed_at >= ?';
      whereArgs.add(completedAfter.toIso8601String());
    }

    if (completedBefore != null) {
      where += ' AND completed_at <= ?';
      whereArgs.add(completedBefore.toIso8601String());
    }

    if (boardIds != null && boardIds.isNotEmpty) {
      where += ' AND board_id IN (${boardIds.map((_) => '?').join(',')})';
      whereArgs.addAll(boardIds);
    }

    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }
}
