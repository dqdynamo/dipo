import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/profile_service.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;

  final List<String> _genderOptions = ['Male', 'Female'];

  Future<void> _submit() async {
    if (_nameController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _gender == null ||
        _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    final double height = double.tryParse(_heightController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = UserProfile(
        displayName: _nameController.text,
        birthday: _birthDate,
        heightCm: height,
        weightKg: weight,
        gender: _gender!,
      );

      try {
        await ProfileService().save(profile);
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e")),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
    const labelStyle = TextStyle(fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("User Information"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: labelStyle,
                prefixIcon: const Icon(Icons.person),
                border: border,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _gender,
              items: _genderOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
              decoration: InputDecoration(
                labelText: "Gender",
                labelStyle: labelStyle,
                prefixIcon: const Icon(Icons.wc),
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
                labelText: "Height (cm)",
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
                labelText: "Weight (kg)",
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
                  labelText: "Birth Date",
                  labelStyle: labelStyle,
                  prefixIcon: const Icon(Icons.cake),
                  border: border,
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  _birthDate == null
                      ? "Select a date"
                      : "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: _birthDate == null ? Colors.grey[600] : Colors.black,
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
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Save and Continue",
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
