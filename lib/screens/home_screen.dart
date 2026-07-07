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

  List<Category> categories = [
  Category(name: "Дом", iconCode: Icons.home.codePoint, templates: ["Убраться", "Постирать белье"]),
  Category(name: "Работа", iconCode: Icons.work.codePoint, templates: ["Отчет", "Встреча"]),
];

  // 1. Метод сохранения категорий
Future<void> _saveCategories() async {
  final prefs = await SharedPreferences.getInstance();
  // Превращаем список объектов Category в список Map, а затем в строку JSON
  final encoded = json.encode(categories.map((c) => c.toJson()).toList());
  await prefs.setString('categories_list', encoded);
}

// 2. Метод загрузки категорий
Future<void> _loadCategories() async {
  final prefs = await SharedPreferences.getInstance();
  final catsString = prefs.getString('categories_list');
  if (catsString != null) {
    setState(() {
      final List<dynamic> decoded = json.decode(catsString);
      categories = decoded.map((item) => Category.fromJson(item)).toList();
    });
  }
}

// 3. Вызов _loadCategories в initState
@override
void initState() {
  super.initState();
  _loadData();
  _loadCategories();
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
  void _addTask(String title, int exp, TaskDifficulty diff, String? categoryName, int? categoryIconCode) {
    setState(() {
      tasks.add(Task(
        id: DateTime.now().toString(),
        title: title,
        experience: exp,
        difficulty: diff,
        categoryName: categoryName, // Передаем новые данные
        categoryIconCode: categoryIconCode,
      ));
      _saveData();
    });
  }

  void _toggleTask(int index) {
  setState(() {
    final task = tasks[index];
    task.isCompleted = !task.isCompleted;
    
    // Если задача выполнена, запоминаем время, иначе обнуляем
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    
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

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Удалить задачу?"),
        // Используем название задачи в тексте сообщения
        content: Text('Вы действительно хотите удалить задачу "${task.title}"? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Отмена")
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tasks.remove(task); // Удаляем объект напрямую из списка
                _saveData();
              });
              Navigator.pop(ctx);
            },
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Opacity(
      opacity: task.isCompleted ? 0.5 : 1.0,
      child: Card(
        color: getDifficultyColor(task.difficulty),
        child: ListTile(
          onTap: () => _toggleTask(tasks.indexOf(task)),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => _toggleTask(tasks.indexOf(task)),
          ),
          // Используем Align или просто заменяем title на Column, если нужно много места
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
            // Эти параметры позволяют тексту переноситься на новые строки
            softWrap: true,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${task.experience} XP"),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteTask(task),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    // 1. Расчеты уровней
    final currentLevel = LevelUtils.getLevelFromXP(xp);
    final currentLevelXp = LevelUtils.getXpInCurrentLevel(xp);
    final requiredForNext = LevelUtils.getRequiredXP(currentLevel);

    final pending = pendingXp;
    final xpAfterCleanup = xp + pending;
    final targetLevel = LevelUtils.getLevelFromXP(xpAfterCleanup);

    // 2. Разделение задач для отображения
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // Невыполненные как раньше (новые сверху)

    final completedTasks = tasks.where((t) => t.isCompleted).toList()
      ..sort((a, b) => (a.completedAt ?? DateTime(0))
          .compareTo(b.completedAt ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("RPG Task Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _deleteCompletedTasks,
            tooltip: "Сдать задачи",
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
                    LinearProgressIndicator(
                      value: ((currentLevelXp + pending) / requiredForNext).clamp(0.0, 1.0),
                      minHeight: 12,
                      color: Colors.orange.withOpacity(0.7),
                      backgroundColor: Colors.grey[300],
                    ),
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
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // Список невыполненных
                ...incompleteTasks.map((t) => _buildTaskTile(t)),
                
                // Разделитель
                if (incompleteTasks.isNotEmpty && completedTasks.isNotEmpty)
                  const Divider(thickness: 2, color: Colors.indigo),
                if (completedTasks.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text("Выполнено", style: TextStyle(color: Colors.grey)),
                  ),
                
                // Список выполненных
                ...completedTasks.map((t) => _buildTaskTile(t)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddTaskScreen(
            onAdd: _addTask, // Теперь сигнатура метода совпадает!
            categories: categories,
            onUpdateCategories: (newCats) {
              setState(() {
                categories = newCats;
                _saveCategories(); // Сохраняем при каждом изменении!
              });
            },
          )),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}