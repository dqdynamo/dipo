import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() async {
    await Future.delayed(const Duration(seconds: 1)); // Задержка для UX
    User? user = FirebaseAuth.instance.currentUser;
    if (mounted && user != null) {
      Navigator.pushReplacementNamed(context, '/home'); // Только если пользователь авторизован
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/img.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "NomadFit",
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // const SizedBox(height: 50),
                // _buildLoginButton(
                //   icon: FontAwesomeIcons.google,
                //   text: "Войти через Google",
                //   color: Colors.red,
                //   textColor: Colors.white,
                //   onPressed: _navigateToNextScreen,
                // ),
                const SizedBox(height: 20),
                _buildLoginButton(
                  icon: Icons.email,
                  text: "Войти через Email",
                  color: Colors.black,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildRegisterText(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // void _navigateToNextScreen() {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   Navigator.pushReplacementNamed(context, user != null ? '/home' : '/login');
  // }

  Widget _buildLoginButton({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor),
        label: Text(text, style: TextStyle(fontSize: 16, color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildRegisterText() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        );
      },
      child: const Text(
        "Нет аккаунта? Зарегистрируйтесь",
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
