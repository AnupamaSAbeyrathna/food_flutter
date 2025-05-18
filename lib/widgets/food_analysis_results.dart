import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // For nice icons
import '../models/food_analysis.dart';

class FoodAnalysisResults extends StatelessWidget {
  final FoodAnalysis result;

  const FoodAnalysisResults({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("🍽️ Food Status"),
        _infoTile("Status", result.foodStatus.toUpperCase()),

        _sectionTitle("🔍 Detected Foods"),
        for (var food in result.detectedFoods)
          _infoTile("•", _capitalize(food)),

        const SizedBox(height: 16),

        _sectionTitle("🧪 Nutrition Info"),
        for (var food in result.nutrition.keys)
          _buildNutritionCard(food, result.nutrition[food]!),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text("$label $value", style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildNutritionCard(String food, Map<String, dynamic> nutrients) {
    final icons = {
      'calories': LucideIcons.flame,
      'fat': LucideIcons.droplet,
      'protein': LucideIcons.dumbbell,
      'carbohydrates': LucideIcons.pizza,
      'fiber': LucideIcons.leaf,
      'sugar': LucideIcons.candy,
      'sodium': LucideIcons.circle,
      'cholesterol': LucideIcons.heartPulse,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalize(food),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: nutrients.entries.map((entry) {
                final icon = icons[entry.key] ?? LucideIcons.circle;
                final valueWithUnit = _formatNutrient(entry.key, entry.value);
                return _nutrientTile(entry.key, valueWithUnit, icon);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientTile(String name, String value, IconData icon) {
    return Chip(
      label: Text(
        "${_capitalize(name)}: $value",
        style: const TextStyle(fontSize: 14),
      ),
      avatar: Icon(icon, size: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  String _capitalize(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1).replaceAll('_', ' ');

  String _formatNutrient(String key, dynamic value) {
    if (key == 'calories') return "$value kcal";
    if (['fat', 'protein', 'carbohydrates', 'fiber', 'sugar'].contains(key)) return "$value g";
    if (['cholesterol', 'sodium'].contains(key)) return "$value mg";
    if (key == 'weight_grams') return "$value g";
    return value.toString();
  }
}
