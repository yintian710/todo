import '../models/board.dart';
import '../models/task.dart';

/// 数据库适配器抽象接口
/// 支持多种数据库实现（SQLite、MySQL等）
abstract class DatabaseAdapter {
  /// 初始化数据库连接
  Future<void> initialize();

  /// 测试数据库连接
  Future<bool> testConnection();

  /// 关闭数据库连接
  Future<void> close();

  // ==================== 工作板操作 ====================

  /// 获取所有工作板
  Future<List<Board>> getAllBoards();

  /// 创建工作板
  Future<int> createBoard(Board board);

  /// 更新工作板
  Future<void> updateBoard(Board board);

  /// 删除工作板
  Future<void> deleteBoard(int boardId);

  /// 批量更新工作板排序
  Future<void> updateBoardsOrder(List<Board> boards);

  // ==================== 任务操作 ====================

  /// 获取指定工作板的任务
  Future<List<Task>> getTasksByBoard(int boardId);

  /// 创建任务
  Future<int> createTask(Task task);

  /// 更新任务
  Future<void> updateTask(Task task);

  /// 删除任务
  Future<void> deleteTask(int taskId);

  /// 切换任务完成状态
  Future<void> toggleTaskCompletion(Task task);

  /// 批量更新任务排序
  Future<void> updateTasksOrder(List<Task> tasks);

  /// 根据条件筛选任务
  Future<List<Task>> filterTasks({
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? completedAfter,
    DateTime? completedBefore,
    List<int>? boardIds,
  });
}
