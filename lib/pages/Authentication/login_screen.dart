import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

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
      _emailError = tr('login_email_required');
      isValid = false;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailError = tr('login_email_invalid');
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = tr('login_password_required');
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = tr('login_password_short');
      isValid = false;
    }
    return isValid;
  }

  String _getErrorMessage(String? code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return tr('login_error_invalid_credentials');
      case 'user-disabled':
        return tr('login_error_user_disabled');
      case 'too-many-requests':
        return tr('login_error_too_many_requests');
      default:
        return tr('login_error_unknown');
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
          _emailError = tr('login_error_user_not_found');
        } else if (e.code == 'wrong-password') {
          _passwordError = tr('login_error_wrong_password');
        } else if (e.code == 'invalid-email') {
          _emailError = tr('login_email_invalid');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('login_error') + _getErrorMessage(e.code))),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('login_error_unknown') + ": $e")),
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
      setState(() => _emailError = tr('login_reset_email_required'));
      return;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = tr('login_email_invalid'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('login_reset_email_sent'))),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _emailError = tr('login_error_user_not_found');
        } else if (e.code == 'invalid-email') {
          _emailError = tr('login_email_invalid');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('login_error') + _getErrorMessage(e.code))),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('login_error_unknown') + ": $e")),
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
                Text(
                  tr('login_title'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: tr('login_email'),
                    hintText: tr('login_email_hint'),
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
                    labelText: tr('login_password'),
                    hintText: tr('login_password_hint'),
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
                    child: Text(
                      tr('login_forgot_password'),
                      style: const TextStyle(fontSize: 14, decoration: TextDecoration.underline),
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
                        : Text(
                      tr('login_sign_in'),
                      style: const TextStyle(fontSize: 16, color: Colors.white, letterSpacing: 1.2),
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
