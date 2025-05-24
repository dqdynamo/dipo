import '../../services/health_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<Map<String, dynamic>> _getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('_meta')
        .doc('profile')
        .get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final healthService = HealthService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final name = data['displayName'] ?? "Unknown User";
          final photoUrl = data['photoUrl'] as String?;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (photoUrl != null) {
                        showDialog(
                          context: context,
                          builder: (_) => GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Dialog(
                              backgroundColor: Colors.transparent,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(photoUrl, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(user?.email ?? "No email"),
                  const SizedBox(height: 30),

                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text("Profile"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Шагов: $steps")),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text("About"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  const Divider(),

                  ExpansionTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text("FAQ"),
                    children: const [
                      ListTile(
                        title: Text("How to sync with Google Fit or Apple Health?"),
                        subtitle: Text("Go to 'Sync' section and grant the required permissions."),
                      ),
                      ListTile(
                        title: Text("How do I change my profile data?"),
                        subtitle: Text("Tap on your profile section and then use the Edit button."),
                      ),
                      ListTile(
                        title: Text("How do I sign out?"),
                        subtitle: Text("Scroll down and tap on the red Sign Out button."),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Скруглённая кнопка выхода:
                  SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/splash');
                      },
                      icon: const Icon(Icons.logout, color: Colors.white, size: 26),
                      label: const Text(
                        "Sign Out",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // 👈 Максимально скруглённые края
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings screen')),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About this app')),
    );
  }
}
