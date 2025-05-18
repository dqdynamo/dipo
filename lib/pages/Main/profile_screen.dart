import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.orange,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            child: Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _TopTab(icon: Icons.bar_chart, label: 'Today\'s\nRanking'),
                _TopTab(icon: Icons.receipt_long, label: 'My Report'),
                _TopTab(icon: Icons.emoji_events, label: 'My\nEvents'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                _SettingsTile(icon: Icons.place, title: 'Set Goal'),
                _SettingsTile(icon: Icons.person, title: 'Personal Info'),
                _SettingsTile(icon: Icons.settings, title: 'System Settings'),
                _SettingsTile(icon: Icons.help_outline, title: 'FAQs'),
                _SettingsTile(icon: Icons.cloud_outlined, title: 'Third-party Apps'),
                _SettingsTile(icon: Icons.sync, title: 'Sync Now', subtitle: '2025-05-17'),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Icon(Icons.watch, size: 80, color: Colors.orange),
                          SizedBox(height: 10),
                          Text(
                            'New Products\nUpdate your Very Fit app to pair the latest smart wearables for best performance.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Device'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Splash Screen")),
    );
  }
}
