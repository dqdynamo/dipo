import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Импортируем новый экран профиля

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Дополнительно")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Профиль", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            /// Профиль теперь кнопка
            ListTile(
              leading: const Icon(Icons.account_circle, size: 40),
              title: Text(user?.email ?? "Неизвестный пользователь"),
              subtitle: const Text("Email пользователя"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            const Divider(),

            /// Пункт "Настройки"
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Настройки"),
              onTap: () {
                // TODO: Добавить переход на страницу настроек
              },
            ),

            /// Пункт "О приложении"
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("О приложении"),
              onTap: () {
                // TODO: Добавить переход на страницу "О приложении"
              },
            ),

            const Spacer(),

            /// Кнопка выхода
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/splash');
                },
                icon: const Icon(Icons.logout),
                label: const Text("Выйти"),
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
