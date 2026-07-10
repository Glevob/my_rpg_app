// lib/utils/task_utils.dart
import 'package:flutter/material.dart';
import '../models/task.dart';

const Map<TaskDifficulty, String> difficultyNames = {
  TaskDifficulty.easy: 'Простая',
  TaskDifficulty.medium: 'Средняя',
  TaskDifficulty.hard: 'Сложная',
  TaskDifficulty.legendary: 'Легендарная',
};

const Map<TaskDifficulty, int> difficultyXpMap = {
  TaskDifficulty.easy: 10,
  TaskDifficulty.medium: 50,
  TaskDifficulty.hard: 100,
  TaskDifficulty.legendary: 250,
};

Color getDifficultyColor(TaskDifficulty difficulty) {
  switch (difficulty) {
    case TaskDifficulty.easy: return Colors.white;
    case TaskDifficulty.medium: return Colors.grey.shade300;
    case TaskDifficulty.hard: return Colors.red.shade200;
    case TaskDifficulty.legendary: return Colors.purple.shade200;
  }
}