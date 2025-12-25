import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kaydol")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const TextField(
                decoration: InputDecoration(
                    labelText: "Ad Soyad", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            const TextField(
                decoration: InputDecoration(
                    labelText: "E-posta", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            const TextField(
                obscureText: true,
                decoration: InputDecoration(
                    labelText: "Şifre", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                  context), // Kaydolunca giriş sayfasına geri döner
              child: const Text("Hesap Oluştur"),
            ),
          ],
        ),
      ),
    );
  }
}
