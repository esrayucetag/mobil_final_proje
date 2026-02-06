import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _showInfo(String title, String msg) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam")),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      await _showInfo("Eksik Bilgi", "Lütfen e-posta ve şifreyi gir.");
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      await _showInfo("Giriş Hatası", e.message ?? "Bir hata oluştu.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      await _showInfo(
          "E-posta gerekli", "Şifre sıfırlama için e-posta girmen lazım.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _showInfo("Gönderildi",
          "Şifre sıfırlama maili gönderildi. Spam klasörüne de bak 💜");
    } on FirebaseAuthException catch (e) {
      await _showInfo("Hata", e.message ?? "Bir hata oluştu.");
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Minchir",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text("Haftanı planla, ritmini koru.",
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.7))),
              const SizedBox(height: 28),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "E-posta"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Şifre"),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Giriş Yap"),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _loading ? null : _resetPassword,
                child: const Text("Şifremi unuttum"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: const Text("Hesabın yok mu? Kaydol"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
