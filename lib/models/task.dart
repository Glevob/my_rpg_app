// lib/models/task.dart
import 'package:flutter/material.dart';

enum TaskDifficulty { easy, medium, hard, legendary }

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

  Task({
    required this.id, required this.title, required this.experience,
    this.isCompleted = false, this.difficulty = TaskDifficulty.easy,
    this.completedAt, this.categoryName, this.categoryIconCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'experience': experience, 'isCompleted': isCompleted,
    'difficulty': difficulty.index, 'completedAt': completedAt?.toIso8601String(),
    'categoryName': categoryName, 'categoryIconCode': categoryIconCode,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] ?? DateTime.now().toString(),
    title: json['title'], experience: json['experience'],
    isCompleted: json['isCompleted'] ?? false,
    difficulty: TaskDifficulty.values[json['difficulty'] ?? 0],
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    categoryName: json['categoryName'], categoryIconCode: json['categoryIconCode'],
  );
}