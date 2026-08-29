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
import 'future_tasks_screen.dart';

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

  // Получение текущего времени с учетом смещения дня в 4:00 утра
  DateTime get _logicalNow => DateTime.now().subtract(const Duration(hours: 4));

  DateTime _calculateNextOccurrence(Task task) {
    final logical = _logicalNow;
    // DateTime now = DateTime.now();
    switch (task.recurrence) {
      case Recurrence.daily:
        return DateTime(logical.year, logical.month, logical.day + 1, 4, 0);
      case Recurrence.weekly:
        // Следующий понедельник 00:00
        int daysUntilMonday = 8 - logical.weekday;
        return DateTime(logical.year, logical.month, logical.day + daysUntilMonday, 4, 0);
      case Recurrence.monthly:
        // 1-е число следующего месяца 00:00
        return DateTime(logical.year, logical.month + 1, 1, 4, 0);
      default:
        return DateTime.now();
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
    final logical = _logicalNow;
    
    // Вспомогательная функция, чтобы всегда получать 23:59:59 текущей даты
    DateTime endOfLogicalDay(DateTime date) {
      return DateTime(date.year, date.month, date.day, 3, 59).add(const Duration(days: 1));
    }

    switch (task.recurrence) {
      case Recurrence.daily:
        // Следующий день, 23:59
        return endOfLogicalDay(logical.add(const Duration(days: 1)));
        
      case Recurrence.weekly:
        // now.weekday: 1=Пн, ..., 7=Вс
        // Чтобы всегда попадать в воскресенье следующей недели:
        // 1. Вычисляем, сколько дней осталось до конца этой недели (воскресенья): (7 - now.weekday)
        // 2. Добавляем +7 дней, чтобы гарантированно перейти в следующую неделю
        int daysToAdd = (7 - logical.weekday) + 7;
        
        return endOfLogicalDay(logical.add(Duration(days: daysToAdd)));
        
      case Recurrence.monthly:
        // 1. Переходим на 1-е число месяца, следующего за "месяцем исполнения"
        // (now.month + 2) дает 1-е число месяца, идущего через один после текущего
        DateTime firstDayTargetMonth = DateTime(logical.year, logical.month + 2, 1);
        // 2. Вычитаем 1 минуту, получаем 23:59 последнего дня того месяца
        return firstDayTargetMonth.subtract(const Duration(minutes: 1));
        
      default:
        return task.dueDate ?? DateTime.now();
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
  void _addTask(String title, int exp, TaskDifficulty diff, String? catName, int? catIcon, DateTime? dueDate, Recurrence recurrence, DateTime? nextOccur, int targetCompletions) {
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
        targetCompletions: targetCompletions, // Сохраняем цель
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
      // Полный опыт: опыт за 1 повторение * целевое количество
      earnedXp += task.experience * task.targetCompletions;

      // task.timesCompleted += 1;
      
      // Инкремент прогресса достижений для каждой задачи
      await AchievementManager.incrementTotalCompletions();
      
      if (task.recurrence != Recurrence.none) {
        // Для повторяющихся просто сбрасываем состояние
        task.isCompleted = false;
        task.timesCompleted = 0;
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

  void _refreshRecurringTasks() async {
    final logical = _logicalNow;
    final currentLogicalDay = DateTime(logical.year, logical.month, logical.day);
    bool updated = false;
    int partialEarnedXp = 0;

    for (var task in recurringTasks) {
      // Обновляем только повторяющиеся и НЕвыполненные задачи
      if (task.recurrence != Recurrence.none && !task.isCompleted && task.dueDate != null) {
        // Пока дата дедлайна меньше сегодня
        while (task.dueDate!.isBefore(currentLogicalDay)) {
          // Если задача была частично выполнена (например, 2 из 3 раз)
          if (task.timesCompleted > 0) {
            // Формула: фактически выполненные * опыт за 1 раз * 0.5
            int taskXp = (task.timesCompleted * task.experience * 0.5).round();
            partialEarnedXp += taskXp;
          }

          // Сбрасываем прогресс для нового периода
          task.timesCompleted = 0;
          
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

    if (partialEarnedXp > 0) {
      xp += partialEarnedXp;
      int currentGlobalXp = await AchievementManager.getTotalXp() + partialEarnedXp;
      await AchievementManager.updateTotalXp(currentGlobalXp);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Срок задач истек. За частичное выполнение получено опыта: $partialEarnedXp"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    if (updated || partialEarnedXp > 0) {
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

  void _incrementTaskProgress(Task task) {
    setState(() {
      if (task.timesCompleted < task.targetCompletions) {
        task.timesCompleted += 1;
        
        // Если достигли цели — отмечаем задачу выполненной
        if (task.timesCompleted >= task.targetCompletions) {
          task.isCompleted = true;
          task.completedAt = DateTime.now();
        }
        
        _saveData();
      }
    });
  }

  // Полностью завершает или сбрасывает задачу (для чекбокса и клика по карточке)
  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      if (task.isCompleted) {
        task.timesCompleted = task.targetCompletions; // Заполняет шкалу полностью
        task.completedAt = DateTime.now();
      } else {
        task.timesCompleted = 0; // Сбрасывает шкалу
        task.completedAt = null;
      }
      _saveData();
    });
  }

  // --- ВИДЖЕТЫ ---
  Widget _buildTaskTile(Task task) {
  final dateFormat = DateFormat('dd.MM HH:mm');
  final bool overdue = task.isOverdue;
  final int totalTaskXp = task.experience * task.targetCompletions;

  return Card(
    color: overdue ? Colors.red[50] : getDifficultyColor(task.difficulty),
    child: Padding( // Убираем InkWell, чтобы карточка не реагировала на случайные нажатия
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Чекбокс слева — единственный способ отметить задачу целиком
          Checkbox(
            value: task.isCompleted || overdue, 
            onChanged: overdue ? null : (_) {
              setState(() {
                task.isCompleted = !task.isCompleted;
                if (task.isCompleted) {
                  task.timesCompleted = task.targetCompletions;
                  task.completedAt = DateTime.now();
                } else {
                  task.timesCompleted = 0;
                  task.completedAt = null;
                }
                _saveData();
              });
            },
          ),
          const SizedBox(width: 4),
          
          // Основной блок (Название + Детали) — теперь просто текст, клик по нему ничего не делает
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        task.title, 
                        style: TextStyle(
                          fontSize: 16,
                          decoration: (task.isCompleted || overdue) ? TextDecoration.lineThrough : null, 
                          color: overdue ? Colors.red : Colors.black,
                          fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.targetCompletions > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${task.timesCompleted}/${task.targetCompletions}",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
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
                    if (overdue)
                      const Text(
                        " • ПРОСРОЧЕНО", 
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Правый блок (XP и кнопки управления: "+" и мусорка)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$totalTaskXp XP", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!task.isCompleted && task.targetCompletions > 1)
                    InkWell(
                      onTap: () => _incrementTaskProgress(task),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                      ),
                    ),
                  if (!task.isCompleted && task.targetCompletions > 1)
                    const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _deleteTask(task),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  int get pendingXp => [...regularTasks, ...recurringTasks].where((t) => t.isCompleted).fold(0, (sum, t) => sum + (t.experience * t.targetCompletions));

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelUtils.getLevelFromXP(xp);
    final currentLevelXp = LevelUtils.getXpInCurrentLevel(xp);
    final requiredForNext = LevelUtils.getRequiredXP(currentLevel);
    final pending = pendingXp; // XP за выполненные, но не сданные задачи
    final targetLevel = LevelUtils.getLevelFromXP(xp + pending);

    final logicalNow = _logicalNow;
    final oneWeekLater = logicalNow.add(const Duration(days: 7));

    bool isWithinOneWeek(Task task) {
      if (task.dueDate == null) return true;
      return task.dueDate!.isBefore(oneWeekLater) || task.dueDate!.isAtSameMomentAs(oneWeekLater);
    }

    // Разделение и сортировка
    // Сначала фильтруем только те, которые должны быть видны сейчас
    final visibleRecurring = recurringTasks.where((t) => 
      (t.nextOccurrence == null || DateTime.now().isAfter(t.nextOccurrence!)) &&
      isWithinOneWeek(t)
    ).toList();

    final visibleRegular = regularTasks.where(isWithinOneWeek).toList();

    final allVisible = [...visibleRegular, ...visibleRecurring];

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
                  } else if (value == 'future') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FutureTasksScreen(
                      regularTasks: regularTasks,
                      recurringTasks: recurringTasks,
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
                    value: 'future',
                    child: ListTile(leading: Icon(Icons.update), title: Text('Будущие задачи (> 1 недели)')),
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