import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

// Имена сложностей оставляем константой
const Map<TaskDifficulty, String> difficultyNames = {
  TaskDifficulty.easy: 'Простая',
  TaskDifficulty.medium: 'Средняя',
  TaskDifficulty.hard: 'Сложная',
  TaskDifficulty.legendary: 'Легендарная',
};

// Переменная для XP, которая будет меняться
Map<TaskDifficulty, int> difficultyXpMap = {
  TaskDifficulty.easy: 10,
  TaskDifficulty.medium: 50,
  TaskDifficulty.hard: 100,
  TaskDifficulty.legendary: 250,
};

// Функция для загрузки настроек при старте приложения
Future<void> loadXpSettings() async {
  final prefs = await SharedPreferences.getInstance();
  for (var d in TaskDifficulty.values) {
    // Если значения нет в памяти, оставляем дефолтное
    difficultyXpMap[d] = prefs.getInt('xp_${d.name}') ?? difficultyXpMap[d]!;
  }
}

// Функция для сохранения нового значения
Future<void> saveXpSetting(TaskDifficulty difficulty, int xp) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('xp_${difficulty.name}', xp);
  difficultyXpMap[difficulty] = xp;
}

Color getDifficultyColor(TaskDifficulty difficulty) {
  switch (difficulty) {
    case TaskDifficulty.easy: return Colors.white;
    case TaskDifficulty.medium: return Colors.grey.shade300;
    case TaskDifficulty.hard: return Colors.red.shade200;
    case TaskDifficulty.legendary: return Colors.purple.shade200;
  }
}