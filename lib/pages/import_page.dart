import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';
import '../services/export_import_service.dart';
import '../services/database_service.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({Key? key}) : super(key: key);

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isLoading = false;
  String? _error;
  String? _selectedFilePath;
  Map<String, List<dynamic>>? _previewData;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _error = null;
        });
        await _previewImport();
      }
    } catch (e) {
      setState(() {
        _error = '选择文件失败: $e';
      });
    }
  }

  Future<void> _previewImport() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jsonStr =
          await ExportImportService.readFromFile(_selectedFilePath!);
      final data = await ExportImportService.importFromJson(jsonStr);

      setState(() {
        _previewData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '预览失败: $e';
        _isLoading = false;
        _previewData = null;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_previewData == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dbService = DatabaseService.instance;
      final provider = context.read<TodoProvider>();

      // 创建工作板ID映射（旧ID -> 新ID）
      final boardIdMap = <int, int>{};

      // 导入工作板
      final boards = _previewData!['boards'] as List<Board>;
      for (final board in boards) {
        final oldId = board.id!;
        final newBoard = Board(
          name: board.name,
          color: board.color,
          sortOrder: board.sortOrder,
          createdAt: board.createdAt,
        );
        final newId = await dbService.createBoard(newBoard);
        boardIdMap[oldId] = newId;
      }

      // 导入任务
      final tasks = _previewData!['tasks'] as List<Task>;
      for (final task in tasks) {
        final newBoardId = boardIdMap[task.boardId];
        if (newBoardId == null) continue;

        final newTask = Task(
          boardId: newBoardId,
          title: task.title,
          isCompleted: task.isCompleted,
          sortOrder: task.sortOrder,
          deadline: task.deadline,
          createdAt: task.createdAt,
          firstCompletedAt: task.firstCompletedAt,
          completedAt: task.completedAt,
        );
        await dbService.createTask(newTask);
      }

      // 重新加载数据
      await provider.loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '导入成功: ${boards.length} 个工作板, ${tasks.length} 个任务'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = '导入失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入数据'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择导入文件',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择JSON文件'),
                    ),
                    if (_selectedFilePath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '已选择: ${_selectedFilePath!.split('/').last}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_previewData != null && !_isLoading) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '预览',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '工作板数量: ${(_previewData!['boards'] as List).length}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '任务数量: ${(_previewData!['tasks'] as List).length}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '工作板列表:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount:
                                (_previewData!['boards'] as List).length,
                            itemBuilder: (context, index) {
                              final board =
                                  (_previewData!['boards'] as List<Board>)[
                                      index];
                              final taskCount = (_previewData!['tasks']
                                      as List<Task>)
                                  .where((t) => t.boardId == board.id)
                                  .length;

                              return ListTile(
                                leading: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: board.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(board.name),
                                subtitle: Text('$taskCount 个任务'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _confirmImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    '确认导入',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
