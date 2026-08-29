// lib/models/task.dart
import 'package:flutter/material.dart';

// Перечисление (список вариантов) сложности задачи. 
// Позволяет выбрать один из фиксированных вариантов: легкая, средняя, сложная, легендарная.
enum TaskDifficulty { easy, medium, hard, legendary }

// Перечисление вариантов повторения задачи (как часто она должна возвращаться).
enum Recurrence { none, daily, weekly, monthly }

// Расширение (extension) позволяет добавить новые функции к нашему перечислению Recurrence.
// В данном случае мы создаем свойство, которое переводит английские статусы повторения на русский язык.
extension RecurrenceExtension on Recurrence {
  String get nameRu {
    switch (this) {
      case Recurrence.none: return "Нет";
      case Recurrence.daily: return "Ежедневно";
      case Recurrence.weekly: return "Еженедельно";
      case Recurrence.monthly: return "Ежемесячно";
    }
  }
}

// Чертеж (класс) для категории задач. Помогает группировать задачи (например, "Дом", "Работа").
class Category {
  String name;           // Название категории (например, "Дом")
  int iconCode;          // Код иконки, чтобы отображать картинку категории в приложении
  List<String> templates;// Готовые шаблоны названий для быстрого создания задач в этой категории

  // Инструкция по созданию категории (конструктор). Все поля обязательны (required).
  Category({required this.name, required this.iconCode, required this.templates});

  // Превращает категорию в специальный текстовый формат (JSON), чтобы сохранить её в память телефона.
  Map<String, dynamic> toJson() => {'name': name, 'iconCode': iconCode, 'templates': templates};
  
  // Создает категорию из сохраненного на телефоне текста (JSON).
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'],
    iconCode: json['iconCode'],
    templates: List<String>.from(json['templates']),
  );
}

// Главный чертеж (класс) для отдельной задачи. Здесь хранится вся информация о ней.
class Task {
  String id;                 // Уникальный ID задачи (номер), чтобы программа могла её найти среди других
  String title;              // Текст задачи (что нужно сделать, например, "Купить молоко")
  int experience;            // Сколько опыта (XP) получит игрок за выполнение этой задачи
  bool isCompleted;          // Статус: выполнена задача (true) или нет (false)
  TaskDifficulty difficulty; // Сложность задачи (берется из enum TaskDifficulty выше)
  DateTime? completedAt;     // Точная дата и время, когда задача была выполнена (может быть пустым — null)
  String? categoryName;      // Название категории, к которой относится задача (может быть без категории)
  int? categoryIconCode;     // Иконка категории (если она есть)
  DateTime? dueDate;         // Крайний срок (дедлайн), до которого нужно выполнить задачу
  Recurrence recurrence;     // Правило повторения (например, повторять ежедневно или нет)
  bool isExpanded; // Новое поле для отслеживания состояния раскрытия
  
  // Проверка: просрочена ли задача. Возвращает "да" (true) или "нет" (false).
  bool get isOverdue {
    if (isCompleted) return false;      // Если задача уже выполнена, она не может быть просрочена
    if (dueDate == null) return false;    // Если дедлайна вообще нет, она тоже не просрочена
    if (recurrence != Recurrence.none) return false; // Повторяющиеся задачи здесь не считаем просроченными

    // Сравниваем точное время дедлайна с текущим моментом. Если дедлайн раньше сейчас — значит, просрочено.
    return dueDate!.isBefore(DateTime.now());
  }
  
  DateTime? nextOccurrence;  // Дата следующего появления задачи (для повторяющихся)
  int timesCompleted;        // Сколько раз за всё время играющий успешно завершал эту задачу
  int targetCompletions;     // Целевое количество выполнений для завершения задачи (например, 3 раза)

