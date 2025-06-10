import 'package:diploma/providers/theme_provider.dart';
import 'package:diploma/services/activity_tracker_service.dart';
import 'package:diploma/services/device_service.dart';
import 'package:diploma/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'pages/Authentication/email_checker_screen.dart';
import 'pages/Authentication/splash_screen.dart';
import 'pages/Authentication/login_screen.dart';
import 'pages/Main/bottom_nav_bar.dart';
import 'pages/Main/goal_screen.dart';
import 'pages/Main/nutrition_screen.dart';
import 'pages/Main/nutrition_plan_screen.dart';
import 'pages/Main/more_screen.dart';
import 'pages/Main/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ActivityTrackerService()),
        ChangeNotifierProvider(create: (_) => DeviceService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/lang',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Tracker',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/splash',
      routes: {
        '/emailChecker': (context) => const EmailCheckerScreen(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const BottomNavBarScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/goal': (context) => const GoalScreen(),
        '/nutritionPlan': (context) => const NutritionPlanScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
