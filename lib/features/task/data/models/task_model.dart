import 'package:hive/hive.dart';
import 'package:smart_task_manager/features/task/domain/entities/task_entity.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends TaskEntity {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String title;
  @override
  @HiveField(2)
  final String description;
  @override
  @HiveField(3)
  final String priority;
  @override
  @HiveField(4)
  final String category;
  @override
  @HiveField(5)
  final DateTime dueDate;
  @override
  @HiveField(6)
  final bool isCompleted;
  @override
  @HiveField(7)
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
  }) : super(
          id: id,
          title: title,
          description: description,
          priority: priority,
          category: category,
          dueDate: dueDate,
          isCompleted: isCompleted,
          createdAt: createdAt,
        );

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'low',
      category: json['category'] ?? 'General',
      dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'due_date': dueDate.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      category: entity.category,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
    );
  }
}