  // Метод, который сдвигает дедлайн повторяющейся задачи на следующий день/неделю/месяц, если время вышло.
  void updateRecurringTaskDate() {
    if (recurrence == Recurrence.none || isCompleted) return; // Если задача не повторяющаяся или уже выполнена, ничего не делаем

    final now = DateTime.now();
    // Пока дедлайн задачи меньше сегодняшнего дня — сдвигаем его вперед на следующий цикл
    while (dueDate != null && dueDate!.isBefore(now)) {
      switch (recurrence) {
        case Recurrence.none:
          return;
        case Recurrence.daily:
          dueDate = dueDate!.add(const Duration(days: 1)); // Добавляем 1 день
          break;
        case Recurrence.weekly:
          dueDate = dueDate!.add(const Duration(days: 7)); // Добавляем 7 дней (неделю)
          break;
        case Recurrence.monthly:
          // Упрощенное добавление ровно одного месяца к дате
          dueDate = DateTime(dueDate!.year, dueDate!.month + 1, dueDate!.day);
          break;
      }
    }
  }

  // Конструктор: инструкция по созданию задачи. 
  // ID, текст и опыт — обязательны. Остальное имеет стандартные значения (по умолчанию).
  Task({
    required this.id, 
    required this.title, 
    required this.experience,
    this.isCompleted = false, 
    this.difficulty = TaskDifficulty.easy,
    this.completedAt, 
    this.categoryName, 
    this.categoryIconCode,
    this.dueDate, 
    this.recurrence = Recurrence.none,
    this.nextOccurrence, 
    this.timesCompleted = 0,
    this.targetCompletions = 1,
    this.isExpanded = false,
  });

  // Превращает объект задачи в формат JSON (текст), чтобы записать её в память телефона.
  Map<String, dynamic> toJson() => {
    'id': id, 
    'title': title, 
    'experience': experience, 
    'isCompleted': isCompleted,
    'difficulty': difficulty.index, 
    'completedAt': completedAt?.toIso8601String(),
    'categoryName': categoryName, 
    'categoryIconCode': categoryIconCode,
    'dueDate': dueDate?.toIso8601String(), 
    'recurrence': recurrence.index,
    'nextOccurrence': nextOccurrence?.toIso8601String(), 
    'timesCompleted': timesCompleted,
    'targetCompletions': targetCompletions,
  };

  // Восстанавливает задачу из сохраненного на телефоне текста (JSON).
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] ?? DateTime.now().toString(), // Если ID нет, создаем текущее время как уникальный текст
    title: json['title'], 
    experience: json['experience'],
    isCompleted: json['isCompleted'] ?? false,
    difficulty: TaskDifficulty.values[json['difficulty'] ?? 0],
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    categoryName: json['categoryName'], 
    categoryIconCode: json['categoryIconCode'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    recurrence: Recurrence.values[json['recurrence'] ?? 0],
    nextOccurrence: json['nextOccurrence'] != null ? DateTime.parse(json['nextOccurrence']) : null,
    timesCompleted: json['timesCompleted'] ?? 0,
    targetCompletions: json['targetCompletions'] ?? 1,
  );


  int calculateEarnedXp() {
    // Полный опыт за все повторения (например, 10 * 4 = 40)
    final int maxPossibleXp = experience * targetCompletions;

    // 1) Если задача выполнена полностью — даем весь опыт
    if (isCompleted && timesCompleted >= targetCompletions) {
      return maxPossibleXp;
    }

    // Опыт за фактически выполненные повторения до просрочки/текущего момента
    final int partialXp = experience * timesCompleted;

    // 2) Если задача просрочена (или имеет частичный прогресс при просрочке)
    if (isOverdue && timesCompleted > 0) {
      // Возвращаем половину от фактически выполненного (округляем до целого через ~/2)
      return (partialXp * 0.5).round();
    }

    // Если не просрочена и еще не завершена — может давать частичный опыт по мере выполнения 
    // (или 0, если вы хотите давать опыт строго по факту завершения/сдачи)
    return partialXp; 
  }

}