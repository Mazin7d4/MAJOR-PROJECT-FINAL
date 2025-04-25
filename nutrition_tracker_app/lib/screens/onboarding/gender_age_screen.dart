import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_button.dart';
import 'height_weight_screen.dart';

class GenderAgeScreen extends StatefulWidget {
  const GenderAgeScreen({super.key});

  @override
  State<GenderAgeScreen> createState() => _GenderAgeScreenState();
}

class _GenderAgeScreenState extends State<GenderAgeScreen> {
  String? _selectedGender;
  DateTime? _dob;

  int? get _calculatedAge {
    if (_dob == null) return null;
    final today = DateTime.now();
    int age = today.year - _dob!.year;
    if (today.month < _dob!.month ||
        (today.month == _dob!.month && today.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  void _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Colors.grey.shade800,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  void _goToNext() {
    if (_selectedGender != null && _dob != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  HeightWeightScreen(gender: _selectedGender!, dob: _dob!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personal Info")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Gender",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Male"),
                  selected: _selectedGender == 'male',
                  onSelected: (selected) {
                    setState(() {
                      _selectedGender = 'male';
                    });
                  },
                  backgroundColor: Colors.grey.shade800,
                  selectedColor: Colors.red,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Female"),
                  selected: _selectedGender == 'female',
                  onSelected: (selected) {
                    setState(() {
                      _selectedGender = 'female';
                    });
                  },
                  backgroundColor: Colors.grey.shade800,
                  selectedColor: Colors.red,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Date of Birth",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dob != null
                          ? DateFormat.yMMMd().format(_dob!)
                          : "Select your birth date",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            if (_calculatedAge != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "Age: $_calculatedAge years",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const Spacer(),
            CustomButton(
              label: "Next",
              onPressed:
                  (_selectedGender != null && _dob != null) ? _goToNext : () {},
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
