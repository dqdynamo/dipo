import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/device_service.dart';

class PairDeviceScreen extends StatefulWidget {
  const PairDeviceScreen({Key? key}) : super(key: key);

  @override
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  @override
  void initState() {
    super.initState();
    // стартуем сканирование
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceService>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DeviceService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add device'),
        backgroundColor: const Color(0xFFFF9240),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ds.isScanning ? ds.stopScan : ds.startScan,
        backgroundColor: Colors.deepOrange,
        child: Icon(ds.isScanning ? Icons.stop : Icons.search),
      ),
      body: ds.isScanning && ds.foundDevices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        itemCount: ds.foundDevices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = ds.foundDevices[i];
          return ListTile(
            title: Text(r.device.name.isNotEmpty
                ? r.device.name
                : '(no name)'),
            subtitle: Text(r.device.id.id),
            onTap: () async {
              await ds.pair(r);
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
