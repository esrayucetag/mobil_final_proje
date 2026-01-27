import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'weekly_note_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<String> allWeeks = [];
  List<String> interrupted = [];
  Map<String, double> scores = {};
  String filter = "Hepsi";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('saved_weeks') ?? [];
    List<String> inter = prefs.getStringList('interrupted_weeks') ?? [];
    Map<String, double> weekScores = {};
    for (String title in saved) {
      weekScores[title] = await _calculateScore(title, prefs);
    }
    setState(() {
      allWeeks = saved;
      interrupted = inter;
      scores = weekScores;
    });
  }

  // İSTATİSTİKLER İÇİN PUAN HESAPLAMA
  Future<double> _calculateScore(String title, SharedPreferences prefs) async {
    String? data = prefs.getString('tasks_$title');
    if (data == null) return 0.0;
    Map<String, dynamic> dec = json.decode(data);
    double total = 0;
    bool rec = false;
    bool any = false;
    for (int i = 0; i < 7; i++) {
      List<dynamic> ts = dec["${i + 1}. Gün"] ?? [];
      if (ts.isEmpty) continue;
      int comp = ts.where((t) => t['isCompleted'] == true).length;
      if (comp == 0) {
        total -= 20;
        rec = true;
      } else {
        any = true;
        double base = rec ? 20.0 : (i == 0 ? 40.0 : 10.0);
        rec = false;
        double tW = ts.fold(0.0, (sum, t) => sum + (t['difficulty'] ?? 1));
        double eW = ts
            .where((t) => t['isCompleted'] == true)
            .fold(0.0, (sum, t) => sum + (t['difficulty'] ?? 1));
        total += (eW / tW) * base;
      }
    }
    return any ? (total < 0 ? 0.0 : total) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    List<String> disp = allWeeks
        .where((w) => filter == "Hepsi"
            ? true
            : (filter == "Yarım"
                ? interrupted.contains(w)
                : !interrupted.contains(w)))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Analizler")),
      body: Column(children: [
        if (allWeeks.isNotEmpty)
          Container(
              height: 180,
              padding: const EdgeInsets.all(15),
              child: BarChart(BarChartData(
                  barGroups: List.generate(
                      allWeeks.length,
                      (i) => BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                                toY: scores[allWeeks[i]] ?? 0,
                                color: interrupted.contains(allWeeks[i])
                                    ? Colors.orange
                                    : Colors.green,
                                width: 15)
                          ]))))),
        Expanded(
            child: ListView.builder(
                itemCount: disp.length,
                itemBuilder: (context, index) {
                  bool isI = interrupted.contains(disp[index]);
                  return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      child: ListTile(
                          title: Text(disp[index]),
                          subtitle: Text(isI ? "Yarım" : "Tamamlandı"),
                          trailing: Text(
                              "${scores[disp[index]]?.toStringAsFixed(1)} P"),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => WeeklyNotePage(
                                      weekTitle: disp[index],
                                      isReadOnly: true)))));
                }))
      ]),
    );
  }
}
