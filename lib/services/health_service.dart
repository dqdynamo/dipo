import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final types = <HealthDataType>[HealthDataType.STEPS];
    final perms = types.map((_) => HealthDataAccess.READ).toList();

    final granted = await requestPermissions();
    if (!granted) return false;

    return await _health.requestAuthorization(types, permissions: perms);
  }

  Future<int> fetchTodaySteps() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final steps = await _health.getTotalStepsInInterval(start, end);
    return steps ?? 0;
  }
}
