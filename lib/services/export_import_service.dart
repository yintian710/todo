import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/board.dart';
import '../models/task.dart';

class ExportImportService {
  // 导出数据为 JSON
  static String exportToJson({
    required List<Board> boards,
    required List<Task> tasks,
  }) {
    final data = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'boards': boards
          .map((board) => {
                'id': board.id,
                'name': board.name,
                'color': board.color.value,
                'sort_order': board.sortOrder,
                'created_at': board.createdAt.toIso8601String(),
              })
          .toList(),
      'tasks': tasks
          .map((task) => {
                'id': task.id,
                'board_id': task.boardId,
                'title': task.title,
                'is_completed': task.isCompleted,
                'sort_order': task.sortOrder,
                'deadline': task.deadline?.toIso8601String(),
                'created_at': task.createdAt.toIso8601String(),
                'first_completed_at': task.firstCompletedAt?.toIso8601String(),
                'completed_at': task.completedAt?.toIso8601String(),
              })
          .toList(),
    };

    return JsonEncoder.withIndent('  ').convert(data);
  }

  // 从 JSON 导入数据
  static Future<Map<String, List<dynamic>>> importFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final boards = (data['boards'] as List)
          .map((boardData) => Board.fromMap({
                'id': boardData['id'],
                'name': boardData['name'],
                'color': boardData['color'],
                'sort_order': boardData['sort_order'],
                'created_at': boardData['created_at'],
              }))
          .toList();

      final tasks = (data['tasks'] as List)
          .map((taskData) => Task.fromMap({
                'id': taskData['id'],
                'board_id': taskData['board_id'],
                'title': taskData['title'],
                'is_completed': taskData['is_completed'] ? 1 : 0,
                'sort_order': taskData['sort_order'],
                'deadline': taskData['deadline'],
                'created_at': taskData['created_at'],
                'first_completed_at': taskData['first_completed_at'],
                'completed_at': taskData['completed_at'],
              }))
          .toList();

      return {
        'boards': boards,
        'tasks': tasks,
      };
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  // 生成 AI 工作报告提示词
  static String generateAIPrompt({
    required List<Task> tasks,
    required Map<int, Board> boardsMap,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('请根据以下任务列表生成工作报告：\n');

    // 按工作板分组
    final tasksByBoard = <int, List<Task>>{};
    for (final task in tasks) {
      tasksByBoard.putIfAbsent(task.boardId, () => []).add(task);
    }

    // 生成每个工作板的任务列表
    for (final entry in tasksByBoard.entries) {
      final boardId = entry.key;
      final boardTasks = entry.value;
      final board = boardsMap[boardId];

      if (board != null) {
        buffer.writeln('## ${board.name}\n');
      }

      for (final task in boardTasks) {
        buffer.write('- ');
        if (task.isCompleted) {
          buffer.write('[已完成] ');
        } else {
          buffer.write('[未完成] ');
        }
        buffer.write(task.title);

        // 添加时间信息
        final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
        buffer.write(' (创建: ${dateFormat.format(task.createdAt)}');

        if (task.completedAt != null) {
          buffer.write(', 完成: ${dateFormat.format(task.completedAt!)}');
        }

        if (task.deadline != null) {
          buffer.write(', 截止: ${dateFormat.format(task.deadline!)}');
        }

        buffer.writeln(')');
      }

      buffer.writeln();
    }

    buffer.writeln('\n请总结以上工作内容，包括：');
    buffer.writeln('1. 主要完成的工作');
    buffer.writeln('2. 工作亮点和成果');
    buffer.writeln('3. 遇到的挑战和解决方案');
    buffer.writeln('4. 下一步工作计划');

    return buffer.toString();
  }

  // 保存文件
  static Future<void> saveToFile(String content, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  // 从文件读取
  static Future<String> readFromFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsString();
  }
}
