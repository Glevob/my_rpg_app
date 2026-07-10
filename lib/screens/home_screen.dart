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

  void _checkLevelUp(int oldXp, int newXp) {
    final oldLevel = LevelUtils.getLevelFromXP(oldXp);
    final newLevel = LevelUtils.getLevelFromXP(newXp);

    if (newLevel > oldLevel) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Поздравляем!"),
          content: Text("Вы перешли на новый уровень!\n\nУровень $oldLevel -> $newLevel"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Круто!"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadData();
    await _loadCategories();
    _processRecurringTasks();
  }

  // --- ЛОГИКА ПОВТОРЯЮЩИХСЯ ЗАДАЧ ---
  void _processRecurringTasks() {
    bool changed = false;
    DateTime now = DateTime.now();
    int earnedXp = 0;

    // Ищем все выполненные задачи
    for (var task in tasks.where((t) => t.isCompleted).toList()) {
      
      // ЛОГИКА АВТО-СДАЧИ:
      // Если задача выполнена, мы забираем опыт и удаляем её (или обновляем, если повторяющаяся)
      
      // 1. Начисляем опыт за выполненную задачу
      earnedXp += task.experience;

      // 2. Если задача повторяющаяся, создаем её копию на следующий цикл
      if (task.recurrence != Recurrence.none) {
        DateTime nextDueDate = _calculateNextDueDate(task); // Нужно реализовать этот метод
        tasks.add(Task(
          id: DateTime.now().millisecondsSinceEpoch.toString() + task.title,
          title: task.title,
          experience: task.experience,
          difficulty: task.difficulty,
          categoryName: task.categoryName,
          categoryIconCode: task.categoryIconCode,
          recurrence: task.recurrence,
          isCompleted: false,
          dueDate: nextDueDate,
        ));
      }

      // 3. Удаляем старую выполненную задачу
      tasks.remove(task);
      changed = true;
    }

    if (changed) {
      setState(() {
        xp += earnedXp;
      });
      _saveData();
      if (earnedXp > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Автоматически сданы задачи! Получено опыта: $earnedXp")),
        );
      }
    }
  }

  // Вспомогательный метод для расчета следующей даты
  DateTime _calculateNextDueDate(Task task) {
    DateTime now = DateTime.now();
    
    // Вспомогательная функция, чтобы всегда получать 23:59:59 текущей даты
    DateTime endOfDay(DateTime date) {
      return DateTime(date.year, date.month, date.day, 23, 59);
    }

    switch (task.recurrence) {
      case Recurrence.daily:
        // Следующий день, 23:59
        return endOfDay(now.add(const Duration(days: 1)));
        
      case Recurrence.weekly:
        // now.weekday: 1=Пн, ..., 7=Вс
        // Чтобы всегда попадать в воскресенье следующей недели:
        // 1. Вычисляем, сколько дней осталось до конца этой недели (воскресенья): (7 - now.weekday)
        // 2. Добавляем +7 дней, чтобы гарантированно перейти в следующую неделю
        int daysToAdd = (7 - now.weekday) + 7;
        
        return endOfDay(now.add(Duration(days: daysToAdd)));
        
      case Recurrence.monthly:
        // 1. Переходим на 1-е число месяца, следующего за "месяцем исполнения"
        // (now.month + 2) дает 1-е число месяца, идущего через один после текущего
        DateTime firstDayTargetMonth = DateTime(now.year, now.month + 2, 1);
        // 2. Вычитаем 1 минуту, получаем 23:59 последнего дня того месяца
        return firstDayTargetMonth.subtract(const Duration(minutes: 1));
        
      default:
        return task.dueDate ?? now;
    }
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
  void _addTask(String title, int exp, TaskDifficulty diff, String? catName, int? catIcon, DateTime? dueDate, Recurrence recurrence) {
    setState(() {
      tasks.add(Task(
        id: DateTime.now().toString(),
        title: title,
        experience: exp,
        difficulty: diff,
        categoryName: catName,
        categoryIconCode: catIcon,
        dueDate: dueDate,
        recurrence: recurrence,
      ));
      _saveData();
    });
  }

  void _toggleTask(int index) {
    final task = tasks[index];
    if (task.isOverdue) return; // Запрет выполнения просроченных

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
        content: Text('Удалить "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
          TextButton(onPressed: () {
            setState(() => tasks.remove(task));
            _saveData();
            Navigator.pop(ctx);
          }, child: const Text("Удалить", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _updateCategories(List<Category> newCats) {
    setState(() {
      categories = newCats;
    });
    _saveCategories(); // Сохраняем в SharedPreferences каждый раз при изменении
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
    final oldXp = xp;
    final earnedXp = pendingXp;
    
    setState(() {
      xp += earnedXp;
      tasks.removeWhere((task) => task.isCompleted);
      _saveData();
    });

    // Вызываем проверку после обновления состояния
    _checkLevelUp(oldXp, xp);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Задачи сданы, опыт начислен!")),
    );
  }

  // --- ВИДЖЕТЫ ---
  Widget _buildTaskTile(Task task) {
    final dateFormat = DateFormat('dd.MM HH:mm');
    final bool overdue = task.isOverdue;

    return Card(
      color: overdue ? Colors.red[50] : getDifficultyColor(task.difficulty),
      child: ListTile(
        onTap: overdue ? null : () => _toggleTask(tasks.indexOf(task)),
        leading: Checkbox(value: task.isCompleted || overdue, onChanged: overdue ? null : (_) => _toggleTask(tasks.indexOf(task))),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: TextStyle(decoration: (task.isCompleted || overdue) ? TextDecoration.lineThrough : null)),
            if (task.dueDate != null || task.recurrence != Recurrence.none)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (task.dueDate != null) Text(dateFormat.format(task.dueDate!), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    if (task.dueDate != null && task.recurrence != Recurrence.none) const Text(" • "),
                    if (task.recurrence != Recurrence.none)
                      Text(task.recurrence.nameRu, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    if (overdue) const Text(" • ПРОСРОЧЕНО", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
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
    final pending = pendingXp; // XP за выполненные, но не сданные задачи
    final targetLevel = LevelUtils.getLevelFromXP(xp + pending);

    // Разделение и сортировка
    final incomplete = tasks.where((t) => !t.isCompleted).toList()..sort((a, b) => b.id.compareTo(a.id));
    final completed = tasks.where((t) => t.isCompleted).toList()..sort((a, b) => (a.completedAt ?? DateTime(0)).compareTo(b.completedAt ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(title: const Text("RPG Task Tracker"), actions: [
        IconButton(icon: const Icon(Icons.cleaning_services), onPressed: _performCleanup),
      ]),
      body: Column(
        children: [
          // Блок уровня и опыта
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(
                currentLevel != targetLevel 
                    ? "Уровень $currentLevel -> $targetLevel | XP: $currentLevelXp / $requiredForNext"
                    : "Уровень $currentLevel | XP: $currentLevelXp / $requiredForNext",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Stack(children: [
                LinearProgressIndicator(value: ((currentLevelXp + pending) / requiredForNext).clamp(0.0, 1.0), minHeight: 10, color: Colors.orange.withOpacity(0.7)),
                LinearProgressIndicator(value: (currentLevelXp / requiredForNext).clamp(0.0, 1.0), minHeight: 10, color: Colors.indigo, backgroundColor: Colors.transparent),
              ]),
            ]),
          ),
          
          // Список задач
          Expanded(
            child: ListView(
              children: [
                ...incomplete.map(_buildTaskTile),
                if (incomplete.isNotEmpty && completed.isNotEmpty) const Divider(thickness: 2),
                ...completed.map((t) => Opacity(opacity: 0.5, child: _buildTaskTile(t))), // Тусклые выполненные
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(
          onAdd: _addTask,
          categories: categories,
          onUpdateCategories: (newCats) => setState(() {
            categories = newCats;
            _saveCategories();
          }),
        ))),
        child: const Icon(Icons.add),
      ),
    );
  }
}