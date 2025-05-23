import 'package:flutter/material.dart';

class MealReminderScreen extends StatefulWidget {
  const MealReminderScreen({super.key});

  @override
  State<MealReminderScreen> createState() => _MealReminderScreenState();
}

class _MealReminderScreenState extends State<MealReminderScreen> {
  final Map<String, TimeOfDay?> _mealTimes = {
    'Breakfast': null,
    'Lunch': null,
    'Dinner': null,
    'Snack': null,
  };

  Future<void> _pickTime(String meal) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _mealTimes[meal] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _mealTimes.entries.map((entry) {
          final meal = entry.key;
          final time = entry.value;
          return Card(
            child: ListTile(
              title: Text(meal),
              subtitle: Text(
                time != null ? time.format(context) : 'No time set',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () => _pickTime(meal),
            ),
          );
        }).toList(),
      ),
    );
  }
}
