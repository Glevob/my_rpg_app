import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/task_utils.dart';

class XpSettingsScreen extends StatefulWidget {
  const XpSettingsScreen({super.key});

  @override
  State<XpSettingsScreen> createState() => _XpSettingsScreenState();
}

class _XpSettingsScreenState extends State<XpSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Настройка опыта (XP)")),
      body: ListView(
        children: TaskDifficulty.values.map((d) {
          return ListTile(
            title: Text(difficultyNames[d]!),
            trailing: SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: difficultyXpMap[d].toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                onFieldSubmitted: (val) {
                  int? newXp = int.tryParse(val);
                  if (newXp != null) {
                    saveXpSetting(d, newXp);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Сохранено!")));
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}