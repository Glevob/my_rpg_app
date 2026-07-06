import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';
import 'category_selection_screen.dart';

class AddTaskScreen extends StatefulWidget {
  final Function(String, int, TaskDifficulty, String?, int?) onAdd;
  final List<Category> categories;
  final Function(List<Category>) onUpdateCategories;

  const AddTaskScreen({super.key, required this.onAdd, required this.categories, required this.onUpdateCategories});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _xpController = TextEditingController(text: "10");
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;
  String? _selectedCatName;
  int? _selectedCatIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Новая задача")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Название")),
            TextField(controller: _xpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "XP")),
            DropdownButtonFormField<TaskDifficulty>(
              value: _selectedDifficulty,
              items: TaskDifficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(difficultyNames[d]!))).toList(),
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
            ),
            ListTile(
              leading: Icon(_selectedCatIcon != null ? IconData(_selectedCatIcon!, fontFamily: 'MaterialIcons') : Icons.category),
              title: Text(_selectedCatName ?? "Выбрать категорию"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategorySelectionScreen(
                categories: widget.categories,
                onUpdateCategories: widget.onUpdateCategories,
                onCategorySelected: (name, icon) => setState(() {
                  _selectedCatName = name;
                  _selectedCatIcon = icon.codePoint;
                  _titleController.text = name; // Пример автозаполнения
                }),
              ))),
            ),
            ElevatedButton(
              onPressed: () {
                final xp = int.tryParse(_xpController.text) ?? 0;
                widget.onAdd(_titleController.text, xp, _selectedDifficulty, _selectedCatName, _selectedCatIcon);
                Navigator.pop(context);
              },
              child: const Text("Создать"),
            ),
          ],
        ),
      ),
    );
  }
}