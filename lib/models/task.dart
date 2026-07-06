// lib/models/task.dart
enum TaskDifficulty { easy, medium, hard, legendary }

class Task {
  String id;
  String title;
  int experience;
  bool isCompleted;
  TaskDifficulty difficulty;

  Task({
    required this.id,
    required this.title,
    required this.experience,
    this.isCompleted = false,
    this.difficulty = TaskDifficulty.easy,
  });

  // Преобразование объекта в Map для JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'experience': experience,
    'isCompleted': isCompleted,
    'difficulty': difficulty.index,
  };

  // Создание объекта из Map
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    // Если json['id'] равен null, создаем уникальный ID прямо сейчас
    id: json['id'] ?? DateTime.now().toString(), 
    title: json['title'],
    experience: json['experience'],
    isCompleted: json['isCompleted'] ?? false,
    difficulty: TaskDifficulty.values[json['difficulty'] ?? 0],
  );
}