import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/board.dart';
import '../models/task.dart';

class DatabaseService {
  static Database? _database;
  static String? _databasePath;

  // 单例模式
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 设置数据库路径
  static Future<void> setDatabasePath(String path) async {
    _databasePath = path;
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // 获取默认数据库路径
  static Future<String> getDefaultDatabasePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dbPath = join(appDocDir.path, 'todo_app');
      await Directory(dbPath).create(recursive: true);
      return join(dbPath, 'todo.db');
    } else {
      final String dbPath = await getDatabasesPath();
      return join(dbPath, 'todo.db');
    }
  }

  Future<Database> _initDatabase() async {
    // 初始化 FFI (用于桌面平台)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = _databasePath ?? await getDefaultDatabasePath();

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
    await db.execute(
        'CREATE INDEX idx_tasks_board_id ON tasks (board_id)');
    await db.execute(
        'CREATE INDEX idx_tasks_is_completed ON tasks (is_completed)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
  }

  // ==================== 工作板操作 ====================

  // 创建工作板
  Future<int> createBoard(Board board) async {
    final db = await database;
    return await db.insert('boards', board.toMap());
  }

  // 获取所有工作板
  Future<List<Board>> getAllBoards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'boards',
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => Board.fromMap(maps[i]));
  }

  // 获取单个工作板
  Future<Board?> getBoard(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'boards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Board.fromMap(maps.first);
  }

  // 更新工作板
  Future<int> updateBoard(Board board) async {
    final db = await database;
    return await db.update(
      'boards',
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  // 删除工作板
  Future<int> deleteBoard(int id) async {
    final db = await database;
    // 先删除该工作板下的所有任务
    await db.delete('tasks', where: 'board_id = ?', whereArgs: [id]);
    // 再删除工作板
    return await db.delete('boards', where: 'id = ?', whereArgs: [id]);
  }

  // 批量更新工作板排序
  Future<void> updateBoardsOrder(List<Board> boards) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < boards.length; i++) {
      batch.update(
        'boards',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [boards[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ==================== 任务操作 ====================

  // 创建任务
  Future<int> createTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  // 获取指定工作板的所有任务
  Future<List<Task>> getTasksByBoard(int boardId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'is_completed ASC, sort_order ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // 获取所有任务
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // 获取单个任务
  Future<Task?> getTask(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  // 更新任务
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // 删除任务
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // 批量更新任务排序
  Future<void> updateTasksOrder(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < tasks.length; i++) {
      batch.update(
        'tasks',
        {
          'sort_order': i,
          'board_id': tasks[i].boardId,
        },
        where: 'id = ?',
        whereArgs: [tasks[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // 切换任务完成状态
  Future<void> toggleTaskCompletion(Task task) async {
    final db = await database;
    final now = DateTime.now();
    final isCompleting = !task.isCompleted;

    final updatedTask = task.copyWith(
      isCompleted: isCompleting,
      firstCompletedAt:
          isCompleting && task.firstCompletedAt == null ? now : null,
      completedAt: isCompleting ? now : null,
    );

    await db.update(
      'tasks',
      updatedTask.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // 按筛选条件查询任务
  Future<List<Task>> getTasksByFilter({
    DateTime? createdFrom,
    DateTime? createdTo,
    DateTime? completedFrom,
    DateTime? completedTo,
    int? boardId,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (createdFrom != null) {
      whereClause += ' created_at >= ?';
      whereArgs.add(createdFrom.toIso8601String());
    }

    if (createdTo != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND';
      whereClause += ' created_at <= ?';
      whereArgs.add(createdTo.toIso8601String());
    }

    if (completedFrom != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND';
      whereClause += ' completed_at >= ?';
      whereArgs.add(completedFrom.toIso8601String());
    }

    if (completedTo != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND';
      whereClause += ' completed_at <= ?';
      whereArgs.add(completedTo.toIso8601String());
    }

    if (boardId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND';
      whereClause += ' board_id = ?';
      whereArgs.add(boardId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // 测试数据库连接
  Future<bool> testConnection(String path) async {
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

  // 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
