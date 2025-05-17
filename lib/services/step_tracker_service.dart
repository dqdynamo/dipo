// lib/services/step_tracker_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class StepTrackerService extends ChangeNotifier {
  /* ---- day state ---- */
  int _steps = 0;
  double _distance = 0;
  int _activeMinutes = 0;
  DateTime _currentDay = DateTime.now();
  List<int> _hourly = List<int>.filled(24, 0);

  /* ---- week state ---- */
  final List<int> _weekSteps = List<int>.filled(7, 0);

  /* ---- getters ---- */
  int get steps => _steps;
  List<int> get stepsByHour => List.unmodifiable(_hourly);

  DateTime get currentDay => _currentDay;
  List<int> weeklySteps(DateTime _) => List.unmodifiable(_weekSteps);

  /* ---- firestore helpers ---- */
  CollectionReference<Map<String, dynamic>> _workoutsCol() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workouts');
  }

  String _dateId(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /* ---- day load/save ---- */
  Future<void> loadWorkoutForDate(DateTime day) async {
    final doc = await _workoutsCol().doc(_dateId(day)).get();
    if (doc.exists) {
      final m = doc.data()!;
      _steps = m['steps'] ?? 0;
      _hourly = (m['hourly'] as List<dynamic>? ?? List.filled(24, 0)).cast<int>();
      _distance = (m['distance'] ?? 0).toDouble();
      _activeMinutes = m['activeMinutes'] ?? 0;
    } else {
      _steps = _activeMinutes = 0;
      _distance = 0.0;
      _hourly = List<int>.filled(24, 0);
    }
    _currentDay = day;
    notifyListeners();
  }

  Future<void> saveWorkout(DateTime day) async {
    await _workoutsCol().doc(_dateId(day)).set({
      'steps': _steps,
      'distance': _distance,
      'activeMinutes': _activeMinutes,
      'calories': (_steps * 0.04).toInt(),
      'hourly': _hourly,
      'date': _dateId(day),
    });
  }

  /* ---- week load ---- */
  Future<void> loadWeek(DateTime monday) async {
    for (int i = 0; i < 7; i++) {
      _weekSteps[i] = 0;
      final d = monday.add(Duration(days: i));
      final snap = await _workoutsCol().doc(_dateId(d)).get();
      if (snap.exists) _weekSteps[i] = snap.data()!['steps'] ?? 0;
    }
    notifyListeners();
  }

  /* ---- mutators ---- */
  void setSteps(int s) {
    _steps = s;
    _distance = s * 0.0008;
    _activeMinutes = (s / 100).round();
    notifyListeners();
  }
}
