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
      // Только меняем статус выполнения. XP не трогаем!
      tasks[index].isCompleted = !tasks[index].isCompleted;
      _saveData();
    });
  }

  void _deleteCompletedTasks() {
    if (pendingXp == 0) return; // Если задач нет, ничего не делаем

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Подтверждение"),
          content: Text("Вы хотите сдать $pendingXp XP и удалить выполненные задачи?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Закрыть окно
              child: const Text("Нет"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть окно перед выполнением
                _performCleanup(); // Вызываем саму логику удаления
              },
              child: const Text("Да"),
            ),
          ],
        );
      },
    );
  }

  // Отдельный метод для самой логики, чтобы не дублировать код
  void _performCleanup() {
    setState(() {
      xp += pendingXp;
      tasks.removeWhere((task) => task.isCompleted);
      _saveData();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Задачи сданы, опыт начислен!")),
    );
  }

  int get pendingXp => tasks
    .where((t) => t.isCompleted)
    .fold(0, (sum, t) => sum + t.experience);

  int get xpAfterCleanup => xp + pendingXp;

  @override
  Widget build(BuildContext context) {
    // Текущий уровень и прогресс (без учета выполненных заданий)
    final currentLevel = LevelUtils.getLevelFromXP(xp);
    final currentLevelXp = LevelUtils.getXpInCurrentLevel(xp);
    final requiredForNext = LevelUtils.getRequiredXP(currentLevel);

    // Опыт, который мы "заработали", но не "применили"
    final pending = pendingXp;
    
    // Прогнозируемый уровень (для отображения "Уровень X -> Y")
    final xpAfterCleanup = xp + pending;
    final targetLevel = LevelUtils.getLevelFromXP(xpAfterCleanup);

    return Scaffold(
      appBar: AppBar(
        title: const Text("RPG Task Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _deleteCompletedTasks,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                pending > 0 ? "XP: $currentLevelXp (+$pending)" : "XP: $currentLevelXp",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                Text(
                  currentLevel != targetLevel 
                      ? "Уровень $currentLevel -> $targetLevel" 
                      : "Уровень $currentLevel",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    // Оранжевая полоса (показывает сколько будет опыта ПОСЛЕ очистки)
                    // Мы делим на requiredForNext текущего уровня, 
                    // чтобы видеть, насколько он заполнится.
                    LinearProgressIndicator(
                      value: ((currentLevelXp + pending) / requiredForNext).clamp(0.0, 1.0),
                      minHeight: 12,
                      color: Colors.orange.withOpacity(0.7),
                      backgroundColor: Colors.grey[300],
                    ),
                    // Фиолетовая полоса (текущий опыт - НИКОГДА не меняется при нажатии на задачу)
                    LinearProgressIndicator(
                      value: (currentLevelXp / requiredForNext).clamp(0.0, 1.0),
                      minHeight: 12,
                      color: Colors.indigo,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
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
                      onChanged: (_) => _toggleTask(index),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
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
          MaterialPageRoute(builder: (_) => AddTaskScreen(onAdd: _addTask)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}