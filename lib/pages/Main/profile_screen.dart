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
          .collection('_meta')
          .doc('profile')
          .get();
      setState(() => userData = doc.data());
    }
  }

  void _goToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    _loadUserData();
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: userData!['photoUrl'] != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(userData!['photoUrl'], height: 300),
          )
              : const Icon(Icons.person, size: 100, color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    return date != null
        ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
        : '';
  }

  Widget _profileTile(String title, String value) {
    return Column(
      children: [
        ListTile(
          title: Center(
              child: Text(title,
                  style: const TextStyle(fontSize: 15, color: Colors.grey))),
          subtitle: Center(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500))),
          onTap: _goToEdit,
        ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _goToEdit,
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showAvatarDialog,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: userData!['photoUrl'] != null
                        ? NetworkImage(userData!['photoUrl'])
                        : null,
                    child: userData!['photoUrl'] == null
                        ? const Icon(Icons.person,
                        size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                _profileTile(
                    "Name", userData!['displayName'] ?? 'No name'),
                _profileTile("Email",
                    FirebaseAuth.instance.currentUser?.email ?? ''),
                _profileTile("Gender", userData!['gender'] ?? ''),
                _profileTile("Height", "${userData!['heightCm']} cm"),
                _profileTile("Weight", "${userData!['weightKg']} kg"),
                _profileTile(
                    "Birth Date", _formatDate(userData!['birthday'])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
