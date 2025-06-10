import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _emailError = "Email is required";
      isValid = false;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailError = "Enter a valid email";
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = "Password is required";
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = "Password must be at least 6 characters";
      isValid = false;
    }
    return isValid;
  }

  String _getErrorMessage(String? code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return 'Invalid credentials. Please check your email and password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }

  Future<void> _login() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _emailError = "No user found with this email.";
        } else if (e.code == 'wrong-password') {
          _passwordError = "Incorrect password.";
        } else if (e.code == 'invalid-email') {
          _emailError = "Invalid email format.";
        } else {
          // Show all other errors as a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login error: ${_getErrorMessage(e.code)}")),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown error: $e")),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = "Enter your email to reset password");
      return;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = "Enter a valid email");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent!")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _emailError = "No user found with this email.";
        } else if (e.code == 'invalid-email') {
          _emailError = "Invalid email format.";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${_getErrorMessage(e.code)}")),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown error: $e")),
        );
        _isLoading = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Sign In",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Enter your email",
                    border: const OutlineInputBorder(),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password",
                    border: const OutlineInputBorder(),
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(fontSize: 14, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "SIGN IN",
                      style: TextStyle(fontSize: 16, color: Colors.white, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
