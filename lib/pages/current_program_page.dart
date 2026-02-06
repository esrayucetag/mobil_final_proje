import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_keys.dart';
import 'weekly_note_page.dart';

class CurrentProgramPage extends StatefulWidget {
  final String uid;
  const CurrentProgramPage({super.key, required this.uid});

  @override
  State<CurrentProgramPage> createState() => _CurrentProgramPageState();
}

class _CurrentProgramPageState extends State<CurrentProgramPage> {
  String? _activeWeek;
  bool _loading = true;

  DateTime? _parseEndDate(String weekTitle) {
    try {
      final endStr = weekTitle.split(' - ').last.trim();
      return DateFormat('dd.MM.yyyy').parse(endStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(StorageKeys.savedWeeks(widget.uid)) ?? [];
    final interrupted =
        prefs.getStringList(StorageKeys.interruptedWeeks(widget.uid)) ?? [];

    final now = DateTime.now();
    String? latestActive;

    for (int i = all.length - 1; i >= 0; i--) {
      final title = all[i];
      if (interrupted.contains(title)) continue;

      final end = _parseEndDate(title);
      if (end == null) continue;

      final expiry =
          DateTime(end.year, end.month, end.day).add(const Duration(days: 1));

      if (now.isBefore(expiry)) {
        latestActive = title;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _activeWeek = latestActive;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeWeek == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Güncel Program")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Şu an aktif veya süresi dolmamış bir programın yok.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // ✅ aktif haftaya direkt götürüyoruz (not + görevler)
    return WeeklyNotePage(
      uid: widget.uid,
      weekTitle: _activeWeek!,
    );
  }
}
