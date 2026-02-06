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
              child: const Text("Tamam"))
        ],
      ),
    );
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      await _showInfo("Eksik Bilgi", "Lütfen e-posta ve şifreyi gir.");
      return;
    }
    if (pass.length < 6) {
      await _showInfo("Şifre zayıf", "Şifre en az 6 karakter olmalı.");
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      if (!mounted) return;
      Navigator.pop(context); // login'e dön
    } on FirebaseAuthException catch (e) {
      await _showInfo("Kayıt Hatası", e.message ?? "Bir hata oluştu.");
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: "E-posta")),
              const SizedBox(height: 12),
              TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Şifre")),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Hesap Oluştur"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
