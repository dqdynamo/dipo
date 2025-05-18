// lib/services/activity_tracker_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'health_service.dart';

class ActivityTrackerService extends ChangeNotifier {
  int _steps = 0;
  double _distance = 0.0;
  int _activeMinutes = 0;
  DateTime _currentDay = DateTime.now();
  List<int> _hourly = List<int>.filled(24, 0);

  final List<int> _weekSteps = List<int>.filled(7, 0);

  int get steps => _steps;
  double get distance => _distance;
  int get activeMinutes => _activeMinutes;
  List<int> get stepsByHour => List.unmodifiable(_hourly);
  DateTime get currentDay => _currentDay;
  List<int> weeklySteps(DateTime _) => List.unmodifiable(_weekSteps);

  final _healthService = HealthService();

  CollectionReference<Map<String, dynamic>> _activityCol() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activity');
  }

  String _dateId(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> loadActivityForDate(DateTime day) async {
    final doc = await _activityCol().doc(_dateId(day)).get();
    if (doc.exists) {
      final m = doc.data()!;
      _steps = m['steps'] ?? 0;
      _hourly = (m['hourly'] as List<dynamic>? ?? List.filled(24, 0))
          .cast<int>();
      _distance = (m['distance'] ?? 0).toDouble();
      _activeMinutes = m['activeMinutes'] ?? 0;
    } else {
      _steps = 0;
      _distance = 0.0;
      _activeMinutes = 0;
      _hourly = List<int>.filled(24, 0);
    }
    _currentDay = day;
    notifyListeners();
  }

  Future<void> saveActivity(DateTime day) async {
    await _activityCol().doc(_dateId(day)).set({
      'steps': _steps,
      'distance': _distance,
      'activeMinutes': _activeMinutes,
      'calories': (_steps * 0.04).toInt(),
      'hourly': _hourly,
      'date': _dateId(day),
    });
  }

  Future<void> loadWeek(DateTime monday) async {
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final snap = await _activityCol().doc(_dateId(d)).get();
      _weekSteps[i] = snap.exists ? (snap.data()!['steps'] ?? 0) : 0;
    }
    notifyListeners();
  }

  void setSteps(int s) {
    _steps = s;
    _distance = s * 0.0008;
    _activeMinutes = (s / 100).round();
    notifyListeners();
  }

  /// Обновить из Health (Google Fit / Health Connect)
  Future<void> refreshFromHealth() async {
    final permissionsGranted = await _healthService.requestPermissions();
    if (permissionsGranted && await _healthService.requestAuthorization()) {
      final steps = await _healthService.fetchTodaySteps();
      setSteps(steps);
      await saveActivity(DateTime.now());
    }
  }

}
