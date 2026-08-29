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
import 'xp_settings_screen.dart';
import '../utils/achievement_manager.dart';
import 'achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int xp = 0;
  // List<Task> tasks = [];
  List<Task> regularTasks = [];     // Список обычных разовых задач
  List<Task> recurringTasks = [];   // Отдельный список повторяющихся задач (шаблонов)
  List<Category> categories = [
    Category(name: "Дом", iconCode: Icons.home.codePoint, templates: ["Убраться", "Постирать белье"]),
    Category(name: "Работа", iconCode: Icons.work.codePoint, templates: ["Отчет", "Встреча"]),
  ];
  List<Task> completedArchive = [];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadData();
    await _loadCategories();

    _refreshRecurringTasks();
    await AchievementManager.loadAllAchievements();
    _processRecurringTasks();

    final allActive = [...regularTasks, ...recurringTasks];
    if (allActive.any((t) => t.isCompleted)) {
      await _performCleanup(); 
    }
    
    setState(() {});
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

  void _processRecurringTasks() {
    bool changed = false;
    DateTime now = DateTime.now();

    for (var task in recurringTasks) {
      // Если задача повторяющаяся, выполнена, и пришло время её "сбросить" 
      // (например, наступил следующий день)
      if (task.recurrence != Recurrence.none && task.isCompleted) {
        if (task.nextOccurrence != null && now.isAfter(task.nextOccurrence!)) {
          task.nextOccurrence = null; // Сбрасываем, чтобы она стала активной
          task.isCompleted = false;
          task.completedAt = null;
          task.dueDate = _calculateNextDueDate(task);
          changed = true;
        }
      }
    }

    if (changed) {
      _saveData();
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
  // Future<void> _saveData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt('user_xp', xp);
  //   await prefs.setString('tasks_list', json.encode(tasks.map((t) => t.toJson()).toList()));
  //   // Сохранение архива
  //   await prefs.setString('archive_list', json.encode(completedArchive.map((t) => t.toJson()).toList()));
  // }
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_xp', xp);
    await prefs.setString('regular_tasks_list', json.encode(regularTasks.map((t) => t.toJson()).toList()));
    await prefs.setString('recurring_tasks_list', json.encode(recurringTasks.map((t) => t.toJson()).toList()));
    await prefs.setString('archive_list', json.encode(completedArchive.map((t) => t.toJson()).toList()));
  }

  // Future<void> _loadData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     xp = prefs.getInt('user_xp') ?? 0;
  //     final tasksString = prefs.getString('tasks_list');
  //     if (tasksString != null) {
  //       final List<dynamic> decoded = json.decode(tasksString);
  //       tasks = decoded.map((item) => Task.fromJson(item)).toList();
  //     }
  //     // Загрузка архива
  //     final archiveString = prefs.getString('archive_list');
  //     if (archiveString != null) {
  //       final List<dynamic> decoded = json.decode(archiveString);
  //       completedArchive = decoded.map((item) => Task.fromJson(item)).toList();
  //     }
  //   });
  // }
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      xp = prefs.getInt('user_xp') ?? 0;
      
      final regularString = prefs.getString('regular_tasks_list');
      if (regularString != null) {
        final List<dynamic> decoded = json.decode(regularString);
        regularTasks = decoded.map((item) => Task.fromJson(item)).toList();
      }

      final recurringString = prefs.getString('recurring_tasks_list');
      if (recurringString != null) {
        final List<dynamic> decoded = json.decode(recurringString);
        recurringTasks = decoded.map((item) => Task.fromJson(item)).toList();
      }

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
  void _addTask(String title, int exp, TaskDifficulty diff, String? catName, int? catIcon, DateTime? dueDate, Recurrence recurrence, DateTime? nextOccur) {
    setState(() {
      final newTask = Task(
        id: DateTime.now().toString(),
        title: title,
        experience: exp,
        difficulty: diff,
        categoryName: catName,
        categoryIconCode: catIcon,
        dueDate: dueDate,
        recurrence: recurrence,
        nextOccurrence: nextOccur,
      );

      if (recurrence == Recurrence.none) {
        regularTasks.add(newTask);
      } else {
        recurringTasks.add(newTask);
      }
      _saveData();
    });
  }

  void _toggleTask(Task task) {
    
    setState(() {
      // Просто переключаем состояние
      task.isCompleted = !task.isCompleted;
      
      // Если задача стала выполненной, фиксируем время, 
      // иначе сбрасываем (полезно для сортировки)
      if (task.isCompleted) {
        task.completedAt = DateTime.now();
      } else {
        task.completedAt = null;
      }
      
      _saveData();
    });
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Удалить задачу?"),
        content: Text(
          task.recurrence != Recurrence.none
              ? "Это повторяющаяся задача. Она исчезнет на сегодня без начисления опыта."
              : "Это действие нельзя отменить."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (task.recurrence != Recurrence.none) {
                  // Сбрасываем выполнение
                  task.isCompleted = false;
                  
                  // Отодвигаем nextOccurrence на следующий период вперед, 
                  // чтобы задача мгновенно пропала с главного экрана (так как не пройдет условие visibleRecurring),
                  // но осталась в общем списке recurringTasks как шаблон.
                  task.nextOccurrence = _calculateNextOccurrence(task);
                  task.dueDate = _calculateNextDueDate(task);
                } else {
                  // Разовую задачу удаляем полностью
                  regularTasks.remove(task);
                }
              });
              
              _saveData();
              Navigator.pop(ctx);
            },
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanup() async {
    final allActive = [...regularTasks, ...recurringTasks];
    final finishedTasks = allActive.where((t) => t.isCompleted).toList();
    if (finishedTasks.isEmpty) return;

    int earnedXp = 0;
    
    for (var task in finishedTasks) {
      earnedXp += task.experience;

      task.timesCompleted += 1;
      
      // Инкремент прогресса достижений для каждой задачи
      await AchievementManager.incrementTotalCompletions();
      
      if (task.recurrence != Recurrence.none) {
        // Для повторяющихся просто сбрасываем состояние
        task.isCompleted = false;
        task.nextOccurrence = _calculateNextOccurrence(task);
        task.dueDate = _calculateNextDueDate(task);
      } else {
        // Для разовых — архив и удаление
        completedArchive.add(task);
        regularTasks.remove(task);
      }
    }

    int currentGlobalXp = await AchievementManager.getTotalXp() + earnedXp;
    await AchievementManager.updateTotalXp(currentGlobalXp);

    setState(() {
      xp += earnedXp;
    });

    await _checkAchievements();
    _saveData();
    
    if (mounted && earnedXp > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Задачи сданы! Получено опыта: $earnedXp")),
      );
    }
  }

  void _refreshRecurringTasks() {
    DateTime now = DateTime.now();
    bool updated = false;

    for (var task in recurringTasks) {
      // Обновляем только повторяющиеся и НЕвыполненные задачи
      if (task.recurrence != Recurrence.none && !task.isCompleted && task.dueDate != null) {
        // Пока дата дедлайна меньше сегодня
        while (task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))) {
          switch (task.recurrence) {
            case Recurrence.daily:
              task.dueDate = task.dueDate!.add(const Duration(days: 1));
              break;
            case Recurrence.weekly:
              task.dueDate = task.dueDate!.add(const Duration(days: 7));
              break;
            case Recurrence.monthly:
              task.dueDate = DateTime(task.dueDate!.year, task.dueDate!.month + 1, task.dueDate!.day);
              break;
            default:
              break;
          }
          updated = true;
        }
      }
    }

    if (updated) {
      _saveData(); // Сохраняем новые даты
    }
  }

  Future<void> _checkAchievements() async {
    // 1. Получаем актуальные данные из хранилища один раз
    final int totalTasks = await AchievementManager.getTotalCompletions();
    final int totalXp = await AchievementManager.getTotalXp();

    // 2. Итерируемся по списку и передаем нужный параметр
    for (var ach in AchievementManager.achievements) {
      int currentValue = 0;

      // Выбираем счетчик в зависимости от типа достижения
      if (ach.id == "tasks_done") {
        currentValue = totalTasks;
      } else if (ach.id == "xp_collector") {
        currentValue = totalXp;
      }

      // 3. Проверяем повышение уровня
      bool earned = await AchievementManager.checkAchievement(ach, currentValue);
      
      if (earned) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Поздравляем! Достижение '${ach.title}' повышено до уровня '${ach.levelTitles[ach.currentLevel - 1]}'!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // --- ВИДЖЕТЫ ---
  Widget _buildTaskTile(Task task) {
    final dateFormat = DateFormat('dd.MM HH:mm');
    final bool overdue = task.isOverdue;

    print("Задача '${task.title}': просрочена? $overdue, дата: ${task.dueDate}");

    return Card(
      // Изменяем цвет карточки на светло-красный, если задача просрочена
      color: overdue ? Colors.red[50] : getDifficultyColor(task.difficulty),
      child: ListTile(
        // Блокируем нажатие и чекбокс для просроченных задач
        onTap: overdue ? null : () => _toggleTask(task),
        leading: Checkbox(
          value: task.isCompleted || overdue, 
          onChanged: overdue ? null : (_) => _toggleTask(task),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок задачи с зачеркиванием и красным цветом при просрочке
            Text(
              task.title, 
              style: TextStyle(
                decoration: (task.isCompleted || overdue) ? TextDecoration.lineThrough : null, 
                color: overdue ? Colors.red : Colors.black,
                fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            // Строка с датой или статусом просрочки
            Row(
              children: [
                if (task.dueDate != null)
                  Flexible(
                    child: Text(
                      dateFormat.format(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12, 
                        color: overdue ? Colors.red : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (task.dueDate != null && task.recurrence != Recurrence.none) 
                  const Text(" • ", style: TextStyle(fontSize: 12, color: Colors.black54)),
                if (task.recurrence != Recurrence.none)
                  Flexible(
                    child: Text(
                      task.recurrence.nameRu,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Явный вывод ПРОСРОЧЕНО для любых неповторяющихся или просроченных задач
                if (overdue)
                  const Text(
                    " • ПРОСРОЧЕНО", 
                    style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
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

  int get pendingXp => [...regularTasks, ...recurringTasks].where((t) => t.isCompleted).fold(0, (sum, t) => sum + t.experience);

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelUtils.getLevelFromXP(xp);
    final currentLevelXp = LevelUtils.getXpInCurrentLevel(xp);
    final requiredForNext = LevelUtils.getRequiredXP(currentLevel);
    final pending = pendingXp; // XP за выполненные, но не сданные задачи
    final targetLevel = LevelUtils.getLevelFromXP(xp + pending);

    // Разделение и сортировка
    // Сначала фильтруем только те, которые должны быть видны сейчас
    final visibleRecurring = recurringTasks.where((t) => 
      t.nextOccurrence == null || DateTime.now().isAfter(t.nextOccurrence!)
    ).toList();

    final allVisible = [...regularTasks, ...visibleRecurring];

    // Теперь разделяем отфильтрованные задачи
    final incomplete = allVisible.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
      
    final completed = allVisible.where((t) => t.isCompleted).toList()
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
                onSelected: (value) async {
                  if (value == 'recurring') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RecurringTasksScreen(
                      tasks: recurringTasks,
                      onUpdate: () { _saveData(); setState(() {}); },
                    )));
                  } else if (value == 'stats') {
                    await _saveData();
                    // Получаем актуальный счетчик перед переходом
                    int totalCount = await AchievementManager.getTotalCompletions();
                    if (!mounted) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StatisticsScreen(
                      tasks: [...regularTasks, ...recurringTasks], // Передаем список активных задач
                      archive: completedArchive,
                      totalXp: xp,
                      totalCompletedCount: totalCount,
                    )));
                  } else if (value == 'achievements') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen(
                      totalTasks: completedArchive.length, 
                      currentLevel: LevelUtils.getLevelFromXP(xp),
                    )));
                  } else if (value == 'settings_xp') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const XpSettingsScreen()));
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
                  const PopupMenuItem<String>(
                    value: 'achievements', // Новый пункт
                    child: ListTile(leading: Icon(Icons.emoji_events), title: Text('Достижения')),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings_xp',
                    child: ListTile(leading: Icon(Icons.settings), title: Text('Настройка опыта (XP)')),
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