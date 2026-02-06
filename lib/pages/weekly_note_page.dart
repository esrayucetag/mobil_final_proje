import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_keys.dart';
import 'about_page.dart';
import 'week_result_page.dart';

class Task {
  String title;
  bool isCompleted;
  int difficulty;
  Task({required this.title, this.isCompleted = false, this.difficulty = 1});

  Map<String, dynamic> toJson() =>
      {'title': title, 'isCompleted': isCompleted, 'difficulty': difficulty};

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        isCompleted: json['isCompleted'] ?? false,
        difficulty: json['difficulty'] ?? 1,
      );
}

class WeeklyNotePage extends StatefulWidget {
  final String weekTitle;
  final bool isReadOnly;
  const WeeklyNotePage(
      {super.key, required this.weekTitle, this.isReadOnly = false});

  @override
  State<WeeklyNotePage> createState() => _WeeklyNotePageState();
}

class _WeeklyNotePageState extends State<WeeklyNotePage> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  final _weeklyNoteCtrl = TextEditingController();
  final _selfNoteCtrl = TextEditingController();

  bool isProgramStarted = false;
  Timer? _debounce;

  Map<String, List<Task>> weeklyTasks = {
    "1. Gün": [],
    "2. Gün": [],
    "3. Gün": [],
    "4. Gün": [],
    "5. Gün": [],
    "6. Gün": [],
    "7. Gün": []
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _weeklyNoteCtrl.dispose();
    _selfNoteCtrl.dispose();
    super.dispose();
  }

  void _debouncedSave() {
    if (widget.isReadOnly) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _saveData);
  }

  // ✅ Etiket sistemi (senin aralıkların)
  String _labelFor(double s) {
    if (s < 20) return "Başarısız";
    if (s < 40) return "Küçük Adımlar";
    if (s < 60) return "Yoldaşın";
    if (s < 70) return "Yeterli";
    if (s < 80) return "İstikrarlı";
    if (s < 95) return "Başarılı";
    return "Efsanevi";
  }

  // ✅ Ağırlıklı puan (senin “başlangıç + devam + geri dönüş” mantığı)
  double _calculateCurrentScore() {
    if (!isProgramStarted) return 0.0;

    // Gün baz puanları: 1.gün 30, diğer gün 12-12-12-12-11 gibi toplam 100 yapacak şekilde
    // Senin son kararlaştırdığın sisteme göre burada base dağıtımını koruyoruz:
    const dayBase = [30.0, 12.0, 12.0, 12.0, 12.0, 11.0, 11.0]; // toplam 100

    // Kaçırma cezası zinciri (ardışık boş günlerde)
    const missPenalty = [-15.0, -7.0, -4.0, -2.0, -1.0, -1.0, -1.0];

    double total = 0.0;
    int missStreak = 0;

    for (int i = 0; i < 7; i++) {
      final dayKey = "${i + 1}. Gün";
      final tasks = weeklyTasks[dayKey] ?? [];

      // Görev yoksa “off day” gibi davran: puan ekleme/çıkarma yok
      if (tasks.isEmpty) continue;

      final completed = tasks.where((t) => t.isCompleted).toList();
      if (completed.isEmpty) {
        // kaçırdı -> ceza (ardışık)
        final pIndex = missStreak.clamp(0, missPenalty.length - 1);
        total += missPenalty[pIndex];
        missStreak++;
        continue;
      }

      // geri dönüş/normal gün puanı: dayBase[i]
      missStreak = 0;

      final totalW = tasks.fold<double>(0, (s, t) => s + t.difficulty);
      final earnedW = completed.fold<double>(0, (s, t) => s + t.difficulty);
      if (totalW <= 0) continue;

      total += (earnedW / totalW) * dayBase[i];
    }

    if (total < 0) return 0.0;
    if (total > 100) return 100.0;
    return total;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    isProgramStarted =
        prefs.getBool(StorageKeys.started(_uid, widget.weekTitle)) ?? false;

    final taskData = prefs.getString(StorageKeys.tasks(_uid, widget.weekTitle));
    final noteData =
        prefs.getString(StorageKeys.weeklyNote(_uid, widget.weekTitle));
    final selfData =
        prefs.getString(StorageKeys.selfNote(_uid, widget.weekTitle));

    if (taskData != null) {
      final decoded = json.decode(taskData) as Map<String, dynamic>;
      weeklyTasks = decoded.map((k, v) {
        final list = (v as List).map((t) => Task.fromJson(t)).toList();
        return MapEntry(k, list);
      });
    }

    _weeklyNoteCtrl.text = noteData ?? "";
    _selfNoteCtrl.text = selfData ?? "";

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveData() async {
    if (widget.isReadOnly) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      StorageKeys.started(_uid, widget.weekTitle),
      isProgramStarted,
    );

    final encoded = json.encode(
      weeklyTasks.map((k, v) => MapEntry(k, v.map((t) => t.toJson()).toList())),
    );

    await prefs.setString(StorageKeys.tasks(_uid, widget.weekTitle), encoded);
    await prefs.setString(
      StorageKeys.weeklyNote(_uid, widget.weekTitle),
      _weeklyNoteCtrl.text.trim(),
    );
    await prefs.setString(
      StorageKeys.selfNote(_uid, widget.weekTitle),
      _selfNoteCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {}); // UI güncel kalsın
  }

  Future<void> _startWeek() async {
    if (widget.isReadOnly) return;
    setState(() => isProgramStarted = true);
    await _saveData();
  }

  Future<void> _finishWeek() async {
    if (widget.isReadOnly) return;

    final score = _calculateCurrentScore();
    final label = _labelFor(score);

    final prefs = await SharedPreferences.getInstance();

    // finished flag + final score/label
    await prefs.setBool(StorageKeys.finished(_uid, widget.weekTitle), true);
    await prefs.setDouble(
        StorageKeys.finalScore(_uid, widget.weekTitle), score);
    await prefs.setString(
        StorageKeys.finalLabel(_uid, widget.weekTitle), label);

    // finished list
    final finKey = StorageKeys.finishedWeeks(_uid);
    final finished = prefs.getStringList(finKey) ?? <String>[];
    if (!finished.contains(widget.weekTitle)) {
      finished.add(widget.weekTitle);
      await prefs.setStringList(finKey, finished);
    }

    // active week temizle (aktif buysa)
    final activeKey = StorageKeys.activeWeek(_uid);
    if (prefs.getString(activeKey) == widget.weekTitle) {
      await prefs.remove(activeKey);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WeekResultPage(
          weekTitle: widget.weekTitle,
          score: score,
          label: label,
        ),
      ),
    );
  }

  Color _statusColor(double s) {
    if (s < 20) return Colors.red;
    if (s < 40) return Colors.orange;
    if (s < 60) return Colors.amber;
    if (s < 70) return Colors.green;
    if (s < 80) return Colors.teal;
    if (s < 95) return Colors.blue;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateCurrentScore();
    _labelFor(score);
    _statusColor(score);

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async => _saveData(),
      child: Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Text("Minchir",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("Hakkında"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Çıkış Yap"),
                  onTap: () async {
                    Navigator.pop(context); 
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (_) {
                    
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          title: Text(widget.weekTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _weeklyNoteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "Haftalık plan notunu buraya yaz…",
                ),
                onChanged: (_) => _debouncedSave(),
                readOnly: widget.isReadOnly,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (isProgramStarted || widget.isReadOnly)
                          ? null
                          : _startWeek,
                      child: Text(isProgramStarted
                          ? "Hafta Başladı"
                          : "Haftayı Başlat"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.isReadOnly ? null : _finishWeek,
                      child: const Text("Haftayı Bitir"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = "${index + 1}. Gün";
                    final list = weeklyTasks[day] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        title: Text(day,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        // ✅ + ikon: sadece hafta başlamadıysa
                        trailing: (!isProgramStarted && !widget.isReadOnly)
                            ? IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _openAddTask(day),
                              )
                            : null,
                        children: [
                          if (list.isEmpty)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Text("Henüz görev yok."),
                            ),
                          ...list.map((t) {
                            final tile = CheckboxListTile(
                              title: Text(t.title),
                              subtitle: Text("Zorluk: ${t.difficulty}"),
                              value: t.isCompleted,
                              onChanged: widget.isReadOnly
                                  ? null
                                  : (val) {
                                      setState(
                                          () => t.isCompleted = val ?? false);
                                      _debouncedSave();
                                    },
                            );

                            // ✅ yanlış görev: hafta başlamadan swipe ile silebil
                            if (isProgramStarted || widget.isReadOnly)
                              return tile;

                            return Dismissible(
                              key: ValueKey(
                                  "${day}_${t.title}_${t.difficulty}_${list.indexOf(t)}"),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(Icons.delete_outline),
                              ),
                              onDismissed: (_) {
                                setState(() => list.remove(t));
                                _debouncedSave();
                              },
                              child: tile,
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ✅ Altta sadece Kendine Not
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Kendine Not",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _selfNoteCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              "Hafta sonunda kendine bir değerlendirme yaz…",
                        ),
                        onChanged: (_) => _debouncedSave(),
                        readOnly: widget.isReadOnly,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddTask(String day) {
    final tc = TextEditingController();
    int tempDiff = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text("$day • Görev ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: tc,
                  decoration: const InputDecoration(hintText: "Görev adı")),
              const SizedBox(height: 16),
              const Text("Zorluk"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final v = i + 1;
                  final selected = tempDiff == v;
                  return GestureDetector(
                    onTap: () => setS(() => tempDiff = v),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                      child: Text(
                        "$v",
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal")),
            ElevatedButton(
              onPressed: () {
                final text = tc.text.trim();
                if (text.isEmpty) return;
                setState(() => weeklyTasks[day]!
                    .add(Task(title: text, difficulty: tempDiff)));
                _debouncedSave();
                Navigator.pop(ctx);
              },
              child: const Text("Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
