import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  int steps;
  double distance;
  int calories;
  DateTime date;

  WorkoutSession({
    required this.steps,
    required this.distance,
    required this.calories,
    required this.date,
  });

  // Конвертация в Firestore-формат
  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'date': Timestamp.fromDate(date),
    };
  }

  // Создание объекта из Firestore
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      steps: map['steps'],
      distance: map['distance'],
      calories: map['calories'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
