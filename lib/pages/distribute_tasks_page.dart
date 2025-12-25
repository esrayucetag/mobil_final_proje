import 'package:flutter/material.dart';
import '../models/weekly_task.dart';

class DistributeTasksPage extends StatelessWidget {
  final List<WeeklyTask> tasks;

  const DistributeTasksPage({super.key, required this.tasks});

  String gunAdi(int index) {
    const gunler = [
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar",
    ];
    return gunler[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dağıtılmış Görevler")),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final task = tasks[i];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(gunAdi(task.dayIndex)),
          );
        },
      ),
    );
  }
}
