import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  Future<void> _register() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      return _showMsg("Eksik Bilgi", "Lütfen e-posta ve şifre gir.");
    }
    if (pass.length < 6) {
      return _showMsg("Zayıf Şifre", "Şifre en az 6 karakter olmalı.");
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (!mounted) return;
      Navigator.pop(context); // Login'e geri
    } on FirebaseAuthException catch (e) {
      await _showMsg("Kayıt Hatası", e.message ?? "Bilinmeyen hata");
    } finally {
      if (mounted) setState(() => _loading = false);
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
      appBar: AppBar(title: const Text("Kaydol")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: "E-posta")),
            const SizedBox(height: 14),
            TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Şifre")),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Hesap Oluştur"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
