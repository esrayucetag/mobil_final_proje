import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weekly_note_page.dart';

class CurrentProgramPage extends StatefulWidget {
  const CurrentProgramPage({super.key});

  @override
  State<CurrentProgramPage> createState() => _CurrentProgramPageState();
}

class _CurrentProgramPageState extends State<CurrentProgramPage> {
  String? lastSavedWeek;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLastSavedWeek();
  }

  Future<void> _checkLastSavedWeek() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> allWeeks = prefs.getStringList('saved_weeks') ?? [];
    List<String> interrupted = prefs.getStringList('interrupted_weeks') ?? [];
    DateTime now = DateTime.now();

    if (allWeeks.isNotEmpty) {
      String? latestActive;
      for (var i = allWeeks.length - 1; i >= 0; i--) {
        try {
          String endDateStr = allWeeks[i].split(' - ')[1];
          DateTime programEnd = DateFormat('dd.MM.yyyy').parse(endDateStr);
          DateTime expiryMoment =
              DateTime(programEnd.year, programEnd.month, programEnd.day)
                  .add(const Duration(days: 1));

          // EKSİK SÜSLÜ PARANTEZLER BURADA EKLENDİ ✨
          if (now.isBefore(expiryMoment) &&
              !interrupted.contains(allWeeks[i])) {
            latestActive = allWeeks[i];
            break;
          }
        } catch (e) {
          continue;
        }
      }
      setState(() {
        lastSavedWeek = latestActive;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (lastSavedWeek == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Güncel Program")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Şu an aktif veya süresi dolmamış bir programın yok aşkım. ✨",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return WeeklyNotePage(weekTitle: lastSavedWeek!);
  }
}
