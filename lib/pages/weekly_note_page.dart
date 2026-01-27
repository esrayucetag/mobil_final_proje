import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class WeeklyNotePage extends StatefulWidget {
  final String weekTitle;
  final bool isReadOnly;
  const WeeklyNotePage(
      {super.key, required this.weekTitle, this.isReadOnly = false});

  @override
  State<WeeklyNotePage> createState() => _WeeklyNotePageState();
}

class _WeeklyNotePageState extends State<WeeklyNotePage> {
  final TextEditingController _noteController = TextEditingController();
  bool isProgramStarted = false;
  Map<String, List<Task>> weeklyTasks = {
    "1. Gün": [],
    "2. Gün": [],
    "3. Gün": [],
    "4. Gün": [],
    "5. Gün": [],
    "6. Gün": [],
    "7. Gün": []
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // GARANTİLENMİŞ PUANLAMA MANTIĞI ✨
  double _calculateCurrentScore() {
    if (!isProgramStarted) return 0.0;

    double totalPoints = 0;
    bool recoveryMode = false;
    bool hasAnyActivity = false; // Sistemde görev var mı kontrolü

    for (int i = 0; i < 7; i++) {
      String dayKey = "${i + 1}. Gün";
      List<Task> tasks = weeklyTasks[dayKey]!;

      if (tasks.isEmpty) continue;
      hasAnyActivity = true;

      int completedTasksCount = tasks.where((t) => t.isCompleted).length;

      if (completedTasksCount == 0) {
        // Kural: Hiç görev yapılmadıysa -20 puan ve yarın telafi modu
        totalPoints -= 20.0;
        recoveryMode = true;
      } else {
        // Puan Ağırlığı Belirleme: Telafi (20), İlk Gün (40), Diğerleri (10)
        double dayWeight = recoveryMode ? 20.0 : (i == 0 ? 40.0 : 10.0);
        recoveryMode = false;

        // Zorluk katsayılarını topla
        double totalDifficulty =
            tasks.fold(0, (sum, item) => sum + item.difficulty);
        double earnedDifficulty = tasks
            .where((t) => t.isCompleted)
            .fold(0, (sum, item) => sum + item.difficulty);

        // Oranla ve puanı ekle (Sıfıra bölünme hatasını engelle)
        if (totalDifficulty > 0) {
          totalPoints += (earnedDifficulty / totalDifficulty) * dayWeight;
        }
      }
    }

    // Puan negatif çıkarsa 0 göster, hiç görev yoksa 0 göster
    return hasAnyActivity ? (totalPoints < 0 ? 0.0 : totalPoints) : 0.0;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    isProgramStarted = prefs.getBool('started_${widget.weekTitle}') ?? false;
    String? taskData = prefs.getString('tasks_${widget.weekTitle}');
    String? noteData = prefs.getString('note_${widget.weekTitle}');

    if (taskData != null) {
      Map<String, dynamic> decoded = json.decode(taskData);
      setState(() {
        weeklyTasks = decoded.map((k, v) =>
            MapEntry(k, (v as List).map((t) => Task.fromJson(t)).toList()));
        if (noteData != null) _noteController.text = noteData;
      });
    }
  }

  Future<void> _saveData() async {
    if (widget.isReadOnly) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('started_${widget.weekTitle}', isProgramStarted);
    String encoded = json.encode(weeklyTasks
        .map((k, v) => MapEntry(k, v.map((t) => t.toJson()).toList())));
    await prefs.setString('tasks_${widget.weekTitle}', encoded);
    await prefs.setString('note_${widget.weekTitle}', _noteController.text);
    setState(() {}); // Puanın anlık güncellenmesi için
  }

  @override
  Widget build(BuildContext context) {
    double currentScore = _calculateCurrentScore();

    return Scaffold(
      appBar: AppBar(
        title: Text("Puan: ${currentScore.toStringAsFixed(1)}"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "Haftalık plan notlarınızı buraya yazın...",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (v) => _saveData(),
            ),
          ),
          if (!isProgramStarted && !widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  setState(() => isProgramStarted = true);
                  _saveData();
                },
                child: const Text("HAFTAYI BAŞLAT",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                String day = "${index + 1}. Gün";
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ExpansionTile(
                    title: Text(day,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: (!isProgramStarted && !widget.isReadOnly)
                        ? IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Colors.blue),
                            onPressed: () => _addTask(day))
                        : null,
                    children: weeklyTasks[day]!
                        .map((task) => CheckboxListTile(
                              title: Text(task.title),
                              subtitle: Text("Zorluk: ${task.difficulty}"),
                              value: task.isCompleted,
                              onChanged: (widget.isReadOnly)
                                  ? null
                                  : (val) {
                                      setState(() => task.isCompleted = val!);
                                      _saveData();
                                    },
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addTask(String day) {
    TextEditingController tc = TextEditingController();
    int tempDiff = 1;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text("$day - Yeni Görev"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: tc,
                  decoration: const InputDecoration(hintText: "Görev adı")),
              const SizedBox(height: 20),
              const Text("Zorluk Seviyesi:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                    5,
                    (i) => GestureDetector(
                          onTap: () => setS(() => tempDiff = i + 1),
                          child: CircleAvatar(
                            backgroundColor: tempDiff == i + 1
                                ? Colors.blue
                                : Colors.grey[200],
                            child: Text("${i + 1}",
                                style: TextStyle(
                                    color: tempDiff == i + 1
                                        ? Colors.white
                                        : Colors.black)),
                          ),
                        )),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () {
                if (tc.text.isNotEmpty) {
                  setState(() => weeklyTasks[day]!
                      .add(Task(title: tc.text, difficulty: tempDiff)));
                  _saveData();
                  Navigator.pop(c);
                }
              },
              child: const Text("Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
