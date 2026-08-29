// Импортируем стандартный набор элементов интерфейса от Google (Flutter).
import 'package:flutter/material.dart';
// Импортируем файл с описанием модели задачи и категорий.
import '../models/task.dart';
// Импортируем экран выбора шаблона задачи внутри категории.
import 'template_selection_screen.dart';

// Экран выбора категории. Это Statefulwidget, потому что список категорий 
// может меняться (мы можем добавлять, удалять или редактировать их прямо здесь).
class CategorySelectionScreen extends StatefulWidget {
  // Список существующих категорий, который передается с предыдущего экрана.
  final List<Category> categories;
  // Функция-команда для сохранения обновленного списка категорий в общую память приложения.
  final Function(List<Category>) onUpdateCategories;
  // Функция, которая вызывается, когда пользователь окончательно выбрал категорию (и, возможно, шаблон).
  final Function(String, IconData, {String? template}) onCategorySelected;

  // Конструктор экрана. Все три параметра обязательны (required).
  const CategorySelectionScreen({
    super.key,
    required this.categories,
    required this.onUpdateCategories,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

// Внутренняя память (состояние) экрана выбора категории.
class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  // Локальный список категорий, с которым мы будем работать на этом экране.
  late List<Category> _currentCategories;

  // Функция инициализации: срабатывает один раз при открытии экрана. 
  // Копируем сюда список категорий, чтобы не менять оригинальный список напрямую до сохранения.
  @override
  void initState() {
    super.initState();
    _currentCategories = List.from(widget.categories);
  }

  // Универсальная функция, которая открывает окошко (диалог) для создания новой или редактирования существующей категории.
  void _addOrEditCategory({Category? category}) {
    // Контроллер текстового поля. Если категория передана — вставляем её старое имя, если нет — оставляем пустым.
    TextEditingController controller = TextEditingController(text: category?.name ?? "");
    // Выбираем иконку по умолчанию: либо у существующей категории, либо стандартную папки.
    int selectedIconCode = category?.iconCode ?? Icons.folder.codePoint;
    // Список готовых иконок, из которых пользователь может выбрать любую для своей категории.
    final List<IconData> iconOptions = [
      Icons.home, Icons.work, Icons.school, Icons.fitness_center, 
      Icons.shopping_cart, Icons.folder, Icons.star, Icons.lightbulb,
      Icons.favorite, Icons.local_cafe, Icons.book, Icons.brush,
      Icons.directions_run, Icons.games, Icons.music_note, Icons.attach_money
    ];

    // Открываем всплывающее окно (диалог) поверх экрана.
    showDialog(
      context: context,
      // StatefulBuilder нужен для того, чтобы окошко могло само себя перерисовывать 
      // (например, когда мы кликаем на другую иконку, она должна подсветиться).
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          // Меняем заголовок в зависимости от того, создаем мы новую или редактируем старую.
          title: Text(category == null ? "Новая категория" : "Редактировать"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Текстовое поле для ввода имени категории.
                TextField(controller: controller, decoration: const InputDecoration(labelText: "Название")),
                const SizedBox(height: 15),
                // Сетка (блок) с иконками, которые можно выбрать.
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  // Превращаем список иконок в набор кликабельных квадратиков.
                  children: iconOptions.map((icon) => InkWell(
                    // При нажатии на иконку обновляем выбранный код иконки внутри диалога.
                    onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // Если эта иконка сейчас выбрана — подсвечиваем её полупрозрачным синим цветом и синей рамкой.
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
          // Кнопки внизу всплывающего окна.
          actions: [
            // Кнопка отмены: просто закрывает окно без сохранения.
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
            // Кнопка сохранения.
            ElevatedButton(
              onPressed: () {
                // Проверяем, что пользователь ввел хоть какой-то текст для названия.
                if (controller.text.isNotEmpty) {
                  setState(() {
                    if (category == null) {
                      // Если категории не было (создаем новую) — добавляем её в наш локальный список.
                      _currentCategories.add(Category(name: controller.text, iconCode: selectedIconCode, templates: []));
                    } else {
                      // Если категория существовала — просто обновляем её имя и иконку.
                      category.name = controller.text;
                      category.iconCode = selectedIconCode;
                    }
                  });
                  // Передаем обновленный список наверх (главному экрану/хранилищу).
                  widget.onUpdateCategories(_currentCategories);
                  // Закрываем всплывающее окно.
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

// Функция удаления категории с предварительным вопросом-подтверждением.
  void _deleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Удалить категорию?"),
        content: const Text("Это действие нельзя отменить."),
        actions: [
          // Отмена удаления.
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
          // Подтверждение удаления (текст красный для привлечения внимания).
          TextButton(
            onPressed: () {
              setState(() => _currentCategories.remove(cat)); // Удаляем из списка
              widget.onUpdateCategories(_currentCategories);   // Сохраняем изменения
              Navigator.pop(ctx);                             // Закрываем окно
            },
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// Главная функция, рисующая интерфейс экрана выбора категории.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Верхняя панель с заголовком.
      appBar: AppBar(title: const Text("Выберите категорию")),
      // Список элементов на экране.
      body: ListView(
        children: [
          // Превращаем каждую категорию из нашего списка в строчку (ListTile).
          ..._currentCategories.map((cat) => ListTile(
            // Иконка категории слева (достаем её по сохраненному коду iconCode).
            leading: Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons')),
            // Название категории.
            title: Text(cat.name),
            // Кнопки управления справа от категории (редактировать и удалить).
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEditCategory(category: cat)),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteCategory(cat)),
              ],
            ),
            // При нажатии на категорию переходим на экран выбора шаблонов задач для этой категории.
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateSelectionScreen(
              category: cat,
              allCategories: _currentCategories,
              onUpdateCategories: widget.onUpdateCategories,
              onTemplateSelected: widget.onCategorySelected,
            ))),
          )),
          // Специальная последняя строчка в списке для добавления новой категории.
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