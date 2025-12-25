import 'package:flutter/material.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Giriş Yap",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
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
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const HomePage())),
              child: const Text("Giriş Yap"),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterPage())),
              child: const Text("Hesabın yok mu? Kaydol"),
            ),
          ],
        ),
      ),
    );
  }
}
