import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  File? _newAvatar;
  String? _photoUrl;

  bool _isLoading = true;
  bool _isSaving = false;

  final genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('_meta')
        .doc('profile')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['displayName'] ?? '';
        _heightController.text = (data['heightCm'] ?? '').toString();
        _weightController.text = (data['weightKg'] ?? '').toString();
        _birthDate = data['birthday'] != null ? DateTime.tryParse(data['birthday']) : null;
        _gender = data['gender'];
        _photoUrl = data['photoUrl'];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAvatarTap() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Change Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _newAvatar = File(picked.path));
                  }
                },
              ),
              if (_photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("Remove Photo"),
                  onTap: () async {
                    Navigator.pop(context);
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
                    await ref.delete().catchError((_) {}); // ignore if not exist
                    setState(() {
                      _photoUrl = null;
                      _newAvatar = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }


  Future<String?> _uploadAvatar(File file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? url = _photoUrl;

    if (_newAvatar != null) {
      url = await _uploadAvatar(_newAvatar!);
    }

    final profileData = {
      'displayName': _nameController.text,
      'heightCm': double.tryParse(_heightController.text) ?? 0,
      'weightKg': double.tryParse(_weightController.text) ?? 0,
      'birthday': _birthDate?.toIso8601String(),
      'gender': _gender,
      'photoUrl': url,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('_meta')
        .doc('profile')
        .set(profileData);

    if (mounted) Navigator.pop(context);
    setState(() => _isSaving = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Edit Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _handleAvatarTap,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _newAvatar != null
                      ? FileImage(_newAvatar!)
                      : (_photoUrl != null
                      ? NetworkImage(_photoUrl!)
                      : null) as ImageProvider<Object>?,
                  child: (_newAvatar == null && _photoUrl == null)
                      ? const Icon(Icons.camera_alt, color: Colors.white, size: 45)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text("Tap to change photo", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: border,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: genderOptions.contains(_gender) ? _gender : null,
                items: genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val),
                decoration: InputDecoration(
                  labelText: "Gender",
                  border: border,
                  prefixIcon: const Icon(Icons.wc),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Height (cm)",
                  border: border,
                  prefixIcon: const Icon(Icons.height),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Weight (kg)",
                  border: border,
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Birth Date",
                    border: border,
                    prefixIcon: const Icon(Icons.cake),
                  ),
                  child: Text(
                    _birthDate != null
                        ? "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}"
                        : "Select a date",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
