import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task.dart';
import '../models/board.dart';
import '../providers/todo_provider.dart';
import '../services/export_import_service.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({Key? key}) : super(key: key);

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTime? _createdFrom;
  DateTime? _createdTo;
  DateTime? _completedFrom;
  DateTime? _completedTo;
  int? _selectedBoardId;

  List<Task> _filteredTasks = [];
  final Set<int> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  Future<void> _pickDate(
      BuildContext context, String label, Function(DateTime?) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    onPicked(date);
  }

  void _applyFilters() {
    final provider = context.read<TodoProvider>();
    final allTasks = provider.getAllTasks();

    setState(() {
      _filteredTasks = allTasks.where((task) {
        // 创建时间范围筛选
        if (_createdFrom != null && task.createdAt.isBefore(_createdFrom!)) {
          return false;
        }
        if (_createdTo != null &&
            task.createdAt.isAfter(_createdTo!.add(const Duration(days: 1)))) {
          return false;
        }

        // 完成时间范围筛选
        if (_completedFrom != null || _completedTo != null) {
          if (task.completedAt == null) return false;

          if (_completedFrom != null &&
              task.completedAt!.isBefore(_completedFrom!)) {
            return false;
          }
          if (_completedTo != null &&
              task.completedAt!
                  .isAfter(_completedTo!.add(const Duration(days: 1)))) {
            return false;
          }
        }

        // 工作板筛选
        if (_selectedBoardId != null && task.boardId != _selectedBoardId) {
          return false;
        }

        return true;
      }).toList();

      // 清除不在筛选结果中的已选任务
      _selectedTaskIds.removeWhere(
          (id) => !_filteredTasks.any((task) => task.id == id));
    });
  }

  void _toggleTaskSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedTaskIds.length == _filteredTasks.length) {
        _selectedTaskIds.clear();
      } else {
        _selectedTaskIds.clear();
        _selectedTaskIds.addAll(_filteredTasks.map((t) => t.id!));
      }
    });
  }

  Future<void> _exportAsAIPrompt() async {
    if (_selectedTaskIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个任务')),
      );
      return;
    }

    final provider = context.read<TodoProvider>();
    final selectedTasks =
        _filteredTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();

    final boardsMap = <int, Board>{};
    for (final board in provider.boards) {
      boardsMap[board.id!] = board;
    }

    final prompt = ExportImportService.generateAIPrompt(
      tasks: selectedTasks,
      boardsMap: boardsMap,
    );

    // 复制到剪贴板
    await Clipboard.setData(ClipboardData(text: prompt));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI提示词已复制到剪贴板')),
      );
    }
  }

  Future<void> _exportAsJson() async {
    if (_selectedTaskIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个任务')),
      );
      return;
    }

    final provider = context.read<TodoProvider>();
    final selectedTasks =
        _filteredTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();

    // 获取相关的工作板
    final boardIds = selectedTasks.map((t) => t.boardId).toSet();
    final boards =
        provider.boards.where((b) => boardIds.contains(b.id)).toList();

    final jsonStr = ExportImportService.exportToJson(
      boards: boards,
      tasks: selectedTasks,
    );

    // 保存文件
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出数据',
        fileName: 'todo_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        await ExportImportService.saveToFile(jsonStr, result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出任务'),
      ),
      body: Column(
        children: [
          // 筛选条件
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '筛选条件',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('创建时间从'),
                          subtitle: Text(_createdFrom?.toString().split(' ')[0] ??
                              '未设置'),
                          onTap: () => _pickDate(context, '创建时间从', (date) {
                            setState(() => _createdFrom = date);
                            _applyFilters();
                          }),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('创建时间到'),
                          subtitle:
                              Text(_createdTo?.toString().split(' ')[0] ?? '未设置'),
                          onTap: () => _pickDate(context, '创建时间到', (date) {
                            setState(() => _createdTo = date);
                            _applyFilters();
                          }),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('完成时间从'),
                          subtitle: Text(
                              _completedFrom?.toString().split(' ')[0] ?? '未设置'),
                          onTap: () => _pickDate(context, '完成时间从', (date) {
                            setState(() => _completedFrom = date);
                            _applyFilters();
                          }),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('完成时间到'),
                          subtitle: Text(
                              _completedTo?.toString().split(' ')[0] ?? '未设置'),
                          onTap: () => _pickDate(context, '完成时间到', (date) {
                            setState(() => _completedTo = date);
                            _applyFilters();
                          }),
                        ),
                      ),
                    ],
                  ),
                  Consumer<TodoProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<int?>(
                        value: _selectedBoardId,
                        decoration: const InputDecoration(
                          labelText: '工作板',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('全部'),
                          ),
                          ...provider.boards.map((board) {
                            return DropdownMenuItem(
                              value: board.id,
                              child: Text(board.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedBoardId = value);
                          _applyFilters();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 任务列表
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    title: Text('筛选结果 (${_filteredTasks.length} 个任务)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('已选 ${_selectedTaskIds.length}'),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _toggleSelectAll,
                          child: Text(_selectedTaskIds.length ==
                                  _filteredTasks.length
                              ? '取消全选'
                              : '全选'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _filteredTasks.isEmpty
                        ? const Center(child: Text('无符合条件的任务'))
                        : Consumer<TodoProvider>(
                            builder: (context, provider, child) {
                              final boardsMap = <int, Board>{};
                              for (final board in provider.boards) {
                                boardsMap[board.id!] = board;
                              }

                              return ListView.builder(
                                itemCount: _filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = _filteredTasks[index];
                                  final board = boardsMap[task.boardId];

                                  return CheckboxListTile(
                                    value: _selectedTaskIds.contains(task.id),
                                    onChanged: (_) =>
                                        _toggleTaskSelection(task.id!),
                                    title: Text(task.title),
                                    subtitle: Text(
                                      '${board?.name ?? "未知工作板"} - ${task.isCompleted ? "已完成" : "未完成"}',
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 导出按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportAsAIPrompt,
                    icon: const Icon(Icons.content_copy),
                    label: const Text('生成AI提示词'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportAsJson,
                    icon: const Icon(Icons.save),
                    label: const Text('导出JSON'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
