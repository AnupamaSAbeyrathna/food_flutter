import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food_analysis.dart';

class FoodAnalysisResults extends StatefulWidget {
  final FoodAnalysis result;

  const FoodAnalysisResults({super.key, required this.result});

  @override
  State<FoodAnalysisResults> createState() => _FoodAnalysisResultsState();
}

class _FoodAnalysisResultsState extends State<FoodAnalysisResults>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            _buildSuccessHeader(),
            const SizedBox(height: 20),
            
            // Detected Foods Card
            _buildDetectedFoodsCard(),
            const SizedBox(height: 20),
            
            // Nutrition Information
            _buildNutritionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Complete!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your food has been successfully analyzed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedFoodsCard() {
    final uniqueFoods = widget.result.detectedFoods.toSet().toList();
    
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.scanLine,
                  color: Color(0xFF667eea),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detected Foods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: uniqueFoods.map((food) => _buildFoodTag(food)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTag(String food) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFoodDetails(food);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667eea).withOpacity(0.8),
              const Color(0xFF764ba2).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.utensils,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _capitalize(food),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFf093fb).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.testTube,
                  color: Color(0xFFf093fb),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nutrition Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.result.nutrition.entries.map((entry) {
            return _buildFoodNutritionSection(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFoodNutritionSection(String food, Map<String, dynamic> nutrients) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.utensils,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _capitalize(food),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildNutritionGrid(nutrients),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(Map<String, dynamic> nutrients) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: nutrients.entries.map((entry) {
        final icon = _getNutrientIcon(entry.key);
        final color = _getNutrientColor(entry.key);
        final valueWithUnit = _formatNutrient(entry.key, entry.value);
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showNutrientInfo(entry.key);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  _capitalize(entry.key),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  valueWithUnit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 10),
            blurRadius: 30,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            offset: const Offset(0, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  void _showFoodDetails(String food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.utensils, color: Color(0xFF667eea)),
            const SizedBox(width: 10),
            Text(_capitalize(food)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected food item: ${_capitalize(food)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'This food was identified through AI image analysis.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNutrientInfo(String nutrient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getNutrientIcon(nutrient), color: _getNutrientColor(nutrient)),
            const SizedBox(width: 10),
            Text(_capitalize(nutrient)),
          ],
        ),
        content: Text(
          _getNutrientDescription(nutrient),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getNutrientIcon(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'calories':
        return LucideIcons.flame;
      case 'fat':
        return LucideIcons.droplet;
      case 'protein':
        return LucideIcons.dumbbell;
      case 'carbohydrates':
        return LucideIcons.pizza;
      case 'fiber':
        return LucideIcons.leaf;
      case 'sugar':
        return LucideIcons.candy;
      case 'sodium':
        return LucideIcons.circle;
      case 'cholesterol':
        return LucideIcons.heartPulse;
      case 'weight_grams':
        return LucideIcons.scale;
      default:
        return LucideIcons.circle;
    }
  }

  Color _getNutrientColor(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'calories':
        return const Color(0xFFEF4444);
      case 'fat':
        return const Color(0xFFF59E0B);
      case 'protein':
        return const Color(0xFF8B5CF6);
      case 'carbohydrates':
        return const Color(0xFF3B82F6);
      case 'fiber':
        return const Color(0xFF10B981);
      case 'sugar':
        return const Color(0xFFEC4899);
      case 'sodium':
        return const Color(0xFF6B7280);
      case 'cholesterol':
        return const Color(0xFFDC2626);
      case 'weight_grams':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
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

  String _getNutrientDescription(String key) {
    switch (key.toLowerCase()) {
      case 'calories':
        return 'Energy from food measured in kilocalories. Provides fuel for your body\'s daily activities and metabolic processes.';
      case 'fat':
        return 'Essential macronutrient that provides energy, supports cell growth, and helps absorb vitamins. Include healthy fats in moderation.';
      case 'protein':
        return 'Building blocks for muscles, bones, skin, and blood. Essential for growth, repair, and maintaining body tissues.';
      case 'carbohydrates':
        return 'Primary source of energy for your body and brain. Choose complex carbs for sustained energy and better nutrition.';
      case 'fiber':
        return 'Indigestible plant material that aids digestion, helps control blood sugar, and may reduce cholesterol levels.';
      case 'sugar':
        return 'Simple carbohydrates that provide quick energy. Limit added sugars and choose natural sources like fruits.';
      case 'cholesterol':
        return 'Waxy substance found in animal products. Your body needs some cholesterol, but too much can increase heart disease risk.';
      case 'sodium':
        return 'Essential mineral that helps regulate fluid balance. Excessive intake may contribute to high blood pressure.';
      case 'weight_grams':
        return 'Total weight of the food portion analyzed. Helps determine serving size and portion control.';
      default:
        return 'Important nutrient that contributes to your overall health and well-being.';
    }
  }
}