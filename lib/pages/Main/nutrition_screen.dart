import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/nutrition_service.dart';
import 'add_edit_meal_screen.dart';
import 'nutrition_goals_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionService _service = NutritionService();
  DateTime _selectedDay = DateTime.now();
  List<Meal> _meals = [];
  Map<String, int> _goals = {};
  List<DateTime> _chartDays = [];
  List<int> _chartCalories = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final meals = await _service.getMealsForDay(_selectedDay);
    final goals = await _service.getGoals();

    final chartDays = List.generate(7, (i) => _selectedDay.subtract(Duration(days: 6 - i)));
    final chartCalories = <int>[];

    for (final d in chartDays) {
      final meals = await _service.getMealsForDay(d);
      final total = meals.fold<int>(0, (s, m) => s + m.calories);
      chartCalories.add(total);
    }

    setState(() {
      _meals = meals;
      _goals = goals;
      _chartDays = chartDays;
      _chartCalories = chartCalories;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
      _loadAll();
    }
  }

  void _deleteMeal(String id) async {
    await _service.deleteMeal(_selectedDay, id);
    _loadAll();
  }

  Map<String, int> _total() {
    int cals = 0, pro = 0, carbs = 0, fat = 0;
    for (var m in _meals) {
      cals += m.calories;
      pro += m.protein;
      carbs += m.carbs;
      fat += m.fat;
    }
    return {'calories': cals, 'protein': pro, 'carbs': carbs, 'fat': fat};
  }

  @override
  Widget build(BuildContext context) {
    final grad = const [Color(0xFFFF9240), Color(0xFFDD4733)];
    final totals = _total();
    final label = DateFormat.yMMMMd('en').format(_selectedDay);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NutritionGoalsScreen()));
                      },
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Text(label,
                              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadAll,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatsPanel(totals: totals, goals: _goals),
              const SizedBox(height: 8),
              _buildCaloriesChart(),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: _meals.isEmpty
                      ? const Center(child: Text('No meals recorded for this date.'))
                      : ListView.builder(
                    itemCount: _meals.length,
                    itemBuilder: (_, i) {
                      final m = _meals[i];
                      return Card(
                        child: ListTile(
                          title: Text('${m.name} (${m.type})'),
                          subtitle: Text('${m.calories} kcal | P: ${m.protein} | C: ${m.carbs} | F: ${m.fat}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMeal(m.id),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) =>
                                  AddEditMealScreen(date: _selectedDay, existing: m)),
                            );
                            _loadAll();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: grad[1],
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditMealScreen(date: _selectedDay)),
          );
          _loadAll();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCaloriesChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calories — Last 7 Days',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  maxY: (_chartCalories.fold(0, (a, b) => a > b ? a : b) + 100).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= _chartDays.length) return const SizedBox();
                          return Text(
                            DateFormat('E').format(_chartDays[i]),
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, horizontalInterval: 200, getDrawingHorizontalLine: (_) {
                    return FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1);
                  }),
                  barGroups: List.generate(_chartDays.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _chartCalories[i].toDouble(),
                          color: const Color(0xFFFF7043),
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final Map<String, int> totals;
  final Map<String, int> goals;

  const _StatsPanel({required this.totals, required this.goals});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Card('Calories', totals['calories']!, goals['calories']!, Colors.deepOrange),
          _Card('Protein', totals['protein']!, goals['protein']!, Colors.green),
          _Card('Carbs', totals['carbs']!, goals['carbs']!, Colors.blue),
          _Card('Fat', totals['fat']!, goals['fat']!, Colors.purple),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label;
  final int val;
  final int goal;
  final Color col;

  const _Card(this.label, this.val, this.goal, this.col);

  @override
  Widget build(BuildContext ctx) {
    final pct = goal > 0 ? (val / goal).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: col.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text('$val / $goal', style: TextStyle(color: col, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: pct, color: col, backgroundColor: Colors.grey.shade300, minHeight: 4),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
