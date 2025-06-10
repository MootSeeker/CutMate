// filepath: c:\Entwicklung\Software\CutMate\lib\screens\home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart';
import 'package:cutmate/screens/weight_entry_screen.dart';
import 'package:cutmate/screens/main_screen.dart';
import 'package:cutmate/services/weight_provider.dart';
import 'package:cutmate/models/weight_entry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
    /// Build weight chart for the last 7 days
  static Widget _buildWeightChart(BuildContext context, List<WeightEntry> entries) {
    // If we don't have any entries or just one entry, show a message
    if (entries.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Log your weight to see progress', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (entries.length < 2) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Need more data points to show chart', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Sort entries by date (oldest to newest)
    final sortedEntries = [...entries];
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));
      // Determine min and max values for the chart
    final weights = sortedEntries.map((e) => e.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    // Calculate the range and ensure a minimum range of 2kg for visual clarity
    final range = maxWeight - minWeight;
    double minY, maxY;
    
    if (range < 2) {
      // If range is small, create a reasonable padding
      final midPoint = (minWeight + maxWeight) / 2;
      minY = midPoint - 1;
      maxY = midPoint + 1;
    } else {
      // Otherwise use the actual values with padding
      minY = minWeight - 0.5;
      maxY = maxWeight + 0.5;
    }
    
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8.0),      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  );
                },
                interval: 1,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                    // Show day of week abbreviation
                    final date = sortedEntries[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(date),
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: sortedEntries.length - 1,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final date = sortedEntries[flSpot.x.toInt()].date;
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n${flSpot.y.toStringAsFixed(1)} kg',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                sortedEntries.length,
                (index) => FlSpot(
                  index.toDouble(),
                  sortedEntries[index].weightKg,
                ),
              ),
              isCurved: true,
              color: const Color(0xFF2F80FF), // primary accent color
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF2F80FF),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2F80FF).withOpacity(0.15),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2F80FF).withOpacity(0.25),
                    const Color(0xFF2F80FF).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CutMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to CutMate',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI wingman for weight loss',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                
                // Weight tracking card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Weight',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [                            Consumer<WeightProvider>(
                              builder: (context, weightProvider, child) {
                                final latestEntry = weightProvider.latestEntry;                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      latestEntry != null
                                          ? '${latestEntry.weightKg.toStringAsFixed(1)} kg'
                                          : '-- kg',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (latestEntry != null)
                                      Text(
                                        'Updated ${DateFormat('MMM d').format(latestEntry.date)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to weight entry screen and refresh data when we return
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WeightEntryScreen(),
                                  ),
                                );
                              },
                              child: const Text('Update'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Meal recommendation card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meal Recommendation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Tap to get AI meal recommendations based on your goals',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to meal tab (index 1)
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(initialIndex: 1),
                                ),
                              );
                            },
                            child: const Text('Get Recommendations'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                  // Progress tracking card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress Tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),                        // Last 7 days weight chart title with trend
                        Row(
                          children: [
                            const Text(
                              'Last 7 Days',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Consumer<WeightProvider>(
                              builder: (context, weightProvider, child) {
                                final entries = weightProvider.last7DaysEntries;
                                if (entries.length >= 2) {
                                  final firstWeight = entries.last.weightKg;
                                  final latestWeight = entries.first.weightKg;
                                  final difference = latestWeight - firstWeight;
                                  
                                  return Row(
                                    children: [
                                      Icon(
                                        difference < 0 
                                            ? Icons.trending_down 
                                            : difference > 0 
                                                ? Icons.trending_up 
                                                : Icons.trending_flat,
                                        color: difference < 0 
                                            ? const Color(0xFF10B981) // success color
                                            : difference > 0 
                                                ? const Color(0xFFF59E0B) // warning color
                                                : Colors.grey,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${difference.abs().toStringAsFixed(1)} kg',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: difference < 0 
                                              ? const Color(0xFF10B981) // success color
                                              : difference > 0 
                                                  ? const Color(0xFFF59E0B) // warning color
                                                  : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Last 7 days weight chart
                        Consumer<WeightProvider>(
                          builder: (context, weightProvider, child) {
                            final entries = weightProvider.last7DaysEntries;
                            return _buildWeightChart(context, entries);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to progress tab - use index 2 (third tab)
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(initialIndex: 2),
                                ),
                              );
                            },
                            child: const Text('View Full Progress'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
