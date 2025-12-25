import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weekly_note_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<String> savedWeeks = [];
  List<String> interruptedWeeks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedWeeks = prefs.getStringList('saved_weeks') ?? [];
      interruptedWeeks = prefs.getStringList('interrupted_weeks') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler")),
      body: savedWeeks.isEmpty
          ? const Center(child: Text("Henüz kayıtlı program yok."))
          : ListView.builder(
              itemCount: savedWeeks.length,
              itemBuilder: (context, index) {
                String title = savedWeeks[index];
                bool isInterrupted = interruptedWeeks.contains(title);

                return ListTile(
                  leading: Icon(Icons.history,
                      color: isInterrupted ? Colors.orange : Colors.blue),
                  title: Text(title),
                  subtitle: Text(isInterrupted
                      ? "⚠️ Durum: Yarım Bırakıldı"
                      : "✅ Durum: Tamamlandı veya Aktif"),
                  trailing: isInterrupted
                      ? const Badge(
                          label: Text("YARIM"), backgroundColor: Colors.orange)
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WeeklyNotePage(
                                weekTitle: title, isReadOnly: true)));
                  },
                );
              },
            ),
    );
  }
}
