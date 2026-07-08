import 'package:flutter/material.dart';
import '../models/task.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final Category category;
  final List<Category> allCategories;
  final Function(List<Category>) onUpdateCategories;
  final Function(String, IconData, {String? template}) onTemplateSelected;

  const TemplateSelectionScreen({super.key, required this.category, required this.allCategories, required this.onUpdateCategories, required this.onTemplateSelected});

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  
  late List<String> _localTemplates;

  @override
  void initState() {
    super.initState();
    _localTemplates = List.from(widget.category.templates);
  }
  
  void _addTemplate() {
    TextEditingController c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Новая задача"),
      content: TextField(controller: c),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
        ElevatedButton(
          onPressed: () {
            if (c.text.isNotEmpty) {
              setState(() => _localTemplates.add(c.text)); // Обновляем UI
              widget.category.templates = _localTemplates; // Сохраняем в объект
              widget.onUpdateCategories(widget.allCategories); // Отправляем в Home
              Navigator.pop(ctx);
            }
          },
          child: const Text("Добавить"),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ListView(children: [
        ..._localTemplates.map((t) => ListTile(
          title: Text(t),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Удалить шаблон?"),
                  content: const Text("Этот шаблон будет удален из категории."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _localTemplates.remove(t);
                        });
                        widget.category.templates = _localTemplates;
                        widget.onUpdateCategories(widget.allCategories);
                        Navigator.pop(ctx); // Закрыть диалог
                      },
                      child: const Text("Удалить", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          onTap: () {
            widget.onTemplateSelected(
              widget.category.name,
              IconData(widget.category.iconCode, fontFamily: 'MaterialIcons'),
              template: t
            );
            Navigator.pop(context); // Закрываем экран шаблонов
            Navigator.pop(context); // Закрываем экран категорий
          }
        )),
        ListTile(leading: const Icon(Icons.add), title: const Text("Добавить шаблон"), onTap: _addTemplate),
      ]),
    );
  }
}