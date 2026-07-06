class Task {
  String id;
  String title;
  int experience;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.experience,
    this.isCompleted = false,
  });
}