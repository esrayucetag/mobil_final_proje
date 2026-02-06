import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_keys.dart';
import 'about_page.dart';
import 'statistics_page.dart';
import 'weekly_note_page.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _activeWeekTitle;

  @override
  void initState() {
    super.initState();
    _checkActiveProgram();
  }

  Future<void> _checkActiveProgram() async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(StorageKeys.savedWeeks(widget.uid)) ?? [];
    final interrupted =
        prefs.getStringList(StorageKeys.interruptedWeeks(widget.uid)) ?? [];

    String? found;
    for (final w in all.reversed) {
      if (!interrupted.contains(w)) {
        found = w;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _activeWeekTitle = found);
  }

  Future<void> _pickAndStartWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    final start = DateTime(picked.year, picked.month, picked.day);
    final end = start.add(const Duration(days: 6));
    final title =
        "${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}";

    // aktif program varsa uyar
    if (_activeWeekTitle != null) {
      final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Yeni Program?"),
              content: Text("'$_activeWeekTitle' yarım bırakılacak. Devam mı?"),
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

      if (!ok) return;

      final prefs = await SharedPreferences.getInstance();
      final inter =
          prefs.getStringList(StorageKeys.interruptedWeeks(widget.uid)) ?? [];
      if (!inter.contains(_activeWeekTitle!)) inter.add(_activeWeekTitle!);
      await prefs.setStringList(
          StorageKeys.interruptedWeeks(widget.uid), inter);
    }

    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(StorageKeys.savedWeeks(widget.uid)) ?? [];
    if (!all.contains(title)) {
      all.add(title);
      await prefs.setStringList(StorageKeys.savedWeeks(widget.uid), all);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => WeeklyNotePage(uid: widget.uid, weekTitle: title)),
    );
    _checkActiveProgram();
  }

  Future<void> _openActiveWeek() async {
    final t = _activeWeekTitle;
    if (t == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => WeeklyNotePage(uid: widget.uid, weekTitle: t)),
    );
    _checkActiveProgram();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Minchir"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StatisticsPage(uid: widget.uid)),
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title:
                    Text("Menü", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("Hakkında"),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutPage())),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Çıkış Yap"),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Yeni hafta başlat",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _pickAndStartWeek,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text("Başlangıç tarihi seç"),
                ),
              ),
              const SizedBox(height: 18),
              if (_activeWeekTitle != null) ...[
                const Text("Aktif Programım",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: Text(_activeWeekTitle!,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text("Devam etmek için dokun"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openActiveWeek,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
