import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_keys.dart';

class WeekResultPage extends StatefulWidget {
  final String uid;
  final String weekTitle;

  const WeekResultPage({
    super.key,
    required this.uid,
    required this.weekTitle,
  });

  @override
  State<WeekResultPage> createState() => _WeekResultPageState();
}

class _WeekResultPageState extends State<WeekResultPage> {
  bool _loading = true;

  double _score = 0;
  String _label = "—";
  IconData _icon = Icons.insights_rounded;

  final _reviewCtrl = TextEditingController();

  // === PUAN ETİKETLERİ (senin son kararın) ===
  _Band _bandOf(double s) {
    if (s < 20)
      return const _Band(
          "Başarısız", Icons.sentiment_very_dissatisfied_rounded);
    if (s < 40)
      return const _Band("Küçük Adımlar", Icons.directions_walk_rounded);
    if (s < 60) return const _Band("Yoldasın", Icons.trending_up_rounded);
    if (s < 70)
      return const _Band("Yeterli", Icons.check_circle_outline_rounded);
    if (s < 80) return const _Band("İstikrarlı", Icons.auto_graph_rounded);
    if (s < 95) return const _Band("Başarılı", Icons.emoji_events_rounded);
    return const _Band("Efsanevi", Icons.auto_awesome_rounded);
  }

  // === PUAN HESABI (tamamlanan günler, kaçırma cezaları, dönüş bonusu) ===
  // Perfect week: 30 + 12 + 12 + 12 + 12 + 12 + 10 = 100
  static const List<double> _base = [30, 12, 12, 12, 12, 12, 10];
  static const List<double> _missPenalty = [
    15,
    7,
    4,
    2,
    1,
    1
  ]; // ardışık kaçırmalarda düşen ceza

  double _computeScore(Map<String, List<_Task>> weeklyTasks) {
    // günlerde görev yoksa: gün "boş gün" sayılır, ne + ne -
    // (sen daha sonra “off day” UX’i ekleyebilirsin; burada hesap stabil kalsın)
    double total = 0;
    int missStreak = 0;

    bool startedByDoing = false; // ilk D görüldü mü?
    bool recovery = false; // bir önceki gün kaçtıysa true

    for (int i = 0; i < 7; i++) {
      final dayKey = "${i + 1}. Gün";
      final tasks = weeklyTasks[dayKey] ?? const <_Task>[];
      if (tasks.isEmpty) {
        // boş gün: sistem karışmasın diye pas geç
        continue;
      }

      final completedCount = tasks.where((t) => t.isCompleted).length;

      if (completedCount == 0) {
        // kaçırdı
        missStreak += 1;
        final p =
            _missPenalty[(missStreak - 1).clamp(0, _missPenalty.length - 1)];
        total -= p;
        recovery = true;
      } else {
        // yaptı
        // zorluk oranı
        final totalDiff =
            tasks.fold<double>(0, (s, t) => s + (t.difficulty.toDouble()));
        final earnedDiff = tasks
            .where((t) => t.isCompleted)
            .fold<double>(0, (s, t) => s + (t.difficulty.toDouble()));
        final ratio = totalDiff <= 0 ? 0.0 : (earnedDiff / totalDiff);

        if (!startedByDoing) {
          // ilk yapılan gün: 30 üzerinden (hangi gün olursa olsun)
          total += 30.0 * ratio;
          startedByDoing = true;
          missStreak = 0;
          recovery = false;
        } else {
          // normal gün: base üzerinden; eğer dönüşse 2x
          final base = _base[i];
          final dayMax = recovery ? (base * 2) : base;
          total += dayMax * ratio;

          missStreak = 0;
          recovery = false;
        }
      }
    }

    // sınırlar
    if (total < 0) total = 0;
    if (total > 100) total = 100;
    return total;
  }

  Future<void> _loadAndFinalize() async {
    final prefs = await SharedPreferences.getInstance();

    // tasks
    final raw =
        prefs.getString(StorageKeys.tasks(widget.uid, widget.weekTitle));
    final taskMap = <String, List<_Task>>{
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
        taskMap[e.key] =
            list.map((x) => _Task.fromJson(x as Map<String, dynamic>)).toList();
      }
    }

    final score = _computeScore(taskMap);
    final band = _bandOf(score);

    // review text
    _reviewCtrl.text =
        prefs.getString(StorageKeys.review(widget.uid, widget.weekTitle)) ?? "";

    // hafta bitiş snapshot'ı kaydet (Analizler buradan da okuyabilir)
    await prefs.setBool(
        StorageKeys.finished(widget.uid, widget.weekTitle), true);
    await prefs.setDouble(
        StorageKeys.resultScore(widget.uid, widget.weekTitle), score);
    await prefs.setString(
        StorageKeys.resultLabel(widget.uid, widget.weekTitle), band.label);
    await prefs.setString(StorageKeys.finishedAt(widget.uid, widget.weekTitle),
        DateTime.now().toIso8601String());

    if (!mounted) return;
    setState(() {
      _score = score;
      _label = band.label;
      _icon = band.icon;
      _loading = false;
    });
  }

  Future<void> _saveReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.review(widget.uid, widget.weekTitle),
        _reviewCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Değerlendirme kaydedildi.")),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAndFinalize();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = widget.weekTitle;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primary.withOpacity(0.12),
                    child: Icon(_icon, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_score.toStringAsFixed(1)} / 100",
                          style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hafta Sonu Değerlendirme",
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          "Neler iyi gitti? Nerede zorlandın? Haftaya neyi farklı yapacaksın?",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveReview,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text("Kaydet"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text("Kapat"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Not: Bu sayfa haftayı bitirdiğin anda Analizlere kayıt atar.",
            style: TextStyle(
                fontSize: 12, color: scheme.onSurface.withOpacity(0.55)),
          ),
        ],
      ),
    );
  }
}

class _Band {
  final String label;
  final IconData icon;
  const _Band(this.label, this.icon);
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
