import 'package:flutter/material.dart';
import '../utils/achievement_manager.dart';

class AchievementsScreen extends StatelessWidget {
  // Добавляем эти поля, чтобы конструктор их принимал
  final int totalTasks;
  final int currentLevel;

  const AchievementsScreen({
    super.key, 
    required this.totalTasks, 
    required this.currentLevel,
  });

  String getProgressSuffix(String id) {
    switch (id) {
      case 'xp_collector':
        return "опыта";
      case 'tasks_done':
      default:
        return "задач";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Мои достижения")),
      body: ListView.builder(
        itemCount: AchievementManager.achievements.length,
        itemBuilder: (context, index) {
          final ach = AchievementManager.achievements[index];
          
          // Рассчитываем прогресс (предотвращаем деление на ноль)
          final int maxThreshold = ach.thresholds.isNotEmpty ? ach.thresholds[ach.currentLevel >= ach.thresholds.length ? ach.thresholds.length - 1 : ach.currentLevel] : 1;
          final double progressValue = (ach.currentProgress / maxThreshold).clamp(0.0, 1.0);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(
                Icons.emoji_events, 
                color: ach.currentLevel > 0 ? Colors.amber : Colors.grey[400],
                size: 40,
              ),
              title: Text(ach.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text("Уровень: ${ach.currentLevel > 0 ? ach.levelTitles[ach.currentLevel - 1] : 'Начальный'}"),
                  const SizedBox(height: 5),
                  // Полоска прогресса
                  LinearProgressIndicator(value: progressValue, backgroundColor: Colors.grey[200]),
                  Text("${ach.currentProgress} / $maxThreshold ${getProgressSuffix(ach.id)}"),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}