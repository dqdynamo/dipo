import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = "Please confirm your password";
      isValid = false;
    } else if (password != confirmPassword) {
      _confirmPasswordError = "Passwords do not match";
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
          _emailError = "This email is already in use";
          _isLoading = false;
        });
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      final uid = userCredential.user?.uid;
      if (uid != null) {
        // --- CREATE user profile and goals in Firestore ---
        await Future.wait([
          // Profile doc
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('_meta')
              .doc('profile')
              .set({
            "displayName": "",
            "photoUrl": null,
            "createdAt": DateTime.now(),
            "weightKg": null, // you can fill later
          }),
          // Goals doc
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc('main')
              .set({
            "weight": null, // set default if you want
          }),
        ]);
      }
      setState(() => _isLoading = false);

      // --- NAVIGATE to next step ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserInfoScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _passwordError = "Password is too weak";
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration error: ${e.message}")),
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
                const Text(
                  "Sign Up",
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
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    hintText: "Re-enter your password",
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
                        : const Text(
                      "SIGN UP",
                      style: TextStyle(fontSize: 16, color: Colors.white, letterSpacing: 1.1),
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
