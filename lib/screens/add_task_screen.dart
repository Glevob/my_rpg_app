// Импортируем стандартный набор элементов интерфейса от Google (Flutter).
import 'package:flutter/material.dart';
// Импортируем библиотеку для работы с форматами дат и времени.
import 'package:intl/intl.dart';
// Импортируем наш файл с описанием задачи (модель Task) и файл с правилами для задач.
import '../models/task.dart';
import '../utils/task_utils.dart';
// Импортируем экран выбора категории.
import 'category_selection_screen.dart';
// Импортируем библиотеку для масок ввода текста.
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddTaskScreen extends StatefulWidget {
  // Обновляем сигнатуру onAdd, чтобы принимать targetCompletions (int)
  final Function(String, int, TaskDifficulty, String?, int?, DateTime?, Recurrence, DateTime?, int) onAdd;
  final List<Category> categories;
  final Function(List<Category>) onUpdateCategories;

  const AddTaskScreen({
    super.key,
    required this.onAdd,
    required this.categories,
    required this.onUpdateCategories,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _xpController = TextEditingController();
  // Контроллер для указания количества выполнений (по умолчанию "1")
  final TextEditingController _targetCompletionsController = TextEditingController(text: '1');
  
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;

  int _getDefaultXp(TaskDifficulty difficulty) {
    return difficultyXpMap[difficulty] ?? 20;
  }

  String? _selectedCatName;
  int? _selectedCatIcon;

  DateTime? _selectedDateTime;
  Recurrence _selectedRecurrence = Recurrence.none;

  final TextEditingController _dateController = TextEditingController();
  final maskFormatter = MaskTextInputFormatter(
    mask: '##.##.####', 
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _xpController.text = _getDefaultXp(_selectedDifficulty).toString();
  }

  @override
  void dispose() {
    _xpController.dispose();
    _titleController.dispose();
    _targetCompletionsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDateTime!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Новая задача"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Название задачи",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<TaskDifficulty>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(labelText: "Сложность", border: OutlineInputBorder()),
                    items: TaskDifficulty.values.map((d) => DropdownMenuItem(
                      value: d, 
                      child: Text(difficultyNames[d] ?? d.name)
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDifficulty = val;
                          _xpController.text = _getDefaultXp(val).toString();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _xpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Опыт (XP)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Поле для указания сколько раз нужно выполнить задачу
            TextField(
              controller: _targetCompletionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Цель выполнений (например, 3 раза)",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.repeat),
              ),
            ),
            const SizedBox(height: 15),
          
            TextField(
              controller: _dateController,
              inputFormatters: [maskFormatter],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Срок / Дедлайн (ДД.ММ.ГГГГ)",
                hintText: "01.01.2026",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onChanged: (value) {
                if (value.length == 10) {
                  try {
                    final DateTime parsedDate = DateFormat('dd.MM.yyyy').parse(value);
                    final DateTime endOfDay = DateTime(
                      parsedDate.year, parsedDate.month, parsedDate.day, 23, 59,
                    );
                    setState(() {
                      _selectedDateTime = endOfDay;
                    });
                  } catch (_) {}
                }
              },
            ),
            const SizedBox(height: 10),
            
            TextButton(
              onPressed: _pickDateTime,
              child: const Text("Выбрать дедлайн из календаря"),
            ),

            DropdownButtonFormField<Recurrence>(
              value: _selectedRecurrence,
              decoration: const InputDecoration(labelText: "Повторять периодически"),
              items: Recurrence.values.map((r) => DropdownMenuItem(
                value: r, child: Text(r.nameRu)
              )).toList(),
              onChanged: (val) => setState(() => _selectedRecurrence = val!),
            ),

            const SizedBox(height: 15),
            
            Card(
              child: ListTile(
                leading: Icon(
                  _selectedCatIcon != null 
                    ? IconData(_selectedCatIcon!, fontFamily: 'MaterialIcons') 
                    : Icons.category 
                ),
                title: Text(_selectedCatName ?? "Выбрать категорию"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategorySelectionScreen(
                    categories: widget.categories,
                    onUpdateCategories: widget.onUpdateCategories,
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
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                final int xp = int.tryParse(_xpController.text) ?? _getDefaultXp(_selectedDifficulty);
                final int targetCompletions = int.tryParse(_targetCompletionsController.text) ?? 1;

                if (_titleController.text.isNotEmpty) {
                  final DateTime? nextOccur = (_selectedRecurrence != Recurrence.none) 
                    ? _selectedDateTime 
                    : null;

                  widget.onAdd(
                    _titleController.text, 
                    xp, 
                    _selectedDifficulty, 
                    _selectedCatName, 
                    _selectedCatIcon,
                    _selectedDateTime,
                    _selectedRecurrence,
                    nextOccur,
                    targetCompletions, // Передаем целевое количество выполнений
                  );
                  Navigator.pop(context);
                } else {
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