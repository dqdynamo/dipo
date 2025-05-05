import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String surname;
  final int age;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.surname,
    required this.age,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController surnameController;
  late TextEditingController ageController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    surnameController = TextEditingController(text: widget.surname);
    ageController = TextEditingController(text: widget.age.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void saveProfile() {
    Navigator.pop(context, {
      'name': nameController.text,
      'surname': surnameController.text,
      'age': int.tryParse(ageController.text) ?? widget.age,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Редактирование профиля")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Имя"),
            ),
            TextField(
              controller: surnameController,
              decoration: const InputDecoration(labelText: "Фамилия"),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Возраст"),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    nameController.text = widget.name;
                    surnameController.text = widget.surname;
                    ageController.text = widget.age.toString();
                  },
                  child: const Text("Очистить"),
                ),
                ElevatedButton(
                  onPressed: saveProfile,
                  child: const Text("Сохранить"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
