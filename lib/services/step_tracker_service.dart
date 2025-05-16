import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkoutSession {
  final int steps;
  final double distance;
  final int calories;
  final int activeMinutes;
  final DateTime date;

  WorkoutSession({
    required this.steps,
    required this.distance,
    required this.calories,
    required this.activeMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'activeMinutes': activeMinutes,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      steps: map['steps'] ?? 0,
      distance: (map['distance'] ?? 0).toDouble(),
      calories: map['calories'] ?? 0,
      activeMinutes: map['activeMinutes'] ?? 0,
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
    );
  }
}

class StepTrackerService extends ChangeNotifier {
  int _steps = 0;
  double _distance = 0.0;
  int _activeMinutes = 0;
  DateTime _currentDay = DateTime.now();

  int get steps => _steps;
  double get distance => _distance;
  int get activeMinutes => _activeMinutes;
  DateTime get currentDay => _currentDay;

  final CollectionReference _workoutsCollection =
  FirebaseFirestore.instance.collection('workouts');

  Future<void> loadWorkoutForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final docId = '${user.uid}_$formattedDate';

    final doc = await _workoutsCollection.doc(docId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _steps = data['steps'] ?? 0;
      _distance = (data['distance'] ?? 0).toDouble();
      _activeMinutes = data['activeMinutes'] ?? 0;
      _currentDay = date;
    } else {
      _steps = 0;
      _distance = 0.0;
      _activeMinutes = 0;
      _currentDay = date;
    }

    notifyListeners();
  }


  Future<void> saveWorkout(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final workout = WorkoutSession(
      steps: _steps,
      distance: _distance,
      calories: (_steps * 0.04).toInt(),
      activeMinutes: _activeMinutes,
      date: date,
    );

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final docId = '${user.uid}_$formattedDate';

    // ВАЖНО: doc(docId), НЕ add()
    await _workoutsCollection.doc(docId).set(workout.toMap());

    notifyListeners();
  }


  // Пример метода для обновления шагов (его можно вызвать из UI)
  void updateSteps(int newSteps) {
    _steps = newSteps;
    notifyListeners();
  }

// Аналогично можно добавить методы для обновления distance и activeMinutes
}


