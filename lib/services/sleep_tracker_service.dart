// lib/services/sleep_tracker_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class SleepTrackerService extends ChangeNotifier {
  int totalMinutes = 0;
  int deepMinutes = 0;
  int lightMinutes = 0;
  int wakeMinutes = 0;
  String sleepStart = '00:00';
  String sleepEnd = '00:00';

  final List<int> _weekMinutes = List<int>.filled(7, 0);
  List<int> weeklySleep(DateTime _) => List.unmodifiable(_weekMinutes);

  CollectionReference<Map<String, dynamic>> _sleepCol() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleep');
  }

  String _id(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> loadSleepForDate(DateTime day) async {
    final snap = await _sleepCol().doc(_id(day)).get();
    _apply(snap);
    notifyListeners();
  }

  Future<void> loadWeek(DateTime monday) async {
    for (int i = 0; i < 7; i++) {
      _weekMinutes[i] = 0;
      final snap = await _sleepCol().doc(_id(monday.add(Duration(days: i)))).get();
      if (snap.exists) _weekMinutes[i] = snap.data()!['totalMin'] ?? 0;
    }
    notifyListeners();
  }

  Future<void> saveSleep(DateTime day) async {
    await _sleepCol().doc(_id(day)).set({
      'totalMin': totalMinutes,
      'deepMin': deepMinutes,
      'lightMin': lightMinutes,
      'wakeMin': wakeMinutes,
      'start': sleepStart,
      'end': sleepEnd,
    });
  }

  void _apply(DocumentSnapshot snap) {
    if (!snap.exists) {
      totalMinutes = deepMinutes = lightMinutes = wakeMinutes = 0;
      sleepStart = sleepEnd = '00:00';
      return;
    }
    final m = snap.data() as Map<String, dynamic>;
    totalMinutes = m['totalMin'] ?? 0;
    deepMinutes = m['deepMin'] ?? 0;
    lightMinutes = m['lightMin'] ?? 0;
    wakeMinutes = m['wakeMin'] ?? 0;
    sleepStart = m['start'] ?? '00:00';
    sleepEnd = m['end'] ?? '00:00';
  }
}

