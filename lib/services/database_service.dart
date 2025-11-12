import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/board.dart';
import '../models/task.dart';
import 'database_adapter.dart';
import 'sqlite_adapter.dart';
import 'mysql_adapter.dart';

class DatabaseService {
  static DatabaseAdapter? _adapter;
  static String? _databasePath;

  // 单例模式
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Future<DatabaseAdapter> get adapter async {
    if (_adapter != null) return _adapter!;
    await _initAdapter();
    return _adapter!;
  }

  // 设置数据库路径
  static Future<void> setDatabasePath(String path) async {
    _databasePath = path;
    if (_adapter != null) {
      await _adapter!.close();
      _adapter = null;
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

  /// 根据路径判断数据库类型并创建相应的适配器
  static DatabaseAdapter _createAdapter(String path) {
    if (path.startsWith('mysql://')) {
      return MySQLAdapter(path);
    } else {
      return SQLiteAdapter(path);
    }
  }

  Future<void> _initAdapter() async {
    String path = _databasePath ?? await getDefaultDatabasePath();
    _adapter = _createAdapter(path);
    await _adapter!.initialize();
  }

  // ==================== 工作板操作 ====================

  Future<List<Board>> getAllBoards() async {
    final db = await adapter;
    return await db.getAllBoards();
  }

  Future<int> createBoard(Board board) async {
    final db = await adapter;
    return await db.createBoard(board);
  }

  Future<void> updateBoard(Board board) async {
    final db = await adapter;
    await db.updateBoard(board);
  }

  Future<void> deleteBoard(int boardId) async {
    final db = await adapter;
    await db.deleteBoard(boardId);
  }

  Future<void> updateBoardsOrder(List<Board> boards) async {
    final db = await adapter;
    await db.updateBoardsOrder(boards);
  }

  // ==================== 任务操作 ====================

  Future<List<Task>> getTasksByBoard(int boardId) async {
    final db = await adapter;
    return await db.getTasksByBoard(boardId);
  }

  Future<int> createTask(Task task) async {
    final db = await adapter;
    return await db.createTask(task);
  }

  Future<void> updateTask(Task task) async {
    final db = await adapter;
    await db.updateTask(task);
  }

  Future<void> deleteTask(int taskId) async {
    final db = await adapter;
    await db.deleteTask(taskId);
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final db = await adapter;
    await db.toggleTaskCompletion(task);
  }

  Future<void> updateTasksOrder(List<Task> tasks) async {
    final db = await adapter;
    await db.updateTasksOrder(tasks);
  }

  Future<List<Task>> filterTasks({
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? completedAfter,
    DateTime? completedBefore,
    List<int>? boardIds,
  }) async {
    final db = await adapter;
    return await db.filterTasks(
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      completedAfter: completedAfter,
      completedBefore: completedBefore,
      boardIds: boardIds,
    );
  }

  // 测试数据库连接
  Future<bool> testConnection(String path) async {
    try {
      final adapter = _createAdapter(path);
      final result = await adapter.testConnection();
      await adapter.close();
      return result;
    } catch (e) {
      return false;
    }
  }

  // 关闭数据库
  Future<void> close() async {
    if (_adapter != null) {
      await _adapter!.close();
      _adapter = null;
    }
  }
}
