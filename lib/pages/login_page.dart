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

  Future<void> _showMsg(String title, String msg) async {
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
      return _showMsg("Eksik Bilgi", "Lütfen e-posta ve şifre gir.");
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
    } on FirebaseAuthException catch (e) {
      await _showMsg("Giriş Hatası", e.message ?? "Bilinmeyen hata");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      return _showMsg("E-posta gerekli", "Şifre sıfırlamak için e-posta yaz.");
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _showMsg(
          "Gönderildi", "Şifre sıfırlama maili gönderildi. (Spam’a da bak)");
    } on FirebaseAuthException catch (e) {
      await _showMsg("Hata", e.message ?? "Bilinmeyen hata");
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
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Minchir",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text("Haftanı planla, ritmini koru.",
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "E-posta"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Şifre"),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Giriş Yap"),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _resetPassword,
              child: const Text("Şifremi Unuttum"),
            ),
            const SizedBox(height: 8),
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
    );
  }
}
