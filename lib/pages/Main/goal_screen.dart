import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Добавь импорт!
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  double _steps = 10000;
  double _sleep = 8;
  double _weight = 60;
  final _goalService = GoalService();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final goals = await _goalService.loadGoals();
      setState(() {
        _steps = goals.steps.toDouble();
        _sleep = goals.sleepHours;
        _weight = goals.weight;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('goals_failed_load', namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _save() async {
    final goals = GoalModel(
      steps: _steps.round(),
      sleepHours: _sleep,
      weight: _weight,
    );
    await _goalService.saveGoals(goals);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9240),
        title: Text(tr("goals_title")),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _GoalSlider(
            label: tr('goals_steps_label'),
            value: _steps,
            unit: tr('goals_steps_unit'),
            min: 1000,
            max: 20000,
            step: 500,
            onChanged: (v) => setState(() => _steps = v),
          ),
          _GoalSlider(
            label: tr('goals_sleep_label'),
            value: _sleep,
            unit: tr('goals_sleep_unit'),
            min: 4,
            max: 12,
            step: 0.5,
            onChanged: (v) => setState(() => _sleep = v),
          ),
          _GoalSlider(
            label: tr('goals_weight_label'),
            value: _weight,
            unit: tr('goals_weight_unit'),
            min: 30,
            max: 150,
            step: 1,
            onChanged: (v) => setState(() => _weight = v),
          ),
        ],
      ),
    );
  }
}

class _GoalSlider extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min, max, step;
  final ValueChanged<double> onChanged;

  const _GoalSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final controller = TextEditingController(text: value.toStringAsFixed(0));
              final result = await showDialog<double>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr('goals_enter_value', namedArgs: {'label': label})),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: tr('goals_enter_hint'),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        final input = double.tryParse(controller.text);
                        if (input != null && input >= min && input <= max) {
                          Navigator.pop(context, input);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('goals_invalid_value'))),
                          );
                        }
                      },
                      child: Text(tr('ok')),
                    ),
                  ],
                ),
              );

              if (result != null) {
                onChanged(result);
              }
            },
            child: Text(
              '${value.toStringAsFixed(0)} $unit',
              style: const TextStyle(fontSize: 24, color: Color(0xFFFF9240)),
            ),
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            activeColor: const Color(0xFFFF9240),
          ),
        ],
      ),
    );
  }
}
