// lib/pages/device/device_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/device_service.dart';
import 'pair_device_screen.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ds     = context.watch<DeviceService>();
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

              /* ---- карточка или плейсхолдер ---- */
              if (device != null)
                _DeviceCard(
                  info: device,
                  onUnpair: ds.unpair,
                  onSync:   () async {
                    // пока sync-метода нет ‒ просто отключим/подключим
                    await ds.unpair();
                    if (context.mounted) Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                    );
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

              const SizedBox(height: 12),
              if (device != null) ...[
                const Divider(height: 1, color: Colors.white54),
                _Tile(icon: Icons.apps, title: 'More'),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────── widgets ───────────────── */

class _DeviceCard extends StatelessWidget {
  final DeviceInfo info;
  final VoidCallback onSync;
  final VoidCallback onUnpair;
  const _DeviceCard(
      {required this.info, required this.onSync, required this.onUnpair});

  @override
  Widget build(BuildContext context) => Padding(
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
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Battery: ${info.battery ?? '--'}%',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
                  // Если позже добавите поля:
                  // Text('FW: ${info.fwVersion}')
                  // Text('Synced: ${DateFormat('dd/MM/yy HH:mm').format(info.syncedAt)}')
                ]),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 0, child: Text('Sync now')),
              const PopupMenuItem(value: 1, child: Text('Unpair')),
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

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _Tile({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title,
        style: const TextStyle(color: Colors.white, fontSize: 16)),
    trailing:
    trailing ?? const Icon(Icons.chevron_right, color: Colors.white),
    onTap: () {},
  );
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
