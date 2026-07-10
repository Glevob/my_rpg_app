import 'package:flutter/material.dart';
import '../models/task.dart';

class StatisticsScreen extends StatelessWidget {
  final List<Task> archive;
  final int totalXp;

  const StatisticsScreen({super.key, required this.archive, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    // 1. Подсчет по категориям
    final byCategory = <String, int>{};
    for (var t in archive) {
      String cat = t.categoryName ?? "Без категории";
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;
    }

    // 2. Подсчет по сложности
    final byDifficulty = <TaskDifficulty, int>{};
    for (var t in archive) {
      byDifficulty[t.difficulty] = (byDifficulty[t.difficulty] ?? 0) + 1;
    }

    // 3. Подсчет по повторам
    final byRecurrence = <Recurrence, int>{};
    for (var t in archive) {
      byRecurrence[t.recurrence] = (byRecurrence[t.recurrence] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Статистика")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Общее"),
          _buildSummaryCard("Полный опыт", "$totalXp XP", Icons.star),
          _buildSummaryCard("Всего выполнено", "${archive.length} задач", Icons.check_circle),
          
          _buildSectionTitle("По категориям"),
          ...byCategory.entries.map((e) => _buildStatTile(e.key, "${e.value}")),
          
          _buildSectionTitle("По сложности"),
          ...byDifficulty.entries.map((e) => _buildStatTile(e.key.name.toUpperCase(), "${e.value}")),
          
          // _buildSectionTitle("По типам повторов"),
          // ...byRecurrence.entries.map((e) => _buildStatTile(e.key.nameRu.isEmpty ? "Разовые" : e.key.nameRu, "${e.value}")),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}