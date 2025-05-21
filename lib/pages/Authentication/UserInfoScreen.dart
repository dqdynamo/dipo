import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;

  Future<void> _submit() async {
    if (_heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _selectedGender == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, заполните все поля")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = {
        'gender': _selectedGender,
        'height': int.tryParse(_heightController.text),
        'weight': int.tryParse(_weightController.text),
        'birthDate': _selectedDate!.toIso8601String(),
        'email': user.email,
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка при сохранении: $e")),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final labelStyle = const TextStyle(fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Личная информация"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedGender,
              items: ['Мужской', 'Женский']
                  .map((gender) =>
                  DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
              decoration: InputDecoration(
                labelText: "Пол",
                labelStyle: labelStyle,
                prefixIcon: const Icon(Icons.person),
                border: border,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Рост (см)",
                labelStyle: labelStyle,
                prefixIcon: const Icon(Icons.height),
                border: border,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Вес (кг)",
                labelStyle: labelStyle,
                prefixIcon: const Icon(Icons.monitor_weight),
                border: border,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Дата рождения",
                  labelStyle: labelStyle,
                  prefixIcon: const Icon(Icons.cake),
                  border: border,
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  _selectedDate == null
                      ? "Выберите дату"
                      : "${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}",
                  style: TextStyle(
                    color:
                    _selectedDate == null ? Colors.grey[600] : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Сохранить и продолжить",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
