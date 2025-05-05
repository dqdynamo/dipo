import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  int age = 19; // Возраст по умолчанию

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? "Даулет Карибеков";
  }

  Future<void> _saveProfile() async {
    if (user != null) {
      await user!.updateDisplayName(_nameController.text);
      await user!.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Профиль обновлен!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Мой профиль")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            /// Фото профиля
            CircleAvatar(
              radius: 50,
              child: Icon(Icons.add, size: 50, color: Colors.grey.shade700),
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),

            /// Имя и возраст
            Text(
              _nameController.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "$age лет",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),


            /// Информация профиля
            _profileOption(Icons.info, "Информация обо мне"),
            _profileOption(Icons.work, "Род деятельности"),
            _profileOption(Icons.fitness_center, "Стаж тренировок"),
            _profileOption(Icons.location_city, "Фитнес-клуб"),
            _profileOption(Icons.flag, "Цель"),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
        child: Text(title, style: const TextStyle(color: Colors.black)),
      ),
    );
  }

  Widget _profileOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      onTap: () {},
    );
  }
}
