// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:provider/provider.dart';
// import 'package:diploma/services/step_tracker_service.dart';
// import 'package:intl/intl.dart';
//
// class ProgressScreen extends StatelessWidget {
//   const ProgressScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final stepService = Provider.of<StepTrackerService>(context);
//     final stepsHistory = _getStepsForLastWeek(stepService.weeklySteps);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Прогресс шагов')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Статистика активности",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             _buildStatsRow(stepsHistory),
//             const SizedBox(height: 20),
//             _buildStepsChart(stepsHistory),
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<int> _getStepsForLastWeek(Map<String, int> stepsData) {
//     List<int> steps = [];
//     DateTime today = DateTime.now();
//
//     for (int i = 6; i >= 0; i--) {
//       String dateKey = DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i)));
//       steps.add(stepsData[dateKey] ?? 0);
//     }
//     return steps;
//   }
//
//   Widget _buildStatsRow(List<int> stepsHistory) {
//     int totalSteps = stepsHistory.fold(0, (sum, steps) => sum + steps);
//     double avgSteps = stepsHistory.isNotEmpty ? totalSteps / stepsHistory.length : 0;
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _buildStatCard("Общий шаги", "$totalSteps", Icons.directions_walk, Colors.blue),
//         _buildStatCard("Среднее", "${avgSteps.toStringAsFixed(0)}", Icons.timeline, Colors.green),
//       ],
//     );
//   }
//
//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Icon(icon, color: color, size: 40),
//             const SizedBox(height: 8),
//             Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStepsChart(List<int> stepsHistory) {
//     const days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];
//
//     return SizedBox(
//       height: 250,
//       child: LineChart(
//         LineChartData(
//           gridData: const FlGridData(show: false),
//           titlesData: FlTitlesData(
//             leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (value, meta) {
//                   int index = value.toInt().clamp(0, days.length - 1);
//                   return Text(days[index], style: const TextStyle(fontSize: 12));
//                 },
//                 interval: 1,
//               ),
//             ),
//           ),
//           borderData: FlBorderData(show: true),
//           lineBarsData: [
//             LineChartBarData(
//               spots: List.generate(
//                 stepsHistory.length,
//                     (index) => FlSpot(index.toDouble(), stepsHistory[index].toDouble()),
//               ),
//               isCurved: true,
//               barWidth: 4,
//               color: Colors.blue,
//               belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
//               dotData: const FlDotData(show: true),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }