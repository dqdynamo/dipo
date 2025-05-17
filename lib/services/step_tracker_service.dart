import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class WorkoutSession {
  final int steps;
  final double distance;
  final int calories;
  final int activeMinutes;
  final DateTime date;
  final List<int> hourly; // 24-часовой массив шагов

  WorkoutSession({
    required this.steps,
    required this.distance,
    required this.calories,
    required this.activeMinutes,
    required this.date,
    required this.hourly,
  });

  Map<String, dynamic> toMap() => {
    'steps': steps,
    'distance': distance,
    'calories': calories,
    'activeMinutes': activeMinutes,
    'date': DateFormat('yyyy-MM-dd').format(date),
    'hourly': hourly,
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final hourly =
    (map['hourly'] as List<dynamic>? ?? List.filled(24, 0)).cast<int>();
    return WorkoutSession(
      steps: map['steps'] ?? 0,
      distance: (map['distance'] ?? 0).toDouble(),
      calories: map['calories'] ?? 0,
      activeMinutes: map['activeMinutes'] ?? 0,
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      hourly: hourly.length == 24 ? hourly : List<int>.filled(24, 0),
    );
  }
}

class StepTrackerService extends ChangeNotifier {
  /* ------ частные поля ------ */
  int _steps = 0;
  double _distance = 0;
  int _activeMinutes = 0;
  DateTime _currentDay = DateTime.now();
  List<int> _hourly = List<int>.filled(24, 0);

  /* ------ геттеры ------ */
  int get steps => _steps;
  double get distance => _distance;
  int get activeMinutes => _activeMinutes;
  DateTime get currentDay => _currentDay;
  List<int> get stepsByHour => List.unmodifiable(_hourly);

  /* ------ Firestore ------ */
  final _col = FirebaseFirestore.instance.collection('workouts');

  /* ------ Загрузка за день ------ */
  Future<void> loadWorkoutForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = '${user.uid}_${DateFormat('yyyy-MM-dd').format(date)}';
    final doc = await _col.doc(id).get();

    if (doc.exists) {
      final ws = WorkoutSession.fromMap(doc.data()!);
      _steps = ws.steps;
      _distance = ws.distance;
      _activeMinutes = ws.activeMinutes;
      _hourly = ws.hourly;
    } else {
      _steps = 0;
      _distance = 0;
      _activeMinutes = 0;
      _hourly = List<int>.filled(24, 0);
    }
    _currentDay = date;
    notifyListeners();
  }

  /* ------ Сохранение за день ------ */
  Future<void> saveWorkout(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = '${user.uid}_${DateFormat('yyyy-MM-dd').format(date)}';
    final ws = WorkoutSession(
      steps: _steps,
      distance: _distance,
      calories: (_steps * 0.04).toInt(),
      activeMinutes: _activeMinutes,
      date: date,
      hourly: _hourly,
    );
    await _col.doc(id).set(ws.toMap());
  }

  /* ------ Методы обновления ------ */

  /// Заменить общее количество шагов (пересчитывает дистанцию/минуты)
  void updateSteps(int newSteps) {
    _steps = newSteps;
    _recalcFromSteps();
  }

  /// Добавить шаги к конкретному часу (0-23)
  void addStepsForHour(int hour, int add) {
    if (hour < 0 || hour > 23) return;
    _hourly[hour] += add;
    _steps += add;
    _recalcFromSteps();
  }

  /// Полностью задать массив из 24 значений шагов
  void setHourly(List<int> newHourly) {
    if (newHourly.length != 24) return;
    _hourly = List<int>.from(newHourly);
    _steps = _hourly.fold(0, (s, e) => s + e);
    _recalcFromSteps();
  }

  /* ------ Внутренний пересчёт ------ */
  void _recalcFromSteps() {
    _distance = _steps * 0.0008;             // 0.8 м на шаг
    _activeMinutes = (_steps / 100).round(); // ~100 шаг/мин
    notifyListeners();
  }
}



