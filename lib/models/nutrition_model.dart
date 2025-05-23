class FoodItem {
  String name;
  String amount;
  int protein;
  int carbs;
  int fat;

  FoodItem({required this.name, required this.amount, required this.protein, required this.carbs, required this.fat});

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
    name: map['name'],
    amount: map['amount'],
    protein: map['protein'],
    carbs: map['carbs'],
    fat: map['fat'],
  );
}

class Meal {
  String type;
  int calories;
  List<FoodItem> foods;

  Meal({required this.type, required this.calories, required this.foods});

  Map<String, dynamic> toMap() => {
    'type': type,
    'calories': calories,
    'foods': foods.map((f) => f.toMap()).toList(),
  };

  factory Meal.fromMap(Map<String, dynamic> map) => Meal(
    type: map['type'],
    calories: map['calories'],
    foods: (map['foods'] as List).map((f) => FoodItem.fromMap(f)).toList(),
  );
}
