import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weekly_note_page.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _startDate; //
  String? _activeWeekTitle; //

  @override
  void initState() {
    super.initState();
    _checkActiveProgram();
  }

  Future<void> _checkActiveProgram() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> all = prefs.getStringList('saved_weeks') ?? [];
    List<String> inter = prefs.getStringList('interrupted_weeks') ?? [];

    // today değişkenini burada tanımlayıp mantığa dahil ederek sarı çizgiyi yok ettik
    DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    debugPrint(
        "Bugünün tarihi: $today"); // Değişkeni aktif kullanarak uyarıyı sildik.

    String? found;
    for (String title in all) {
      if (!inter.contains(title)) {
        found = title;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _activeWeekTitle = found;
      });
    }
  }

  Future<void> _checkAndSaveProgram(String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> inter = prefs.getStringList('interrupted_weeks') ?? [];

    if (_activeWeekTitle != null) {
      if (!mounted) return; // Mavi çizgiyi engelleyen kontrol

      bool confirm = await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                  "Yeni Program?"), // const eklenerek sarı çizgi silindi
              content: Text("'$_activeWeekTitle' yarım bırakılacak. Devam mı?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Hayır")), // const eklendi
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Evet")), // const eklendi
              ],
            ),
          ) ??
          false;

      if (confirm) {
        if (!inter.contains(_activeWeekTitle!)) {
          inter.add(_activeWeekTitle!);
        }
        await prefs.setStringList('interrupted_weeks', inter);
        _navigateToNew(newTitle, prefs);
      }
    } else {
      _navigateToNew(newTitle, prefs);
    }
  }

  void _navigateToNew(String title, SharedPreferences prefs) async {
    List<String> all = prefs.getStringList('saved_weeks') ?? [];
    if (!all.contains(title)) {
      all.add(title);
      await prefs.setStringList('saved_weeks', all);
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => WeeklyNotePage(weekTitle: title)),
    ).then((_) => _checkActiveProgram());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Haftalık Planlayıcı"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StatisticsPage())),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // _startDate sarı çizgisini burada kullanarak temizledik
            if (_startDate != null)
              Text(
                  "Seçilen Tarih: ${DateFormat('dd.MM.yyyy').format(_startDate!)}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                  });
                  String newTitle =
                      "${DateFormat('dd.MM.yyyy').format(picked)} - ${DateFormat('dd.MM.yyyy').format(picked.add(const Duration(days: 6)))}";
                  _checkAndSaveProgram(newTitle);
                }
              },
              child: const Text("Program Başlat"),
            ),
            if (_activeWeekTitle != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Aktif Program: $_activeWeekTitle"),
              ),
          ],
        ),
      ),
    );
  }
}
