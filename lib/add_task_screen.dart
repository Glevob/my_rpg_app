import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  final Function(String, int) onAdd;

  const AddTaskScreen({super.key, required this.onAdd});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  double _experience = 10;

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
              autofocus: true, // Фокус сразу на поле ввода
              decoration: const InputDecoration(
                labelText: "Название задачи",
                border: OutlineInputBorder(), // Красивая рамка
              ),
            ),
            const SizedBox(height: 20),
            Text("Опыт: ${_experience.toInt()}", style: const TextStyle(fontSize: 16)),
            Slider(
              value: _experience,
              min: 5, max: 100, divisions: 19,
              onChanged: (val) => setState(() => _experience = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Валидация: если текст пустой, ничего не делаем
                if (_titleController.text.trim().isEmpty) return;

                widget.onAdd(_titleController.text.trim(), _experience.toInt());
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