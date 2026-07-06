import 'package:flutter/material.dart';
import 'add_task_screen.dart'; // Предполагаем, что этот файл в той же папке

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int xp = 0;
  // Список задач: каждая задача — это Map с названием, опытом и статусом
  List<Map<String, dynamic>> tasks = [];

  void _addTask(String title, int exp) {
    setState(() {
      tasks.add({'title': title, 'exp': exp, 'isCompleted': false});
    });
  }

  void _toggleTask(int index) {
    setState(() {
      final task = tasks[index];
      // Если задача была не выполнена, начисляем опыт
      if (!task['isCompleted']) {
        xp += task['exp'] as int;
      } else {
        // Если снимаем отметку, вычитаем опыт
        xp -= task['exp'] as int;
      }
      task['isCompleted'] = !task['isCompleted'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RPG Task Tracker"),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text("XP: $xp", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            leading: Checkbox(
              value: task['isCompleted'],
              onChanged: (_) => _toggleTask(index),
            ),
            title: Text(task['title']),
            trailing: Text("${task['exp']} XP"),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(onAdd: _addTask),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}