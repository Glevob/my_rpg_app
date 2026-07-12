class Achievement {
  final String id;
  final String title;
  final List<String> levelTitles; // Например: ["Новичок", "Мастер", "Легенда"]
  final List<int> thresholds;    // Пороговые значения: [10, 50, 100] задач
  int currentProgress; // СКОЛЬКО задач выполнено (накопительный счетчик)
  int currentLevel;    // ТЕКУЩИЙ открытый уровень

  Achievement({
    required this.id,
    required this.title,
    required this.levelTitles,
    required this.thresholds,
    this.currentProgress = 0,
    this.currentLevel = 0,
  });
}