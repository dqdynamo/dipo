import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

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
    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_DEEP,
    ];

    final perms = types.map((_) => HealthDataAccess.READ).toList();

    final granted = await requestPermissions();
    if (!granted) return false;

    return await _health.requestAuthorization(types, permissions: perms);
  }

  Future<int> fetchTodaySteps() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final steps = await _health.getTotalStepsInInterval(start, now);
    return steps ?? 0;
  }

  Future<double> fetchAverageHeartRate() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final hrData = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: [HealthDataType.HEART_RATE],
    );

    if (hrData.isEmpty) return 0;

    final avg = hrData.map((e) => e.value as double).reduce((a, b) => a + b) / hrData.length;
    return avg;
  }

  Future<int> fetchTodaySleepMinutes() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));

    final sleepData = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
      ],
    );

    return sleepData.fold<int>(0, (sum, e) {
      final duration = e.dateTo.difference(e.dateFrom).inMinutes;
      return sum + duration;
    });
  }

  Health get health => _health;

  /// SleepData модель
  Future<SleepData> fetchSleepData() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));

    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
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
}

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
