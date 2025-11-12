import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<Board> _boards = [];
  Map<int, List<Task>> _tasksByBoard = {};
  bool _isLoading = false;
  String? _error;

  List<Board> get boards => _boards;
  Map<int, List<Task>> get tasksByBoard => _tasksByBoard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 获取指定工作板的任务
  List<Task> getTasksForBoard(int boardId) {
    return _tasksByBoard[boardId] ?? [];
  }

  // 加载所有数据
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _boards = await _dbService.getAllBoards();
      _tasksByBoard.clear();

      for (final board in _boards) {
        final tasks = await _dbService.getTasksByBoard(board.id!);
        _tasksByBoard[board.id!] = _sortTasks(tasks);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 任务排序：未完成在前，已完成在后
  List<Task> _sortTasks(List<Task> tasks) {
    final incompleteTasks =
        tasks.where((t) => !t.isCompleted).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final completedTasks =
        tasks.where((t) => t.isCompleted).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return [...incompleteTasks, ...completedTasks];
  }

  // ==================== 工作板操作 ====================

  // 创建工作板
  Future<void> createBoard(String name, Color color) async {
    try {
      final sortOrder = _boards.length;
      final board = Board(
        name: name,
        color: color,
        sortOrder: sortOrder,
      );

      final id = await _dbService.createBoard(board);
      final newBoard = board.copyWith(id: id);

      _boards.add(newBoard);
      _tasksByBoard[id] = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 更新工作板
  Future<void> updateBoard(Board board) async {
    try {
      await _dbService.updateBoard(board);
      final index = _boards.indexWhere((b) => b.id == board.id);
      if (index != -1) {
        _boards[index] = board;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 删除工作板
  Future<void> deleteBoard(int boardId) async {
    try {
      await _dbService.deleteBoard(boardId);
      _boards.removeWhere((b) => b.id == boardId);
      _tasksByBoard.remove(boardId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 重新排序工作板
  Future<void> reorderBoards(int oldIndex, int newIndex) async {
    try {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final board = _boards.removeAt(oldIndex);
      _boards.insert(newIndex, board);

      // 更新所有工作板的排序
      for (int i = 0; i < _boards.length; i++) {
        _boards[i] = _boards[i].copyWith(sortOrder: i);
      }

      await _dbService.updateBoardsOrder(_boards);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ==================== 任务操作 ====================

  // 创建任务
  Future<void> createTask(int boardId, String title) async {
    try {
      final tasks = _tasksByBoard[boardId] ?? [];
      final sortOrder = tasks.where((t) => !t.isCompleted).length;

      final task = Task(
        boardId: boardId,
        title: title,
        sortOrder: sortOrder,
      );

      final id = await _dbService.createTask(task);
      final newTask = task.copyWith(id: id);

      if (_tasksByBoard[boardId] == null) {
        _tasksByBoard[boardId] = [];
      }
      _tasksByBoard[boardId]!.insert(sortOrder, newTask);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 更新任务
  Future<void> updateTask(Task task) async {
    try {
      await _dbService.updateTask(task);
      final tasks = _tasksByBoard[task.boardId];
      if (tasks != null) {
        final index = tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          tasks[index] = task;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 删除任务
  Future<void> deleteTask(int boardId, int taskId) async {
    try {
      await _dbService.deleteTask(taskId);
      _tasksByBoard[boardId]?.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 切换任务完成状态
  Future<void> toggleTaskCompletion(Task task) async {
    try {
      await _dbService.toggleTaskCompletion(task);

      // 重新加载该工作板的任务以确保排序正确
      final tasks = await _dbService.getTasksByBoard(task.boardId);
      _tasksByBoard[task.boardId] = _sortTasks(tasks);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 在同一工作板内重新排序任务
  Future<void> reorderTasks(int boardId, int oldIndex, int newIndex) async {
    try {
      final tasks = _tasksByBoard[boardId]!;

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final task = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, task);

      // 更新排序
      await _updateTasksOrder(tasks);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 跨工作板移动任务
  Future<void> moveTaskToBoard(Task task, int newBoardId) async {
    try {
      final oldBoardId = task.boardId;

      // 从旧工作板移除
      _tasksByBoard[oldBoardId]?.removeWhere((t) => t.id == task.id);

      // 添加到新工作板
      final newTasks = _tasksByBoard[newBoardId] ?? [];
      final newSortOrder = newTasks.where((t) => !t.isCompleted).length;

      final updatedTask = task.copyWith(
        boardId: newBoardId,
        sortOrder: newSortOrder,
      );

      await _dbService.updateTask(updatedTask);

      if (_tasksByBoard[newBoardId] == null) {
        _tasksByBoard[newBoardId] = [];
      }
      _tasksByBoard[newBoardId]!.add(updatedTask);

      // 重新排序两个工作板的任务
      _tasksByBoard[oldBoardId] = _sortTasks(_tasksByBoard[oldBoardId]!);
      _tasksByBoard[newBoardId] = _sortTasks(_tasksByBoard[newBoardId]!);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 更新任务排序
  Future<void> _updateTasksOrder(List<Task> tasks) async {
    for (int i = 0; i < tasks.length; i++) {
      tasks[i] = tasks[i].copyWith(sortOrder: i);
    }
    await _dbService.updateTasksOrder(tasks);
  }

  // 设置任务倒计时
  Future<void> setTaskDeadline(Task task, DateTime? deadline) async {
    try {
      final updatedTask = task.copyWith(
        deadline: deadline,
        clearDeadline: deadline == null,
      );
      await _dbService.updateTask(updatedTask);

      final tasks = _tasksByBoard[task.boardId];
      if (tasks != null) {
        final index = tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          tasks[index] = updatedTask;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // 按倒计时排序任务
  void sortTasksByDeadline(int boardId) {
    final tasks = _tasksByBoard[boardId];
    if (tasks == null) return;

    // 分离未完成任务
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    // 分离有倒计时和无倒计时的未完成任务
    final tasksWithDeadline =
        incompleteTasks.where((t) => t.deadline != null).toList();
    final tasksWithoutDeadline =
        incompleteTasks.where((t) => t.deadline == null).toList();

    // 对有倒计时的任务排序：已超时的在最前，然后按剩余时间排序
    tasksWithDeadline.sort((a, b) {
      final now = DateTime.now();
      final aOverdue = a.deadline!.isBefore(now);
      final bOverdue = b.deadline!.isBefore(now);

      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;

      // 都超时或都未超时，按截止时间排序
      return a.deadline!.compareTo(b.deadline!);
    });

    // 重新组合：倒计时任务 + 无倒计时任务 + 已完成任务
    _tasksByBoard[boardId] = [
      ...tasksWithDeadline,
      ...tasksWithoutDeadline,
      ...completedTasks,
    ];

    // 更新数据库中的排序
    _updateTasksOrder(_tasksByBoard[boardId]!);

    notifyListeners();
  }

  // 获取所有任务（用于导出）
  List<Task> getAllTasks() {
    final allTasks = <Task>[];
    for (final tasks in _tasksByBoard.values) {
      allTasks.addAll(tasks);
    }
    return allTasks;
  }
}
