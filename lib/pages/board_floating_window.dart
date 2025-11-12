import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../models/board.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';

class BoardFloatingWindow extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BoardFloatingWindow({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  @override
  State<BoardFloatingWindow> createState() => _BoardFloatingWindowState();
}

class _BoardFloatingWindowState extends State<BoardFloatingWindow> with WindowListener {
  bool _isAlwaysOnTop = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initWindow() async {
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    await windowManager.setTitle('${widget.arguments['boardName']} - 浮窗');
  }

  Future<void> _toggleAlwaysOnTop() async {
    setState(() {
      _isAlwaysOnTop = !_isAlwaysOnTop;
    });
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
  }

  @override
  Widget build(BuildContext context) {
    final boardId = widget.arguments['boardId'] as int;
    final boardName = widget.arguments['boardName'] as String;
    final boardColor = Color(widget.arguments['boardColor'] as int);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: boardColor, width: 2),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              decoration: BoxDecoration(
                color: boardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      boardName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 置顶按钮
                  IconButton(
                    icon: Icon(
                      _isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _toggleAlwaysOnTop,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: _isAlwaysOnTop ? '取消置顶' : '置顶',
                  ),
                  const SizedBox(width: 8),
                  // 关闭按钮
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () async {
                      await windowManager.close();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // 任务列表
            Expanded(
              child: Consumer<TodoProvider>(
                builder: (context, provider, child) {
                  final tasks = provider.getTasksForBoard(boardId);

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        '还没有任务',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _CompactTaskItem(
                        task: task,
                        boardColor: boardColor,
                        boardId: boardId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 紧凑型任务项
class _CompactTaskItem extends StatelessWidget {
  final Task task;
  final Color boardColor;
  final int boardId;

  const _CompactTaskItem({
    Key? key,
    required this.task,
    required this.boardColor,
    required this.boardId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TodoProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: task.isCompleted ? Colors.grey.shade300 : boardColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 复选框
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: task.isCompleted,
              onChanged: (_) {
                provider.toggleTaskCompletion(task);
              },
              activeColor: boardColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          // 任务内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任务标题
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 11,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 倒计时信息
                if (task.deadline != null) ...[
                  const SizedBox(height: 2),
                  _buildCompactDeadline(task.deadline!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    final isOverdue = difference.isNegative;

    String timeText;
    Color timeColor;

    if (isOverdue) {
      final overdueDuration = now.difference(deadline);
      if (overdueDuration.inDays > 0) {
        timeText = '超时 ${overdueDuration.inDays}天';
      } else if (overdueDuration.inHours > 0) {
        timeText = '超时 ${overdueDuration.inHours}小时';
      } else {
        timeText = '超时 ${overdueDuration.inMinutes}分钟';
      }
      timeColor = Colors.red;
    } else {
      if (difference.inDays > 0) {
        timeText = '剩余 ${difference.inDays}天';
        timeColor = difference.inDays <= 1 ? Colors.orange : Colors.green;
      } else if (difference.inHours > 0) {
        timeText = '剩余 ${difference.inHours}小时';
        timeColor = Colors.orange;
      } else {
        timeText = '剩余 ${difference.inMinutes}分钟';
        timeColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 10, color: timeColor),
          const SizedBox(width: 2),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 9,
              color: timeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
