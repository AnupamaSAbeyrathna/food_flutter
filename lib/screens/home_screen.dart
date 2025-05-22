import 'package:flutter/material.dart';
import 'food_analysis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FoodAnalysisScreen()),
            );
          },
          child: const Text("Go to Food Analysis"),
        ),
      ),
    );
  }
}
