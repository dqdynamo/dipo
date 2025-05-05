import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diploma/models/workout_session.dart';

class WorkoutService {
  final CollectionReference workouts =
  FirebaseFirestore.instance.collection('workouts');

  Future<void> saveWorkout(WorkoutSession workout) async {
    await workouts.add(workout.toMap());
  }

  Stream<List<WorkoutSession>> getWorkouts() {
    return workouts.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return WorkoutSession.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
