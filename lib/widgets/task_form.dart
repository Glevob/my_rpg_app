// lib/widgets/task_form.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';

class TaskForm extends StatefulWidget {
  final Function(String, TaskDifficulty) onSave;

  const TaskForm({super.key, required this.onSave});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _controller = TextEditingController();
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Название задачи')),
        DropdownButtonFormField<TaskDifficulty>(
          value: _selectedDifficulty,
          items: TaskDifficulty.values.map((level) {
            return DropdownMenuItem(value: level, child: Text(difficultyNames[level]!));
          }).toList(),
          onChanged: (value) => setState(() => _selectedDifficulty = value!),
        ),
        ElevatedButton(
          onPressed: () => widget.onSave(_controller.text, _selectedDifficulty),
          child: const Text('Создать'),
        ),
      ],
    );
  }
}