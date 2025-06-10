import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailCheckerScreen extends StatefulWidget {
  const EmailCheckerScreen({super.key});

  @override
  State<EmailCheckerScreen> createState() => _EmailCheckerScreenState();
}

class _EmailCheckerScreenState extends State<EmailCheckerScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _result = "";

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _result = "Enter email");
      return;
    }
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      setState(() {
        _result = methods.isEmpty
            ? "No user found for this email."
            : "Sign-in methods: ${methods.join(', ')}";
      });
    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Email Check")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkEmail,
              child: const Text("Check Email"),
            ),
            const SizedBox(height: 24),
            Text(
              _result,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
