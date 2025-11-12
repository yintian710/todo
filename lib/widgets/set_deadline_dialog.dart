import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';

class SetDeadlineDialog extends StatefulWidget {
  final Task task;

  const SetDeadlineDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<SetDeadlineDialog> createState() => _SetDeadlineDialogState();
}

class _SetDeadlineDialogState extends State<SetDeadlineDialog> {
  DateTime? _selectedDateTime;
  final _daysController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.task.deadline;
  }

  @override
  void dispose() {
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _setFromCountdown() {
    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;

    if (days == 0 && hours == 0 && minutes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入倒计时时间')),
      );
      return;
    }

    setState(() {
      _selectedDateTime = DateTime.now().add(
        Duration(days: days, hours: hours, minutes: minutes),
      );
    });
  }

  void _saveDeadline() {
    context.read<TodoProvider>().setTaskDeadline(widget.task, _selectedDateTime);
    Navigator.of(context).pop();
  }

  void _clearDeadline() {
    context.read<TodoProvider>().setTaskDeadline(widget.task, null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置倒计时'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '方式1: 选择具体时间',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDateTime == null
                  ? '选择日期和时间'
                  : '${_selectedDateTime!.year}-${_selectedDateTime!.month.toString().padLeft(2, '0')}-${_selectedDateTime!.day.toString().padLeft(2, '0')} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'),
            ),
            const SizedBox(height: 24),
            const Text(
              '方式2: 设置倒计时',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: '天',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: '小时',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: '分钟',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _setFromCountdown,
                child: const Text('应用倒计时'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.task.deadline != null)
          TextButton(
            onPressed: _clearDeadline,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedDateTime == null ? null : _saveDeadline,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
