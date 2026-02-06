import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_keys.dart';
import 'weekly_note_page.dart';

class StartDatePage extends StatefulWidget {
  const StartDatePage({super.key});

  @override
  State<StartDatePage> createState() => _StartDatePageState();
}

class _StartDatePageState extends State<StartDatePage> {
  DateTime selectedDate = DateTime.now();
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  String _weekTitle(DateTime start) {
    final a = DateFormat('dd.MM.yyyy').format(start);
    final b =
        DateFormat('dd.MM.yyyy').format(start.add(const Duration(days: 6)));
    return "$a - $b";
  }

  Future<void> _createWeek() async {
    final start =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final newTitle = _weekTitle(start);

    final prefs = await SharedPreferences.getInstance();
    final activeKey = StorageKeys.activeWeek(_uid);
    final currentActive = prefs.getString(activeKey);

    // Eğer aktif hafta varsa, kullanıcıdan onay al: yarım bırakılacak
    if (currentActive != null && currentActive != newTitle) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Yeni Program?"),
              content: Text("'$currentActive' yarım bırakılacak. Devam mı?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Hayır")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Evet")),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      final interKey = StorageKeys.interruptedWeeks(_uid);
      final inter = prefs.getStringList(interKey) ?? <String>[];
      if (!inter.contains(currentActive)) {
        inter.add(currentActive);
        await prefs.setStringList(interKey, inter);
      }
    }

    // saved list
    final savedKey = StorageKeys.savedWeeks(_uid);
    final saved = prefs.getStringList(savedKey) ?? <String>[];
    if (!saved.contains(newTitle)) {
      saved.add(newTitle);
      await prefs.setStringList(savedKey, saved);
    }

    // active week set
    await prefs.setString(activeKey, newTitle);

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WeeklyNotePage(weekTitle: newTitle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Başlangıç Tarihi")),
      body: Column(
        children: [
          Expanded(
            child: CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              onDateChanged: (d) => setState(() => selectedDate = d),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _createWeek,
                child: Text("Haftayı Oluştur: ${_weekTitle(selectedDate)}"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
