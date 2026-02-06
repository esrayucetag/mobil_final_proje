import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'weekly_note_page.dart';

class StartDatePage extends StatefulWidget {
  final String uid;
  const StartDatePage({super.key, required this.uid});

  @override
  State<StartDatePage> createState() => _StartDatePageState();
}

class _StartDatePageState extends State<StartDatePage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final end = start.add(const Duration(days: 6));
    final weekTitle =
        "${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}";

    return Scaffold(
      appBar: AppBar(title: const Text("Tarih Seçimi")),
      body: Column(
        children: [
          Expanded(
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              onDateChanged: (date) => setState(() => selectedDate = date),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyNotePage(
                        uid: widget.uid,
                        weekTitle: weekTitle,
                      ),
                    ),
                  );
                },
                child: const Text("Haftayı Planla"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
