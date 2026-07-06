// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int xp = 0;
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_xp', xp);
    await prefs.setString('tasks_list', json.encode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      xp = prefs.getInt('user_xp') ?? 0;
      final tasksString = prefs.getString('tasks_list');
      if (tasksString != null) {
        final List<dynamic> decoded = json.decode(tasksString);
        tasks = decoded.map((item) => Task.fromJson(item)).toList();
      }
    });
  }

  void _addTask(String title, int exp, TaskDifficulty diff) {
    setState(() {
      tasks.add(Task(id: DateTime.now().toString(), title: title, experience: exp, difficulty: diff));
      _saveData();
    });
  }

  void _toggleTask(int index) {
    setState(() {
      final task = tasks[index];
      task.isCompleted = !task.isCompleted;
      xp += task.isCompleted ? task.experience : -task.experience;
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RPG Task Tracker"), actions: [
        Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text("XP: $xp", style: const TextStyle(fontSize: 18)))),
      ]),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            color: getDifficultyColor(task.difficulty),
            child: ListTile(
              onTap: () => _toggleTask(index),
              leading: Checkbox(value: task.isCompleted, onChanged: (_) => _toggleTask(index)),
              title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
              trailing: Text("${task.experience} XP"),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(onAdd: _addTask))),
        child: const Icon(Icons.add),
      ),
    );
  }
}