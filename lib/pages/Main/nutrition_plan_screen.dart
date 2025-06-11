import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

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
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(tr('nutrition_goal_adjust_title'), style: TextStyle(color: theme.colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: TextStyle(color: theme.colorScheme.onSurface)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: tr('nutrition_goal_adjust_label'),
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('cancel')),
              ),
              TextButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value == null) {
                    setState(() => error = tr('nutrition_goal_adjust_error_number'));
                    return;
                  }
                  if (shouldBeLess && value >= currentWeight) {
                    setState(() => error = tr('nutrition_goal_adjust_error_less'));
                    return;
                  }
                  if (!shouldBeLess && value <= currentWeight) {
                    setState(() => error = tr('nutrition_goal_adjust_error_more'));
                    return;
                  }
                  Navigator.pop(context, value);
                },
                child: Text(tr('confirm')),
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

    if (_selectedGoal == NutritionGoalType.maintain) {
      goalWeight = currentWeight!;
    }

    if (_selectedGoal == NutritionGoalType.lose && goalWeight >= currentWeight!) {
      final confirm = await _confirmGoalCorrection(
        message: tr('nutrition_goal_must_be_less'),
        currentWeight: currentWeight,
        shouldBeLess: true,
      );
      if (confirm == null) return;
      goalWeight = confirm;
    }

    if (_selectedGoal == NutritionGoalType.gain && goalWeight <= currentWeight!) {
      final confirm = await _confirmGoalCorrection(
        message: tr('nutrition_goal_must_be_more'),
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
      SnackBar(content: Text(tr('nutrition_plan_saved'))),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(tr('nutrition_plan_title'), style: TextStyle(color: theme.colorScheme.onSurface)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.secondary.withOpacity(0.7), theme.colorScheme.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildStep(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _introStep(theme);
      case 1:
        return _bmiResultStep(theme);
      case 2:
        return _planSelectionStep(theme);
      default:
        return Center(child: Text(tr('nutrition_invalid_state')));
    }
  }

  Widget _introStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('nutrition_intro_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _card(theme, [
                  Text(tr('nutrition_intro_bmi_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(tr('nutrition_intro_bmi_desc')),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button(theme, tr('nutrition_btn_calculate_bmi'), _calculateBMIAndPlan),
      ],
    );
  }

  Widget _bmiResultStep(ThemeData theme) {
    final bmi = _plan!.bmi;
    final bmiCategory =
    bmi < 18.5 ? tr('nutrition_bmi_underweight') : (bmi < 25 ? tr('nutrition_bmi_normal') : (bmi < 30 ? tr('nutrition_bmi_overweight') : tr('nutrition_bmi_obese')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('nutrition_bmi_result_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _card(theme, [
                  Text('${tr('nutrition_bmi_label')}: ${bmi.toStringAsFixed(1)} ($bmiCategory)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${tr('nutrition_bmr_label')}: ${_plan!.bmr.round()} ${tr('nutrition_kcal_day')}'),
                  Text('${tr('nutrition_tdee_label')}: ${_plan!.tdee.round()} ${tr('nutrition_kcal_day')}'),
                ]),
                const SizedBox(height: 16),
                _accordionCard(
                  theme: theme,
                  title: tr('nutrition_bmr_tdee_title'),
                  expanded: _showBmrInfo,
                  onTap: () => setState(() => _showBmrInfo = !_showBmrInfo),
                  content: Text(tr('nutrition_bmr_tdee_desc')),
                ),
                const SizedBox(height: 12),
                _accordionCard(
                  theme: theme,
                  title: tr('nutrition_bmi_categories_title'),
                  expanded: _showBmiInfo,
                  onTap: () => setState(() => _showBmiInfo = !_showBmiInfo),
                  content: Text(tr('nutrition_bmi_categories_desc')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button(theme, tr('nutrition_btn_choose_goal'), () => setState(() => _step = 2)),
      ],
    );
  }

  Widget _planSelectionStep(ThemeData theme) {
    final recommendation = _plan!.goalType;
    final reason = recommendation == NutritionGoalType.lose
        ? tr('nutrition_goal_recommend_lose')
        : recommendation == NutritionGoalType.gain
        ? tr('nutrition_goal_recommend_gain')
        : tr('nutrition_goal_recommend_maintain');

    final icon = recommendation == NutritionGoalType.lose
        ? '🔻'
        : recommendation == NutritionGoalType.gain
        ? '🔺'
        : '⚖️';

    final title = recommendation == NutritionGoalType.lose
        ? tr('nutrition_goal_lose')
        : recommendation == NutritionGoalType.gain
        ? tr('nutrition_goal_gain')
        : tr('nutrition_goal_maintain');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('nutrition_choose_goal_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _card(theme, [
                  RadioListTile<NutritionGoalType>(
                    value: NutritionGoalType.maintain,
                    groupValue: _selectedGoal,
                    onChanged: (v) => setState(() => _selectedGoal = v),
                    title: Text('⚖️ ${tr('nutrition_goal_maintain')}'),
                    activeColor: theme.colorScheme.secondary,
                  ),
                  RadioListTile<NutritionGoalType>(
                    value: NutritionGoalType.lose,
                    groupValue: _selectedGoal,
                    onChanged: (v) => setState(() => _selectedGoal = v),
                    title: Text('🔻 ${tr('nutrition_goal_lose')}'),
                    activeColor: theme.colorScheme.secondary,
                  ),
                  RadioListTile<NutritionGoalType>(
                    value: NutritionGoalType.gain,
                    groupValue: _selectedGoal,
                    onChanged: (v) => setState(() => _selectedGoal = v),
                    title: Text('🔺 ${tr('nutrition_goal_gain')}'),
                    activeColor: theme.colorScheme.secondary,
                  ),
                ]),
                const SizedBox(height: 16),
                _card(theme, [
                  Text('$icon ${tr('nutrition_recommended_plan')}: $title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(reason),
                ], color: theme.colorScheme.secondaryContainer.withOpacity(0.2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _button(theme, tr('nutrition_btn_apply_plan'), _saveFinalPlan),
      ],
    );
  }

  Widget _card(ThemeData theme, List<Widget> children, {Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.85 : 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurface),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _accordionCard({
    required ThemeData theme,
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
          color: theme.colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.92 : 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: theme.iconTheme.color),
                ],
              ),
              if (expanded) const SizedBox(height: 10),
              if (expanded) content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(ThemeData theme, String label, VoidCallback onPressed) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? theme.colorScheme.secondary : theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 3,
        ),
        child: Text(label),
      ),
    );
  }
}
