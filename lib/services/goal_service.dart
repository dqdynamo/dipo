import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';

class GoalService {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('goals');
  }

  Future<GoalModel> loadGoals() async {
    if (_uid == null) {
      throw Exception("User not logged in");
    }

    final doc = await _collection.doc('main').get(); // using fixed doc id
    if (doc.exists) {
      return GoalModel.fromMap(doc.data()!);
    } else {
      return GoalModel(steps: 10000, sleepHours: 8, weight: 60);
    }
  }

  Future<void> saveGoals(GoalModel goals) async {
    if (_uid == null) return;
    await _collection.doc('main').set(goals.toMap());
  }
}
