import 'package:flutter/material.dart';
import 'day_detail_page.dart'; // Bu dosyayı bir sonraki adımda açacağız

class DistributeMainPage extends StatelessWidget {
  final String weeklyNote;
  final String weekTitle;

  const DistributeMainPage({
    super.key,
    required this.weeklyNote,
    required this.weekTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(weekTitle), // Üstte tarih aralığı yazıyor
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📝 Haftalık Notların:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(weeklyNote, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("Hangi güne görev ekleyeceksin?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),

          // 1. GÜN - 7. GÜN BUTONLARI
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                int dayNumber = index + 1;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () {
                      // Bu butona basınca o günün özel sayfasına gideceğiz
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DayDetailPage(dayNumber: dayNumber),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 10),
                        Text("$dayNumber. GÜN",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
