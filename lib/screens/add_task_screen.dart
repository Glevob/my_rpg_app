// Импортируем стандартный набор элементов интерфейса от Google (Flutter).
import 'package:flutter/material.dart';
// Импортируем библиотеку для работы с форматами дат и времени (чтобы красиво их показывать и превращать текст в дату).
import 'package:intl/intl.dart';
// Импортируем наш файл с описанием задачи (модель Task) и файл с правилами для задач.
import '../models/task.dart';
import '../utils/task_utils.dart';
// Импортируем экран выбора категории.
import 'category_selection_screen.dart';
// Импортируем библиотеку для масок ввода текста (чтобы автоматически ставить точки в дате, например "01.01.2026").
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

// Экран добавления новой задачи. Это "StatefulWidget", то есть экран, который умеет 
// запоминать изменения пользователя (например, что он ввел текст или выбрал сложность) и перерисовываться.
class AddTaskScreen extends StatefulWidget {
  // Функция-команда (callback), которую мы вызовем при сохранении задачи, чтобы передать все данные на главный экран.
  final Function(String, int, TaskDifficulty, String?, int?, DateTime?, Recurrence, DateTime?) onAdd;
  // Список существующих категорий, чтобы пользователь мог выбрать одну из них.
  final List<Category> categories;
  // Функция для обновления списка категорий, если что-то изменится.
  final Function(List<Category>) onUpdateCategories;

