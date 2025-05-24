import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool _showBmrInfo = false;
  bool _showBmiInfo = false;

  final _planService = NutritionPlanService();
  final _goalService = GoalService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<double?> _confirmGoalCorrection({
    required String message,
    required double currentWeight,
    required bool shouldBeLess,
  }) async {
    final controller = TextEditingController();
    String? error;

    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Adjust Weight Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'New Goal Weight (kg)',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value == null) {
                    setState(() => error = 'Enter a valid number');
                    return;
                  }
                  if (shouldBeLess && value >= currentWeight) {
                    setState(() => error = 'Must be less than current weight');
                    return;
                  }
                  if (!shouldBeLess && value <= currentWeight) {
                    setState(() => error = 'Must be more than current weight');
                    return;
                  }
                  Navigator.pop(context, value);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
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
    final currentWeight = profile.profile?.weightKg;
    double goalWeight = _goalWeight ?? currentWeight!;

    if (_selectedGoal == NutritionGoalType.lose && goalWeight >= currentWeight!) {
      final confirm = await _confirmGoalCorrection(
        message: 'To lose weight, goal must be less than current weight.',
        currentWeight: currentWeight,
        shouldBeLess: true,
      );
      if (confirm == null) return;
      goalWeight = confirm;
    }


    if (_selectedGoal == NutritionGoalType.gain && goalWeight <= currentWeight!) {
    final confirm = await _confirmGoalCorrection(
    message: 'To gain weight, goal must be more than current weight.',
    currentWeight: currentWeight,
    shouldBeLess: false,
    );
    if (confirm == null) return;
    goalWeight = confirm;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('goals')
        .doc('main')
        .set({'weight': goalWeight}, SetOptions(merge: true));

    final plan = await _planService.generate(
      profile,
      _goalService,
      override: _selectedGoal,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan Saved!')),
    );

    Navigator.pushReplacementNamed(context, '/nutrition');
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
      default:
        return const Center(child: Text('Invalid state'));
    }
  }

  Widget _introStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Nutrition Setup',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _card([
                  const Text('What is BMI?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'BMI (Body Mass Index) is a number calculated from your height and weight. '
                        'It helps us determine whether your weight is in a healthy range.',
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button('Calculate My BMI', _calculateBMIAndPlan),
      ],
    );
  }

  Widget _bmiResultStep() {
    final bmi = _plan!.bmi;
    final bmiCategory =
    bmi < 18.5 ? 'Underweight' : (bmi < 25 ? 'Normal' : (bmi < 30 ? 'Overweight' : 'Obese'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your BMI Result',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _card([
                  Text('BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('BMR: ${_plan!.bmr.round()} kcal/day'),
                  Text('TDEE: ${_plan!.tdee.round()} kcal/day'),
                ]),
                const SizedBox(height: 16),
                _accordionCard(
                  title: 'What is BMR and TDEE?',
                  expanded: _showBmrInfo,
                  onTap: () => setState(() => _showBmrInfo = !_showBmrInfo),
                  content: const Text(
                    '• BMR (Basal Metabolic Rate) is the number of calories your body needs at rest.\n\n'
                        '• TDEE (Total Daily Energy Expenditure) includes your activity and shows the total calories you burn daily.\n\n'
                        'We use TDEE to calculate how much you should eat for your chosen goal.',
                  ),
                ),
                const SizedBox(height: 12),
                _accordionCard(
                  title: 'BMI Categories by Gender',
                  expanded: _showBmiInfo,
                  onTap: () => setState(() => _showBmiInfo = !_showBmiInfo),
                  content: const Text(
                    '📊 Male:\n'
                        ' - <18.5: Underweight\n'
                        ' - 18.5–24.9: Normal\n'
                        ' - 25–29.9: Overweight\n'
                        ' - 30+: Obese\n\n'
                        '📊 Female:\n'
                        ' - <18.0: Underweight\n'
                        ' - 18.0–24.4: Normal\n'
                        ' - 24.5–29.9: Overweight\n'
                        ' - 30+: Obese\n\n'
                        'Note: BMI is only an estimate and doesn’t consider muscle mass or body composition.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button('Choose Goal Plan', () => setState(() => _step = 2)),
      ],
    );
  }

  Widget _planSelectionStep() {
    final recommendation = _plan!.goalType;
    final reason = recommendation == NutritionGoalType.lose
        ? 'Your BMI indicates excess weight. We recommend a weight loss plan.'
        : recommendation == NutritionGoalType.gain
        ? 'Your BMI indicates underweight. We recommend a weight gain plan.'
        : 'Your weight is within a normal range. We recommend maintaining it.';

    final icon = recommendation == NutritionGoalType.lose
        ? '🔻'
        : recommendation == NutritionGoalType.gain
        ? '🔺'
        : '⚖️';

    final title = recommendation == NutritionGoalType.lose
        ? 'Lose Weight'
        : recommendation == NutritionGoalType.gain
        ? 'Gain Weight'
        : 'Maintain Weight';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Goal',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
                const SizedBox(height: 16),
                _card([
                  Text('$icon Recommended Plan: $title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(reason),
                ], color: Colors.green.shade50),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button('Apply Plan', _saveFinalPlan),
      ],
    );
  }

  Widget _confirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plan Saved!',
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _card([
                  Text('🎯 Calorie Target: ${_plan!.calorieTarget} kcal/day',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (_currentWeight != null && _goalWeight != null)
                    Text('Current: ${_currentWeight!.toStringAsFixed(1)} kg → Goal: ${_goalWeight!.toStringAsFixed(1)} kg'),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button('Finish', () => Navigator.pop(context)),
      ],
    );
  }

  Widget _card(List<Widget> children, {Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _accordionCard({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            if (expanded) const SizedBox(height: 10),
            if (expanded) content,
          ],
        ),
      ),
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
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
