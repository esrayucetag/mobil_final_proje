class Task {
  String title;
  int difficulty; // 1-5 arası
  bool isCompleted;

  Task({
    required this.title,
    required this.difficulty,
    this.isCompleted = false, // Varsayılan olarak yapılmadı
  });
}
