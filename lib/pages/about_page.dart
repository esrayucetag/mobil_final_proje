import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hakkında")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Minchir • Haftalık Planlayıcı\n\n"
          "Amaç: Haftalık hedeflerini günlere böl, istikrarını takip et, "
          "hafta sonunda net bir sonuç al.\n\n"
          "Puanlama sistemi: başlangıç + devam + geri dönüş mantığıyla "
          "istikrarı ödüllendirir.",
        ),
      ),
    );
  }
}
