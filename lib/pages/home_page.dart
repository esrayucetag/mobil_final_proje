import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_keys.dart';
import 'about_page.dart';
import 'start_date_page.dart';
import 'statistics_page.dart';
import 'weekly_note_page.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _activeWeekTitle;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final key = StorageKeys.activeWeek(_uid);
    final title = prefs.getString(key);
    if (!mounted) return;
    setState(() => _activeWeekTitle = title);
  }

  Future<void> _openActive() async {
    final title = _activeWeekTitle;
    if (title == null) return;
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WeeklyNotePage(weekTitle: title)),
    );
    await _loadActive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.62),
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                      child: Text(
                        "Minchir",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Divider(height: 1, color: Colors.black.withOpacity(0.08)),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text("Hakkında"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Çıkış Yap"),
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("Minchir"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StatisticsPage()));
              await _loadActive();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Aktif Programım",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  _activeWeekTitle == null
                      ? "Şu an aktif program yok."
                      : _activeWeekTitle!,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StartDatePage()));
                          await _loadActive();
                        },
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text("Yeni Hafta Başlat"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _activeWeekTitle == null ? null : _openActive,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("Aç"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
