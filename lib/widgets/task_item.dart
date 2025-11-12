import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/set_deadline_dialog.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final Color boardColor;
  final bool readOnly;

  const TaskItem({
    Key? key,
    required this.task,
    required this.boardColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  Timer? _countdownTimer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    if (widget.task.deadline != null && !widget.task.isCompleted) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateCountdown(),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (widget.task.deadline == null || widget.task.isCompleted) {
      setState(() {
        _countdownText = '';
      });
      return;
    }

    final now = DateTime.now();
    final deadline = widget.task.deadline!;
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final overdue = now.difference(deadline);
      if (overdue.inDays > 0) {
        setState(() {
          _countdownText = '已超时 ${overdue.inDays}天';
        });
      } else if (overdue.inHours > 0) {
        setState(() {
          _countdownText = '已超时 ${overdue.inHours}小时';
        });
      } else if (overdue.inMinutes > 0) {
        setState(() {
          _countdownText = '已超时 ${overdue.inMinutes}分钟';
        });
      } else {
        setState(() {
          _countdownText = '已超时';
        });
      }
    } else {
      if (difference.inDays > 0) {
        setState(() {
          _countdownText =
              '${difference.inDays}天 ${difference.inHours % 24}小时';
        });
      } else if (difference.inHours > 0) {
        setState(() {
          _countdownText =
              '${difference.inHours}小时 ${difference.inMinutes % 60}分钟';
        });
      } else if (difference.inMinutes > 0) {
        setState(() {
          _countdownText =
              '${difference.inMinutes}分钟 ${difference.inSeconds % 60}秒';
        });
      } else {
        setState(() {
          _countdownText = '${difference.inSeconds}秒';
        });
      }
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    if (widget.readOnly) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'deadline',
          child: Row(
            children: [
              Icon(Icons.access_time),
              SizedBox(width: 8),
              Text('设置倒计时'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.info),
              SizedBox(width: 8),
              Text('查看详情'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'deadline':
          _showSetDeadlineDialog();
          break;
        case 'detail':
          _showTaskDetail();
          break;
        case 'delete':
          _deleteTask();
          break;
      }
    });
  }

  void _showSetDeadlineDialog() {
    showDialog(
      context: context,
      builder: (context) => SetDeadlineDialog(task: widget.task),
    );
  }

  void _showTaskDetail() {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(task: widget.task),
    );
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除任务 "${widget.task.title}" 吗?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<TodoProvider>()
                    .deleteTask(widget.task.boardId, widget.task.id!);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Color _getTaskColor() {
    if (widget.task.isCompleted) {
      return Colors.grey;
    }

    if (widget.task.deadlineStatus == DeadlineStatus.overdue) {
      return Colors.red;
    }

    return widget.boardColor;
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = _getTaskColor();
    final isOverdue = widget.task.deadlineStatus == DeadlineStatus.overdue;

    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      onLongPress: () {
        // 移动端长按显示菜单
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero);
        _showContextMenu(context, position);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.task.isCompleted
              ? Colors.grey.shade200
              : (isOverdue ? Colors.red.shade50 : Colors.white),
          border: Border(
            left: BorderSide(
              color: taskColor,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          leading: Checkbox(
            value: widget.task.isCompleted,
            onChanged: widget.readOnly
                ? null
                : (value) {
                    context
                        .read<TodoProvider>()
                        .toggleTaskCompletion(widget.task);
                  },
            activeColor: taskColor,
          ),
          title: Text(
            widget.task.title,
            style: TextStyle(
              decoration: widget.task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: widget.task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: _countdownText.isNotEmpty
              ? Text(
                  _countdownText,
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          trailing: widget.task.deadline != null
              ? Icon(
                  Icons.access_time,
                  color: isOverdue ? Colors.red : Colors.orange,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}
