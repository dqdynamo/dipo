import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkTheme = false;
  bool notificationsEnabled = true;
  String currentLanguage = "English";
  String? appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPrefs();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${info.version} (${info.buildNumber})";
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      notificationsEnabled = prefs.getBool('notifications') ?? true;
      currentLanguage = prefs.getString('app_language') == 'ru' ? 'Русский' : 'English';
    });
  }

  void _changeLanguageDialog() async {
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Choose language"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: const Text("English"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ru'),
            child: const Text("Русский"),
          ),
        ],
      ),
    );
    if (lang != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
      setState(() {
        currentLanguage = lang == 'ru' ? 'Русский' : 'English';
      });
      // Перезагрузи app или поменяй локаль, если используешь локализацию.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language changed. Restart app to apply.')),
      );
    }
  }

  void _changeTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    setState(() => isDarkTheme = value);
    // Если используешь ThemeProvider, тут можешь добавить вызов: context.read<ThemeProvider>().toggleTheme(value)
  }

  void _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => notificationsEnabled = value);
    // Тут можно добавить включение/выключение реальных уведомлений
  }

  void _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A password reset email has been sent.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deleted.")),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Re-authentication required. Please log in again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            onTap: _changePassword,
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            subtitle: Text(currentLanguage),
            onTap: _changeLanguageDialog,
          ),
          const Divider(),

          SwitchListTile(
            value: isDarkTheme,
            onChanged: _changeTheme,
            title: const Text("Dark Theme"),
            secondary: const Icon(Icons.brightness_6),
          ),

          SwitchListTile(
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
            title: const Text("Notifications"),
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("App Version"),
            subtitle: Text(appVersion ?? "Loading..."),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}
