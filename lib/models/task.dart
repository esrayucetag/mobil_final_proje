class Task {
  String title;
  bool isCompleted;
  int difficulty;
  Task({required this.title, this.isCompleted = false, this.difficulty = 1});

  Map<String, dynamic> toJson() =>
      {'title': title, 'isCompleted': isCompleted, 'difficulty': difficulty};
  factory Task.fromJson(Map<String, dynamic> json) => Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      difficulty: json['difficulty'] ?? 1);
}
