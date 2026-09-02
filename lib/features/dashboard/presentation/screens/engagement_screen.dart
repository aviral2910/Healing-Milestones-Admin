import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_screen.dart'; // To reuse the provider

class EngagementScreen extends ConsumerWidget {
  const EngagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final List dauHistory = stats['dauHistory'] ?? [];
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Active Users (DAU)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 250,
                padding: const EdgeInsets.only(right: 20, left: 10, top: 30, bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121214),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: dauHistory.isEmpty ? const Center(child: Text("No DAU data yet.", style: TextStyle(color: Colors.white))) : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
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
                            if (index >= 0 && index < dauHistory.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dauHistory[index]['day'],
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
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
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              textAlign: TextAlign.left,
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (dauHistory.length - 1).toDouble(),
                    minY: 0,
                    maxY: _getMaxY(dauHistory),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(dauHistory.length, (index) {
                          return FlSpot(index.toDouble(), (dauHistory[index]['users'] as int).toDouble());
                        }),
                        isCurved: true,
                        color: const Color(0xFF6366F1), // Indigo accent
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
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
              )
            ],
          );
        },
      ),
    );
  }

  double _getMaxY(List data) {
    if (data.isEmpty) return 50.0;
    double maxVal = 0;
    for (var d in data) {
      if ((d['users'] as int).toDouble() > maxVal) {
        maxVal = (d['users'] as int).toDouble();
      }
    }
    return maxVal > 0 ? maxVal + 10 : 50.0;
  }
}
