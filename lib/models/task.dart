// lib/models/task.dart
import 'package:flutter/material.dart';

enum TaskDifficulty { easy, medium, hard, legendary }
enum Recurrence { none, daily, weekly, monthly }
extension RecurrenceExtension on Recurrence {
  String get nameRu {
    switch (this) {
      case Recurrence.none: return "Нет";
      case Recurrence.daily: return "Ежедневно";
      case Recurrence.weekly: return "Еженедельно";
      case Recurrence.monthly: return "Ежемесячно";
      default: return "";
    }
  }
}

class Category {
  String name;
  int iconCode;
  List<String> templates;

  Category({required this.name, required this.iconCode, required this.templates});

  Map<String, dynamic> toJson() => {'name': name, 'iconCode': iconCode, 'templates': templates};
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'],
    iconCode: json['iconCode'],
    templates: List<String>.from(json['templates']),
  );
}

class Task {
  String id;
  String title;
  int experience;
  bool isCompleted;
  TaskDifficulty difficulty;
  DateTime? completedAt;
  String? categoryName;
  int? categoryIconCode;
  DateTime? dueDate;
  Recurrence recurrence;
  bool get isOverdue {
    return dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
  }

  Task({
    required this.id, required this.title, required this.experience,
    this.isCompleted = false, this.difficulty = TaskDifficulty.easy,
    this.completedAt, this.categoryName, this.categoryIconCode,
    this.dueDate, this.recurrence = Recurrence.none,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'experience': experience, 'isCompleted': isCompleted,
    'difficulty': difficulty.index, 'completedAt': completedAt?.toIso8601String(),
    'categoryName': categoryName, 'categoryIconCode': categoryIconCode,
    'dueDate': dueDate?.toIso8601String(), 'recurrence': recurrence.index,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] ?? DateTime.now().toString(),
    title: json['title'], experience: json['experience'],
    isCompleted: json['isCompleted'] ?? false,
    difficulty: TaskDifficulty.values[json['difficulty'] ?? 0],
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    categoryName: json['categoryName'], categoryIconCode: json['categoryIconCode'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    recurrence: Recurrence.values[json['recurrence'] ?? 0],
  );
}