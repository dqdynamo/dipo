import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Meal {
  final String id;
  final String name;
  final String type; // Breakfast, Lunch, Dinner, Snack
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'timeAdded': FieldValue.serverTimestamp(),
  };

  static Meal fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Meal(
      id: doc.id,
      name: d['name'] ?? '',
      type: d['type'] ?? '',
      calories: d['calories'] ?? 0,
      protein: d['protein'] ?? 0,
      carbs: d['carbs'] ?? 0,
      fat: d['fat'] ?? 0,
    );
  }
}

class NutritionService {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _dayMealsCol(DateTime date) {
    final day = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('nutrition')
        .doc(day)
        .collection('meals');
  }

  Future<List<Meal>> getMealsForDay(DateTime date) async {
    final snap = await _dayMealsCol(date).orderBy('timeAdded').get();
    return snap.docs.map((d) => Meal.fromDoc(d)).toList();
  }

  Future<void> addMeal(DateTime date, Meal meal) {
    return _dayMealsCol(date).add(meal.toMap());
  }

  Future<void> updateMeal(DateTime date, String mealId, Meal meal) {
    return _dayMealsCol(date).doc(mealId).update(meal.toMap());
  }

  Future<void> deleteMeal(DateTime date, String mealId) {
    return _dayMealsCol(date).doc(mealId).delete();
  }

  // --- GOALS ---
  Future<Map<String, int>> getGoals() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('nutrition_goals').doc('goals').get();
    final data = doc.data() ?? {};
    return {
      'calories': data['calories'] ?? 2000,
      'protein': data['protein'] ?? 100,
      'carbs': data['carbs'] ?? 300,
      'fat': data['fat'] ?? 70,
    };
  }

  Future<void> setGoals(Map<String, int> goals) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('nutrition_goals').doc('goals').set(goals);
  }
}
