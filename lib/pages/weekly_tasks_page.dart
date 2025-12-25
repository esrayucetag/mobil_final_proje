import 'package:flutter/material.dart';
import '../models/weekly_task.dart';
import 'distribute_tasks_page.dart';

class WeeklyTasksPage extends StatelessWidget {
  final int startDayIndex;

  WeeklyTasksPage({super.key, required this.startDayIndex});

  final List<String> taskTitles = [
    "Spor",
    "Ders",
    "Kitap",
  ];

  @override
  Widget build(BuildContext context) {
    final tasks = taskTitles
        .map(
          (t) => WeeklyTask(title: t, dayIndex: startDayIndex),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Haftalık Görevler")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Görevleri Dağıt"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DistributeTasksPage(tasks: tasks),
              ),
            );
          },
        ),
      ),
    );
  }
}
