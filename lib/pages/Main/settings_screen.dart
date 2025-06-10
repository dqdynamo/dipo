import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
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
      notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  void _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => notificationsEnabled = value);
    // Добавь реальную логику уведомлений при необходимости
  }

  void _changeLanguageDialog() async {
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr("language")),
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
      context.setLocale(Locale(lang));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('language_changed'))),
      );
    }
  }

  void _openPrivacyPolicy() async {
    const url = "https://your-privacy-policy-link.com";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openSupport() async {
    final email = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      query: 'subject=App Support',
    );
    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    }
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr("delete_account")),
        content: const Text("Are you sure you want to delete your account? This cannot be undone."),
        actions: [
          TextButton(
            child: Text(tr("cancel")),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: Text(tr("delete"), style: const TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("account_deleted"))),
          );
          // Вернуть на экран входа или сплэш-скрин:
          Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr("reauth_required"))),
          );
          // Можно отправить на экран логина:
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.message}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String currentLanguage =
    context.locale.languageCode == 'ru' ? 'Русский' : 'English';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("settings")),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr("language")),
            subtitle: Text(currentLanguage),
            onTap: _changeLanguageDialog,
          ),
          const Divider(),
          SwitchListTile(
            value: themeProvider.isDark,
            onChanged: (value) => themeProvider.toggleTheme(value),
            title: Text(tr("dark_theme")),
            secondary: const Icon(Icons.brightness_6),
          ),
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
            title: Text(tr("notifications")),
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(tr("app_version")),
            subtitle: Text(appVersion ?? "Loading..."),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(tr("privacy_policy")),
            onTap: _openPrivacyPolicy,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(tr("support")),
            onTap: _openSupport,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(tr("delete_account"), style: const TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}
