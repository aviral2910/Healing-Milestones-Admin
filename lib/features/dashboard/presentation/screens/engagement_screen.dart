import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart';

enum ChartPeriod { weekly, monthly, yearly }

class EngagementScreen extends ConsumerStatefulWidget {
  const EngagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends ConsumerState<EngagementScreen> {
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
              PaginatingChartWidget(
                title: 'Active Users',
                history: rawHistory,
                dataKey: 'dau',
                color: const Color(0xFF6366F1), // Indigo
                isAverage: true, // If we need to aggregate daily to monthly, we use average
              ),
              const SizedBox(height: 40),
              
              PaginatingChartWidget(
                title: 'Published Stories',
                history: rawHistory,
                dataKey: 'stories',
                color: const Color(0xFFF59E0B), // Amber
                isAverage: false, // Stories should be summed
              ),
              const SizedBox(height: 40),
              
              PaginatingChartWidget(
                title: 'Created Journeys',
                history: rawHistory,
                dataKey: 'journeys',
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
}

class PaginatingChartWidget extends StatefulWidget {
  final String title;
  final List history;
  final String dataKey;
  final Color color;
  final bool isAverage;

  const PaginatingChartWidget({
    Key? key,
    required this.title,
    required this.history,
    required this.dataKey,
    required this.color,
    required this.isAverage,
  }) : super(key: key);

  @override
  State<PaginatingChartWidget> createState() => _PaginatingChartWidgetState();
}

class _PaginatingChartWidgetState extends State<PaginatingChartWidget> {
  ChartPeriod _period = ChartPeriod.weekly;
  DateTime _currentCursor = DateTime.now(); // Represents the "end" or "focus" date of the view

  void _nextPeriod() {
    setState(() {
      if (_period == ChartPeriod.weekly) {
        _currentCursor = _currentCursor.add(const Duration(days: 7));
      } else if (_period == ChartPeriod.monthly) {
        _currentCursor = _currentCursor.add(const Duration(days: 30));
      } else if (_period == ChartPeriod.yearly) {
        _currentCursor = DateTime(_currentCursor.year, _currentCursor.month + 12, _currentCursor.day);
      }
      if (_currentCursor.isAfter(DateTime.now())) {
        _currentCursor = DateTime.now();
      }
    });
  }

  void _prevPeriod() {
    setState(() {
      if (_period == ChartPeriod.weekly) {
        _currentCursor = _currentCursor.subtract(const Duration(days: 7));
      } else if (_period == ChartPeriod.monthly) {
        _currentCursor = _currentCursor.subtract(const Duration(days: 30));
      } else if (_period == ChartPeriod.yearly) {
        _currentCursor = DateTime(_currentCursor.year, _currentCursor.month - 12, _currentCursor.day);
      }
    });
  }

  String _getDateLabel() {
    if (_period == ChartPeriod.weekly) {
      DateTime start = _currentCursor.subtract(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(_currentCursor)}';
    } else if (_period == ChartPeriod.monthly) {
      DateTime start = _currentCursor.subtract(const Duration(days: 29));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(_currentCursor)}';
    } else {
      DateTime start = DateTime(_currentCursor.year, _currentCursor.month - 11, 1);
      return '${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(_currentCursor)}';
    }
  }

  // Returns { "label": str, "val": double }
  List<Map<String, dynamic>> _processData() {
    List<Map<String, dynamic>> result = [];
    
    if (_period == ChartPeriod.weekly) {
      // Last 7 days ending at _currentCursor
      DateTime start = _currentCursor.subtract(const Duration(days: 6));
      for (int i = 0; i < 7; i++) {
        DateTime day = start.add(Duration(days: i));
        double val = _getValueForDay(day);
        result.add({
          "label": DateFormat('E').format(day), // Mon, Tue...
          "val": val,
        });
      }
    } else if (_period == ChartPeriod.monthly) {
      // Last 30 days ending at _currentCursor
      DateTime start = _currentCursor.subtract(const Duration(days: 29));
      for (int i = 0; i < 30; i++) {
        DateTime day = start.add(Duration(days: i));
        double val = _getValueForDay(day);
        result.add({
          "label": (i % 5 == 0 || i == 29) ? DateFormat('d').format(day) : "", // Label every 5th day + last day
          "val": val,
        });
      }
    } else if (_period == ChartPeriod.yearly) {
      // Last 12 months ending at _currentCursor month
      for (int i = 11; i >= 0; i--) {
        DateTime targetMonth = DateTime(_currentCursor.year, _currentCursor.month - i, 1);
        double sum = 0;
        int count = 0;
        int daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          DateTime day = DateTime(targetMonth.year, targetMonth.month, d);
          // If the day is in the future relative to _currentCursor, skip it so we don't count it (though our cursor is usually today)
          if (day.isAfter(_currentCursor)) break;
          
          double val = _getValueForDay(day);
          sum += val;
          count++;
        }
        double finalVal = widget.isAverage ? (count == 0 ? 0 : sum / count) : sum;
        result.add({
          "label": DateFormat('MMM').format(targetMonth),
          "val": finalVal,
        });
      }
    }
    return result;
  }
  double _getValueForDay(DateTime target) {
    for (var d in widget.history) {
      DateTime rowDate = DateTime.parse(d["date"]);
      if (rowDate.year == target.year && rowDate.month == target.month && rowDate.day == target.day) {
        return (d[widget.dataKey] as num).toDouble();
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final data = _processData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            _buildToggleGroup(),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.only(right: 20, left: 10, top: 16, bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121214),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            children: [
              // Pagination Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _prevPeriod,
                  ),
                  Text(_getDateLabel(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentCursor.isAfter(DateTime.now().subtract(const Duration(days: 1))) ? null : _nextPeriod,
                    disabledColor: Colors.white24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _period == ChartPeriod.monthly ? _buildLineChart(data, widget.color) : _buildBarChart(data, widget.color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleGroup() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildToggleBtn('W', ChartPeriod.weekly),
          _buildToggleBtn('M', ChartPeriod.monthly),
          _buildToggleBtn('Y', ChartPeriod.yearly),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, ChartPeriod filter) {
    final isSelected = filter == _period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _period = filter;
          _currentCursor = DateTime.now(); // reset cursor to now when switching filters
        });
      },
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
                width: data.length > 7 ? 12 : 24, // Thinner bars for yearly, thicker for weekly
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
    if (maxY == 0) maxY = 10;

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
            dotData: const FlDotData(show: false),
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
