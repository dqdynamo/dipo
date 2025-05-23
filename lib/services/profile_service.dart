import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProfile {
  String displayName;
  DateTime? birthday;
  double heightCm;
  double weightKg;
  String gender; // NEW FIELD

  UserProfile({
    required this.displayName,
    this.birthday,
    required this.heightCm,
    required this.weightKg,
    this.gender = 'Male',
  });

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'birthday': birthday?.toIso8601String(),
    'heightCm': heightCm,
    'weightKg': weightKg,
    'gender': gender,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    displayName: m['displayName'] ?? '',
    birthday: m['birthday'] != null ? DateTime.parse(m['birthday']) : null,
    heightCm: (m['heightCm'] ?? 0).toDouble(),
    weightKg: (m['weightKg'] ?? 0).toDouble(),
    gender: m['gender'] ?? 'Male',
  );
}

class ProfileService extends ChangeNotifier {
  UserProfile? profile;

  CollectionReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('_meta');
  }

  Future<void> load() async {
    final snap = await _doc.doc('profile').get();
    profile = snap.exists
        ? UserProfile.fromMap(snap.data()!)
        : UserProfile(displayName: '', heightCm: 0, weightKg: 0);
    notifyListeners();
  }

  Future<void> save(UserProfile p) async {
    profile = p;
    await _doc.doc('profile').set(p.toMap());
    notifyListeners();
  }
}
