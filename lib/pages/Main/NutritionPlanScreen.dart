import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/NutritionPlanService.dart';
import '../../services/goal_service.dart';
import '../../services/profile_service.dart';

class NutritionPlanScreen extends StatefulWidget {
  const NutritionPlanScreen({super.key});

  @override
  State<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  NutritionPlan? _plan;
  double? _goalWeight;
  double? _currentWeight;

  final _service = NutritionPlanService();
  final _goalService = GoalService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlan());
  }

  Future<void> _loadPlan() async {
    final profileService = context.read<ProfileService>();

    try {
      await profileService.load();
      final goals = await _goalService.loadGoals();
      final plan = await _service.generate(profileService, _goalService);

      setState(() {
        _plan = plan;
        _goalWeight = goals.weight;
        _currentWeight = profileService.profile?.weightKg;
      });
    } catch (e) {
      print('ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grad = const [Color(0xFFFF9240), Color(0xFFDD4733)];

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
          child: _plan == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Nutrition Plan',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _infoCard(),
              const SizedBox(height: 24),
              _goalCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    final bmi = _plan!.bmi;
    final bmiCategory = bmi < 18.5
        ? 'Underweight'
        : (bmi < 25 ? 'Normal' : (bmi < 30 ? 'Overweight' : 'Obese'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('BMR: ${_plan!.bmr.round()} kcal/day'),
            Text('TDEE: ${_plan!.tdee.round()} kcal/day'),
          ],
        ),
      ),
    );
  }

  Widget _goalCard() {
    final goalName = _plan!.goalType == NutritionGoalType.lose
        ? 'Lose Weight'
        : _plan!.goalType == NutritionGoalType.gain
        ? 'Gain Weight'
        : 'Maintain Weight';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal: $goalName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_currentWeight != null && _goalWeight != null)
              Text(
                'Current: ${_currentWeight!.toStringAsFixed(1)} kg → Goal: ${_goalWeight!.toStringAsFixed(1)} kg',
              ),
            const SizedBox(height: 8),
            Text(
              'Calorie Target: ${_plan!.calorieTarget} kcal/day',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}