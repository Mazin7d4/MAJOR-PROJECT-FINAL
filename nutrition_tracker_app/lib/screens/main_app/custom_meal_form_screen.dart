import 'package:flutter/material.dart';
import 'detailed_nutrition_screen.dart';

class CustomMealFormScreen extends StatefulWidget {
  final String mealName;

  const CustomMealFormScreen({super.key, required this.mealName});

  @override
  State<CustomMealFormScreen> createState() => _CustomMealFormScreenState();
}

class _CustomMealFormScreenState extends State<CustomMealFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _kcalController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _proteinController = TextEditingController();

  void _saveCustomMeal() {
    if (_formKey.currentState!.validate()) {
      final food = {
        'name': _nameController.text.trim(),
        'brand': 'Custom Meal',
        'calories': double.tryParse(_kcalController.text) ?? 0.0,
        'carbs': double.tryParse(_carbsController.text) ?? 0.0,
        'fat': double.tryParse(_fatController.text) ?? 0.0,
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'quantity': double.tryParse(_sizeController.text) ?? 100.0,
        'source': 'custom',
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DetailedNutritionScreen(
            mealName: widget.mealName,
            food: food,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Custom Meal")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Icon(Icons.restaurant_menu, size: 64, color: Colors.red),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Meal Name",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: "Meal Size (g or ml)",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kcalController,
                decoration: const InputDecoration(
                  labelText: "Calories per 100g/ml",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(
                  labelText: "Carbs per 100g/ml",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(
                  labelText: "Fat per 100g/ml",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(
                  labelText: "Protein per 100g/ml",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveCustomMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save & Continue", style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
