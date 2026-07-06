import 'package:flutter/material.dart';
import 'add_task_screen.dart'; // Предполагаем, что этот файл в той же папке

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int xp = 0;
  List<Map<String, dynamic>> tasks = [];

  // Метод для сортировки списка
  void _sortTasks() {
    tasks.sort((a, b) {
      final aDone = a['isCompleted'] as bool;
      final bDone = b['isCompleted'] as bool;
      if (aDone == bDone) return 0;
      return aDone ? 1 : -1;
    });
  }

  // Метод дял добавления задачи
  void _addTask(String title, int exp) {
    setState(() {
      tasks.add({'title': title, 'exp': exp, 'isCompleted': false});
      _sortTasks();
    });
  }

  // Метод выполнения задачи
  void _toggleTask(int index) {
    setState(() {
      final task = tasks[index];
      
      if (!task['isCompleted']) {
        xp += task['exp'] as int;
      } else {
        xp -= task['exp'] as int;
      }
      
      task['isCompleted'] = !task['isCompleted'];
      _sortTasks();
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
          final isDone = task['isCompleted'] as bool;
          
          return ListTile(
            key: ValueKey(task.toString() + index.toString()), 
            onTap: () => _toggleTask(index),
            leading: Checkbox(
              value: isDone,
              onChanged: (_) => _toggleTask(index),
            ),
            title: Text(
              task['title'],
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : Colors.black,
              ),
            ),
            trailing: Text(
              "${task['exp']} XP",
              style: TextStyle(
                color: isDone ? Colors.grey : Colors.indigo,
                fontWeight: isDone ? FontWeight.normal : FontWeight.bold,
              ),
            ),
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