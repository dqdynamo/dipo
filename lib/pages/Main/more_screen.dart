import '../../services/health_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'package:diploma/pages/Main/settings_screen.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // <-- Автоматическая поддержка темы
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
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "No email",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 30),

                  ListTile(
                    leading: Icon(Icons.account_circle, color: theme.iconTheme.color),
                    title: Text("Profile", style: theme.textTheme.bodyLarge),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(),

                  ListTile(
                    leading: Icon(Icons.favorite, color: theme.iconTheme.color),
                    title: Text("Синхронизация с Google Fit / Apple Health", style: theme.textTheme.bodyLarge),
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
                    leading: Icon(Icons.settings, color: theme.iconTheme.color),
                    title: Text("Settings", style: theme.textTheme.bodyLarge),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.info, color: theme.iconTheme.color),
                    title: Text("About", style: theme.textTheme.bodyLarge),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  const Divider(),

                  ExpansionTile(
                    leading: Icon(Icons.help_outline, color: theme.iconTheme.color),
                    title: Text("FAQ", style: theme.textTheme.bodyLarge),
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

                  // Sign Out button with proper color for dark/light theme
                  SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/splash');
                      },
                      icon: const Icon(Icons.logout, size: 26, color: Colors.white),
                      label: const Text(
                        "Sign Out",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,      // ЯРКО-КРАСНЫЙ цвет кнопки!
                        foregroundColor: Colors.white,    // Белый текст и иконка
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
