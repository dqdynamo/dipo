import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'add_edit_meal_screen.dart';
import '../../services/nutrition_plan_service.dart';
import '../../services/profile_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DateTime _selectedDate = DateTime.now();
  late String _uid;
  bool _loading = true;

  int _caloriesIn = 0;
  double _protein = 0, _fat = 0, _carbs = 0;

  List<Map<String, dynamic>> _meals = [];
  NutritionPlan? _plan;
  double? _currentWeight;
  double? _goalWeight;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _loadAll();
  }

  String get _dateId => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadAll() async {
    await _loadPlan();
    await _loadGoalWeight();
    await _loadCurrentWeight();
    await _loadDay();
  }

  Future<void> _loadPlan() async {
    try {
      final plan = await NutritionPlanService().load();
      setState(() {
        _plan = plan;
      });
    } catch (e) {
      setState(() {
        _plan = null;
      });
    }
  }

  Future<void> _loadGoalWeight() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('goals')
        .doc('main')
        .get();
    setState(() {
      _goalWeight = (doc.data()?['weight'] as num?)?.toDouble();
    });
  }

  Future<void> _loadCurrentWeight() async {
    final profileService = ProfileService();
    await profileService.load();
    final profile = profileService.profile;
    setState(() {
      _currentWeight = profile?.weightKg;
    });
  }

  Future<void> _loadDay() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('nutrition')
        .doc(_dateId)
        .get();

    final mealsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('nutrition')
        .doc(_dateId)
        .collection('meals')
        .get();

    final d = doc.data() ?? {};
    final m = d['macros'] ?? {};

    setState(() {
      _caloriesIn = d['caloriesIn'] ?? 0;
      _protein = (m['protein'] ?? 0).toDouble();
      _fat = (m['fat'] ?? 0).toDouble();
      _carbs = (m['carbs'] ?? 0).toDouble();
      _meals = mealsSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
      _loading = false;
    });
  }

  void _changeDate(int offset) async {
    final nextDate = _selectedDate.add(Duration(days: offset));
    final today = DateTime.now();
    // Не разрешаем выбрать дату в будущем
    if (nextDate.isAfter(DateTime(today.year, today.month, today.day))) return;

    setState(() {
      _selectedDate = nextDate;
    });
    await _loadDay();
  }

  String? get _estimatedDays {
    if (_plan == null || _currentWeight == null || _goalWeight == null) return null;

    double diff = (_currentWeight! - _goalWeight!).abs();
    if (diff < 0.1) return null; // Уже достигнуто

    // 0.5 кг в неделю = 0.0714 кг/день
    double days = diff / 0.0714;
    int daysInt = days.round();

    if (_plan!.goalType == NutritionGoalType.maintain) {
      return "Maintaining";
    }
    return "$daysInt days";
  }

  Widget _buildTopHeader() {
    Widget buildArrow({required IconData icon, required VoidCallback? onTap, bool enabled = true}) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.07),
          ),
          child: Icon(icon, size: 24, color: enabled ? Colors.black87 : Colors.grey[400]),
        ),
      );
    }

    Widget buildRing(DateTime date, {bool isMain = false}) {
      final id = DateFormat('yyyy-MM-dd').format(date);
      final dateStr = DateFormat('d MMM').format(date);

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('nutrition')
            .doc(id)
            .get(),
        builder: (ctx, snap) {
          double pct = 0;
          int cals = 0;
          int target = _plan?.calorieTarget ?? 2000;

          if (snap.hasData && snap.data!.exists) {
            final d = snap.data!.data() as Map<String, dynamic>;
            cals = d['caloriesIn'] ?? 0;
            target = _plan?.calorieTarget ?? 2000;
            pct = (cals / target).clamp(0.0, 1.0);
          }

          final col = pct >= 0.8 ? Colors.green : pct >= 0.3 ? Colors.orange : Colors.grey;

          if (!isMain) {
            return Column(
              children: [
                Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                CircularPercentIndicator(
                  radius: 38,
                  lineWidth: 6,
                  percent: pct,
                  progressColor: col,
                  backgroundColor: Colors.grey.shade300,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(fontSize: 12)),
              ],
            );
          }

          return Column(
            children: [
              Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              CircularPercentIndicator(
                radius: 60,
                lineWidth: 10,
                percent: pct,
                progressColor: col,
                backgroundColor: Colors.grey.shade300,
                circularStrokeCap: CircularStrokeCap.round,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$cals', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('/ $target kcal', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildRing(_selectedDate.subtract(const Duration(days: 1))),
            const SizedBox(width: 6),
            buildArrow(icon: Icons.arrow_left, onTap: () => _changeDate(-1)),
            const SizedBox(width: 6),
            buildRing(_selectedDate, isMain: true),
            const SizedBox(width: 6),
            buildArrow(
              icon: Icons.arrow_right,
              onTap: !isToday ? () => _changeDate(1) : null,
              enabled: !isToday,
            ),
            const SizedBox(width: 6),
            buildRing(_selectedDate.add(const Duration(days: 1))),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              _loadDay();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEEE, MMM d').format(_selectedDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildPlanInfoCards() {
    if (_plan == null) return SizedBox();

    final goalTitle = _plan!.goalType == NutritionGoalType.lose
        ? "Lose Weight"
        : _plan!.goalType == NutritionGoalType.gain
        ? "Gain Weight"
        : "Maintain Weight";

    final bmiValue = _plan!.bmi.toStringAsFixed(1);
    final bmiLabel = _plan!.bmi < 18.5
        ? "Underweight"
        : (_plan!.bmi < 25 ? "Normal" : _plan!.bmi < 30 ? "Overweight" : "Obese");

    String? estimated = _estimatedDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Your Plan",
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.flag, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 6),
                            Text(goalTitle,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_plan!.calorieTarget} kcal",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BMI",
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.monitor_weight,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 6),
                            Text(bmiValue,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          bmiLabel,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("Weight Progress",
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.accessibility_new_rounded,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "${_currentWeight?.toStringAsFixed(1) ?? '-'}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Icon(Icons.flag, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 4),
                            Text(
                              "${_goalWeight?.toStringAsFixed(1) ?? '-'} kg",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Current   →   Goal",
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: Colors.grey[600]),
                        ),
                        if (estimated != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timer, size: 18, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(
                                "Estimated: $estimated",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Карточка для смены плана
              SizedBox(
                width: 120,
                child: Card(
                  color: Colors.orange[100],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Переход по маршруту (убедись, что /nutritionPlan зарегистрирован в main.dart)
                      Navigator.pushNamed(context, '/nutritionPlan');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.settings, color: Colors.orange, size: 28),
                          SizedBox(height: 10),
                          Text(
                            "Change\nPlan",
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget macroCircle({
    required String label,
    required double value,
    required double goal,
  }) {
    final pct = value / goal;
    final pctInt = (pct * 100).round();

    Color pctColor;
    if (pct >= 1.0)
      pctColor = Colors.red;
    else if (pct >= 0.8)
      pctColor = Colors.green;
    else if (pct >= 0.4)
      pctColor = Colors.orange;
    else
      pctColor = Colors.yellow[700]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black),
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            CircularPercentIndicator(
              radius: 42,
              lineWidth: 7,
              percent: pct > 1 ? 1 : pct,
              backgroundColor: Colors.grey.shade300,
              progressColor: pctColor,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
            Text(
              '$pctInt %',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: pctColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${value.toStringAsFixed(1)} г',
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
        ),
        Text(
          '${goal.toStringAsFixed(1)} г',
          style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Colors.grey.shade400),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newMeal = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => const AddMealDialog(),
          );
          if (newMeal != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_uid)
                .collection('nutrition')
                .doc(_dateId)
                .collection('meals')
                .add(newMeal);
            await _recalculateSummary();
            _loadDay();
          }
        },
        backgroundColor: Colors.orange[100],
        child: const Icon(Icons.add, color: Colors.black87),
        elevation: 3,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          _buildTopHeader(),
          buildPlanInfoCards(),
          // Макро-кольца
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                macroCircle(
                  label: 'Protein',
                  value: _protein,
                  goal: _plan?.proteinTarget ?? 1,
                ),
                macroCircle(
                  label: 'Carbs',
                  value: _carbs,
                  goal: _plan?.carbsTarget ?? 1,
                ),
                macroCircle(
                  label: 'Fat',
                  value: _fat,
                  goal: _plan?.fatTarget ?? 1,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Meals",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ..._meals.map((meal) => Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu,
                  color: Colors.orange),
              title: Text(meal['name']),
              subtitle: Text(
                  '${meal['calories']} kcal • P:${meal['protein']} F:${meal['fat']} C:${meal['carbs']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteMeal(meal['id']),
              ),
            ),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('nutrition')
        .doc(_dateId)
        .collection('meals')
        .doc(id)
        .delete();
    await _recalculateSummary();
    _loadDay();
  }

  Future<void> _recalculateSummary() async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('nutrition')
        .doc(_dateId);
    final mealsSnap = await ref.collection('meals').get();

    num kcal = 0;
    double p = 0, f = 0, c = 0;
    for (var doc in mealsSnap.docs) {
      final d = doc.data();
      kcal += d['calories'] ?? 0;
      p += (d['protein'] ?? 0).toDouble();
      f += (d['fat'] ?? 0).toDouble();
      c += (d['carbs'] ?? 0).toDouble();
    }

    await ref.set({
      'caloriesIn': kcal.toInt(),
      'macros': {'protein': p, 'fat': f, 'carbs': c}
    }, SetOptions(merge: true));
  }
}
