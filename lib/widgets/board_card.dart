import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/board.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_dialog.dart';
import '../pages/board_window_page.dart';

class BoardCard extends StatefulWidget {
  final Board board;

  const BoardCard({
    Key? key,
    required this.board,
  }) : super(key: key);

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> {
  bool _isExpanded = true;
  final _taskTitleController = TextEditingController();

  @override
  void dispose() {
    _taskTitleController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showColorPicker() {
    Color pickerColor = widget.board.color;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final provider = context.read<TodoProvider>();
                final updatedBoard = widget.board.copyWith(color: pickerColor);
                provider.updateBoard(updatedBoard);
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.board.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑工作板'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '工作板名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final provider = context.read<TodoProvider>();
                  final updatedBoard =
                      widget.board.copyWith(name: controller.text);
                  provider.updateBoard(updatedBoard);
                  Navigator.pop(context);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _deleteBoard() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除工作板 "${widget.board.name}" 及其所有任务吗?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.read<TodoProvider>().deleteBoard(widget.board.id!);
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

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(boardId: widget.board.id!),
    );
  }

  void _sortByDeadline() {
    context.read<TodoProvider>().sortTasksByDeadline(widget.board.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已按倒计时排序')),
    );
  }

  void _openBoardWindow() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BoardWindowPage(board: widget.board),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('单独窗口仅在桌面平台支持')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final tasks = provider.getTasksForBoard(widget.board.id!);

        return Card(
          color: widget.board.color.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 工作板标题栏
              Container(
                color: widget.board.color.withOpacity(0.2),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(_isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more),
                    onPressed: _toggleExpanded,
                  ),
                  title: Text(
                    widget.board.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${tasks.length} 个任务'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        tooltip: '按倒计时排序',
                        onPressed: _sortByDeadline,
                      ),
                      if (Platform.isWindows ||
                          Platform.isLinux ||
                          Platform.isMacOS)
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          tooltip: '单独窗口显示',
                          onPressed: _openBoardWindow,
                        ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'color',
                            child: Row(
                              children: [
                                Icon(Icons.color_lens),
                                SizedBox(width: 8),
                                Text('更改颜色'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('编辑名称'),
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
                        onSelected: (value) {
                          switch (value) {
                            case 'color':
                              _showColorPicker();
                              break;
                            case 'edit':
                              _showEditDialog();
                              break;
                            case 'delete':
                              _deleteBoard();
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 任务列表
              if (_isExpanded)
                Column(
                  children: [
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            '还没有任务',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderTasks(
                              widget.board.id!, oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskItem(
                            key: ValueKey(task.id),
                            task: task,
                            boardColor: widget.board.color,
                          );
                        },
                      ),

                    // 添加任务按钮
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddTaskDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('添加任务'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
