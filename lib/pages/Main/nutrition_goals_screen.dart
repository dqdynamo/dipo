import 'package:flutter/material.dart';
import '../../services/nutrition_service.dart';

class NutritionGoalsScreen extends StatefulWidget {
  const NutritionGoalsScreen({super.key});

  @override
  State<NutritionGoalsScreen> createState() => _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends State<NutritionGoalsScreen> {
  final _service = NutritionService();
  final _cal = TextEditingController();
  final _pro = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await _service.getGoals();
    _cal.text = g['calories'].toString();
    _pro.text = g['protein'].toString();
    _carb.text = g['carbs'].toString();
    _fat.text = g['fat'].toString();
  }

  Future<void> _save() async {
    await _service.setGoals({
      'calories': int.parse(_cal.text),
      'protein': int.parse(_pro.text),
      'carbs': int.parse(_carb.text),
      'fat': int.parse(_fat.text),
    });
    Navigator.pop(context);
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
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('Nutrition Goals',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Column(
                    children: [
                      _field(_cal, 'Calories'),
                      _field(_pro, 'Protein (g)'),
                      _field(_carb, 'Carbs (g)'),
                      _field(_fat, 'Fat (g)'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: grad[1],
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
