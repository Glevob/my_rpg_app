// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';
import '../utils/level_utils.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int xp = 0;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- ЛОГИКА ДАННЫХ ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_xp', xp);
    await prefs.setString('tasks_list', json.encode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      xp = prefs.getInt('user_xp') ?? 0;
      final tasksString = prefs.getString('tasks_list');
      if (tasksString != null) {
        final List<dynamic> decoded = json.decode(tasksString);
        tasks = decoded.map((item) => Task.fromJson(item)).toList();
      }
    });
  }

  // --- УПРАВЛЕНИЕ ЗАДАЧАМИ ---
  void _addTask(String title, int exp, TaskDifficulty diff) {
    setState(() {
      tasks.add(Task(id: DateTime.now().toString(), title: title, experience: exp, difficulty: diff));
      _saveData();
    });
  }

  void _toggleTask(int index) {
    setState(() {
      final task = tasks[index];
      task.isCompleted = !task.isCompleted;
      xp += task.isCompleted ? task.experience : -task.experience;
      _saveData();
    });
  }

  void _deleteCompletedTasks() {
    setState(() {
      tasks.removeWhere((task) => task.isCompleted);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Вычисляем текущий уровень
    final currentLevel = LevelUtils.getLevelFromXP(xp);
    
    // 2. Считаем, сколько опыта нужно для следующего уровня
    final requiredForNext = LevelUtils.getRequiredXP(currentLevel);

    final currentLevelXp = LevelUtils.getXpInCurrentLevel(xp); // Остаток от уровня
    
    // 3. Считаем, сколько всего опыта нужно было набрать до начала текущего уровня
    int totalSpentOnPreviousLevels = 0;
    for (int i = 1; i < currentLevel; i++) {
      totalSpentOnPreviousLevels += LevelUtils.getRequiredXP(i);
    }
    
    // 4. Опыт, набранный именно на этом уровне
    final xpInCurrentLevel = xp - totalSpentOnPreviousLevels;

    return Scaffold(
      appBar: AppBar(
        title: const Text("RPG Task Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services), 
            onPressed: _deleteCompletedTasks,
            tooltip: "Удалить выполненные",
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text("XP: $currentLevelXp", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Уровень $currentLevel", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              LinearProgressIndicator(
                value: currentLevelXp / requiredForNext, 
                minHeight: 12
              ),
              Text("$currentLevelXp / $requiredForNext XP"),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  color: getDifficultyColor(task.difficulty),
                  child: ListTile(
                    onTap: () => _toggleTask(index),
                    leading: Checkbox(
                      value: task.isCompleted, 
                      onChanged: (_) => _toggleTask(index)
                    ),
                    title: Text(
                      task.title, 
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null
                      )
                    ),
                    trailing: Text("${task.experience} XP"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => AddTaskScreen(onAdd: _addTask))
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}