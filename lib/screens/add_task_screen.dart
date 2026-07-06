import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';

class AddTaskScreen extends StatefulWidget {
  final Function(String, int, TaskDifficulty) onAdd;

  const AddTaskScreen({super.key, required this.onAdd});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _xpController = TextEditingController(text: "10");
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;

  @override
  void dispose() {
    _titleController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Новая задача")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Название задачи",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _xpController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(4), // Ограничение: максимум 9999 XP
                FilteringTextInputFormatter.digitsOnly, // Разрешить только цифры
              ],
              decoration: const InputDecoration(
                labelText: "Количество опыта (XP)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star_border), // Добавляем иконку для красоты
              ),
              onTap: () => _xpController.selection = TextSelection(
                baseOffset: 0, 
                extentOffset: _xpController.text.length
              ), // Выделяет текст при нажатии — очень удобно!
            ),
            DropdownButtonFormField<TaskDifficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Сложность'),
              items: TaskDifficulty.values.map((d) => DropdownMenuItem(
                value: d, child: Text(difficultyNames[d]!))).toList(),
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final xp = int.tryParse(_xpController.text.trim()) ?? 0;

                // Валидация: если текст пустой или опыт не является числом
                if (title.isEmpty || xp <= 0) return;

                widget.onAdd(_titleController.text, int.parse(_xpController.text), _selectedDifficulty);
                Navigator.pop(context);
              },
              child: const Text("Добавить задачу"),
            ),
          ],
        ),
      ),
    );
  }
}