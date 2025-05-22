// lib/services/sleep_tracker_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'health_service.dart';


class SleepTrackerService extends ChangeNotifier {
  int totalMinutes = 0;
  int deepMinutes = 0;
  int lightMinutes = 0;
  int wakeMinutes = 0;
  String sleepStart = '00:00';
  String sleepEnd = '00:00';

  final List<int> _weekMinutes = List<int>.filled(7, 0);
  final List<int> _monthMinutes = List<int>.filled(31, 0);
  final List<int> _yearMinutes = List<int>.filled(12, 0);

  List<int> weeklySleep(DateTime _) => List.unmodifiable(_weekMinutes);
  List<int> monthlySleep(DateTime _) => List.unmodifiable(_monthMinutes);
  List<int> yearlySleep(DateTime _) => List.unmodifiable(_yearMinutes);

  final _healthService = HealthService();

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
    if (snap.exists) {
      _apply(snap);
    } else {
      final granted = await _healthService.requestPermissions();
      if (granted && await _healthService.requestAuthorization()) {
        final sleepData = await _healthService.fetchSleepDataForDate(day);
        totalMinutes = sleepData.deep + sleepData.light + sleepData.wake;
        deepMinutes = sleepData.deep;
        lightMinutes = sleepData.light;
        wakeMinutes = sleepData.wake;
        sleepStart = sleepData.start;
        sleepEnd = sleepData.end;

        await saveSleep(day); // кэшируем
      } else {
        totalMinutes = deepMinutes = lightMinutes = wakeMinutes = 0;
        sleepStart = sleepEnd = '00:00';
      }
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

  Future<void> loadWeek(DateTime monday) async {
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final snap = await _sleepCol().doc(_id(d)).get();
      _weekMinutes[i] = snap.exists ? (snap.data()!['totalMin'] ?? 0) : 0;
    }
    notifyListeners();
  }

  Future<void> loadMonth(DateTime monthStart) async {
    final year = monthStart.year;
    final month = monthStart.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int i = 0; i < daysInMonth; i++) {
      final d = DateTime(year, month, i + 1);
      final snap = await _sleepCol().doc(_id(d)).get();
      _monthMinutes[i] = snap.exists ? (snap.data()!['totalMin'] ?? 0) as int : 0;
    }
    for (int i = daysInMonth; i < 31; i++) {
      _monthMinutes[i] = 0;
    }
    notifyListeners();
  }

  Future<void> loadYear(int year) async {
    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      int totalMin = 0;
      for (int j = 0; j < daysInMonth; j++) {
        final d = DateTime(year, month, j + 1);
        final snap = await _sleepCol().doc(_id(d)).get();
        totalMin += snap.exists ? (snap.data()!['totalMin'] as num).toInt() : 0;
      }
      _yearMinutes[i] = totalMin;
    }
    notifyListeners();
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

  Future<void> refreshFromHealth() async {
    final permissionsGranted = await _healthService.requestPermissions();
    if (permissionsGranted && await _healthService.requestAuthorization()) {
      final minutes = await _healthService.fetchTodaySleepMinutes();
      totalMinutes = minutes;

      final sleepData = await _healthService.fetchSleepData();
      deepMinutes = sleepData.deep;
      lightMinutes = sleepData.light;
      wakeMinutes = sleepData.wake;
      sleepStart = sleepData.start;
      sleepEnd = sleepData.end;

      notifyListeners();
      await saveSleep(DateTime.now());
    }
  }
}
