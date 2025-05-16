import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:diploma/services/step_tracker_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int stepGoal = 10000;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StepTrackerService>(context, listen: false).loadWorkoutForDate(selectedDate);
    });
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
    });
    Provider.of<StepTrackerService>(context, listen: false).loadWorkoutForDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, selectedDate, _onDateChanged),
                      const SizedBox(height: 24),
                      Consumer<StepTrackerService>(
                        builder: (context, stepService, child) {
                          final steps = stepService.steps;
                          final percent = (steps / stepGoal).clamp(0.0, 1.0);
                          final calories = (steps * 0.04).toInt();
                          final distance = (steps * 0.0008);

                          return Column(
                            children: [
                              Center(
                                child: CircularPercentIndicator(
                                  radius: 120.0,
                                  lineWidth: 14.0,
                                  percent: percent,
                                  animation: true,
                                  circularStrokeCap: CircularStrokeCap.round,
                                  progressColor: Colors.orange,
                                  backgroundColor: Colors.orange.shade100,
                                  center: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.directions_walk, color: Colors.orange, size: 30),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$steps',
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                      ),
                                      const Text("шагов", style: TextStyle(fontSize: 16)),
                                      const SizedBox(height: 6),
                                      Text("Цель: $stepGoal", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                      Text("Завершено: ${(percent * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildStatCard("Калории", "$calories ккал", Icons.local_fire_department, Colors.red),
                                  _buildStatCard("Активность", "${(steps / 100).toStringAsFixed(1)} мин", Icons.timer, Colors.orange),
                                  _buildStatCard("Пульс", "-", Icons.favorite, Colors.pink),
                                  _buildStatCard("Расстояние", "${distance.toStringAsFixed(2)} км", Icons.place, Colors.blue),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await stepService.saveWorkout(selectedDate);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Данные за день сохранены")),
                                  );
                                },
                                icon: const Icon(Icons.save),
                                label: const Text("Сохранить день"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime selectedDate, void Function(DateTime) onDateChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              locale: const Locale('ru'),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                DateFormat.yMMMMd('ru').format(selectedDate),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}
