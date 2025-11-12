import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/todo_provider.dart';

class AddBoardDialog extends StatefulWidget {
  const AddBoardDialog({Key? key}) : super(key: key);

  @override
  State<AddBoardDialog> createState() => _AddBoardDialogState();
}

class _AddBoardDialogState extends State<AddBoardDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _createBoard() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入工作板名称')),
      );
      return;
    }

    context
        .read<TodoProvider>()
        .createBoard(_nameController.text.trim(), _selectedColor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建工作板'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '工作板名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _createBoard(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('选择颜色'),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
            onTap: _pickColor,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createBoard,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
