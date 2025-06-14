import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/models/weight_entry.dart';
import 'package:cutmate/services/weight_provider.dart';
import 'package:cutmate/services/settings_provider.dart';

/// Screen for entering weight data
class WeightEntryScreen extends StatefulWidget {
  const WeightEntryScreen({super.key});

  @override
  State<WeightEntryScreen> createState() => _WeightEntryScreenState();
}

class _WeightEntryScreenState extends State<WeightEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Get the entered weight and convert to kg if needed
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final enteredWeight = double.parse(_weightController.text);
      final weightInKg = settingsProvider.convertToStorageUnit(enteredWeight);
      
      // Create weight entry
      final entry = WeightEntry(
        date: _selectedDate,
        weightKg: weightInKg,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        source: 'manual',
      );
      
      // Save entry using the provider
      Provider.of<WeightProvider>(context, listen: false).addEntry(entry);
      
      // Return to previous screen
      Navigator.pop(context, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Weight'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Weight input
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, _) {
                  final unit = settingsProvider.weightUnitSuffix;
                  final minWeight = unit == 'kg' 
                    ? AppConstants.minWeightKg 
                    : SettingsProvider.kgToLbs(AppConstants.minWeightKg);
                  final maxWeight = unit == 'kg' 
                    ? AppConstants.maxWeightKg 
                    : SettingsProvider.kgToLbs(AppConstants.maxWeightKg);
                    
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight ($unit)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Enter your weight',
                          suffixText: unit,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          
                          final weight = double.tryParse(value);
                          if (weight == null) {
                            return 'Please enter a valid number';
                          }
                          
                          if (weight < minWeight || weight > maxWeight) {
                            return 'Weight must be between ${minWeight.toStringAsFixed(1)} ' 
                              'and ${maxWeight.toStringAsFixed(0)} $unit';
                          }
                          
                          return null;
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Notes input
              const Text(
                'Notes (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Add notes about this weigh-in',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save Weight'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
