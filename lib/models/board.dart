import 'package:flutter/material.dart';

class Board {
  final int? id;
  final String name;
  final Color color;
  final int sortOrder;
  final DateTime createdAt;

  Board({
    this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Board.fromMap(Map<String, dynamic> map) {
    return Board(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Board copyWith({
    int? id,
    String? name,
    Color? color,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
