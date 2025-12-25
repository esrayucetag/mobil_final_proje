import 'package:flutter/material.dart';

// Görev modelimizi sayfa içinde tanımlıyoruz (İleride ayırabilirsin)
class Task {
  String title;
  int difficulty;
  bool isCompleted;

  Task(
      {required this.title,
      required this.difficulty,
      this.isCompleted = false});
}

class DayDetailPage extends StatefulWidget {
  final int dayNumber;
  const DayDetailPage({super.key, required this.dayNumber});

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  final List<Task> _tasks = []; // O güne ait görevler listesi
  final TextEditingController _taskController = TextEditingController();
  double _currentDifficulty = 1.0; // Şeritteki başlangıç değeri

  // Zorluk seviyesine göre renk döndüren fonksiyon
  Color _getDifficultyColor(double value) {
    if (value <= 1) return Colors.green;
    if (value <= 2) return Colors.yellow.shade700;
    if (value <= 3) return Colors.orange;
    if (value <= 4) return Colors.deepOrange;
    return Colors.red;
  }

  // Görev ekleme penceresini açan fonksiyon
  void _openAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin altında kalmaması için
      builder: (context) {
        return StatefulBuilder(
          // Modal içinde slider'ın hareket etmesi için
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: "Görev Yazın",
                      hintText: "Örn: 20 sayfa kitap oku",
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Zorluk Katsayısı: ${_currentDifficulty.toInt()}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(_currentDifficulty),
                    ),
                  ),

                  // İŞTE O RENKLİ ŞERİT (SLIDER)
                  Slider(
                    value: _currentDifficulty,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: _getDifficultyColor(_currentDifficulty),
                    onChanged: (value) {
                      setModalState(() {
                        _currentDifficulty = value;
                      });
                    },
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_taskController.text.isNotEmpty) {
                        setState(() {
                          _tasks.add(Task(
                            title: _taskController.text,
                            difficulty: _currentDifficulty.toInt(),
                          ));
                        });
                        _taskController.clear();
                        _currentDifficulty = 1.0; // Sıfırla
                        Navigator.pop(context); // Kapat
                      }
                    },
                    child: const Text("Görevi Kaydet"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.dayNumber}. Gün Görevleri")),
      body: _tasks.isEmpty
          ? const Center(
              child: Text("Henüz görev eklenmedi. + butonuna basın."))
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (val) {
                      setState(() {
                        task.isCompleted = val!;
                      });
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: CircleAvatar(
                    backgroundColor:
                        _getDifficultyColor(task.difficulty.toDouble()),
                    radius: 12,
                    child: Text(
                      task.difficulty.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
