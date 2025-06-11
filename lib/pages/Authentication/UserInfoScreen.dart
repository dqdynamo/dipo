import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
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

  List<String> get _genderOptions => [
    tr("user_info_male"),
    tr("user_info_female"),
  ];

  Future<void> _submit() async {
    if (_nameController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _gender == null ||
        _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("user_info_fill_all"))),
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
          SnackBar(content: Text(tr("user_info_error_saving", args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _skip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final emptyProfile = UserProfile(
        displayName: "",
        birthday: null,
        heightCm: 0,
        weightKg: 0,
        gender: "",
      );
      try {
        await ProfileService().save(emptyProfile);
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("user_info_error_saving", args: [e.toString()]))),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color mainBg = isDark ? const Color(0xFF232032) : const Color(0xFFF4F6F8);
    final Color fieldBg = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? Colors.white70 : Colors.black54;
    final Color iconColor = isDark ? Colors.white : Colors.deepOrange;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.deepOrange.withOpacity(0.4), width: 1.3),
    );
    final labelStyle = TextStyle(fontWeight: FontWeight.w600, color: textColor);
    final hintStyle = TextStyle(color: hintColor);

    return Scaffold(
      backgroundColor: mainBg,
      appBar: AppBar(
        title: Text(tr("user_info_title"), style: TextStyle(color: textColor)),
        backgroundColor: Colors.deepOrange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: tr("user_info_name"),
                labelStyle: labelStyle,
                hintText: tr("user_info_name"),
                hintStyle: hintStyle,
                prefixIcon: Icon(Icons.person, color: iconColor),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                filled: true,
                fillColor: fieldBg,
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _gender,
              style: TextStyle(color: textColor),
              dropdownColor: isDark ? const Color(0xFF232032) : Colors.white,
              items: _genderOptions
                  .map((g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: TextStyle(color: textColor)),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
              decoration: InputDecoration(
                labelText: tr("user_info_gender"),
                labelStyle: labelStyle,
                prefixIcon: Icon(Icons.wc, color: iconColor),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                filled: true,
                fillColor: fieldBg,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: tr("user_info_height"),
                labelStyle: labelStyle,
                hintText: tr("user_info_height"),
                hintStyle: hintStyle,
                prefixIcon: Icon(Icons.height, color: iconColor),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                filled: true,
                fillColor: fieldBg,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: tr("user_info_weight"),
                labelStyle: labelStyle,
                hintText: tr("user_info_weight"),
                hintStyle: hintStyle,
                prefixIcon: Icon(Icons.monitor_weight, color: iconColor),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                filled: true,
                fillColor: fieldBg,
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: tr("user_info_birth_date"),
                  labelStyle: labelStyle,
                  prefixIcon: Icon(Icons.cake, color: iconColor),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  filled: true,
                  fillColor: fieldBg,
                ),
                child: Text(
                  _birthDate == null
                      ? tr("user_info_select_date")
                      : "${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: _birthDate == null ? hintColor : textColor,
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
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  tr("user_info_save_continue"),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _skip,
                icon: Icon(Icons.skip_next, color: isDark ? Colors.white70 : Colors.deepOrange),
                label: Text(
                  tr("skip"),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.deepOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
