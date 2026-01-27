import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Bunu ekle
import 'pages/login_page.dart';

void main() async {
  // Firebase'i başlatmak için bu iki satır ŞART ✨
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Haftalık Planlayıcı',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
