import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'activity_level_screen.dart';

class HeightWeightScreen extends StatefulWidget {
  final String gender;
  final DateTime dob;

  const HeightWeightScreen({
    super.key,
    required this.gender,
    required this.dob,
  });

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  // Units
  String heightUnit = 'cm';
  String weightUnit = 'kg';

  // Height
  double? heightCm;
  int? heightFeet;
  int? heightInches;

  // Weight
  double? weight;

  bool get _isFormComplete {
    if (weight == null) return false;
    if (heightUnit == 'cm') {
      return heightCm != null;
    } else {
      return heightFeet != null && heightInches != null;
    }
  }

  void _goToNext() {
    if (!_isFormComplete) return;

    double finalHeightCm;
    double finalWeightKg;

    // Convert height to cm
    if (heightUnit == 'cm') {
      finalHeightCm = heightCm!;
    } else {
      finalHeightCm = (heightFeet! * 30.48) + (heightInches! * 2.54);
    }

    // Convert weight to kg
    if (weightUnit == 'kg') {
      finalWeightKg = weight!;
    } else {
      finalWeightKg = weight! * 0.453592;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ActivityLevelScreen(
              gender: widget.gender,
              dob: widget.dob,
              weightKg: finalWeightKg,
              heightCm: finalHeightCm,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Body Stats")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Height",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ToggleButtons(
                  isSelected: [heightUnit == 'cm', heightUnit == 'ft'],
                  onPressed: (index) {
                    setState(() {
                      heightUnit = index == 0 ? 'cm' : 'ft';
                      heightCm = null;
                      heightFeet = null;
                      heightInches = null;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("cm"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("ft/in"),
                    ),
                  ],
                  color: Colors.white,
                  selectedColor: Colors.red,
                  fillColor: Colors.grey.shade800,
                  borderColor: Colors.grey.shade600,
                  selectedBorderColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (heightUnit == 'cm')
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Height (cm)",
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged:
                    (value) => setState(() {
                      heightCm = double.tryParse(value);
                    }),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Feet",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged:
                          (value) => setState(() {
                            heightFeet = int.tryParse(value);
                          }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Inches",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged:
                          (value) => setState(() {
                            heightInches = int.tryParse(value);
                          }),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            const Text(
              "Weight",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ToggleButtons(
                  isSelected: [weightUnit == 'kg', weightUnit == 'lbs'],
                  onPressed: (index) {
                    setState(() {
                      weightUnit = index == 0 ? 'kg' : 'lbs';
                      weight = null;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("kg"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("lbs"),
                    ),
                  ],
                  color: Colors.white,
                  selectedColor: Colors.red,
                  fillColor: Colors.grey.shade800,
                  borderColor: Colors.grey.shade600,
                  selectedBorderColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Weight ($weightUnit)",
                labelStyle: const TextStyle(color: Colors.white),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged:
                  (value) => setState(() {
                    weight = double.tryParse(value);
                  }),
            ),
            const Spacer(),
            CustomButton(
              label: "Next",
              onPressed: _isFormComplete ? _goToNext : () {},
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
