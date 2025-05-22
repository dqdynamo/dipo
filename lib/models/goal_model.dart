class GoalModel {
  final int steps;
  final double sleepHours;
  final double weight;

  GoalModel({
    required this.steps,
    required this.sleepHours,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'sleepHours': sleepHours,
      'weight': weight,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      steps: map['steps'] ?? 10000,
      sleepHours: (map['sleepHours'] ?? 8).toDouble(),
      weight: (map['weight'] ?? 60).toDouble(),
    );
  }
}
