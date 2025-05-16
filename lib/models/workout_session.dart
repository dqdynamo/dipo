import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  int steps;
  double distance;
  int calories;
  int activeMinutes;
  DateTime date;

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
      'date': Timestamp.fromDate(date),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      steps: map['steps'],
      distance: map['distance'],
      calories: map['calories'],
      activeMinutes: map['activeMinutes'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
