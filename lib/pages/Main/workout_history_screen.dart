import 'package:flutter/material.dart';
import 'package:diploma/services/workout_service.dart';
import 'package:diploma/models/workout_session.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  final WorkoutService _workoutService = WorkoutService();

  WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("История тренировок")),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: _workoutService.getWorkouts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final workouts = snapshot.data!;
          if (workouts.isEmpty) return const Center(child: Text("Нет записанных тренировок"));

          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return ListTile(
                title: Text("Шаги: ${workout.steps}"),
                subtitle: Text("Дата: ${workout.date.toLocal()}"),
                trailing: Text("${workout.calories} ккал"),
              );
            },
          );
        },
      ),
    );
  }
}
