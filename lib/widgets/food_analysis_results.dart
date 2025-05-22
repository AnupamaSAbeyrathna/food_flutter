import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_analysis.dart';

class FoodAnalysisResults extends StatelessWidget {
  final FoodAnalysis result;

  const FoodAnalysisResults({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            icon: LucideIcons.flame,
            title: "Total This Meal",
            child: _buildNutritionSummary(result.totalThisMeal),
          ),
          _buildSectionCard(
            icon: LucideIcons.calendarDays,
            title: "Total Today",
            child: _buildNutritionSummary(result.totalToday),
          ),
          _buildSectionCard(
            icon: LucideIcons.utensils,
            title: "Food Status",
            child: _infoTile("Status", result.foodStatus.toUpperCase()),
          ),
          _buildSectionCard(
            icon: LucideIcons.scanLine,
            title: "Detected Foods",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  result.detectedFoods
                      .toSet()
                      .toList()
                      .map<Widget>((food) => _infoTile("•", _capitalize(food)))
                      .toList(),
            ),
          ),
          _buildSectionCard(
            icon: LucideIcons.testTube,
            title: "Nutrition Info",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  result.nutrition.entries.map((entry) {
                    final food = entry.key;
                    final nutrients = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalize(food),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNutritionChips(nutrients),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text("$label $value", style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildNutritionChips(Map<String, dynamic> nutrients) {
    final icons = _icons;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children:
          nutrients.entries.map((entry) {
            final icon = icons[entry.key] ?? LucideIcons.circle;
            final valueWithUnit = _formatNutrient(entry.key, entry.value);
            return Tooltip(
              message: _nutrientDescription(entry.key),
              child: _nutrientTile(entry.key, valueWithUnit, icon),
            );
          }).toList(),
    );
  }

  Widget _nutrientTile(String name, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            _capitalize(name),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(Map<String, dynamic> totals) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          totals.entries.map((entry) {
            final icon = _icons[entry.key] ?? LucideIcons.circle;
            final valueWithUnit = _formatNutrient(entry.key, entry.value);
            return Tooltip(
              message: _nutrientDescription(entry.key),
              child: Chip(
                avatar: Icon(icon, size: 18),
                label: Text("${_capitalize(entry.key)}: $valueWithUnit"),
              ),
            );
          }).toList(),
    );
  }

  String _capitalize(String input) =>
      input.isEmpty
          ? input
          : input[0].toUpperCase() + input.substring(1).replaceAll('_', ' ');

  String _formatNutrient(String key, dynamic value) {
    if (key == 'calories') return "$value kcal";
    if (['fat', 'protein', 'carbohydrates', 'fiber', 'sugar'].contains(key))
      return "$value g";
    if (['cholesterol', 'sodium'].contains(key)) return "$value mg";
    if (key == 'weight_grams') return "$value g";
    return value.toString();
  }

  String _nutrientDescription(String key) {
    switch (key) {
      case 'calories':
        return 'Energy from food (kilocalories)';
      case 'fat':
        return 'Total fat in grams';
      case 'protein':
        return 'Protein amount in grams';
      case 'carbohydrates':
        return 'Total carbs in grams';
      case 'fiber':
        return 'Dietary fiber in grams';
      case 'sugar':
        return 'Sugars in grams';
      case 'cholesterol':
        return 'Cholesterol in milligrams';
      case 'sodium':
        return 'Sodium in milligrams';
      case 'weight_grams':
        return 'Total weight in grams';
      default:
        return 'Nutrient information';
    }
  }

  Map<String, IconData> get _icons => {
    'calories': LucideIcons.flame,
    'fat': LucideIcons.droplet,
    'protein': LucideIcons.dumbbell,
    'carbohydrates': LucideIcons.pizza,
    'fiber': LucideIcons.leaf,
    'sugar': LucideIcons.candy,
    'sodium': LucideIcons.circle,
    'cholesterol': LucideIcons.heartPulse,
    'weight_grams': LucideIcons.scale,
  };
}
