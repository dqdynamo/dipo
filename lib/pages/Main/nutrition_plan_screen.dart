import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/goal_service.dart';
import '../../services/nutrition_plan_service.dart';
import '../../services/profile_service.dart';

class NutritionPlanScreen extends StatefulWidget {
  const NutritionPlanScreen({super.key});

  @override
  State<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  int _step = 0;
  NutritionPlan? _plan;
  double? _goalWeight;
  double? _currentWeight;
  NutritionGoalType? _selectedGoal;

  final _planService = NutritionPlanService();
  final _goalService = GoalService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final profile = context.read<ProfileService>();
    await profile.load();
    final goals = await _goalService.loadGoals();
    setState(() {
      _goalWeight = goals.weight;
      _currentWeight = profile.profile?.weightKg;
    });
  }

  Future<void> _calculateBMIAndPlan() async {
    final profile = context.read<ProfileService>();
    final plan = await _planService.generate(profile, _goalService);
    setState(() {
      _plan = plan;
      _selectedGoal = plan.goalType;
      _step = 1;
    });
  }

  Future<void> _saveFinalPlan() async {
    final profile = context.read<ProfileService>();
    final plan = await _planService.generate(profile, _goalService, override: _selectedGoal);
    setState(() {
      _plan = plan;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grad = const [Color(0xFFFF9240), Color(0xFFDD4733)];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _introStep();
      case 1:
        return _bmiResultStep();
      case 2:
        return _planSelectionStep();
      case 3:
        return _confirmationStep();
      default:
        return const Center(child: Text('Ошибка состояния'));
    }
  }

  Widget _introStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome to Nutrition Setup',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _card([
          const Text(
            'What is BMI?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'BMI (Body Mass Index) is a measure based on your height and weight. '
                'It helps us determine whether your weight is within a healthy range.',
          ),
        ]),
        const Spacer(),
        _button('Calculate My BMI', _calculateBMIAndPlan),
      ],
    );
  }

  Widget _bmiResultStep() {
    final bmi = _plan!.bmi;
    final bmiCategory = bmi < 18.5
        ? 'Underweight'
        : (bmi < 25 ? 'Normal' : (bmi < 30 ? 'Overweight' : 'Obese'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your BMI Result',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _card([
          Text('BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('BMR: ${_plan!.bmr.round()} kcal/day'),
          Text('TDEE: ${_plan!.tdee.round()} kcal/day'),
        ]),
        const Spacer(),
        _button('Choose Goal Plan', () => setState(() => _step = 2)),
      ],
    );
  }

  Widget _planSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Your Goal',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _card([
          RadioListTile<NutritionGoalType>(
            value: NutritionGoalType.maintain,
            groupValue: _selectedGoal,
            onChanged: (v) => setState(() => _selectedGoal = v),
            title: const Text('⚖️ Maintain weight'),
          ),
          RadioListTile<NutritionGoalType>(
            value: NutritionGoalType.lose,
            groupValue: _selectedGoal,
            onChanged: (v) => setState(() => _selectedGoal = v),
            title: const Text('🔻 Lose weight'),
          ),
          RadioListTile<NutritionGoalType>(
            value: NutritionGoalType.gain,
            groupValue: _selectedGoal,
            onChanged: (v) => setState(() => _selectedGoal = v),
            title: const Text('🔺 Gain weight'),
          ),
        ]),
        const Spacer(),
        _button('Apply Plan', _saveFinalPlan),
      ],
    );
  }

  Widget _confirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Plan Saved!',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _card([
          Text('🎯 Calorie Target: ${_plan!.calorieTarget} kcal/day',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (_currentWeight != null && _goalWeight != null)
            Text(
              'Current: ${_currentWeight!.toStringAsFixed(1)} kg → Goal: ${_goalWeight!.toStringAsFixed(1)} kg',
            ),
        ]),
        const Spacer(),
        _button('Finish', () => Navigator.pop(context)),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}
