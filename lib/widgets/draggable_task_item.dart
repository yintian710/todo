import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';
import 'task_item.dart';

class DraggableTaskItem extends StatelessWidget {
  final Task task;
  final Color boardColor;
  final int boardId;

  const DraggableTaskItem({
    Key? key,
    required this.task,
    required this.boardColor,
    required this.boardId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            task.title,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: TaskItem(
        task: task,
        boardColor: boardColor,
        boardId: boardId,
      ),
    );
  }
}
