import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/storage_keys.dart';
import 'week_result_page.dart';

class WeeklyNotePage extends StatefulWidget {
  final String uid;
  final String weekTitle;
  final bool isReadOnly;

  const WeeklyNotePage({
    super.key,
    required this.uid,
    required this.weekTitle,
    this.isReadOnly = false,
  });

  @override
  State<WeeklyNotePage> createState() => _WeeklyNotePageState();
}

class _WeeklyNotePageState extends State<WeeklyNotePage> {
  final _weeklyNoteCtrl = TextEditingController();
  final _selfNoteCtrl = TextEditingController();

  Timer? _debounce;

  bool _started = false;

  Map<String, List<Task>> weeklyTasks = {
    "1. Gün": [],
    "2. Gün": [],
    "3. Gün": [],
    "4. Gün": [],
    "5. Gün": [],
    "6. Gün": [],
    "7. Gün": [],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _weeklyNoteCtrl.dispose();
    _selfNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _started =
        prefs.getBool(StorageKeys.started(widget.uid, widget.weekTitle)) ??
            false;

    final note =
        prefs.getString(StorageKeys.note(widget.uid, widget.weekTitle));
    final self =
        prefs.getString(StorageKeys.selfNote(widget.uid, widget.weekTitle));
    final data =
        prefs.getString(StorageKeys.tasks(widget.uid, widget.weekTitle));

    if (note != null) _weeklyNoteCtrl.text = note;
    if (self != null) _selfNoteCtrl.text = self;

    if (data != null) {
      try {
        final decoded = json.decode(data) as Map<String, dynamic>;
        weeklyTasks = decoded.map(
          (k, v) =>
              MapEntry(k, (v as List).map((e) => Task.fromJson(e)).toList()),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _save() async {
    if (widget.isReadOnly) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        StorageKeys.started(widget.uid, widget.weekTitle), _started);

    final encoded = json.encode(
      weeklyTasks.map((k, v) => MapEntry(k, v.map((t) => t.toJson()).toList())),
    );

    await prefs.setString(
        StorageKeys.tasks(widget.uid, widget.weekTitle), encoded);
    await prefs.setString(
        StorageKeys.note(widget.uid, widget.weekTitle), _weeklyNoteCtrl.text);
    await prefs.setString(
        StorageKeys.selfNote(widget.uid, widget.weekTitle), _selfNoteCtrl.text);
  }

  void _debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _save());
  }

  Future<void> _confirmEndWeek() async {
    if (widget.isReadOnly) return;

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Haftayı bitir?"),
            content: const Text("Sonuç ekranına geçilecek. Emin misin?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Vazgeç")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Bitir")),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WeekResultPage(uid: widget.uid, weekTitle: widget.weekTitle),
      ),
    );
  }

  void _openAddTask(String day) {
    if (widget.isReadOnly) return;
    if (_started) return; // ✅ haftayı başlatınca + kalktı -> burası da kilit

    final tc = TextEditingController();
    int diff = 1;

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
              const SizedBox(height: 14),
              const Text("Zorluk"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(
                  5,
                  (i) => ChoiceChip(
                    label: Text("${i + 1}"),
                    selected: diff == i + 1,
                    onSelected: (_) => setS(() => diff = i + 1),
                  ),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal")),
            ElevatedButton(
              onPressed: () {
                final title = tc.text.trim();
                if (title.isEmpty) return;
                setState(() => weeklyTasks[day]!
                    .add(Task(title: title, difficulty: diff)));
                _debouncedSave();
                Navigator.pop(ctx);
              },
              child: const Text("Ekle"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = !widget.isReadOnly && !_started;

    return Scaffold(
      appBar: AppBar(title: Text(widget.weekTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              TextField(
                controller: _weeklyNoteCtrl,
                maxLines: 2,
                readOnly: widget.isReadOnly,
                decoration: const InputDecoration(
                  hintText: "Haftalık plan notunu buraya yaz…",
                ),
                onChanged: (_) => _debouncedSave(),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (widget.isReadOnly || _started)
                          ? null
                          : () async {
                              setState(() => _started = true);
                              await _save();
                            },
                      child:
                          Text(_started ? "Hafta Başladı" : "Haftayı Başlat"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.isReadOnly ? null : _confirmEndWeek,
                      child: const Text("Haftayı Bitir"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (_, index) {
                    final day = "${index + 1}. Gün";
                    final tasks = weeklyTasks[day]!;

                    return Card(
                      child: ExpansionTile(
                        title: Text(day,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: canAdd
                            ? IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _openAddTask(day),
                              )
                            : null,
                        children: tasks.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text("Görev yok"),
                                )
                              ]
                            : tasks
                                .map(
                                  (t) => CheckboxListTile(
                                    title: Text(t.title),
                                    subtitle: Text("Zorluk: ${t.difficulty}"),
                                    value: t.isCompleted,
                                    onChanged: widget.isReadOnly
                                        ? null
                                        : (val) {
                                            setState(() =>
                                                t.isCompleted = val ?? false);
                                            _debouncedSave();
                                          },
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // ✅ altta SADECE kendine not
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Kendine Not",
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _selfNoteCtrl,
                        maxLines: 3,
                        readOnly: widget.isReadOnly,
                        decoration: const InputDecoration(
                            hintText: "Haftanın sonunda kendine not bırak…"),
                        onChanged: (_) => _debouncedSave(),
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
}
