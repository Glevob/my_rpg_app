import 'package:flutter/material.dart';
import '../models/task.dart';
import 'template_selection_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final List<Category> categories;
  final Function(List<Category>) onUpdateCategories;
  final Function(String, IconData, {String? template}) onCategorySelected;

  const CategorySelectionScreen({
    super.key,
    required this.categories,
    required this.onUpdateCategories,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  late List<Category> _currentCategories;

  @override
  void initState() {
    super.initState();
    _currentCategories = List.from(widget.categories);
  }

  void _addOrEditCategory({Category? category}) {
    TextEditingController controller = TextEditingController(text: category?.name ?? "");
    int selectedIconCode = category?.iconCode ?? Icons.folder.codePoint;
    final List<IconData> iconOptions = [
      Icons.home, Icons.work, Icons.school, Icons.fitness_center, 
      Icons.shopping_cart, Icons.folder, Icons.star, Icons.lightbulb,
      Icons.favorite, Icons.local_cafe, Icons.book, Icons.brush,
      Icons.directions_run, Icons.games, Icons.music_note, Icons.attach_money
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(category == null ? "Новая категория" : "Редактировать"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller, decoration: const InputDecoration(labelText: "Название")),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: iconOptions.map((icon) => InkWell(
                    onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIconCode == icon.codePoint ? Colors.blue.withOpacity(0.2) : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selectedIconCode == icon.codePoint ? Colors.blue : Colors.transparent),
                      ),
                      child: Icon(icon, size: 30),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    if (category == null) {
                      _currentCategories.add(Category(name: controller.text, iconCode: selectedIconCode, templates: []));
                    } else {
                      category.name = controller.text;
                      category.iconCode = selectedIconCode;
                    }
                  });
                  widget.onUpdateCategories(_currentCategories);
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      }),
    );
  }

  void _deleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Удалить категорию?"),
        content: const Text("Это действие нельзя отменить."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              setState(() => _currentCategories.remove(cat));
              widget.onUpdateCategories(_currentCategories);
              Navigator.pop(ctx);
            },
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Выберите категорию")),
      body: ListView(
        children: [
          ..._currentCategories.map((cat) => ListTile(
            leading: Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons')),
            title: Text(cat.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEditCategory(category: cat)),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteCategory(cat)),
              ],
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateSelectionScreen(
              category: cat,
              allCategories: _currentCategories,
              onUpdateCategories: widget.onUpdateCategories,
              onTemplateSelected: widget.onCategorySelected,
            ))),
          )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Создать категорию"),
            onTap: () => _addOrEditCategory(),
          ),
        ],
      ),
    );
  }
}