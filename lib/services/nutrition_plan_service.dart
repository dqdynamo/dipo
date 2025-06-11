import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart';

enum NutritionGoalType { maintain, lose, gain }

class NutritionPlan {
  final double bmi;
  final double bmr;
  final double tdee;
  final NutritionGoalType goalType;
  final int calorieTarget;

  double get proteinTarget => calorieTarget * 0.25 / 4;
  double get fatTarget => calorieTarget * 0.3 / 9;
  double get carbsTarget => calorieTarget * 0.45 / 4;

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
    // Просто сохраняем вычисленные значения
    'proteinTarget': proteinTarget,
    'fatTarget': fatTarget,
    'carbsTarget': carbsTarget,
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

  Future<NutritionPlan> generate(ProfileService profileService, dynamic _, {NutritionGoalType? override}) async {
    final profile = profileService.profile!;
    final height = profile.heightCm;
    final currentWeight = profile.weightKg;
    final age = _calculateAge(profile.birthday);
    final gender = profile.gender;

    // BMI calculation
    final bmi = currentWeight / pow(height / 100, 2);

    // BMR calculation
    final bmr = gender == 'Male'
        ? 10 * currentWeight + 6.25 * height - 5 * age + 5
        : 10 * currentWeight + 6.25 * height - 5 * age - 161;

    final tdee = bmr * 1.4;

    // BMI-based logic
    final inferredGoalType = bmi < 18.5
        ? NutritionGoalType.gain
        : (bmi < 25 ? NutritionGoalType.maintain : NutritionGoalType.lose);

    final goalType = override ?? inferredGoalType;

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
