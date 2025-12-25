import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weekly_note_page.dart';
import 'statistics_page.dart';
import 'current_program_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _startDate;
  DateTime? _endDate;

  // 1. Sadece tarih seçiyoruz, hemen kaydetmiyoruz!
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: "Programın Başlayacağı Günü Seç",
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = picked.add(const Duration(days: 6));
      });
      // Buradaki otomatik kayıt çağırma satırını sildim aşkım!
    }
  }

  // 2. Bu fonksiyonu artık buton tetikleyecek
  Future<void> _checkAndSaveProgram() async {
    if (_startDate == null || _endDate == null) {
      _showErrorDialog("Lütfen önce bir başlangıç tarihi seç aşkım!");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> allWeeks = prefs.getStringList('saved_weeks') ?? [];
    String newWeekTitle =
        "${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}";

    String? overlappingWeek;
    for (String week in allWeeks) {
      try {
        List<String> parts = week.split(' - ');
        DateTime oldStart = DateFormat('dd.MM.yyyy').parse(parts[0]);
        DateTime oldEnd = DateFormat('dd.MM.yyyy').parse(parts[1]);

        if ((_startDate!.isBefore(oldEnd) && _startDate!.isAfter(oldStart)) ||
            _startDate!.isAtSameMomentAs(oldStart) ||
            _startDate!.isAtSameMomentAs(oldEnd)) {
          overlappingWeek = week;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (overlappingWeek != null) {
      if (!mounted) return;
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Aktif Program Var!"),
              content: Text(
                  "Bu tarihler halihazırdaki '$overlappingWeek' programının içinde kalıyor. Eskisini yarım bırakıp yeniye geçelim mi?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Evet")),
              ],
            ),
          ) ??
          false;

      if (confirm) {
        await _markAsInterrupted(overlappingWeek);
        _navigateToNewProgram(newWeekTitle);
      }
    } else {
      _navigateToNewProgram(newWeekTitle);
    }
  }

  Future<void> _markAsInterrupted(String title) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> interrupted = prefs.getStringList('interrupted_weeks') ?? [];
    if (!interrupted.contains(title)) {
      interrupted.add(title);
      await prefs.setStringList('interrupted_weeks', interrupted);
    }
  }

  void _navigateToNewProgram(String title) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> allWeeks = prefs.getStringList('saved_weeks') ?? [];

    // AŞKIM BURASI ÇOK ÖNEMLİ:
    // Yeni programı açarken, eğer bu isimde bir "yarım bırakıldı" kaydı varsa onu siliyoruz.
    List<String> interrupted = prefs.getStringList('interrupted_weeks') ?? [];
    if (interrupted.contains(title)) {
      interrupted.remove(title);
      await prefs.setStringList('interrupted_weeks', interrupted);
    }

    if (!allWeeks.contains(title)) {
      allWeeks.add(title);
      await prefs.setStringList('saved_weeks', allWeeks);
    }

    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WeeklyNotePage(weekTitle: title)));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hata"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Haftalık Planlayıcı"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TARİH SEÇME BUTONU
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(_startDate == null
                  ? "Başlangıç Tarihi Seç"
                  : "Seçilen: ${DateFormat('dd.MM.yyyy').format(_startDate!)}"),
              onPressed: () => _selectStartDate(context),
            ),
            const SizedBox(height: 10),

            // İŞTE SENİN ÇALIŞMAYAN KAYDET BUTONUN BURADA CANLANIYOR AŞKIM!
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50)),
              onPressed:
                  _checkAndSaveProgram, // Artık butona basınca kontrol ediyor!
              child: const Text("Programı Kaydet ve Başla"),
            ),

            const Divider(height: 40, indent: 50, endIndent: 50),

            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text("Güncel Programım"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CurrentProgramPage())),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text("İstatistikler"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StatisticsPage())),
            ),
          ],
        ),
      ),
    );
  }
}
