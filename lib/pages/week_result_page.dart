import 'package:flutter/material.dart';
import 'home_page.dart'; // ⭐ EKLENDİ

class WeekResultPage extends StatelessWidget {
  final String weekTitle;
  final double score;
  final String label;

  const WeekResultPage({
    super.key,
    required this.weekTitle,
    required this.score,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hafta Sonucu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(weekTitle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "${score.toStringAsFixed(1)} puan",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            const Text(
              "Bu hafta için kendinle gurur duy. İstersen dinlen, istersen bir tık daha güçlen.",
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                child: const Text("Kapat"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
