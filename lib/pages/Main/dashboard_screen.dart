import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diploma/services/step_tracker_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Consumer<StepTrackerService>(
                builder: (context, stepService, child) {
                  return Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildStatCard("Шаги", "${stepService.steps}", Icons.directions_walk, Colors.blue),
                        _buildStatCard("Калории", "${(stepService.steps * 0.04).toStringAsFixed(1)} kcal", Icons.local_fire_department, Colors.red),
                        _buildStatCard("Активность", "${(stepService.steps / 100).toStringAsFixed(1)} мин", Icons.timer, Colors.orange),
                        _buildStatCard("Пульс", "-", Icons.favorite, Colors.pink),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Dashboard",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        CircleAvatar(
          backgroundImage: AssetImage("assets/profile.jpg"),
          radius: 20,
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
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}
