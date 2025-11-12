import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_item.dart';

class BoardWindowPage extends StatefulWidget {
  final Board board;

  const BoardWindowPage({
    Key? key,
    required this.board,
  }) : super(key: key);

  @override
  State<BoardWindowPage> createState() => _BoardWindowPageState();
}

class _BoardWindowPageState extends State<BoardWindowPage> {
  @override
  void initState() {
    super.initState();
    // 如果使用 window_manager，可以在这里设置窗口置顶
    // 由于我们没有为每个窗口单独管理，暂时不实现
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.board.name),
        backgroundColor: widget.board.color,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          final tasks = provider.getTasksForBoard(widget.board.id!);

          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                '还没有任务',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskItem(
                key: ValueKey(task.id),
                task: task,
                boardColor: widget.board.color,
                boardId: widget.board.id!,
                readOnly: true, // 单独窗口只能勾选完成
              );
            },
          );
        },
      ),
    );
  }
}
