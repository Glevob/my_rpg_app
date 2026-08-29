// Импортируем стандартный набор инструментов Flutter для создания визуальных элементов (кнопок, текста, карточек).
import 'package:flutter/material.dart';
// Импортируем файл с менеджером достижений, где хранится список всех наград и их прогресс.
import '../utils/achievement_manager.dart';

// Создаем экран достижений (экран, который пользователь видит, когда хочет посмотреть свои успехи).
// Слово "StatelessWidget" означает, что сам по себе этот экран статический — он просто рисует то, что ему передали.
class AchievementsScreen extends StatelessWidget {
  // Поле для общего количества задач (передается при открытии экрана).
  final int totalTasks;
  // Поле для текущего уровня (передается при открытии экрана).
  final int currentLevel;

  // Конструктор: инструкция по созданию этого экрана. Требует обязательно передать totalTasks и currentLevel.
  const AchievementsScreen({
    super.key, 
    required this.totalTasks, 
    required this.currentLevel,
  });

  // Вспомогательная функция, которая подбирает правильное слово под каждое достижение.
  // Если ID достижения 'xp_collector', вернет "опыта", во всех остальных случаях (например, 'tasks_done') — "задач".
  String getProgressSuffix(String id) {
    switch (id) {
      case 'xp_collector':
        return "опыта";
      case 'tasks_done':
      default:
        return "задач";
    }
  }

  // Главная функция, которая собирает внешний вид (интерфейс) этого экрана.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Верхняя панель приложения с заголовком "Мои достижения".
      appBar: AppBar(title: const Text("Мои достижения")),
      // Тело экрана, которое создает вертикальный список элементов.
      body: ListView.builder(
        // Указываем, сколько всего будет элементов в списке (равно количеству достижений в AchievementManager).
        itemCount: AchievementManager.achievements.length,
        // Функция, которая рисует каждый отдельный элемент списка под определенным номером (index).
        itemBuilder: (context, index) {
          // Берем конкретное достижение из общего списка по его порядковому номеру.
          final ach = AchievementManager.achievements[index];
          
          // Рассчитываем максимальное пороговое значение для полоски прогресса.
          // Если список порогов не пустой, смотрим на текущий уровень. Если уровень вышел за пределы списка, берем последний порог, иначе — актуальный. Иначе ставим 1 (чтобы не было ошибки деления на ноль).
          final int maxThreshold = ach.thresholds.isNotEmpty ? ach.thresholds[ach.currentLevel >= ach.thresholds.length ? ach.thresholds.length - 1 : ach.currentLevel] : 1;
          // Вычисляем заполненность полоски прогресса в виде дроби от 0.0 (пусто) до 1.0 (заполнено на 100%).
          final double progressValue = (ach.currentProgress / maxThreshold).clamp(0.0, 1.0);

          // Возвращаем карточку для каждого достижения.
          return Card(
            // Отступы вокруг карточки: вертикальные (сверху/снизу) по 8 пикселей, горизонтальные (слева/справа) по 16.
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            // Строка внутри карточки, содержащая иконку, заголовок и описание.
            child: ListTile(
              // Иконка слева от текста (кубок). Если уровень больше 0, иконка золотая (amber), иначе серая.
              leading: Icon(
                Icons.emoji_events, 
                color: ach.currentLevel > 0 ? Colors.amber : Colors.grey[400],
                size: 40,
              ),
              // Жирный заголовок карточки — название достижения (например, "Задачник").
              title: Text(ach.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Подзаголовок, содержащий текст уровня, полоску прогресса и текстовый счетчик.
              subtitle: Column(
                // Выравниваем текст в колонке по левому краю.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5), // Небольшой отступ сверху
                  // Показываем текущий уровень: если он больше 0, берем название из списка, иначе пишем "Начальный".
                  Text("Уровень: ${ach.currentLevel > 0 ? ach.levelTitles[ach.currentLevel - 1] : 'Начальный'}"),
                  const SizedBox(height: 5), // Отступ
                  // Визуальная шкала (полоска) прогресса заполнения достижения.
                  LinearProgressIndicator(value: progressValue, backgroundColor: Colors.grey[200]),
                  // Текстовое описание прогресса, например: "5 / 10 задач" или "150 / 1000 опыта" (с помощью функции getProgressSuffix).
                  Text("${ach.currentProgress} / $maxThreshold ${getProgressSuffix(ach.id)}"),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}