class FoodAnalysis {
  final String foodStatus;
  final List<String> detectedFoods;
  final Map<String, Map<String, dynamic>> nutrition;
  

  FoodAnalysis({
    required this.foodStatus,
    required this.detectedFoods,
    required this.nutrition,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      foodStatus: json['food_status'],
      detectedFoods: List<String>.from(json['detected_foods']),
      nutrition: (json['nutrition'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          Map<String, dynamic>.from(value),
        ),
      ),
    );
  }
}

class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final Map<String, double> additionalNutrients;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.additionalNutrients,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, double> additionalNutrients = {};

    // Parse main nutrients
    final calories = _parseDouble(json['calories']);
    final protein = _parseDouble(json['protein']);
    final carbs = _parseDouble(json['carbs']);
    final fat = _parseDouble(json['fat']);

    // Parse any additional nutrients
    json.forEach((key, value) {
      if (!['calories', 'protein', 'carbs', 'fat'].contains(key)) {
        if (value is num) {
          additionalNutrients[key] = value.toDouble();
        }
      }
    });

    return NutritionInfo(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      additionalNutrients: additionalNutrients,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
