class Task {
  final int? id;
  final int boardId;
  final String title;
  final bool isCompleted;
  final int sortOrder;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? firstCompletedAt;
  final DateTime? completedAt;

  Task({
    this.id,
    required this.boardId,
    required this.title,
    this.isCompleted = false,
    required this.sortOrder,
    this.deadline,
    DateTime? createdAt,
    this.firstCompletedAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'first_completed_at': firstCompletedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      boardId: map['board_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      firstCompletedAt: map['first_completed_at'] != null
          ? DateTime.parse(map['first_completed_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Task copyWith({
    int? id,
    int? boardId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? createdAt,
    DateTime? firstCompletedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      createdAt: createdAt ?? this.createdAt,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // 获取倒计时状态
  DeadlineStatus get deadlineStatus {
    if (deadline == null) return DeadlineStatus.none;
    if (isCompleted) return DeadlineStatus.none;

    final now = DateTime.now();
    if (now.isAfter(deadline!)) {
      return DeadlineStatus.overdue;
    }
    return DeadlineStatus.active;
  }

  // 获取剩余时间（秒）
  int? get remainingSeconds {
    if (deadline == null) return null;
    final now = DateTime.now();
    return deadline!.difference(now).inSeconds;
  }
}

enum DeadlineStatus {
  none,
  active,
  overdue,
}
