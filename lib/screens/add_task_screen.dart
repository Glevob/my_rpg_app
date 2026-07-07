import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';
import 'category_selection_screen.dart';


class AddTaskScreen extends StatefulWidget {
  // Обновленная сигнатура: добавили DateTime? и Recurrence
  final Function(String, int, TaskDifficulty, String?, int?, DateTime?, Recurrence) onAdd;
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
  final TextEditingController _xpController = TextEditingController(text: "10");
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;
  String? _selectedCatName;
  int? _selectedCatIcon;

  DateTime? _selectedDateTime;
  Recurrence _selectedRecurrence = Recurrence.none;

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
            // Поле для многострочного текста
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
            
            // Поле для XP
            TextField(
              controller: _xpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Опыт (XP)",
                border: OutlineInputBorder(),
              ),
            ),

            // Выбор даты/времени
            ListTile(
              title: Text(_selectedDateTime == null ? "Дата и время" : DateFormat('dd.MM.yyyy HH:mm').format(_selectedDateTime!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
            ),

            // Выбор периодичности
            DropdownButtonFormField<Recurrence>(
              value: _selectedRecurrence,
              decoration: const InputDecoration(labelText: "Повторять"),
              items: Recurrence.values.map((r) => DropdownMenuItem(
                value: r, child: Text(r.nameRu)
              )).toList(),
              onChanged: (val) => setState(() => _selectedRecurrence = val!),
            ),

            const SizedBox(height: 15),
            
            // Выбор сложности
            DropdownButtonFormField<TaskDifficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: "Сложность",
                border: OutlineInputBorder(),
              ),
              items: TaskDifficulty.values.map((d) => DropdownMenuItem(
                value: d, 
                child: Text(difficultyNames[d] ?? d.toString())
              )).toList(),
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
            ),
            const SizedBox(height: 15),
            
            // Выбор категории
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
                    onCategorySelected: (name, icon) => setState(() {
                      _selectedCatName = name;
                      _selectedCatIcon = icon.codePoint;
                    }),
                  ))
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Кнопка сохранения
            // Кнопка сохранения
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                final xp = int.tryParse(_xpController.text) ?? 0;
                if (_titleController.text.isNotEmpty) {
                  widget.onAdd(
                    _titleController.text, 
                    xp, 
                    _selectedDifficulty, 
                    _selectedCatName, 
                    _selectedCatIcon,
                    _selectedDateTime,
                    _selectedRecurrence,
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