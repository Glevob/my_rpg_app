import 'package:flutter/material.dart';
import '../models/task.dart';

class RecurringTasksScreen extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onUpdate;

  const RecurringTasksScreen({super.key, required this.tasks, required this.onUpdate});

  @override
  State<RecurringTasksScreen> createState() => _RecurringTasksScreenState();
}

class _RecurringTasksScreenState extends State<RecurringTasksScreen> {
  @override
  Widget build(BuildContext context) {
    // Фильтруем только повторяющиеся задачи
    final recurringTasks = widget.tasks.where((t) => t.recurrence != Recurrence.none).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Управление повторами")),
      body: recurringTasks.isEmpty
          ? const Center(child: Text("Нет повторяющихся задач"))
          : ListView.builder(
              itemCount: recurringTasks.length,
              itemBuilder: (context, index) {
                final task = recurringTasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text("Тип: ${task.recurrence.nameRu}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        widget.tasks.remove(task);
                      });
                      widget.onUpdate();
                    },
                  ),
                );
              },
            ),
    );
  }
}