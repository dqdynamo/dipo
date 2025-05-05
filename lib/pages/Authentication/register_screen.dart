import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заполните все поля")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароли не совпадают")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Ошибка регистрации";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Этот email уже используется";
      } else if (e.code == 'weak-password') {
        errorMessage = "Пароль слишком слабый";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Регистрация",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                hintText: "Введите email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Пароль",
                hintText: "Введите пароль",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.visibility_off),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: "Подтвердите пароль",
                hintText: "Введите пароль ещё раз",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.visibility_off),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "ЗАРЕГИСТРИРОВАТЬСЯ",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
