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
  List<int> _hourly = List<int>.filled(24, 0);

  final List<int> _weekSteps = List<int>.filled(7, 0);
  final List<int> _monthSteps = List<int>.filled(31, 0);
  final List<int> _yearSteps = List<int>.filled(12, 0);

  int get steps => _steps;
  double get distance => _distance;
  int get activeMinutes => _activeMinutes;
  int get avgHeartRate => _avgHeartRate;
  int get calories => _calories;
  List<int> get stepsByHour => List.unmodifiable(_hourly);
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
    final doc = await _activityCol().doc(_dateId(day)).get();
    if (doc.exists) {
      final m = doc.data()!;
      _steps = m['steps'] ?? 0;
      _hourly = (m['hourly'] as List<dynamic>? ?? List.filled(24, 0)).cast<int>();
      _steps  = _hourly.fold<int>(0, (s, e) => s + e);
      _distance = (m['distance'] ?? 0).toDouble();
      _activeMinutes = m['activeMinutes'] ?? 0;
      _avgHeartRate = m['heartRate'] ?? 0;
      _calories = m['calories'] ?? 0;
    } else {
      final permissionsGranted = await _healthService.requestPermissions();
      if (permissionsGranted && await _healthService.requestAuthorization()) {
        _steps = await _healthService.fetchStepsForDate(day);
        _distance = await _healthService.fetchDistanceForDate(day);
        _calories = await _healthService.fetchCaloriesForDate(day);
        _activeMinutes = await _healthService.fetchTodayMoveMinutesForDate(day);
        _avgHeartRate = (await _healthService.fetchAverageHeartRateForDate(day)).toInt();
        _hourly       = await _healthService.fetchHourlyStepsForDate(day);
        _steps        = _hourly.fold<int>(0, (s, e) => s + e);
        await saveActivity(day);
      } else {
        _steps = 0;
        _distance = 0.0;
        _activeMinutes = 0;
        _hourly = List<int>.filled(24, 0);
        _avgHeartRate = 0;
        _calories = 0;
      }
    }
    _currentDay = day;
    notifyListeners();
  }

  Future<void> saveActivity(DateTime day) async {
    await _activityCol().doc(_dateId(day)).set({
      'steps': _steps,
      'distance': _distance,
      'activeMinutes': _activeMinutes,
      'calories': _calories,
      'hourly': _hourly,
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
    print("🔄 refreshFromHealth called");
    final permissionsGranted = await _healthService.requestPermissions();
    if (permissionsGranted && await _healthService.requestAuthorization()) {
      _steps = await _healthService.fetchTodaySteps();
      _distance = await _healthService.fetchTodayDistance();
      _calories = await _healthService.fetchTodayCalories();
      _activeMinutes = await _healthService.fetchTodayMoveMinutes();
      _avgHeartRate = (await _healthService.fetchAverageHeartRate()).toInt();
      _hourly        = await _healthService.fetchHourlyStepsForDate(DateTime.now());
      _steps        = _hourly.fold<int>(0, (s, e) => s + e);

      print("📤 Saving activity for ${DateTime.now()} — steps: $_steps, distance: $_distance, calories: $_calories");
      await saveActivity(DateTime.now());
      notifyListeners();
    } else {
      debugPrint('Health permissions not granted');
    }
  }

  /// Adds steps to both the daily total and the current hour.
  void addSteps(int delta) {
    final h = DateTime.now().hour;
    _steps  += delta;
    _hourly[h] += delta;
    notifyListeners();
  }
}
