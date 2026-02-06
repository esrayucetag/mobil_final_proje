import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/storage_keys.dart';
import 'weekly_note_page.dart';

class StatisticsPage extends StatefulWidget {
  final String uid;
  const StatisticsPage({super.key, required this.uid});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<String> _weeks = [];
  String _filter = "Hepsi"; // Hepsi / Tamamlanan / Devam ediyor
  final Map<String, double> _scores = {};
  final Map<String, String> _labels = {};
  final Map<String, String> _selfNotes = {};
  final Map<String, String> _weekNotes = {};
  final Map<String, String> _reviews = {};

  static const List<double> _base = [30, 12, 12, 12, 12, 12, 10];
  static const List<double> _missPenalty = [15, 7, 4, 2, 1, 1];

  _Band _bandOf(double s) {
    if (s < 20)
      return _Band("Başarısız", Icons.sentiment_very_dissatisfied_rounded,
          const Color(0xFFEF4444));
    if (s < 40)
      return _Band("Küçük Adımlar", Icons.directions_walk_rounded,
          const Color(0xFFF59E0B));
    if (s < 60)
      return _Band(
          "Yoldasın", Icons.trending_up_rounded, const Color(0xFF3B82F6));
    if (s < 70)
      return _Band("Yeterli", Icons.check_circle_outline_rounded,
          const Color(0xFF22C55E));
    if (s < 80)
      return _Band(
          "İstikrarlı", Icons.auto_graph_rounded, const Color(0xFF14B8A6));
    if (s < 95)
      return _Band(
          "Başarılı", Icons.emoji_events_rounded, const Color(0xFF8B5CF6));
    return _Band(
        "Efsanevi", Icons.auto_awesome_rounded, const Color(0xFF111827));
  }

  double _computeScore(Map<String, List<_Task>> weeklyTasks) {
    double total = 0;
    int missStreak = 0;
    bool startedByDoing = false;
    bool recovery = false;

    for (int i = 0; i < 7; i++) {
      final dayKey = "${i + 1}. Gün";
      final tasks = weeklyTasks[dayKey] ?? const <_Task>[];
      if (tasks.isEmpty) continue;

      final completedCount = tasks.where((t) => t.isCompleted).length;

      if (completedCount == 0) {
        missStreak += 1;
        final p =
            _missPenalty[(missStreak - 1).clamp(0, _missPenalty.length - 1)];
        total -= p;
        recovery = true;
      } else {
        final totalDiff =
            tasks.fold<double>(0, (s, t) => s + (t.difficulty.toDouble()));
        final earnedDiff = tasks
            .where((t) => t.isCompleted)
            .fold<double>(0, (s, t) => s + (t.difficulty.toDouble()));
        final ratio = totalDiff <= 0 ? 0.0 : (earnedDiff / totalDiff);

        if (!startedByDoing) {
          total += 30.0 * ratio;
          startedByDoing = true;
          missStreak = 0;
          recovery = false;
        } else {
          final base = _base[i];
          final dayMax = recovery ? (base * 2) : base;
          total += dayMax * ratio;
          missStreak = 0;
          recovery = false;
        }
      }
    }

    if (total < 0) total = 0;
    if (total > 100) total = 100;
    return total;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final weeks = prefs.getStringList(StorageKeys.savedWeeks(widget.uid)) ?? [];
    // yeni -> eski sıralama (en yeni üstte)
    weeks.sort((a, b) => b.compareTo(a));

    final Map<String, double> scores = {};
    final Map<String, String> labels = {};
    final Map<String, String> selfNotes = {};
    final Map<String, String> weekNotes = {};
    final Map<String, String> reviews = {};

    for (final w in weeks) {
      // tasks parse
      final raw = prefs.getString(StorageKeys.tasks(widget.uid, w));
      final map = <String, List<_Task>>{
        "1. Gün": [],
        "2. Gün": [],
        "3. Gün": [],
        "4. Gün": [],
        "5. Gün": [],
        "6. Gün": [],
        "7. Gün": [],
      };

      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          final list = (e.value as List).cast<dynamic>();
          map[e.key] = list
              .map((x) => _Task.fromJson(x as Map<String, dynamic>))
              .toList();
        }
      }

      final score = _computeScore(map);
      final band = _bandOf(score);

      scores[w] = score;
      labels[w] = band.label;

