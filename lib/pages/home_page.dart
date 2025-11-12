import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/board_card.dart';
import '../widgets/add_board_dialog.dart';
import 'export_page.dart';
import 'import_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadData();
    });
  }

  void _showAddBoardDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddBoardDialog(),
    );
  }

  void _navigateToExport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExportPage()),
    );
  }

  void _navigateToImport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo 应用'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: '导出',
            onPressed: _navigateToExport,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导入',
            onPressed: _navigateToImport,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).pushNamed('/config');
            },
          ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '错误: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadData(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.boards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dashboard_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '还没有工作板',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击右下角按钮创建第一个工作板',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 横向排列工作板 - 支持拖拽重排
          return ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            itemCount: provider.boards.length,
            onReorder: (oldIndex, newIndex) {
              provider.reorderBoards(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final board = provider.boards[index];
              return Container(
                key: ValueKey(board.id),
                width: 380,
                margin: const EdgeInsets.only(right: 16),
                child: BoardCard(
                  board: board,
                  index: index,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBoardDialog,
        tooltip: '添加工作板',
        child: const Icon(Icons.add),
      ),
    );
  }
}
