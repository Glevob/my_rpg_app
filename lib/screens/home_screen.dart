import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';
import '../utils/level_utils.dart';
import 'add_task_screen.dart';
import 'package:intl/intl.dart';

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

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(categories.map((c) => c.toJson()).toList());
    await prefs.setString('categories_list', encoded);
  }

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

  // --- УПРАВЛЕНИЕ ЗАДАЧАМИ ---
  void _addTask(String title, int exp, TaskDifficulty diff, String? categoryName, int? categoryIconCode, DateTime? dueDate, Recurrence recurrence) {
  setState(() {
    tasks.add(Task(
      id: DateTime.now().toString(),
      title: title,
      experience: exp,
      difficulty: diff,
      categoryName: categoryName,
      categoryIconCode: categoryIconCode,
      dueDate: dueDate,
      recurrence: recurrence,
    ));
    _saveData();
  });
}

  void _toggleTask(int index) {
    final task = tasks[index];
    
    // Если задача просрочена, не даем менять её статус
    if (task.isOverdue) return;

    setState(() {
      task.isCompleted = !task.isCompleted;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
      _saveData();
    });
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Удалить задачу?"),
        content: Text('Вы действительно хотите удалить задачу "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              setState(() {
                tasks.remove(task);
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

  void _deleteCompletedTasks() {
    if (pendingXp == 0) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Подтверждение"),
        content: Text("Сдать $pendingXp XP и удалить выполненные задачи?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Нет")),
          TextButton(onPressed: () {
            _performCleanup();
            Navigator.pop(context);
          }, child: const Text("Да")),
        ],
      ),
    );
  }

  void _performCleanup() {
    setState(() {
      xp += pendingXp;
      tasks.removeWhere((task) => task.isCompleted);
      _saveData();
    });
  }

  // --- ВИДЖЕТЫ ---
  Widget _buildTaskTile(Task task) {
    final dateFormat = DateFormat('dd.MM HH:mm');
    final bool overdue = task.isOverdue;

    return Card(
      color: overdue ? Colors.red[50] : getDifficultyColor(task.difficulty),
      child: ListTile(
        onTap: overdue ? null : () => _toggleTask(tasks.indexOf(task)), // Блокируем нажатие
        leading: Checkbox(
          value: task.isCompleted || overdue, // Чекбокс активен, если выполнено или просрочено
          onChanged: overdue ? null : (_) => _toggleTask(tasks.indexOf(task)),
        ),
        title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              // Зачеркиваем, если выполнено ИЛИ просрочено
              decoration: (task.isCompleted || overdue) ? TextDecoration.lineThrough : null,
              color: overdue ? Colors.red : Colors.black, // Красный текст для просроченных
              fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (overdue)
            const Text("ПРОСРОЧЕНО", style: TextStyle(fontSize: 10, color: Colors.red)),
            if (task.dueDate != null || task.recurrence != Recurrence.none)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (task.dueDate != null)
                      Text(
                        dateFormat.format(task.dueDate!),
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    if (task.dueDate != null && task.recurrence != Recurrence.none)
                      const Text(" • "),
                    if (task.recurrence != Recurrence.none)
                      Text(
                        task.recurrence.nameRu,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${task.experience} XP"),
            GestureDetector(
              onTap: () => _deleteTask(task),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  int get pendingXp => tasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + t.experience);

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelUtils.getLevelFromXP(xp);
    final currentLevelXp = LevelUtils.getXpInCurrentLevel(xp);
    final requiredForNext = LevelUtils.getRequiredXP(currentLevel);
    final pending = pendingXp;
    final targetLevel = LevelUtils.getLevelFromXP(xp + pending);

    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList()..sort((a, b) => b.id.compareTo(a.id));
    final completedTasks = tasks.where((t) => t.isCompleted).toList()..sort((a, b) => (a.completedAt ?? DateTime(0)).compareTo(b.completedAt ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("RPG Task Tracker"),
        actions: [
          IconButton(icon: const Icon(Icons.cleaning_services), onPressed: _deleteCompletedTasks),
        ],
      ),
      body: Column(
        children: [
          // Блок прогресс-бара уровня
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Уровень ${currentLevel != targetLevel ? '$currentLevel -> $targetLevel' : currentLevel}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                LinearProgressIndicator(value: (currentLevelXp / requiredForNext).clamp(0.0, 1.0), minHeight: 12),
                Text("$currentLevelXp / $requiredForNext XP"),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                ...incompleteTasks.map((t) => _buildTaskTile(t)),
                if (incompleteTasks.isNotEmpty && completedTasks.isNotEmpty) const Divider(),
                ...completedTasks.map((t) => _buildTaskTile(t)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(
          onAdd: _addTask,
          categories: categories,
          onUpdateCategories: (newCats) {
            setState(() {
              categories = newCats;
              _saveCategories();
            });
          },
        ))),
        child: const Icon(Icons.add),
      ),
    );
  }
}