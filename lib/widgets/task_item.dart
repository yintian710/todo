import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/set_deadline_dialog.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final Color boardColor;
  final int boardId;
  final bool readOnly;

  const TaskItem({
    Key? key,
    required this.task,
    required this.boardColor,
    required this.boardId,
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
    _startTimer();
  }

  @override
  void didUpdateWidget(TaskItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果任务状态或截止时间变化，重新启动定时器
    if (oldWidget.task.isCompleted != widget.task.isCompleted ||
        oldWidget.task.deadline != widget.task.deadline) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateCountdown();
    // 只在有截止时间且未完成时启动定时器
    if (widget.task.deadline != null && !widget.task.isCompleted) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted) {
            _updateCountdown();
          }
        },
      );
    }
  }

  void _restartTimer() {
    _countdownTimer?.cancel();
    _startTimer();
  }

  void _updateCountdown() {
    if (widget.task.deadline == null || widget.task.isCompleted) {
      if (_countdownText.isNotEmpty) {
        setState(() {
          _countdownText = '';
        });
      }
      return;
    }

    final now = DateTime.now();
    final deadline = widget.task.deadline!;
    final difference = deadline.difference(now);

    String newText;
    if (difference.isNegative) {
      // 已超时 - 显示红色
      final overdue = now.difference(deadline);
      final minutes = overdue.inMinutes;
      final seconds = overdue.inSeconds % 60;
      newText = '-${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      // 未超时 - 显示剩余时间
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      newText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    if (_countdownText != newText) {
      setState(() {
        _countdownText = newText;
      });
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.task.isCompleted
              ? Colors.grey.shade100
              : (isOverdue ? Colors.red.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: taskColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (!widget.readOnly) {
                context
                    .read<TodoProvider>()
                    .toggleTaskCompletion(widget.task);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      color: widget.task.isCompleted
                          ? taskColor
                          : Colors.transparent,
                      border: Border.all(
                        color: taskColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: widget.task.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),

                  // 任务内容
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.task.isCompleted
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),

                  // 倒计时显示
                  if (_countdownText.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _countdownText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red.shade900 : Colors.orange.shade900,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
