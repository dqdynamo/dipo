import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/device_service.dart';
import '../../services/health_service.dart';
import 'pair_device_screen.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DeviceService>();
    final device = ds.device;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF9240), Color(0xFFDD4733)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text('Device',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 20),
              const _ConnectionSelector(),
              const SizedBox(height: 20),
              if (device != null)
                _DeviceCard(
                  info: device,
                  onUnpair: ds.unpair,
                  onSync: () async {
                    await ds.unpair();
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                      );
                    }
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _PairPlaceholder(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionSelector extends StatefulWidget {
  const _ConnectionSelector();

  @override
  State<_ConnectionSelector> createState() => _ConnectionSelectorState();
}

class _ConnectionSelectorState extends State<_ConnectionSelector> {
  String _mode = 'BLE';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Выберите способ подключения:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ToggleButtons(
          borderColor: Colors.white,
          selectedBorderColor: Colors.white,
          fillColor: Colors.white24,
          borderRadius: BorderRadius.circular(8),
          isSelected: [_mode == 'BLE', _mode == 'HEALTH'],
          onPressed: (index) async {
            setState(() {
              _mode = index == 0 ? 'BLE' : 'HEALTH';
            });

            if (_mode == 'BLE') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
              );
            } else {
              final healthService = HealthService();
              final granted = await healthService.requestPermissions();
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Разрешения не предоставлены')),
                  );
                }
                return;
              }

              final authorized = await healthService.requestAuthorization();
              final msg = authorized
                  ? 'Доступ к данным здоровья предоставлен'
                  : 'Не удалось получить доступ к данным здоровья';
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            }
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Bluetooth (BLE)', style: TextStyle(color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Google/Apple Health', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceInfo info;
  final VoidCallback onSync;
  final VoidCallback onUnpair;

  const _DeviceCard({
    required this.info,
    required this.onSync,
    required this.onUnpair,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/device_icon.png'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('ID: ${info.id}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Battery: ${info.battery ?? '--'}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 0, child: Text('Sync now')),
                PopupMenuItem(value: 1, child: Text('Unpair')),
              ],
              onSelected: (v) {
                if (v == 0) onSync();
                if (v == 1) onUnpair();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PairPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _PairPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 60),
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepOrange,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: const Text('Pair a device'),
      ),
    ],
  );
}
