import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class AddTaskDialog extends StatefulWidget {
  final int boardId;

  const AddTaskDialog({
    Key? key,
    required this.boardId,
  }) : super(key: key);

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务内容')),
      );
      return;
    }

    context
        .read<TodoProvider>()
        .createTask(widget.boardId, _titleController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加任务'),
      content: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: '任务内容',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        maxLines: 3,
        onSubmitted: (_) => _createTask(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('添加'),
        ),
      ],
    );
  }
}
