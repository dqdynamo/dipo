import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';

class GoalService {
  // Always retrieve the current user's UID in real time.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Reference to the 'goals' collection for the current user.
  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _uid;
    if (uid == null) {
      throw Exception("User not logged in");
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('goals');
  }

  /// Loads the user's goals from Firestore.
  /// If not found, returns default goals.
  Future<GoalModel> loadGoals() async {
    final doc = await _collection.doc('main').get();
    if (doc.exists && doc.data() != null) {
      return GoalModel.fromMap(doc.data()!);
    } else {
      // Default goals
      return GoalModel(steps: 10000, sleepHours: 8, weight: 60);
    }
  }

  /// Saves the given goals for the current user to Firestore.
  Future<void> saveGoals(GoalModel goals) async {
    await _collection.doc('main').set(goals.toMap());
  }
}
