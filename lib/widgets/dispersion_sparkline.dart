import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DispersionSparkline extends StatelessWidget {
  final List<double> yards; // recent distances for that club (or last N shots)

  const DispersionSparkline({super.key, required this.yards});

  @override
  Widget build(BuildContext context) {
    if (yards.isEmpty) {
      return const SizedBox(width: 80, height: 24);
    }
    final spots = <FlSpot>[];
    for (int i = 0; i < yards.length; i++) {
      spots.add(FlSpot(i.toDouble(), yards[i]));
    }
    final minY = yards.reduce((a, b) => a < b ? a : b);
    final maxY = yards.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      width: 100, height: 28,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY * 0.98,
          maxY: maxY * 1.02,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: spots,
              dotData: const FlDotData(show: false),
              barWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