      selfNotes[w] = prefs.getString(StorageKeys.selfNote(widget.uid, w)) ?? "";
      weekNotes[w] = prefs.getString(StorageKeys.note(widget.uid, w)) ?? "";
      reviews[w] = prefs.getString(StorageKeys.review(widget.uid, w)) ?? "";
    }

    if (!mounted) return;
    setState(() {
      _weeks = weeks;
      _scores
        ..clear()
        ..addAll(scores);
      _labels
        ..clear()
        ..addAll(labels);
      _selfNotes
        ..clear()
        ..addAll(selfNotes);
      _weekNotes
        ..clear()
        ..addAll(weekNotes);
      _reviews
        ..clear()
        ..addAll(reviews);
    });
  }

  bool _isFinished(SharedPreferences prefs, String week) {
    return prefs.getBool(StorageKeys.finished(widget.uid, week)) ?? false;
  }

  Future<void> _deleteWeek(String week) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Geçmişi silmek istiyor musun?"),
            content: const Text(
                "Emin misin? Geçmiş geleceğe yön verir. Bu kayıt geri gelmez."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Vazgeç")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Sil")),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final prefs = await SharedPreferences.getInstance();

    // listeden çıkar
    final weeks = prefs.getStringList(StorageKeys.savedWeeks(widget.uid)) ?? [];
    weeks.remove(week);
    await prefs.setStringList(StorageKeys.savedWeeks(widget.uid), weeks);

    // tek tek keyleri temizle
    await prefs.remove(StorageKeys.tasks(widget.uid, week));
    await prefs.remove(StorageKeys.note(widget.uid, week));
    await prefs.remove(StorageKeys.selfNote(widget.uid, week));
    await prefs.remove(StorageKeys.started(widget.uid, week));
    await prefs.remove(StorageKeys.finished(widget.uid, week));
    await prefs.remove(StorageKeys.resultScore(widget.uid, week));
    await prefs.remove(StorageKeys.resultLabel(widget.uid, week));
    await prefs.remove(StorageKeys.finishedAt(widget.uid, week));
    await prefs.remove(StorageKeys.review(widget.uid, week));

    if (!mounted) return;
    await _load();
  }

  void _openViewSheet(String week) {
    final score = _scores[week] ?? 0;
    final band = _bandOf(score);
    final self = (_selfNotes[week] ?? "").trim();
    final weeklyNote = (_weekNotes[week] ?? "").trim();
    final review = (_reviews[week] ?? "").trim();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: band.color.withOpacity(0.12),
                child: Icon(band.icon, color: band.color),
              ),
              title: Text(week,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text("${band.label} • ${score.toStringAsFixed(1)} P"),
            ),
            if (weeklyNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text("Haftalık Not",
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(weeklyNote),
            ],
            if (self.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Kendine Not",
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(self),
            ],
            if (review.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Hafta Sonu Değerlendirme",
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(review),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyNotePage(
                      uid: widget.uid,
                      weekTitle: week,
                      isReadOnly: true,
                    ),
                  ),
                ).then((_) => _load());
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text("Detayı Aç"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<String> _filtered(List<String> weeks, Map<String, bool> finishedMap) {
    if (_filter == "Hepsi") return weeks;
    if (_filter == "Tamamlanan") {
      return weeks.where((w) => finishedMap[w] == true).toList();
    }
    // Devam ediyor
    return weeks.where((w) => finishedMap[w] != true).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        final prefs = snap.data;

        final finishedMap = <String, bool>{};
        if (prefs != null) {
          for (final w in _weeks) {
            finishedMap[w] = _isFinished(prefs, w);
          }
        }

        final shown = _filtered(_weeks, finishedMap);

        // ÜST BARLAR: en fazla 12 hafta göster (kullanıcı sorusunun cevabı)
        final barWeeks = shown
            .take(12)
            .toList()
            .reversed
            .toList(); // chart soldan sağa eski->yeni

        return Scaffold(
          appBar: AppBar(title: const Text("Analizler")),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    height: 180,
                    child: (barWeeks.isEmpty)
                        ? Center(
                            child: Text(
                              "Henüz analiz yok.",
                              style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.6)),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              barTouchData: BarTouchData(enabled: true),
                              maxY: 100,
                              minY: 0,
                              barGroups: List.generate(barWeeks.length, (i) {
                                final w = barWeeks[i];
                                final s = _scores[w] ?? 0;
                                final band = _bandOf(s);
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: s,
                                      width: 14,
                                      borderRadius: BorderRadius.circular(10),
                                      color: band.color,
                                    )
                                  ],
                                );
                              }),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Filtre:",
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(value: "Hepsi", child: Text("Hepsi")),
                      DropdownMenuItem(
                          value: "Tamamlanan", child: Text("Tamamlanan")),
                      DropdownMenuItem(
                          value: "Devam ediyor", child: Text("Devam ediyor")),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _filter = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...shown.map((week) {
                final score = _scores[week] ?? 0;
                final band = _bandOf(score);
                final isFinished = finishedMap[week] == true;

                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 6,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: band.color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    title: Text(
                      week,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      "${band.label} • ${score.toStringAsFixed(1)} P${isFinished ? "" : ""}",
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == "view") _openViewSheet(week);
                        if (v == "delete") _deleteWeek(week);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "view", child: Text("Görüntüle")),
                        PopupMenuItem(value: "delete", child: Text("Sil")),
                      ],
                    ),
                    onTap: () => _openViewSheet(week),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _Band {
  final String label;
  final IconData icon;
  final Color color;
  const _Band(this.label, this.icon, this.color);
}

class _Task {
  final String title;
  final bool isCompleted;
  final int difficulty;

  const _Task({
    required this.title,
    required this.isCompleted,
    required this.difficulty,
  });

  factory _Task.fromJson(Map<String, dynamic> json) => _Task(
        title: (json['title'] ?? '').toString(),
        isCompleted: json['isCompleted'] == true,
        difficulty: (json['difficulty'] ?? 1) is int
            ? (json['difficulty'] ?? 1)
            : int.tryParse("${json['difficulty']}") ?? 1,
      );
}
