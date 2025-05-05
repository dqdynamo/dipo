import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diploma/services/step_tracker_service.dart';

class StepScreen extends StatelessWidget {
  const StepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepService = Provider.of<StepTrackerService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Шагомер")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Шаги: ${stepService.steps}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await stepService.saveWorkout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Тренировка сохранена!")),
                );
              },
              child: const Text("Сохранить тренировку"),
            ),
          ],
        ),
      ),
    );
  }
}
