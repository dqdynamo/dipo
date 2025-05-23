import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'health_service.dart';

class ActivityTrackerService extends ChangeNotifier {
  int _steps = 0;
  double _distance = 0.0;
  int _activeMinutes = 0;
  int _avgHeartRate = 0;
  int _calories = 0;
  DateTime _currentDay = DateTime.now();

  final List<int> _weekSteps = List<int>.filled(7, 0);
  final List<int> _monthSteps = List<int>.filled(31, 0);
  final List<int> _yearSteps = List<int>.filled(12, 0);

  int get steps => _steps;
  double get distance => _distance;
  int get activeMinutes => _activeMinutes;
  int get avgHeartRate => _avgHeartRate;
  int get calories => _calories;
  DateTime get currentDay => _currentDay;
  List<int> weeklySteps(DateTime _) => List.unmodifiable(_weekSteps);
  List<int> monthlySteps(DateTime _) => List.unmodifiable(_monthSteps);
  List<int> yearlySteps(int _) => List.unmodifiable(_yearSteps);

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
    _currentDay = day;
    final doc = await _activityCol().doc(_dateId(day)).get();
    if (doc.exists) {
      final m = doc.data()!;
      _steps = m['steps'] ?? 0;
      _distance = (m['distance'] ?? 0).toDouble();
      _activeMinutes = m['activeMinutes'] ?? 0;
      _calories = m['calories'] ?? 0;
      _avgHeartRate = m['heartRate'] ?? 0;
    } else {
      _steps = 0;
      _distance = 0.0;
      _activeMinutes = 0;
      _calories = 0;
      _avgHeartRate = 0;
    }

    await refreshFromHealth();
    await saveActivity(day);

    notifyListeners();
  }

  Future<void> saveActivity(DateTime day) async {
    await _activityCol().doc(_dateId(day)).set({
      'steps': _steps,
      'distance': _distance,
      'activeMinutes': _activeMinutes,
      'calories': _calories,
      'heartRate': _avgHeartRate,
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

  Future<void> loadMonth(DateTime monthStart) async {
    final year = monthStart.year;
    final month = monthStart.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int i = 0; i < daysInMonth; i++) {
      final d = DateTime(year, month, i + 1);
      final snap = await _activityCol().doc(_dateId(d)).get();
      _monthSteps[i] = snap.exists ? (snap.data()!['steps'] ?? 0) : 0;
    }
    for (int i = daysInMonth; i < 31; i++) {
      _monthSteps[i] = 0;
    }
    notifyListeners();
  }

  Future<void> loadYear(int year) async {
    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      int totalSteps = 0;
      for (int day = 1; day <= daysInMonth; day++) {
        final d = DateTime(year, month, day);
        final snap = await _activityCol().doc(_dateId(d)).get();
        totalSteps += snap.exists ? ((snap.data()!['steps'] ?? 0) as num).toInt() : 0;
      }
      _yearSteps[i] = totalSteps;
    }
    notifyListeners();
  }

  void setSteps(int s) {
    _steps = s;
    notifyListeners();
  }

  Future<void> refreshFromHealth() async {
    final granted = await _healthService.requestPermissions();
    if (!granted) {
      print('Permissions not granted');
      return;
    }

    final authorized = await _healthService.requestAuthorization();
    if (!authorized) {
      print('Authorization not granted');
      return;
    }

    final steps = await _healthService.fetchTodaySteps();
    if (steps > 0) {
      setSteps(steps);
      await saveActivity(_currentDay);
    } else {
      print('No steps retrieved from Google Fit');
    }
  }
}
