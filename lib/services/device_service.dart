import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceInfo {
  final String name;   // имя устройства
  final String id;     // MAC / UUID
  final int? battery;  // %, null = unknown
  const DeviceInfo({required this.name, required this.id, this.battery});
}

class DeviceService extends ChangeNotifier {
  /* ───────── публичное состояние ───────── */
  DeviceInfo? device;
  bool get isScanning => _scanSub != null;
  List<ScanResult> get foundDevices => List.unmodifiable(_found);

  /* ───────── приватное ───────── */
  StreamSubscription<List<ScanResult>>? _scanSub;
  final List<ScanResult> _found = [];

  /* ───────── SCAN ───────── */
  Future<void> startScan() async {
    if (_scanSub != null) return; // уже сканируем

    _found.clear();
    _scanSub = FlutterBluePlus.scanResults.listen((list) {
      for (final sr in list) {
        if (_found.every((e) => e.device.id != sr.device.id)) {
          _found.add(sr);
          notifyListeners();
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      withServices: const [], // добавьте Guid, если нужно ограничить
    );

    _scanSub!.onDone(stopScan);      // завершится по таймауту
    notifyListeners();
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
    notifyListeners();
  }

  /* ───────── PAIR ───────── */
  Future<void> pair(ScanResult sr) async {
    stopScan();                       // на всякий случай
    final dev = sr.device;

    await dev.connect(timeout: const Duration(seconds: 10));

    // пробуем прочитать заряд (Battery Service 0x180F / Char 0x2A19)
    int? batt;
    try {
      final svcs = await dev.discoverServices();
      final bSvc = svcs.firstWhere(
              (s) => s.uuid == Guid('0000180f-0000-1000-8000-00805f9b34fb'),
          orElse: () => svcs.first);
      final bChar = bSvc.characteristics.firstWhere(
              (c) => c.uuid == Guid('00002a19-0000-1000-8000-00805f9b34fb'),
          orElse: () => bSvc.characteristics.first);
      final val = await bChar.read();
      batt = val.isNotEmpty ? val.first : null;
    } catch (_) {
      batt = null;
    }

    device = DeviceInfo(
      name: dev.name.isNotEmpty ? dev.name : 'Unknown',
      id: dev.id.id,
      battery: batt,
    );
    notifyListeners();
  }

  /* ───────── UNPAIR ───────── */
  Future<void> unpair() async {
    if (device != null) {
      final list = await FlutterBluePlus.connectedDevices;
      final target = list
          .cast<BluetoothDevice?>()
          .firstWhere((d) => d?.id.id == device!.id, orElse: () => null);
      await target?.disconnect();
    }
    device = null;
    notifyListeners();
  }
}
