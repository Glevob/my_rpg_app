// lib/utils/task_utils.dart
import 'package:flutter/material.dart';
import '../models/task.dart';

const Map<TaskDifficulty, String> difficultyNames = {
  TaskDifficulty.easy: 'Простая',
  TaskDifficulty.medium: 'Средняя',
  TaskDifficulty.hard: 'Сложная',
  TaskDifficulty.legendary: 'Легендарная',
};

Color getDifficultyColor(TaskDifficulty difficulty) {
  switch (difficulty) {
    case TaskDifficulty.easy: return Colors.white;
    case TaskDifficulty.medium: return Colors.grey.shade300;
    case TaskDifficulty.hard: return Colors.red.shade200;
    case TaskDifficulty.legendary: return Colors.purple.shade200;
  }
}