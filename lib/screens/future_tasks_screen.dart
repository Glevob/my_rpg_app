import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class FutureTasksScreen extends StatelessWidget {
  final List<Task> regularTasks;
  final List<Task> recurringTasks;
  final VoidCallback onUpdate;

  const FutureTasksScreen({
    super.key,
    required this.regularTasks,
    required this.recurringTasks,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final logicalNow = DateTime.now().subtract(const Duration(hours: 4));
    final oneWeekLater = logicalNow.add(const Duration(days: 7));

    final distantRegular = regularTasks.where((t) => t.dueDate != null && t.dueDate!.isAfter(oneWeekLater)).toList();
    final distantRecurring = recurringTasks.where((t) => t.dueDate != null && t.dueDate!.isAfter(oneWeekLater)).toList();
    final allDistant = [...distantRegular, ...distantRecurring]
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Будущие задачи (> 1 недели)"),
      ),
      body: allDistant.isEmpty
          ? const Center(
              child: Text(
                "Нет задач со сроком более 1 недели",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: allDistant.length,
              itemBuilder: (context, index) {
                final task = allDistant[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Срок: ${dateFormat.format(task.dueDate!)}"),
                    trailing: Text("${task.experience} XP", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}