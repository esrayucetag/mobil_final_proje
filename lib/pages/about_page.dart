import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hakkında")),
      body: const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          "Minchir — haftalık görevlerini planlayıp ritmini koruman için tasarlandı.\n\n"
          "Amaç: küçük adımları görünür kılmak, istikrarı güçlendirmek.",
          style: TextStyle(height: 1.4),
        ),
      ),
    );
  }
}
