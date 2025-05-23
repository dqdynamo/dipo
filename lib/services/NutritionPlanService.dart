import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';
import 'goal_service.dart';

enum NutritionGoalType { maintain, lose, gain }

class NutritionPlan {
  final double bmi;
  final double bmr;
  final double tdee;
  final NutritionGoalType goalType;
  final int calorieTarget;

  NutritionPlan({
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.goalType,
    required this.calorieTarget,
  });

  Map<String, dynamic> toMap() => {
    'bmi': bmi,
    'bmr': bmr,
    'tdee': tdee,
    'goalType': goalType.name,
    'calorieTarget': calorieTarget,
  };

  factory NutritionPlan.fromMap(Map<String, dynamic> m) => NutritionPlan(
    bmi: (m['bmi'] ?? 0).toDouble(),
    bmr: (m['bmr'] ?? 0).toDouble(),
    tdee: (m['tdee'] ?? 0).toDouble(),
    goalType: NutritionGoalType.values.firstWhere((e) => e.name == m['goalType']),
    calorieTarget: m['calorieTarget'] ?? 2000,
  );
}

class NutritionPlanService {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<NutritionPlan> generate(ProfileService profileService, GoalService goalService) async {
    final profile = profileService.profile!;
    final goals = await goalService.loadGoals();

    final height = profile.heightCm;
    final currentWeight = profile.weightKg;
    final goalWeight = goals.weight;
    final age = _calculateAge(profile.birthday);
    final gender = profile.gender;

    final bmi = currentWeight / pow(height / 100, 2);

    final bmr = gender == 'Male'
        ? 10 * currentWeight + 6.25 * height - 5 * age + 5
        : 10 * currentWeight + 6.25 * height - 5 * age - 161;

    final tdee = bmr * 1.4;

    final delta = goalWeight - currentWeight;
    final goalType = delta > 1
        ? NutritionGoalType.gain
        : delta < -1
        ? NutritionGoalType.lose
        : NutritionGoalType.maintain;

    final calorieTarget = (goalType == NutritionGoalType.gain
        ? tdee * 1.2
        : goalType == NutritionGoalType.lose
        ? tdee * 0.8
        : tdee)
        .round();

    final plan = NutritionPlan(
      bmi: bmi,
      bmr: bmr,
      tdee: tdee,
      goalType: goalType,
      calorieTarget: calorieTarget,
    );

    await _save(plan);
    return plan;
  }

  Future<void> _save(NutritionPlan plan) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('nutrition_goals')
        .doc('plan')
        .set(plan.toMap());
  }

  Future<NutritionPlan?> load() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('nutrition_goals')
        .doc('plan')
        .get();
    if (!snap.exists) return null;
    return NutritionPlan.fromMap(snap.data()!);
  }

  int _calculateAge(DateTime? birthday) {
    if (birthday == null) return 25;
    final today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age;
  }
}
