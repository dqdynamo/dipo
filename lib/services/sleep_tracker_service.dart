import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class SleepTrackerService extends ChangeNotifier {
  int totalMinutes = 0;
  int deepMinutes = 0;
  int lightMinutes = 0;
  int wakeMinutes  = 0;
  String sleepStart = '00:00';
  String sleepEnd   = '00:00';

  final _col = FirebaseFirestore.instance.collection('sleep');

  Future<void> loadSleepForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = '${user.uid}_${DateFormat('yyyy-MM-dd').format(date)}';
    final doc = await _col.doc(id).get();
    if (doc.exists) {
      final d = doc.data() as Map<String, dynamic>;
      totalMinutes = d['total'] ?? 0;
      deepMinutes  = d['deep']  ?? 0;
      lightMinutes = d['light'] ?? 0;
      wakeMinutes  = d['wake']  ?? 0;
      sleepStart   = d['start'] ?? '00:00';
      sleepEnd     = d['end']   ?? '00:00';
    } else {
      totalMinutes = deepMinutes = lightMinutes = wakeMinutes = 0;
      sleepStart = sleepEnd = '00:00';
    }
    notifyListeners();
  }

  Future<void> saveSleep(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = '${user.uid}_${DateFormat('yyyy-MM-dd').format(date)}';
    await _col.doc(id).set({
      'total': totalMinutes,
      'deep' : deepMinutes,
      'light': lightMinutes,
      'wake' : wakeMinutes,
      'start': sleepStart,
      'end'  : sleepEnd,
    });
  }
}
