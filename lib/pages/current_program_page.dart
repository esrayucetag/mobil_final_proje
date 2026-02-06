import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_keys.dart';
import 'weekly_note_page.dart';

class CurrentProgramPage extends StatefulWidget {
  const CurrentProgramPage({super.key});

  @override
  State<CurrentProgramPage> createState() => _CurrentProgramPageState();
}

class _CurrentProgramPageState extends State<CurrentProgramPage> {
  String? _activeWeek;
  bool _loading = true;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getString(StorageKeys.activeWeek(_uid));

    if (!mounted) return;
    setState(() {
      _activeWeek = active;
      _loading = false;
    });
  }

  void _open() {
    final w = _activeWeek;
    if (w == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WeeklyNotePage(weekTitle: w)),
    ).then((_) => _loadActive());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Güncel Program")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Aktif Programım",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _activeWeek ?? "Şu an aktif bir program yok.",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.75),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _activeWeek == null ? null : _open,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("Programı Aç"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
