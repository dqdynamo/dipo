import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

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

  late String _type;
  late List<String> _types;

  @override
  void initState() {
    super.initState();

    // Используй ключи для типа еды
    _types = [
      tr('breakfast'),
      tr('lunch'),
      tr('dinner'),
      tr('snack'),
    ];

    final m = widget.existing;
    if (m != null) {
      _nameCtrl.text = m.name;
      _calCtrl.text = m.calories.toString();
      _proCtrl.text = m.protein.toString();
      _carbCtrl.text = m.carbs.toString();
      _fatCtrl.text = m.fat.toString();
      _type = tr(m.type.toLowerCase()); // Преобразуй тип к локализованному значению
    } else {
      _type = _types[0];
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

    // Найти исходный (оригинальный) тип на английском (ключ)
    final typeIndex = _types.indexOf(_type);
    final typeKey = ['Breakfast', 'Lunch', 'Dinner', 'Snack'][typeIndex];

    final meal = Meal(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text,
      type: typeKey,
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
      appBar: AppBar(
        title: Text(widget.existing == null ? tr('add_meal') : tr('edit_meal')),
      ),
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
                decoration: InputDecoration(labelText: tr('meal_type')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: tr('meal_name')),
                validator: (v) => v == null || v.trim().isEmpty ? tr('enter_name') : null,
              ),
              const SizedBox(height: 12),
              _numberField(_calCtrl, tr('calories'), tr('enter_calories')),
              _numberField(_proCtrl, tr('protein'), tr('enter_protein')),
              _numberField(_carbCtrl, tr('carbs'), tr('enter_carbs')),
              _numberField(_fatCtrl, tr('fat'), tr('enter_fat')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMeal,
                child: Text(widget.existing == null ? tr('add_meal') : tr('save_changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label, String error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (v) => v == null || int.tryParse(v) == null ? error : null,
      ),
    );
  }
}

class AddMealDialog extends StatefulWidget {
  const AddMealDialog({super.key});
  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  late String _type;
  late List<String> _types;

  @override
  void initState() {
    super.initState();
    _types = [
      tr('breakfast'),
      tr('lunch'),
      tr('dinner'),
      tr('snack'),
    ];
    _type = _types[0];
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('add_meal')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
                decoration: InputDecoration(labelText: tr('meal_type')),
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: tr('meal_name')),
                validator: (v) => v == null || v.trim().isEmpty ? tr('enter_name') : null,
              ),
              TextFormField(
                controller: _calCtrl,
                decoration: InputDecoration(labelText: tr('calories')),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? tr('enter_calories') : null,
              ),
              TextFormField(
                controller: _proCtrl,
                decoration: InputDecoration(labelText: tr('protein')),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? tr('enter_protein') : null,
              ),
              TextFormField(
                controller: _carbCtrl,
                decoration: InputDecoration(labelText: tr('carbs')),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? tr('enter_carbs') : null,
              ),
              TextFormField(
                controller: _fatCtrl,
                decoration: InputDecoration(labelText: tr('fat')),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? tr('enter_fat') : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final typeIndex = _types.indexOf(_type);
              final typeKey = ['Breakfast', 'Lunch', 'Dinner', 'Snack'][typeIndex];

              Navigator.pop<Map<String, dynamic>>(context, {
                'name': _nameCtrl.text,
                'type': typeKey,
                'calories': int.tryParse(_calCtrl.text) ?? 0,
                'protein': int.tryParse(_proCtrl.text) ?? 0,
                'carbs': int.tryParse(_carbCtrl.text) ?? 0,
                'fat': int.tryParse(_fatCtrl.text) ?? 0,
              });
            }
          },
          child: Text(tr('add')),
        ),
      ],
    );
  }
}
