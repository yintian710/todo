import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;

  const TaskDetailDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return AlertDialog(
      title: const Text('任务详情'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('任务内容', task.title),
            const Divider(),
            _buildDetailRow('状态', task.isCompleted ? '已完成' : '未完成'),
            const Divider(),
            _buildDetailRow('创建时间', dateFormat.format(task.createdAt)),
            if (task.firstCompletedAt != null) ...[
              const Divider(),
              _buildDetailRow(
                '首次完成时间',
                dateFormat.format(task.firstCompletedAt!),
              ),
            ],
            if (task.completedAt != null) ...[
              const Divider(),
              _buildDetailRow(
                '最近完成时间',
                dateFormat.format(task.completedAt!),
              ),
            ],
            if (task.deadline != null) ...[
              const Divider(),
              _buildDetailRow(
                '截止时间',
                dateFormat.format(task.deadline!),
              ),
              const Divider(),
              _buildDetailRow(
                '倒计时状态',
                _getDeadlineStatusText(),
                statusColor: _getDeadlineStatusColor(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  String _getDeadlineStatusText() {
    if (task.deadline == null) return '无';
    if (task.isCompleted) return '已完成';

    final now = DateTime.now();
    if (now.isAfter(task.deadline!)) {
      final overdue = now.difference(task.deadline!);
      return '已超时 ${_formatDuration(overdue)}';
    } else {
      final remaining = task.deadline!.difference(now);
      return '剩余 ${_formatDuration(remaining)}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天 ${duration.inHours % 24}小时';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时 ${duration.inMinutes % 60}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  Color? _getDeadlineStatusColor() {
    if (task.deadline == null || task.isCompleted) return null;

    final now = DateTime.now();
    if (now.isAfter(task.deadline!)) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
}
