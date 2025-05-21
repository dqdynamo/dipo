import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;

  bool _isLoading = true;

  final List<String> genderOptions = ['Мужской', 'Женский'];

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

      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['email'] ?? '';
          _gender = data['gender'];
          _heightController.text = data['height'].toString();
          _weightController.text = data['weight'].toString();
          _birthDate = DateTime.tryParse(data['birthDate'] ?? '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'gender': _gender,
        'height': int.tryParse(_heightController.text),
        'weight': int.tryParse(_weightController.text),
        'birthDate': _birthDate?.toIso8601String(),
      });

      Navigator.pop(context); // вернуться назад на профиль
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Редактировать профиль"),
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              enabled: false,
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Email (не редактируется)",
                border: border,
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: genderOptions.contains(_gender) ? _gender : null,
              items: genderOptions
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
              decoration: InputDecoration(
                labelText: "Пол",
                border: border,
                prefixIcon: const Icon(Icons.wc),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Рост (см)",
                border: border,
                prefixIcon: const Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Вес (кг)",
                border: border,
                prefixIcon: const Icon(Icons.monitor_weight),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Дата рождения",
                  border: border,
                  prefixIcon: const Icon(Icons.cake),
                ),
                child: Text(
                  _birthDate != null
                      ? "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}"
                      : "Выберите дату",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
