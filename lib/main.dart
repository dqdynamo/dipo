import 'package:diploma/pages/Main/workout_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:diploma/pages/Authentication/splash_screen.dart';
import 'package:diploma/pages/Authentication/login_screen.dart';
import 'package:diploma/pages/Main/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:diploma/services/step_tracker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StepTrackerService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const BottomNavBarScreen(),
        '/workout_history': (context) => WorkoutHistoryScreen(),
      },
    );
  }
}