  // Конструктор экрана. Требует обязательно передать функцию сохранения и список категорий.
  const AddTaskScreen({
    super.key,
    required this.onAdd,
    required this.categories,
    required this.onUpdateCategories,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

// Внутренняя память (состояние) экрана добавления задачи. Здесь хранятся все введенные пользователем данные.
class _AddTaskScreenState extends State<AddTaskScreen> {
  // Контроллер для текстового поля названия задачи (следит за тем, что печатает пользователь).
  final TextEditingController _titleController = TextEditingController();
  // Выбранная сложность задачи по умолчанию (легкая).
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;
  // Имя выбранной категории (по умолчанию не выбрана, поэтому null).
  String? _selectedCatName;
  // Код иконки выбранной категории.
  int? _selectedCatIcon;

  // Выбранные дата и время дедлайна (могут быть пустыми).
  DateTime? _selectedDateTime;
  // Периодичность задачи по умолчанию (без повторений).
  Recurrence _selectedRecurrence = Recurrence.none;

  // Контроллер для текстового поля ввода даты вручную.
  final TextEditingController _dateController = TextEditingController();
  // Настройка маски ввода: превращает печатаемый текст в шаблон "ДД.ММ.ГГГГ" и разрешает вводить только цифры.
  final maskFormatter = MaskTextInputFormatter(
    mask: '##.##.####', 
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Функция, которая открывает всплывающее окошко календаря и часов для выбора дедлайна.
  Future<void> _pickDateTime() async {
    // Открываем календарь выбора даты.
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Начинаем с сегодняшнего дня
      firstDate: DateTime.now(),   // Нельзя выбрать дату из прошлого
      lastDate: DateTime(2030),    // Ограничение по дате до 2030 года
    );
    if (date != null) {
      // Если дату выбрали, открываем выбор времени.
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        // Сохраняем объединенные дату и время в переменную и записываем текст в поле ввода.
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDateTime!);
        });
      }
    }
  }

  // Функция для установки выбранной категории и автоматического заполнения названия, если есть шаблон.
  void _setCategory(String name, IconData icon, String? templateTitle) {
    setState(() {
      _selectedCatName = name;
      _selectedCatIcon = icon.codePoint;
      // Если в категории был шаблон названия — автоматически вставляем его в поле ввода задачи.
      if (templateTitle != null && templateTitle.isNotEmpty) {
        _titleController.text = templateTitle;
      }
    });
  }

  // Главная функция, которая рисует интерфейс экрана добавления задачи.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Верхняя панель приложения с заголовком.
      appBar: AppBar(
        title: const Text("Новая задача"),
      ),
      // Прокручиваемый список элементов, чтобы на маленьких экранах ничего не обрезалось.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Поле для ввода названия задачи (поддерживает несколько строк).
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Название задачи", // (Текст подсказки в поле)
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
            ),
            const SizedBox(height: 15),

            // Выпадающий список для выбора сложности задачи.
            DropdownButtonFormField<TaskDifficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: "Сложность", border: OutlineInputBorder()),
              items: TaskDifficulty.values.map((d) => DropdownMenuItem(
                value: d, 
                child: Text(difficultyNames[d] ?? d.name) // Берем красивое русское имя сложности
              )).toList(),
              // При изменении сложности обновляем состояние экрана.
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
            ),
            // Информационный текст, показывающий, сколько опыта получит игрок за выбранную сложность.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Награда: ${difficultyXpMap[_selectedDifficulty]} XP",
                style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
            ),
          
            // Текстовое поле для ввода даты с маской (пользователь вводит цифры, точки ставятся сами).
            TextField(
              controller: _dateController,
              inputFormatters: [maskFormatter],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Дата (ДД.ММ.ГГГГ)",
                hintText: "01.01.2026",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              // Когда пользователь что-то меняет в поле даты...
              onChanged: (value) {
                // Если введено ровно 10 символов (полная дата вида 01.01.2026)...
                if (value.length == 10) {
                  try {
                    // Пытаемся превратить текст в дату. 
                    // DateTime.parse по умолчанию ставит время 00:00:00.
                    final DateTime parsedDate = DateFormat('dd.MM.yyyy').parse(value);

                    // Сдвигаем время на конец дня (23 часа 59 минут), 
                    // чтобы при ручном вводе дедлайн выставлялся на 23:59.
                    final DateTime endOfDay = DateTime(
                      parsedDate.year, 
                      parsedDate.month, 
                      parsedDate.day, 
                      23, 
                      59,
                    );

                    // Пытаемся превратить текст в настоящую дату и сохранить.
                    setState(() {
                      _selectedDateTime = endOfDay;
                    });
                  } catch (_) {}
                }
              },
            ),
            const SizedBox(height: 10),
            
            // Кнопка-ссылка для вызова всплывающего календаря/часов.
            TextButton(
              onPressed: _pickDateTime,
              child: const Text("Выбрать дату/время из календаря"),
            ),

            // Выпадающий список для выбора периодичности (повторения задачи).
            DropdownButtonFormField<Recurrence>(
              value: _selectedRecurrence,
              decoration: const InputDecoration(labelText: "Повторять"),
              items: Recurrence.values.map((r) => DropdownMenuItem(
                value: r, child: Text(r.nameRu) // Показываем русское название повторения
              )).toList(),
              onChanged: (val) => setState(() => _selectedRecurrence = val!),
            ),

            const SizedBox(height: 15),
            
            // Карточка выбора категории. При нажатии открывает отдельный экран выбора категорий.
            Card(
              child: ListTile(
                leading: Icon(
                  _selectedCatIcon != null 
                    ? IconData(_selectedCatIcon!, fontFamily: 'MaterialIcons') // Рисуем иконку категории, если она выбрана
                    : Icons.category // Иначе показываем стандартную иконку категории
                ),
                title: Text(_selectedCatName ?? "Выбрать категорию"), // Имя категории или текст-подсказка
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategorySelectionScreen(
                    categories: widget.categories,
                    onUpdateCategories: widget.onUpdateCategories,
                    // Функция, которая сработает при выборе категории на следующем экране.
                    onCategorySelected: (name, icon, {String? template}) {
                      setState(() {
                        _selectedCatName = name;
                        _selectedCatIcon = icon.codePoint;
                        if (template != null) _titleController.text = template;
                      });
                    },
                  )),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Большая кнопка сохранения задачи.
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                // Считаем опыт на основе выбранной сложности.
                final xp = difficultyXpMap[_selectedDifficulty] ?? 0;
                // Проверяем: если название задачи не пустое...
                if (_titleController.text.isNotEmpty) {
                  // Если задача повторяющаяся, сохраняем дату как стартовую точку повторения, иначе null.
                  final DateTime? nextOccur = (_selectedRecurrence != Recurrence.none) 
                    ? _selectedDateTime 
                    : null;
                  // Вызываем главную функцию сохранения и отправляем все данные наверх.
                  widget.onAdd(
                    _titleController.text, 
                    xp, 
                    _selectedDifficulty, 
                    _selectedCatName, 
                    _selectedCatIcon,
                    _selectedDateTime,
                    _selectedRecurrence,
                    nextOccur,
                  );
                  // Закрываем экран создания задачи и возвращаемся назад.
                  Navigator.pop(context);
                } else {
                  // Если поле названия пустое, показываем всплывающую ошибку (SnackBar).
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Введите название задачи")),
                  );
                }
              },
              child: const Text("Создать задачу", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}