import '../../services/health_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'package:diploma/pages/Main/settings_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
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

  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getUserProfile();
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _profileFuture = _getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final healthService = HealthService();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем кнопку назад
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final name = data['displayName'] ?? tr("unknown_user");
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
                    user?.email ?? tr("no_email"),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 30),

                  ListTile(
                    leading: Icon(Icons.account_circle, color: theme.iconTheme.color),
                    title: Text(tr("profile"), style: theme.textTheme.bodyLarge),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                      // После возврата обновляем профиль
                      await _reloadProfile();
                    },
                  ),
                  const Divider(),

                  ListTile(
                    leading: Icon(Icons.favorite, color: theme.iconTheme.color),
                    title: Text(tr("sync_health"), style: theme.textTheme.bodyLarge),
                    onTap: () async {
                      final success = await healthService.requestAuthorization();
                      if (success) {
                        final steps = await healthService.fetchTodaySteps();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr("steps_today", namedArgs: {"count": steps.toString()}))),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr("no_health_access"))),
                        );
                      }
                    },
                  ),
                  const Divider(),

                  ListTile(
                    leading: Icon(Icons.settings, color: theme.iconTheme.color),
                    title: Text(tr("settings"), style: theme.textTheme.bodyLarge),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.info, color: theme.iconTheme.color),
                    title: Text(tr("about"), style: theme.textTheme.bodyLarge),
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
                    title: Text(tr("faq"), style: theme.textTheme.bodyLarge),
                    children: [
                      ListTile(
                        title: Text(tr("faq_sync_title")),
                        subtitle: Text(tr("faq_sync_body")),
                      ),
                      ListTile(
                        title: Text(tr("faq_profile_title")),
                        subtitle: Text(tr("faq_profile_body")),
                      ),
                      ListTile(
                        title: Text(tr("faq_signout_title")),
                        subtitle: Text(tr("faq_signout_body")),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(tr("sign_out")),
                            content: Text(tr("sign_out_confirm")),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(tr("cancel")),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(tr("sign_out")),
                              ),
                            ],
                          ),
                        );
                        if (result == true) {
                          await FirebaseAuth.instance.signOut();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr("sign_out_success"))),
                          );
                          Navigator.pushReplacementNamed(context, '/splash');
                        }
                      },
                      icon: const Icon(Icons.logout, size: 26, color: Colors.white),
                      label: Text(
                        tr("sign_out"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('about')),
        backgroundColor: isDark ? const Color(0xFF191825) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF191825) : Colors.white,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NomadFit",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr("version"),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr("about_app_desc"),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr("about_app_tech"),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                "© 2025   ${tr("all_rights_reserved")}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white, // Always white
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
