import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditProfile_Screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() => userData = doc.data());
    }
  }

  void _goToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }


  Widget _buildRow(String title, String value) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          subtitle: Text(value, style: const TextStyle(fontSize: 18)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _goToEdit,
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _formatDate(String isoDate) {
    final DateTime date = DateTime.parse(isoDate);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final topBar = AppBar(
      backgroundColor: Colors.deepOrange,
      title: const Text("Личная инфо"),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _goToEdit,
        )
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar,
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: [
                _buildRow("Имя пользователя", userData!['email'] ?? ''),
                _buildRow(
                    "Дата рождения",
                    userData!['birthDate'] != null
                        ? _formatDate(userData!['birthDate'])
                        : ''),
                _buildRow("Пол", userData!['gender'] ?? ''),
                _buildRow("Рост", "${userData!['height']} см"),
                _buildRow("Вес", "${userData!['weight']} кг"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
