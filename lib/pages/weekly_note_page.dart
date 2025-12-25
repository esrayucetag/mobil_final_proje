import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<String, List<Task>> weeklyTasks = {
    "1. Gün": [],
    "2. Gün": [],
    "3. Gün": [],
    "4. Gün": [],
    "5. Gün": [],
    "6. Gün": [],
    "7. Gün": [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- SENİN ÖZEL PUAN SİSTEMİN (GELECEK GÜNLER CEZA VERMEZ) ---
  double _calculateCurrentScore() {
    double totalScore = 0;
    bool recoveryMode = false;

    List<String> days = weeklyTasks.keys.toList();
    DateTime now = DateTime.now();
    DateTime start;
    try {
      start = DateFormat('dd.MM.yyyy').parse(widget.weekTitle.split(' - ')[0]);
    } catch (e) {
      start = DateTime.now();
    }

    for (int i = 0; i < days.length; i++) {
      DateTime dayDate =
          DateTime(start.year, start.month, start.day).add(Duration(days: i));

      // Eğer gün henüz gelmediyse puanlamaya katma (Skorun neden -40 olduğunu çözen kısım)
      if (now.isBefore(dayDate) && !_isDayToday(dayDate)) {
        continue;
      }

      List<Task> tasks = weeklyTasks[days[i]]!;
      if (tasks.isEmpty) continue;

      int completedCount = tasks.where((t) => t.isCompleted).length;

      if (completedCount == 0) {
        totalScore -= 20; // HİÇBİR ŞEY YAPMADIYSA CEZA
        recoveryMode = true;
      } else {
        double dayBase = (i == 0) ? 40.0 : 10.0;
        if (recoveryMode) {
          dayBase *= 2; // GERİ DÖNÜŞ ÖDÜLÜ
          recoveryMode = false;
        }

        double dayTotalWeight =
            tasks.fold(0, (sum, item) => sum + item.difficulty);
        double dayEarnedWeight = tasks
            .where((t) => t.isCompleted)
            .fold(0, (sum, item) => sum + item.difficulty);

        totalScore += (dayEarnedWeight / dayTotalWeight) * dayBase;
      }
    }
    return totalScore;
  }

  bool _isDayToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isDayAccessible(int dayIndex) {
    if (widget.isReadOnly) return false;
    try {
      DateTime now = DateTime.now();
      DateTime start =
          DateFormat('dd.MM.yyyy').parse(widget.weekTitle.split(' - ')[0]);
      DateTime target = DateTime(start.year, start.month, start.day)
          .add(Duration(days: dayIndex));
      if (now.isBefore(target) && !_isDayToday(target)) return false;
      if (now.isAfter(target.add(const Duration(days: 2)))) return false;
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('tasks_${widget.weekTitle}');
    String? note = prefs.getString('note_${widget.weekTitle}');
    if (data != null) {
      Map<String, dynamic> decoded = json.decode(data);
      setState(() {
        weeklyTasks = decoded.map((key, value) => MapEntry(
            key, (value as List).map((t) => Task.fromJson(t)).toList()));
        if (note != null) _noteController.text = note;
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = json.encode(weeklyTasks.map(
        (key, value) => MapEntry(key, value.map((t) => t.toJson()).toList())));
    await prefs.setString('tasks_${widget.weekTitle}', encoded);
    await prefs.setString('note_${widget.weekTitle}', _noteController.text);
  }

  @override
  Widget build(BuildContext context) {
    double currentScore = _calculateCurrentScore();
    return Scaffold(
      appBar: AppBar(
        title: Text("Skor: ${currentScore.toStringAsFixed(1)}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor:
            currentScore < 0 ? Colors.red.shade50 : Colors.green.shade50,
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.blue),
              onPressed: () async {
                await _saveData();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                      content: Text("Kaydedildi! ✅"),
                      duration: Duration(seconds: 1)),
                );
              },
            )
        ],
      ),
      body: Column(
        children: [
          // SADECE NOT ALANI (OTOMATİK DAĞITMAZ)
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                onChanged: (val) => _saveData(),
                decoration: const InputDecoration(
                  hintText: "Haftalık stratejini buraya not al...",
                  helperText: "Bu alan sadece senin referansın içindir.",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                String day = "${index + 1}. Gün";
                bool accessible = _isDayAccessible(index);
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: accessible ? null : Colors.grey.shade100,
                  child: ExpansionTile(
                    leading: Icon(
                        accessible ? Icons.calendar_today : Icons.lock,
                        color: accessible ? Colors.blue : Colors.grey),
                    title: Text(day,
                        style: TextStyle(
                            color: accessible ? Colors.black : Colors.grey)),
                    trailing: accessible
                        ? IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addTask(day))
                        : null,
                    children: weeklyTasks[day]!.map((task) {
                      return ListTile(
                        title: Text(task.title,
                            style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null)),
                        trailing: Checkbox(
                          value: task.isCompleted,
                          onChanged: accessible
                              ? (val) {
                                  setState(() => task.isCompleted = val!);
                                  _saveData();
                                }
                              : null,
                        ),
                      );
                    }).toList(),
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
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("$day Görev Ekle"),
              content: TextField(
                  controller: tc,
                  decoration: const InputDecoration(hintText: "Görev adı...")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () {
                      if (tc.text.isNotEmpty) {
                        setState(() => weeklyTasks[day]!
                            .add(Task(title: tc.text, difficulty: 2)));
                        _saveData();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Ekle")),
              ],
            ));
  }
}
