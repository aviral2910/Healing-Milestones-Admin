import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_screen.dart'; // To reuse the provider

enum TimeFilter { daily, weekly, monthly }

class EngagementScreen extends ConsumerStatefulWidget {
  const EngagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends ConsumerState<EngagementScreen> {
  TimeFilter _usersFilter = TimeFilter.daily;
  TimeFilter _storiesFilter = TimeFilter.daily;
  TimeFilter _journeysFilter = TimeFilter.daily;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Engagement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (stats) {
          final List rawHistory = stats['platformHistory'] ?? [];
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildGraphSection(
                title: 'Active Users',
                history: rawHistory,
                dataKey: 'dau',
                filter: _usersFilter,
                onFilterChanged: (f) => setState(() => _usersFilter = f),
                color: const Color(0xFF6366F1), // Indigo
                isAverage: true, // DAU shouldn't be summed for weekly, it should be averaged
              ),
              const SizedBox(height: 40),
              
              _buildGraphSection(
                title: 'Published Stories',
                history: rawHistory,
                dataKey: 'stories',
                filter: _storiesFilter,
                onFilterChanged: (f) => setState(() => _storiesFilter = f),
                color: const Color(0xFFF59E0B), // Amber
                isAverage: false, // Stories should be summed
              ),
              const SizedBox(height: 40),
              
              _buildGraphSection(
                title: 'Created Journeys',
                history: rawHistory,
                dataKey: 'journeys',
                filter: _journeysFilter,
                onFilterChanged: (f) => setState(() => _journeysFilter = f),
                color: const Color(0xFF10B981), // Emerald
                isAverage: false,
              ),
              const SizedBox(height: 40),

              const Text('Trending Tags & Categories', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121214),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: const Text('Coming Soon: Dynamic trending tags list and category metrics.', style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGraphSection({
    required String title,
    required List history,
    required String dataKey,
    required TimeFilter filter,
    required ValueChanged<TimeFilter> onFilterChanged,
    required Color color,
    required bool isAverage,
  }) {
    final processedData = _processData(history, filter, dataKey, isAverage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            _buildToggleGroup(filter, onFilterChanged),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.only(right: 20, left: 10, top: 30, bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: processedData.isEmpty 
              ? const Center(child: Text("No data yet.", style: TextStyle(color: Colors.white54)))
              : _buildChart(processedData, color, filter),
        ),
      ],
    );
  }

  Widget _buildToggleGroup(TimeFilter currentFilter, ValueChanged<TimeFilter> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildToggleBtn('D', TimeFilter.daily, currentFilter, onChanged),
          _buildToggleBtn('W', TimeFilter.weekly, currentFilter, onChanged),
          _buildToggleBtn('M', TimeFilter.monthly, currentFilter, onChanged),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, TimeFilter filter, TimeFilter current, ValueChanged<TimeFilter> onChanged) {
    final isSelected = filter == current;
    return GestureDetector(
      onTap: () => onChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _processData(List rawData, TimeFilter filter, String key, bool isAverage) {
    if (rawData.isEmpty) return [];

    if (filter == TimeFilter.daily) {
      // Just return the last 7 days for readability
      var sublist = rawData.length > 7 ? rawData.sublist(rawData.length - 7) : rawData;
      return sublist.map((e) {
        // e["date"] is "2023-10-01" -> extract "10-01" or parse to Weekday
        DateTime dt = DateTime.parse(e["date"]);
        return {"label": "${dt.month}/${dt.day}", "val": (e[key] as num).toDouble()};
      }).toList();
    } 
    else if (filter == TimeFilter.weekly) {
      // Group last 28 days into 4 weeks
      var sublist = rawData.length > 28 ? rawData.sublist(rawData.length - 28) : rawData;
      List<Map<String, dynamic>> weeks = [];
      for (int i = 0; i < sublist.length; i += 7) {
        var chunk = sublist.sublist(i, (i + 7 > sublist.length) ? sublist.length : i + 7);
        double sum = 0;
        for (var c in chunk) sum += (c[key] as num).toDouble();
        double val = isAverage ? (sum / chunk.length) : sum;
        weeks.add({"label": "W${(i/7).floor() + 1}", "val": val});
      }
      return weeks;
    } 
    else {
      // Monthly (For now, just return the sum/avg of the whole 30 days as "This Month")
      double sum = 0;
      for (var c in rawData) sum += (c[key] as num).toDouble();
      double val = isAverage ? (sum / rawData.length) : sum;
      return [{"label": "This M.", "val": val}];
    }
  }

  Widget _buildChart(List<Map<String, dynamic>> data, Color color, TimeFilter filter) {
    if (filter == TimeFilter.weekly || filter == TimeFilter.monthly) {
      return _buildBarChart(data, color);
    }
    return _buildLineChart(data, color);
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, Color color) {
    double maxY = 0;
    for (var d in data) {
      if (d['val'] > maxY) maxY = d['val'];
    }
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(data[value.toInt()]['label'], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY / 4) > 0 ? (maxY / 4) : 1,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11));
              },
              reservedSize: 36,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxY * 1.2,
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index]['val'],
                color: color,
                width: data.length > 7 ? 8 : 24, // Thinner bars if many, thicker if few
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, Color color) {
    double maxY = 0;
    for (var d in data) {
      if (d['val'] > maxY) maxY = d['val'];
    }
    if (maxY == 0) maxY = 10; // default ceiling

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[index]['label'],
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY / 4) > 0 ? (maxY / 4) : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  textAlign: TextAlign.left,
                );
              },
              reservedSize: 36,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (index) {
              return FlSpot(index.toDouble(), data[index]['val']);
            }),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
