import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'nutrition_plan_screen.dart';
import 'nutrition_screen.dart';

class NutritionWrapperScreen extends StatelessWidget {
  const NutritionWrapperScreen({super.key});

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
      future: _hasSavedPlan(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const NutritionScreen()
            : const NutritionPlanScreen();
      },
    );
  }
}
