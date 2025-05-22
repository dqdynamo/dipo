import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class SleepData {
  final int deep;
  final int light;
  final int wake;
  final String start;
  final String end;

  SleepData({
    required this.deep,
    required this.light,
    required this.wake,
    required this.start,
    required this.end,
  });
}

class HealthService {
  final Health _health = Health();

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestPermissions() async {
    final activityGranted = await Permission.activityRecognition.isGranted;
    final locationGranted = await Permission.location.isGranted;
    final sensorsGranted = await Permission.sensors.isGranted;

    if (!activityGranted) await Permission.activityRecognition.request();
    if (!locationGranted) await Permission.location.request();
    if (!sensorsGranted) await Permission.sensors.request();

    return await Permission.activityRecognition.isGranted &&
        await Permission.location.isGranted &&
        await Permission.sensors.isGranted;
  }

  Future<bool> requestAuthorization() async {
    print("🔐 Starting authorization request...");

    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
      // HealthDataType.DISTANCE_DELTA,
      // HealthDataType.ACTIVE_ENERGY_BURNED,
      // HealthDataType.EXERCISE_TIME,
    ];

    final perms = types.map((_) => HealthDataAccess.READ).toList();

    final granted = await requestPermissions();
    print("✅ Android permissions granted: $granted");

    if (!granted) {
      print("❌ Android permissions denied.");
      return false;
    }

    final authorized = await _health.requestAuthorization(types, permissions: perms);
    print("📲 Health Connect authorization result: $authorized");

    return authorized;
  }


  Future<int> fetchTodaySteps() async {
    return await fetchStepsForDate(DateTime.now());
  }

  Future<int> fetchTodayCalories() async {
    return await fetchCaloriesForDate(DateTime.now());
  }

  Future<double> fetchTodayDistance() async {
    return await fetchDistanceForDate(DateTime.now());
  }

  Future<int> fetchTodaySleepMinutes() async {
    final data = await fetchSleepData();
    return data.deep + data.light + data.wake;
  }

  Future<int> fetchStepsForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    final steps = await _health.getTotalStepsInInterval(start, end);
    return steps ?? 0;
  }

  Future<double> fetchDistanceForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.DISTANCE_DELTA],
    );
    if (data.isEmpty) return 0.0;
    return data.map((e) => e.value as double).fold(0.0, (a, b) => a + b) / 1000;
  }

  Future<int> fetchCaloriesForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.ACTIVE_ENERGY_BURNED],
    );
    if (data.isEmpty) return 0;
    return data.map((e) => e.value as double).fold(0.0, (a, b) => a + b).round();
  }

  Future<int> fetchTodayMoveMinutes() async {
    return await fetchTodayMoveMinutesForDate(DateTime.now());
  }

  Future<int> fetchTodayMoveMinutesForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.EXERCISE_TIME],
    );
    if (data.isEmpty) return 0;
    return data.map((e) => e.value as double).fold(0.0, (a, b) => a + b).round();
  }

  Future<double> fetchAverageHeartRate() async {
    return await fetchAverageHeartRateForDate(DateTime.now());
  }

  Future<double> fetchAverageHeartRateForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final hrData = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.HEART_RATE],
    );
    if (hrData.isEmpty) return 0;
    return hrData.map((e) => e.value as double).reduce((a, b) => a + b) / hrData.length;
  }

  Future<SleepData> fetchSleepData() async {
    return await fetchSleepDataForDate(DateTime.now());
  }

  Future<SleepData> fetchSleepDataForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_AWAKE,
      ],
    );

    int deep = data
        .where((e) => e.type == HealthDataType.SLEEP_DEEP)
        .fold(0, (sum, e) => sum + e.dateTo.difference(e.dateFrom).inMinutes);
    int light = data
        .where((e) => e.type == HealthDataType.SLEEP_LIGHT)
        .fold(0, (sum, e) => sum + e.dateTo.difference(e.dateFrom).inMinutes);
    int wake = data
        .where((e) => e.type == HealthDataType.SLEEP_AWAKE)
        .fold(0, (sum, e) => sum + e.dateTo.difference(e.dateFrom).inMinutes);

    data.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final startStr = data.isNotEmpty ? DateFormat('HH:mm').format(data.first.dateFrom) : '00:00';
    final endStr = data.isNotEmpty ? DateFormat('HH:mm').format(data.last.dateTo) : '00:00';

    return SleepData(
      deep: deep,
      light: light,
      wake: wake,
      start: startStr,
      end: endStr,
    );
  }

  /// 24-element list with steps for each hour of the given day
  Future<List<int>> fetchHourlyStepsForDate(DateTime day) async {
    final result = List<int>.filled(24, 0);
    for (int h = 0; h < 24; h++) {
      final from = DateTime(day.year, day.month, day.day, h);
      final to   = from.add(const Duration(hours: 1));
      final steps = await _health.getTotalStepsInInterval(from, to);
      result[h] = steps ?? 0;
    }
    return result;
  }

}
