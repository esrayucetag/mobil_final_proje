import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_keys.dart';
import 'weekly_note_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  List<String> allWeeks = [];
  Map<String, double> scores = {};
  Map<String, String> labels = {};
  String filter = "Hepsi";

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---- label & color ----
  String _labelFor(double s) {
    if (s < 20) return "Başarısız";
    if (s < 40) return "Küçük Adımlar";
    if (s < 60) return "Yoldaşın";
    if (s < 70) return "Yeterli";
    if (s < 80) return "İstikrarlı";
    if (s < 95) return "Başarılı";
    return "Efsanevi";
  }

  Color _colorFor(double s) {
    if (s < 20) return Colors.red;
    if (s < 40) return Colors.orange;
    if (s < 60) return Colors.amber;
    if (s < 70) return Colors.green;
    if (s < 80) return Colors.teal;
    if (s < 95) return Colors.blue;
    return Colors.purple;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = StorageKeys.savedWeeks(_uid);
    final saved = prefs.getStringList(savedKey) ?? <String>[];

    final Map<String, double> sc = {};
    final Map<String, String> lb = {};

    for (final w in saved) {
      // bitmişse finalScore al
      final fs = prefs.getDouble(StorageKeys.finalScore(_uid, w));
      if (fs != null) {
        sc[w] = fs;
        lb[w] =
            prefs.getString(StorageKeys.finalLabel(_uid, w)) ?? _labelFor(fs);
      } else {
        // bitmediyse şu anki skoru hesapla (gelişiyor)
        final calc = await _calculateLiveScore(prefs, w);
        sc[w] = calc;
        lb[w] = "Gelişiyor";
      }
    }

    if (!mounted) return;
    setState(() {
      allWeeks = saved.reversed.toList(); // en yeni üstte
      scores = sc;
      labels = lb;
    });
  }

  Future<double> _calculateLiveScore(
      SharedPreferences prefs, String weekTitle) async {
    final raw = prefs.getString(StorageKeys.tasks(_uid, weekTitle));
    final started =
        prefs.getBool(StorageKeys.started(_uid, weekTitle)) ?? false;
    if (raw == null || !started) return 0.0;

    final decoded = json.decode(raw) as Map<String, dynamic>;

    const dayBase = [30.0, 12.0, 12.0, 12.0, 12.0, 11.0, 11.0];
    const missPenalty = [-15.0, -7.0, -4.0, -2.0, -1.0, -1.0, -1.0];

    double total = 0.0;
    int missStreak = 0;

    for (int i = 0; i < 7; i++) {
      final dayKey = "${i + 1}. Gün";
      final list = (decoded[dayKey] ?? []) as List<dynamic>;

      if (list.isEmpty) continue;

      final completed = list.where((t) => t['isCompleted'] == true).toList();
      if (completed.isEmpty) {
        total += missPenalty[missStreak.clamp(0, missPenalty.length - 1)];
        missStreak++;
        continue;
      }

      missStreak = 0;

      double totalW = 0.0;
      double earnedW = 0.0;

      for (final t in list) {
        final d = (t['difficulty'] ?? 1).toDouble();
        totalW += d;
        if (t['isCompleted'] == true) earnedW += d;
      }
      if (totalW <= 0) continue;
      total += (earnedW / totalW) * dayBase[i];
    }

    if (total < 0) return 0.0;
    if (total > 100) return 100.0;
    return total;
  }

  Future<void> _openViewSheet(String weekTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyNote =
        prefs.getString(StorageKeys.weeklyNote(_uid, weekTitle)) ?? "";
    final selfNote =
        prefs.getString(StorageKeys.selfNote(_uid, weekTitle)) ?? "";

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weekTitle,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text("Haftalık Not",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(weeklyNote.isEmpty ? "—" : weeklyNote),
            const SizedBox(height: 12),
            const Text("Kendine Not",
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(selfNote.isEmpty ? "—" : selfNote),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeeklyNotePage(
                              weekTitle: weekTitle, isReadOnly: true),
                        ),
                      );
                      await _load();
                    },
                    child: const Text("Görüntüle"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Kapat"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWeek(String weekTitle) async {
    if (!mounted) return;

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Silinsin mi?"),
            content: const Text(
                "Emin misin? Geçmiş, geleceğe yön verir. Yine de silmek istiyor musun?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Vazgeç")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Sil")),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final prefs = await SharedPreferences.getInstance();

    // tekil keyleri kaldır
    await prefs.remove(StorageKeys.tasks(_uid, weekTitle));
    await prefs.remove(StorageKeys.weeklyNote(_uid, weekTitle));
    await prefs.remove(StorageKeys.selfNote(_uid, weekTitle));
    await prefs.remove(StorageKeys.started(_uid, weekTitle));
    await prefs.remove(StorageKeys.finished(_uid, weekTitle));
    await prefs.remove(StorageKeys.finalScore(_uid, weekTitle));
    await prefs.remove(StorageKeys.finalLabel(_uid, weekTitle));

    // listelerden çıkar
    final savedKey = StorageKeys.savedWeeks(_uid);
    final saved = prefs.getStringList(savedKey) ?? <String>[];
    saved.remove(weekTitle);
    await prefs.setStringList(savedKey, saved);

    final finKey = StorageKeys.finishedWeeks(_uid);
    final finished = prefs.getStringList(finKey) ?? <String>[];
    finished.remove(weekTitle);
    await prefs.setStringList(finKey, finished);

    final interKey = StorageKeys.interruptedWeeks(_uid);
    final inter = prefs.getStringList(interKey) ?? <String>[];
    inter.remove(weekTitle);
    await prefs.setStringList(interKey, inter);

    final activeKey = StorageKeys.activeWeek(_uid);
    if (prefs.getString(activeKey) == weekTitle) {
      await prefs.remove(activeKey);
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final disp = allWeeks.where((w) {
      if (filter == "Hepsi") return true;
      final isFinished = labels[w] != "Gelişiyor";
      return filter == "Tamamlanan" ? isFinished : !isFinished;
    }).toList();

    // üst barlar (max 12)
    final top = allWeeks.take(12).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Analizler")),
      body: Column(
        children: [
          if (top.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: SizedBox(
                  height: 170,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),
                        barGroups: List.generate(top.length, (i) {
                          final w = top[i];
                          final s = scores[w] ?? 0.0;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: s,
                                width: 14,
                                borderRadius: BorderRadius.circular(10),
                                color: _colorFor(s),
                              ),
                            ],
                          );
                        }),
                        maxY: 100,
                        minY: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text("Filtre:",
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: filter,
                  items: const [
                    DropdownMenuItem(value: "Hepsi", child: Text("Hepsi")),
                    DropdownMenuItem(
                        value: "Tamamlanan", child: Text("Tamamlanan")),
                    DropdownMenuItem(value: "Devam", child: Text("Devam Eden")),
                  ],
                  onChanged: (v) => setState(() => filter = v ?? "Hepsi"),
                ),
              ],
            ),
          ),
          Expanded(
            child: disp.isEmpty
                ? const Center(child: Text("Henüz kayıt yok."))
                : ListView.builder(
                    itemCount: disp.length,
                    itemBuilder: (context, i) {
                      final w = disp[i];
                      final s = scores[w] ?? 0.0;
                      final lb = labels[w] ?? _labelFor(s);
                      final c = _colorFor(s);

                      return Card(
                        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        child: ListTile(
                          leading: Container(
                            width: 5,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          title: Text(w,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text("$lb • ${s.toStringAsFixed(1)} P"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == "view") _openViewSheet(w);
                              if (v == "delete") _deleteWeek(w);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: "view", child: Text("Görüntüle")),
                              PopupMenuItem(
                                  value: "delete", child: Text("Sil")),
                            ],
                          ),
                          onTap: () => _openViewSheet(w),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
