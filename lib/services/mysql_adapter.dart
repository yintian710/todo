import 'package:mysql1/mysql1.dart';
import '../models/board.dart';
import '../models/task.dart';
import 'database_adapter.dart';

/// MySQL 数据库适配器
class MySQLAdapter implements DatabaseAdapter {
  final String url;
  MySQLConnection? _connection;

  MySQLAdapter(this.url);

  /// 解析 MySQL URL
  /// 格式: mysql://user:password@host:port/database
  ConnectionSettings _parseUrl() {
    final uri = Uri.parse(url);

    if (uri.scheme != 'mysql') {
      throw Exception('Invalid MySQL URL scheme. Expected mysql://');
    }

    return ConnectionSettings(
      host: uri.host,
      port: uri.hasPort ? uri.port : 3306,
      user: uri.userInfo.split(':').first,
      password: uri.userInfo.contains(':')
          ? uri.userInfo.split(':').sublist(1).join(':')
          : '',
      db: uri.path.startsWith('/') ? uri.path.substring(1) : uri.path,
    );
  }

  @override
  Future<void> initialize() async {
    final settings = _parseUrl();
    _connection = await MySqlConnection.connect(settings);

    // 创建表（如果不存在）
    await _createTables();
  }

  @override
  Future<bool> testConnection() async {
    try {
      final settings = _parseUrl();
      final conn = await MySqlConnection.connect(settings);
      await conn.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  Future<void> _createTables() async {
    // 创建工作板表
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS boards (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        color INT NOT NULL,
        sort_order INT NOT NULL,
        created_at DATETIME NOT NULL,
        INDEX idx_sort_order (sort_order)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ''');

    // 创建任务表
    await _conn.query('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        board_id INT NOT NULL,
        title TEXT NOT NULL,
        is_completed TINYINT(1) NOT NULL DEFAULT 0,
        sort_order INT NOT NULL,
        deadline DATETIME,
        created_at DATETIME NOT NULL,
        first_completed_at DATETIME,
        completed_at DATETIME,
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE,
        INDEX idx_board_id (board_id),
        INDEX idx_is_completed (is_completed)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ''');
  }

  MySQLConnection get _conn {
    if (_connection == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _connection!;
  }

  // ==================== 工作板操作 ====================

  @override
  Future<List<Board>> getAllBoards() async {
    final results = await _conn.query(
      'SELECT * FROM boards ORDER BY sort_order ASC',
    );

    return results.map((row) {
      return Board.fromMap({
        'id': row['id'],
        'name': row['name'],
        'color': row['color'],
        'sort_order': row['sort_order'],
        'created_at': (row['created_at'] as DateTime).toIso8601String(),
      });
    }).toList();
  }

  @override
  Future<int> createBoard(Board board) async {
    final result = await _conn.query(
      '''INSERT INTO boards (name, color, sort_order, created_at)
         VALUES (?, ?, ?, ?)''',
      [
        board.name,
        board.color.value,
        board.sortOrder,
        board.createdAt,
      ],
    );
    return result.insertId!;
  }

  @override
  Future<void> updateBoard(Board board) async {
    await _conn.query(
      '''UPDATE boards
         SET name = ?, color = ?, sort_order = ?
         WHERE id = ?''',
      [
        board.name,
        board.color.value,
        board.sortOrder,
        board.id,
      ],
    );
  }

  @override
  Future<void> deleteBoard(int boardId) async {
    await _conn.query('DELETE FROM boards WHERE id = ?', [boardId]);
  }

  @override
  Future<void> updateBoardsOrder(List<Board> boards) async {
    for (final board in boards) {
      await _conn.query(
        'UPDATE boards SET sort_order = ? WHERE id = ?',
        [board.sortOrder, board.id],
      );
    }
  }

  // ==================== 任务操作 ====================

  @override
  Future<List<Task>> getTasksByBoard(int boardId) async {
    final results = await _conn.query(
      'SELECT * FROM tasks WHERE board_id = ? ORDER BY sort_order ASC',
      [boardId],
    );

    return results.map((row) {
      return Task.fromMap({
        'id': row['id'],
        'board_id': row['board_id'],
        'title': row['title'],
        'is_completed': row['is_completed'],
        'sort_order': row['sort_order'],
        'deadline': row['deadline'] != null
            ? (row['deadline'] as DateTime).toIso8601String()
            : null,
        'created_at': (row['created_at'] as DateTime).toIso8601String(),
        'first_completed_at': row['first_completed_at'] != null
            ? (row['first_completed_at'] as DateTime).toIso8601String()
            : null,
        'completed_at': row['completed_at'] != null
            ? (row['completed_at'] as DateTime).toIso8601String()
            : null,
      });
    }).toList();
  }

  @override
  Future<int> createTask(Task task) async {
    final result = await _conn.query(
      '''INSERT INTO tasks (board_id, title, is_completed, sort_order,
         deadline, created_at, first_completed_at, completed_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        task.boardId,
        task.title,
        task.isCompleted ? 1 : 0,
        task.sortOrder,
        task.deadline,
        task.createdAt,
        task.firstCompletedAt,
        task.completedAt,
      ],
    );
    return result.insertId!;
  }

  @override
  Future<void> updateTask(Task task) async {
    await _conn.query(
      '''UPDATE tasks
         SET board_id = ?, title = ?, is_completed = ?, sort_order = ?,
             deadline = ?, first_completed_at = ?, completed_at = ?
         WHERE id = ?''',
      [
        task.boardId,
        task.title,
        task.isCompleted ? 1 : 0,
        task.sortOrder,
        task.deadline,
        task.firstCompletedAt,
        task.completedAt,
        task.id,
      ],
    );
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _conn.query('DELETE FROM tasks WHERE id = ?', [taskId]);
  }

  @override
  Future<void> toggleTaskCompletion(Task task) async {
    final now = DateTime.now();
    final isCompleted = !task.isCompleted;

    await _conn.query(
      '''UPDATE tasks
         SET is_completed = ?, completed_at = ?, first_completed_at = COALESCE(first_completed_at, ?)
         WHERE id = ?''',
      [
        isCompleted ? 1 : 0,
        isCompleted ? now : null,
        isCompleted ? now : null,
        task.id,
      ],
    );
  }

  @override
  Future<void> updateTasksOrder(List<Task> tasks) async {
    for (final task in tasks) {
      await _conn.query(
        '''UPDATE tasks
           SET board_id = ?, sort_order = ?, is_completed = ?,
               deadline = ?, first_completed_at = ?, completed_at = ?
           WHERE id = ?''',
        [
          task.boardId,
          task.sortOrder,
          task.isCompleted ? 1 : 0,
          task.deadline,
          task.firstCompletedAt,
          task.completedAt,
          task.id,
        ],
      );
    }
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
      whereArgs.add(createdAfter);
    }

    if (createdBefore != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(createdBefore);
    }

    if (completedAfter != null) {
      where += ' AND completed_at >= ?';
      whereArgs.add(completedAfter);
    }

    if (completedBefore != null) {
      where += ' AND completed_at <= ?';
      whereArgs.add(completedBefore);
    }

    if (boardIds != null && boardIds.isNotEmpty) {
      where += ' AND board_id IN (${boardIds.map((_) => '?').join(',')})';
      whereArgs.addAll(boardIds);
    }

    final results = await _conn.query(
      'SELECT * FROM tasks WHERE $where ORDER BY created_at DESC',
      whereArgs,
    );

    return results.map((row) {
      return Task.fromMap({
        'id': row['id'],
        'board_id': row['board_id'],
        'title': row['title'],
        'is_completed': row['is_completed'],
        'sort_order': row['sort_order'],
        'deadline': row['deadline'] != null
            ? (row['deadline'] as DateTime).toIso8601String()
            : null,
        'created_at': (row['created_at'] as DateTime).toIso8601String(),
        'first_completed_at': row['first_completed_at'] != null
            ? (row['first_completed_at'] as DateTime).toIso8601String()
            : null,
        'completed_at': row['completed_at'] != null
            ? (row['completed_at'] as DateTime).toIso8601String()
            : null,
      });
    }).toList();
  }
}
