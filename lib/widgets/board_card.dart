import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/board.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';
import '../widgets/draggable_task_item.dart';
import '../pages/board_window_page.dart';

class BoardCard extends StatefulWidget {
  final Board board;
  final int index;

  const BoardCard({
    Key? key,
    required this.board,
    required this.index,
  }) : super(key: key);

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> {
  bool _isAddingTask = false;
  final _taskTitleController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _taskTitleController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _sortByDeadline() {
    context.read<TodoProvider>().sortTasksByDeadline(widget.board.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已按倒计时排序'), duration: Duration(seconds: 1)),
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

  void _startAddingTask() {
    setState(() {
      _isAddingTask = true;
    });
    // 延迟聚焦，确保组件已完全构建
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _cancelAddingTask() {
    if (mounted) {
      setState(() {
        _isAddingTask = false;
        _taskTitleController.clear();
      });
    }
  }

  Future<void> _submitTask() async {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty) {
      _cancelAddingTask();
      return;
    }

    final provider = context.read<TodoProvider>();
    await provider.createTask(widget.board.id!, title);

    if (mounted) {
      setState(() {
        _taskTitleController.clear();
        _isAddingTask = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: (node, event) {
        // Ctrl+Enter 快捷键启动添加任务
        if (event is RawKeyDownEvent &&
            event.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !_isAddingTask) {
          _startAddingTask();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          final tasks = provider.getTasksForBoard(widget.board.id!);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 工作板标题栏 - 只有标题栏可拖拽
                ReorderableDragStartListener(
                  index: widget.index,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.board.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.drag_indicator,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.board.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '${tasks.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 倒计时排序按钮
                        IconButton(
                          icon: const Icon(Icons.sort, color: Colors.white),
                          tooltip: '按倒计时排序',
                          onPressed: _sortByDeadline,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            switch (value) {
                              case 'window':
                                _openBoardWindow();
                                break;
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
                          itemBuilder: (context) => [
                            if (Platform.isWindows ||
                                Platform.isLinux ||
                                Platform.isMacOS)
                              const PopupMenuItem(
                                value: 'window',
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_new),
                                    SizedBox(width: 8),
                                    Text('单独窗口'),
                                  ],
                                ),
                              ),
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
                        ),
                      ],
                    ),
                  ),
                ),

                // 任务列表
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      children: [
                        // 快速添加任务
                        if (_isAddingTask)
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: widget.board.color),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: RawKeyboardListener(
                              focusNode: FocusNode(),
                              onKey: (RawKeyEvent event) {
                                if (event is RawKeyDownEvent) {
                                  // Esc 取消
                                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                                    _cancelAddingTask();
                                  }
                                  // Ctrl+Enter 换行（TextField 默认处理）
                                  // 普通 Enter 提交
                                  else if (event.logicalKey == LogicalKeyboardKey.enter &&
                                      !event.isControlPressed) {
                                    _submitTask();
                                  }
                                }
                              },
                              child: TextField(
                                controller: _taskTitleController,
                                focusNode: _focusNode,
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: '输入任务内容，回车确认，Ctrl+Enter换行，Esc取消',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: _startAddingTask,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '添加任务 (Ctrl+Enter)',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 任务列表
                        Expanded(
                          child: DragTarget<Task>(
                            onWillAccept: (task) => task != null,
                            onAccept: (task) {
                              // 跨工作板拖拽
                              if (task.boardId != widget.board.id!) {
                                provider.moveTaskToBoard(task, widget.board.id!);
                              }
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                color: candidateData.isNotEmpty
                                    ? widget.board.color.withOpacity(0.1)
                                    : Colors.grey.shade50,
                                child: tasks.isEmpty
                                    ? Center(
                                        child: Text(
                                          '还没有任务',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        itemCount: tasks.length,
                                        itemBuilder: (context, index) {
                                          final task = tasks[index];
                                          return _DraggableTaskWrapper(
                                            key: ValueKey(task.id),
                                            task: task,
                                            boardColor: widget.board.color,
                                            boardId: widget.board.id!,
                                            index: index,
                                            totalTasks: tasks.length,
                                          );
                                        },
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 可拖拽任务包装器，支持精确插入位置
class _DraggableTaskWrapper extends StatelessWidget {
  final Task task;
  final Color boardColor;
  final int boardId;
  final int index;
  final int totalTasks;

  const _DraggableTaskWrapper({
    Key? key,
    required this.task,
    required this.boardColor,
    required this.boardId,
    required this.index,
    required this.totalTasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TodoProvider>();

    return DragTarget<Task>(
      onWillAccept: (draggedTask) {
        // 接受任何任务，包括同板和跨板
        return draggedTask != null && draggedTask.id != task.id;
      },
      onAccept: (draggedTask) {
        if (draggedTask.boardId == boardId) {
          // 同板内拖拽 - 重新排序
          final tasks = provider.getTasksForBoard(boardId);
          final oldIndex = tasks.indexWhere((t) => t.id == draggedTask.id);
          if (oldIndex != -1 && oldIndex != index) {
            provider.reorderTasks(boardId, oldIndex, index);
          }
        } else {
          // 跨板拖拽 - 移动到目标板
          provider.moveTaskToBoard(draggedTask, boardId);
          // 移动后，将任务重排到当前位置
          Future.delayed(const Duration(milliseconds: 100), () {
            final tasks = provider.getTasksForBoard(boardId);
            final newIndex = tasks.indexWhere((t) => t.id == draggedTask.id);
            if (newIndex != -1 && newIndex != index) {
              provider.reorderTasks(boardId, newIndex, index);
            }
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return Column(
          children: [
            // 拖拽时显示插入指示器
            if (isHovering)
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: boardColor,
              ),
            // 实际的任务项
            DraggableTaskItem(
              task: task,
              boardColor: boardColor,
              boardId: boardId,
            ),
          ],
        );
      },
    );
  }
}
