import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'UserInfoScreen.dart';

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

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    bool isValid = true;

    if (email.isEmpty) {
      _emailError = tr("register_email_required");
      isValid = false;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailError = tr("register_email_invalid");
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = tr("register_password_required");
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = tr("register_password_short");
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = tr("register_confirm_required");
      isValid = false;
    } else if (password != confirmPassword) {
      _confirmPasswordError = tr("register_passwords_not_match");
      isValid = false;
    }
    return isValid;
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        setState(() {
          _emailError = tr("register_email_in_use");
          _isLoading = false;
        });
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('_meta')
            .doc('profile')
            .set({
          "displayName": "",
          "photoUrl": null,
          "createdAt": DateTime.now(),
          "weightKg": null,
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .doc('main')
            .set({
          "weight": null,
        });

        setState(() => _isLoading = false);

        // Показать экран проверки email
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _passwordError = tr("register_password_weak");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("register_error") + (e.message ?? ""))),
          );
        }
        _isLoading = false;
      });
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
                  tr("register_title"),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: tr("register_email"),
                    hintText: tr("register_email_hint"),
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
                    labelText: tr("register_password"),
                    hintText: tr("register_password_hint"),
                    border: const OutlineInputBorder(),
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: tr("register_confirm"),
                    hintText: tr("register_confirm_hint"),
                    border: const OutlineInputBorder(),
                    errorText: _confirmPasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      tr("register_sign_up"),
                      style: const TextStyle(fontSize: 16, color: Colors.white, letterSpacing: 1.1),
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

/// Экран проверки email пользователя
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _checking = false;
  bool _resent = false;

  Future<void> _openMailApp() async {
    const uri = 'mailto:';
    if (await canLaunchUrl(Uri.parse(uri))) {
      await launchUrl(Uri.parse(uri));
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserInfoScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("email_verification_not_verified"))),
      );
    }
    setState(() => _checking = false);
  }

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      setState(() => _resent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("email_verification_resent"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("email_verification_title")),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 68, color: theme.primaryColor),
            const SizedBox(height: 26),
            Text(
              tr("email_verification_message", args: [widget.email]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mail_outline),
                label: Text(tr("email_verification_open_mail")),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _openMailApp,
              ),
            ),
            const SizedBox(height: 10),
            if (_resent)
              Text(
                tr("email_verification_resent"),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checking ? null : _checkVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _checking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(tr("email_verification_continue")),
              ),
            ),
            TextButton(
              onPressed: _resendEmail,
              child: Text(tr("email_verification_resend")),
            ),
          ],
        ),
      ),
    );
  }
}
