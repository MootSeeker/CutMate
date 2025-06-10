import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cutmate/models/weight_entry.dart';
import 'package:cutmate/services/weight_provider.dart';
import 'package:cutmate/constants/app_constants.dart';

/// Screen for displaying weight progress charts and stats
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedTimePeriod = AppConstants.chartTimePeriods.first; // Default to first period (7 days)
  
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
                  // Recent weight chart with time period selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weight Trend',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _buildTimePeriodDropdown(),
                  ],
                ),
                const SizedBox(height: 8),
                _buildWeightChart(
                  context, 
                  weightProvider.getEntriesForPeriod(_selectedTimePeriod),
                ),
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
    final periodChange = weightProvider.getWeightChangeForPeriod(_selectedTimePeriod);
    
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
          // Period change card
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last $_selectedTimePeriod Days',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    periodChange != null ? '${periodChange.toStringAsFixed(1)} kg' : '--',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,                      color: periodChange != null && periodChange < 0
                          ? const Color(0xFF10B981) // success color
                          : periodChange != null && periodChange > 0
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
    /// Build selector for chart time period
  Widget _buildTimePeriodDropdown() {
    // Use segmented button on larger screens, dropdown on smaller screens
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 400) {
      // Use segmented button on larger screens
      return SegmentedButton<int>(
        segments: AppConstants.chartTimePeriods.map((days) {
          return ButtonSegment<int>(
            value: days,
            label: Text('$days d'),
          );
        }).toList(),
        selected: {_selectedTimePeriod},
        onSelectionChanged: (Set<int> selection) {
          if (selection.isNotEmpty) {
            setState(() {
              _selectedTimePeriod = selection.first;
            });
          }
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else {
      // Use dropdown on smaller screens
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedTimePeriod,
            isDense: true,
            items: AppConstants.chartTimePeriods.map((days) {
              String label;
              if (days == 7) {
                label = '7 Days';
              } else if (days == 30) {
                label = '30 Days';
              } else if (days == 60) {
                label = '60 Days';
              } else if (days == 90) {
                label = '90 Days';
              } else {
                label = '$days Days';
              }
              
              return DropdownMenuItem<int>(
                value: days,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTimePeriod = value;
                });
              }
            },
          ),
        ),
      );    }
  }
  
  /// Build weight chart for the selected time period
  Widget _buildWeightChart(BuildContext context, List<WeightEntry> entries) {
    if (entries.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Not enough data for selected period'),
      );
    }
    
    // Sort entries by date (oldest to newest)
    final sortedEntries = [...entries];
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));
    
    // Determine min and max values for the chart
    final weights = sortedEntries.map((e) => e.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    // Calculate the range and ensure a minimum range for visual clarity
    final range = maxWeight - minWeight;
    double minY, maxY;
    
    if (range < 2) {
      // If range is small, create a reasonable padding
      final midPoint = (minWeight + maxWeight) / 2;
      minY = midPoint - 1;
      maxY = midPoint + 1;
    } else {
      // Otherwise use the actual values with padding
      minY = minWeight - (range * 0.1); // 10% padding
      maxY = maxWeight + (range * 0.1); // 10% padding
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8.0),      child: LineChart(
        LineChartData(
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
            ),            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                    // Choose date format based on time period
                    final date = sortedEntries[value.toInt()].date;
                    String dateFormat;
                    
                    // Show fewer labels for longer time periods
                    int interval = sortedEntries.length ~/ 5; // aim for ~5 labels
                    if (interval < 1) interval = 1;
                    
                    if (value.toInt() % interval != 0 && 
                        value.toInt() != 0 && 
                        value.toInt() != sortedEntries.length - 1) {
                      return const SizedBox();
                    }
                    
                    // Choose format based on time period
                    if (_selectedTimePeriod <= 7) {
                      dateFormat = 'E'; // Day of week for short periods
                    } else if (_selectedTimePeriod <= 30) {
                      dateFormat = 'd MMM'; // Day and month for medium periods
                    } else {
                      dateFormat = 'MMM d'; // Month and day for longer periods
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        DateFormat(dateFormat).format(date),
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
          ),          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 0.8,
                dashArray: [5, 5],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 0.8,
              );
            },
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
                  
                  // Use different date format based on time period
                  String dateFormat;
                  if (_selectedTimePeriod <= 14) {
                    dateFormat = 'EEE, MMM d';
                  } else {
                    dateFormat = 'MMM d, yyyy';
                  }
                  
                  return LineTooltipItem(
                    '${DateFormat(dateFormat).format(date)}\n${flSpot.y.toStringAsFixed(1)} kg',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
            handleBuiltInTouches: true,
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
                color: const Color(0xFF2F80FF).withOpacity(0.2),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2F80FF).withOpacity(0.3),
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
  
  /// Build list of weight history entries
  Widget _buildWeightHistoryList(List<WeightEntry> entries) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {        final entry = entries[index];
        final formattedDate = DateFormat('MMM d, yyyy').format(entry.date);
          // Calculate weight change from previous entry
        double? change;
        String? changeText;
        if (index < entries.length - 1) {
          change = entry.weightKg - entries[index + 1].weightKg;
          // Only show non-zero changes
          if (change != 0) {
            changeText = change > 0 ? '+${change.toStringAsFixed(1)} kg' : '${change.toStringAsFixed(1)} kg';
          }
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.monitor_weight),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${entry.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),                if (changeText != null && change != null)
                  Text(
                    changeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: change < 0 
                          ? const Color(0xFF10B981) // success color
                          : change > 0 
                              ? const Color(0xFFF59E0B) // warning color
                              : Colors.grey,
                    ),
                  ),
              ],
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
