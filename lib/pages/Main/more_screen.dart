
import '../../services/health_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final healthService = HealthService();

    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.account_circle, size: 40),
              title: Text(user?.email ?? "Unknown user"),
              subtitle: const Text("User email"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("Синхронизация с Google Fit / Apple Health"),
              onTap: () async {
                final success = await healthService.requestAuthorization();
                if (success) {
                  final steps = await healthService.fetchTodaySteps();
                  final heart = await healthService.fetchAverageHeartRate();
                  final sleep = await healthService.fetchTodaySleepMinutes();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Шагов: $steps | Пульс: ${heart.toStringAsFixed(1)} | Сон: $sleep мин")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Доступ к данным не получен")),
                  );
                }
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () {},
            ),

            const Spacer(),

            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/splash');
                },
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
