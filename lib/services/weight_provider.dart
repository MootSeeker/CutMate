import 'package:flutter/foundation.dart';
import 'package:cutmate/models/weight_entry.dart';
import 'package:cutmate/services/storage_service.dart';

/// Provider class for weight entry data
class WeightProvider extends ChangeNotifier {
  List<WeightEntry> _entries = [];
  
  /// All weight entries
  List<WeightEntry> get entries => _entries;
  
  /// The most recent weight entry
  WeightEntry? get latestEntry {
    if (_entries.isNotEmpty) {
      return _entries.first;
    }
    return null;
  }
  
  /// Initialize the provider with data from storage
  Future<void> initialize() async {
    _entries = await StorageService.loadWeightEntries();
    notifyListeners();
  }
  
  /// Add a new weight entry
  Future<void> addEntry(WeightEntry entry) async {
    await StorageService.addWeightEntry(entry);
    _entries = await StorageService.loadWeightEntries();
    notifyListeners();
  }
  
  /// Calculate weight change since beginning
  double? get totalWeightChange {
    if (_entries.length < 2) {
      return null;
    }
    
    // Get earliest and latest entries
    final latest = _entries.first;
    final earliest = _entries.last;
    
    return latest.weightKg - earliest.weightKg;
  }
  
  /// Calculate weight change in the last 30 days
  double? get last30DaysChange {
    if (_entries.isEmpty) {
      return null;
    }
    
    final latestWeight = _entries.first.weightKg;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    // Find the entry closest to 30 days ago
    WeightEntry? oldestInRange;
    for (final entry in _entries) {
      if (entry.date.isAfter(thirtyDaysAgo)) {
        oldestInRange = entry;
      } else {
        break;
      }
    }
    
    if (oldestInRange != null && oldestInRange != _entries.first) {
      return latestWeight - oldestInRange.weightKg;
    }
    return null;
  }
  
  /// Get the last 7 days of entries for the chart
  List<WeightEntry> get last7DaysEntries {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _entries.where((entry) => entry.date.isAfter(sevenDaysAgo)).toList();
  }
}
