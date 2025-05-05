import 'package:flutter/material.dart';
import 'workout_history_screen.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWorkoutCard("Кардио тренировка", "30 минут", Icons.favorite, Colors.red),
          _buildWorkoutCard("Силовая тренировка", "45 минут", Icons.fitness_center, Colors.blue),
          _buildWorkoutCard("Йога", "20 минут", Icons.self_improvement, Colors.green),
          const SizedBox(height: 10), // Отступ перед историей тренировок
          _buildHistoryCard(context), // Добавляем историю тренировок
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddWorkoutModal(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWorkoutCard(String title, String duration, IconData icon, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        subtitle: Text(duration, style: const TextStyle(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow, color: Colors.black),
          onPressed: () {
            // TODO: Добавить запуск тренировки
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    return Card(
      color: Colors.orange[100], // Подсветка истории
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.orange, size: 40),
        title: const Text(
          "История тренировок",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        subtitle: const Text("Просмотреть прошедшие тренировки", style: TextStyle(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WorkoutHistoryScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showAddWorkoutModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController durationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Чтобы лист мог занимать весь экран
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Добавить тренировку",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Название тренировки",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Продолжительность (минуты)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text;
                  String duration = durationController.text;
                  print("Добавлена тренировка: $name, $duration минут");

                  Navigator.pop(context); // Закрываем окно
                },
                child: const Text("Добавить"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
