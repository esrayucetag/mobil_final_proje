import 'package:flutter/material.dart';
import 'weekly_note_page.dart';

class StartDatePage extends StatefulWidget {
  const StartDatePage({super.key});

  @override
  State<StartDatePage> createState() => _StartDatePageState();
}

class _StartDatePageState extends State<StartDatePage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Hata riskini azaltmak için başlığı en basit haliyle oluşturalım
    String weekTitle =
        "${selectedDate.day}.${selectedDate.month} - ${selectedDate.add(const Duration(days: 6)).day}.${selectedDate.add(const Duration(days: 6)).month}";

    return Scaffold(
      appBar: AppBar(title: const Text("Tarih Seçimi")),
      body: Column(
        children: [
          Expanded(
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeeklyNotePage(weekTitle: weekTitle),
                ),
              );
            },
            child: const Text("Haftayı Planla"),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
