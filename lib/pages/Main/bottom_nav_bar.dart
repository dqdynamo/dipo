import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart'; // Добавлено

import 'dashboard_screen.dart';
import 'progress_screen.dart';
import 'nutrition_screen.dart';
import 'nutrition_plan_screen.dart';
import 'more_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  static int initialIndex = 0;

  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  late int _currentIndex;
  late PageController _pageController;
  late Future<bool> _hasSavedPlanFuture;

  @override
  void initState() {
    super.initState();
    _currentIndex = BottomNavBarScreen.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _hasSavedPlanFuture = _hasSavedPlan();
  }

  Future<bool> _hasSavedPlan() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('nutrition_goals')
        .doc('plan')
        .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSavedPlanFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasPlan = snapshot.data!;
        final List<Widget> _pages = [
          const DashboardScreen(),
          const ProgressScreen(),
          hasPlan ? const NutritionScreen() : const NutritionPlanScreen(),
          const MoreScreen(),
        ];

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                BottomNavBarScreen.initialIndex = index;
              });
            },
            children: _pages,
            physics: const NeverScrollableScrollPhysics(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                BottomNavBarScreen.initialIndex = index;
                _pageController.jumpToPage(index);
              });
            },
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard),
                  label: tr('dashboard')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.bar_chart),
                  label: tr('progress')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.restaurant_menu),
                  label: tr('nutrition')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.more_horiz),
                  label: tr('more')),
            ],
          ),
        );
      },
    );
  }
}
