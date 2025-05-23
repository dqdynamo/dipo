import 'package:flutter/material.dart';
import '../../services/nutrition_service.dart';

class AddEditMealScreen extends StatefulWidget {
  final DateTime date;
  final Meal? existing;

  const AddEditMealScreen({super.key, required this.date, this.existing});

  @override
  State<AddEditMealScreen> createState() => _AddEditMealScreenState();
}

class _AddEditMealScreenState extends State<AddEditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = NutritionService();

  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String _type = 'Breakfast';

  final _types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    if (m != null) {
      _nameCtrl.text = m.name;
      _calCtrl.text = m.calories.toString();
      _proCtrl.text = m.protein.toString();
      _carbCtrl.text = m.carbs.toString();
      _fatCtrl.text = m.fat.toString();
      _type = m.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    final meal = Meal(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text,
      type: _type,
      calories: int.parse(_calCtrl.text),
      protein: int.parse(_proCtrl.text),
      carbs: int.parse(_carbCtrl.text),
      fat: int.parse(_fatCtrl.text),
    );

    if (widget.existing != null) {
      await _service.updateMeal(widget.date, widget.existing!.id, meal);
    } else {
      await _service.addMeal(widget.date, meal);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Meal' : 'Edit Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Meal Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              _numberField(_calCtrl, 'Calories'),
              _numberField(_proCtrl, 'Protein (g)'),
              _numberField(_carbCtrl, 'Carbs (g)'),
              _numberField(_fatCtrl, 'Fat (g)'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMeal,
                child: Text(widget.existing == null ? 'Add Meal' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid number' : null,
      ),
    );
  }
}