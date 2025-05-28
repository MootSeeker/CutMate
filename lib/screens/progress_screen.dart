import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cutmate/models/weight_entry.dart';
import 'package:cutmate/services/weight_provider.dart';

/// Screen for displaying weight progress charts and stats
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing progress feature
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Consumer<WeightProvider>(
        builder: (context, weightProvider, child) {
          final entries = weightProvider.entries;
          
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No weight data yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Log your weight to see your progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight stats summary
                _buildStatsSummary(context, weightProvider),
                const SizedBox(height: 24),
                
                // Recent weight chart
                Text(
                  'Last 7 Days',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildWeightChart(context, weightProvider.last7DaysEntries),
                const SizedBox(height: 24),
                
                // Weight history list
                Text(
                  'Weight History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildWeightHistoryList(entries),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Build weight stats summary cards
  Widget _buildStatsSummary(BuildContext context, WeightProvider weightProvider) {
    final totalChange = weightProvider.totalWeightChange;
    final monthChange = weightProvider.last30DaysChange;
    
    return Row(
      children: [
        // Total change card
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Change',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalChange != null ? '${totalChange.toStringAsFixed(1)} kg' : '--',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,                      color: totalChange != null && totalChange < 0
                          ? const Color(0xFF10B981) // success color
                          : totalChange != null && totalChange > 0
                              ? const Color(0xFFF59E0B) // warning color
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // 30-day change card
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last 30 Days',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthChange != null ? '${monthChange.toStringAsFixed(1)} kg' : '--',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,                      color: monthChange != null && monthChange < 0
                          ? const Color(0xFF10B981) // success color
                          : monthChange != null && monthChange > 0
                              ? const Color(0xFFF59E0B) // warning color
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build weight chart for the last 7 days
  Widget _buildWeightChart(BuildContext context, List<WeightEntry> entries) {
    if (entries.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Not enough data for chart'),
      );
    }
    
    // Sort entries by date (oldest to newest)
    final sortedEntries = [...entries];
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));
    
    // Determine min and max values for the chart
    final weights = sortedEntries.map((e) => e.weightKg).toList();
    double minY = weights.reduce((a, b) => a < b ? a : b) - 1;
    double maxY = weights.reduce((a, b) => a > b ? a : b) + 1;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                    // Show day of week abbreviation
                    final date = sortedEntries[value.toInt()].date;
                    return Text(
                      DateFormat('E').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: sortedEntries.length - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                sortedEntries.length,
                (index) => FlSpot(
                  index.toDouble(),
                  sortedEntries[index].weightKg,
                ),
              ),
              isCurved: true,              color: const Color(0xFF2F80FF), // primary accent color
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2F80FF).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build list of weight history entries
  Widget _buildWeightHistoryList(List<WeightEntry> entries) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final formattedDate = DateFormat('MMM d, yyyy').format(entry.date);
        
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.monitor_weight),
            ),
            title: Text(
              '${entry.weightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(
                    entry.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              entry.source,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
