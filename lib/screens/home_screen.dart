import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';
import '../utils/level_utils.dart';
import 'add_task_screen.dart';
import 'package:intl/intl.dart';
import 'recurring_tasks_screen.dart';
import 'statistics_screen.dart';

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
  List<Task> completedArchive = [];

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

  DateTime _calculateNextOccurrence(Task task) {
    DateTime now = DateTime.now();
    switch (task.recurrence) {
      case Recurrence.daily:
        return DateTime(now.year, now.month, now.day + 1, 0, 0);
      case Recurrence.weekly:
        // Следующий понедельник 00:00
        int daysUntilMonday = 8 - now.weekday;
        return DateTime(now.year, now.month, now.day + daysUntilMonday, 0, 0);
      case Recurrence.monthly:
        // 1-е число следующего месяца 00:00
        return DateTime(now.year, now.month + 1, 1, 0, 0);
      default:
        return now;
    }
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
        // Задаче, которая была выполнена, назначаем дату следующего появления
        task.nextOccurrence = _calculateNextOccurrence(task);
        task.isCompleted = false; // Сбрасываем статус
        task.completedAt = null;
        task.dueDate = _calculateNextDueDate(task); // Новый дедлайн
        // ВАЖНО: Мы НЕ добавляем её в tasks, если она должна появиться позже
      } else {
        // РАЗОВЫЕ: ПЕРЕНОСИМ В АРХИВ
        completedArchive.add(task); 
        tasks.remove(task);
      }
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

  // Активация задач, чей день настал
  void _checkAndGenerateTasks() {
    DateTime now = DateTime.now();
    bool added = false;

    // Ищем задачи, которые были "отложены" (nextOccurrence не null и уже наступил)
    // Для этого вам нужно хранить где-то список "будущих" задач или сканировать существующие
    // Проще всего: при выполнении задачи мы НЕ удаляем её, а прячем (isCompleted = false, nextOccurrence = дата)
    
    // В данном случае, если вы храните все задачи в списке tasks:
    for (var task in tasks.where((t) => !t.isCompleted && t.nextOccurrence != null).toList()) {
      if (now.isAfter(task.nextOccurrence!)) {
        task.nextOccurrence = null; // Делаем активной
        added = true;
      }
    }
    
    if (added) setState(() {});
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
    // Сохранение архива
    await prefs.setString('archive_list', json.encode(completedArchive.map((t) => t.toJson()).toList()));
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
      // Загрузка архива
      final archiveString = prefs.getString('archive_list');
      if (archiveString != null) {
        final List<dynamic> decoded = json.decode(archiveString);
        completedArchive = decoded.map((item) => Task.fromJson(item)).toList();
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
    final earnedXp = pendingXp;
    if (earnedXp == 0) return;

    final oldXp = xp;

    setState(() {
      xp += earnedXp;
      final finishedTasks = tasks.where((t) => t.isCompleted).toList();

      for (var task in finishedTasks) {
        if (task.recurrence != Recurrence.none) {
          task.nextOccurrence = _calculateNextOccurrence(task);
          task.dueDate = _calculateNextDueDate(task);
          task.isCompleted = false;
          task.completedAt = null;
        } else {
          completedArchive.add(task); // Добавляем в архив перед удалением
          tasks.remove(task);
        }
      }
      _saveData();
    });

    _checkLevelUp(oldXp, xp);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Задачи сданы! Получено опыта: $earnedXp")),
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
    // Сначала фильтруем только те, которые должны быть видны сейчас
    final visibleTasks = tasks.where((t) => 
      t.nextOccurrence == null || DateTime.now().isAfter(t.nextOccurrence!)
    ).toList();

    // Теперь разделяем отфильтрованные задачи
    final incomplete = visibleTasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
      
    final completed = visibleTasks.where((t) => t.isCompleted).toList()
      ..sort((a, b) => (a.completedAt ?? DateTime(0)).compareTo(b.completedAt ?? DateTime(0)));

    return Scaffold(
          appBar: AppBar(
            title: const Text("RPG Task Tracker"),
            actions: [
              IconButton(
                icon: const Icon(Icons.cleaning_services), 
                onPressed: _performCleanup
              ),
              
              // Новое меню в углу
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'recurring') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RecurringTasksScreen(
                      tasks: tasks,
                      onUpdate: () { _saveData(); setState(() {}); },
                    )));
                  } else if (value == 'stats') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StatisticsScreen(
                      archive: completedArchive,
                      totalXp: xp,
                    )));
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'recurring',
                    child: ListTile(leading: Icon(Icons.loop), title: Text('Повторяющиеся')),
                  ),
                  const PopupMenuItem<String>(
                    value: 'stats',
                    child: ListTile(leading: Icon(Icons.bar_chart), title: Text('Статистика')),
                  ),
                ],
              ),
            ],
          ),
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