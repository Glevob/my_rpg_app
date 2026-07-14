import '../models/achievement.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementManager {
  // Список всех достижений
  static List<Achievement> achievements = [
    Achievement(
      id: "tasks_done",
      title: "Задачник",
      levelTitles: ["Ученик", "Мастер", "Гуру"],
      thresholds: [10, 50, 100],
    ),
  ];

  // Проверка прогресса
  static Future<bool> checkAchievement(Achievement ach, int newValue) async {
    // 1. Обновляем значение
    ach.currentProgress = newValue;
    
    // 2. Сохраняем прогресс КАЖДЫЙ раз, когда он меняется
    await saveAchievementLevel(ach); 
    
    // 3. Проверяем повышение уровня
    if (ach.currentLevel < ach.thresholds.length && 
        ach.currentProgress >= ach.thresholds[ach.currentLevel]) {
      ach.currentLevel++;
      await saveAchievementLevel(ach); // Сохраняем и новый уровень
      return true; // Уровень повышен!
    }
    return false;
  }

  // Сохранение уровня конкретного достижения
  static Future<void> saveAchievementLevel(Achievement ach) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ach_level_${ach.id}', ach.currentLevel);
    await prefs.setInt('ach_progress_${ach.id}', ach.currentProgress); // если используете прогресс
  }

  // Загрузка всех уровней при старте
  static Future<void> loadAllAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (var ach in achievements) {
      ach.currentLevel = prefs.getInt('ach_level_${ach.id}') ?? 0;
      ach.currentProgress = prefs.getInt('ach_progress_${ach.id}') ?? 0;
    }
  }
}