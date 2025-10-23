import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/db_service.dart';
import '../services/voice_coach.dart';
import '../models/shot.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceCoach>().announceScreen("Analytics Dashboard");
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DbService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Shot>>(
        stream: db.shotsStream,
        initialData: const <Shot>[],
        builder: (context, snap) {
          final all = (snap.data ?? const <Shot>[]).where((s) => s.distance <= 120).toList();
          if (all.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                
                _buildPerformanceOverview(context, all),
                const SizedBox(height: 24),
                
                _buildStrokesGainedAnalysis(context, all),
                const SizedBox(height: 24),
                
                _buildConsistencyMetrics(context, all),
                const SizedBox(height: 24),
                
                _buildPracticeTrend(context, all),
                const SizedBox(height: 24),
                
                _buildClubPerformance(context, all),
                const SizedBox(height: 24),
                
                _buildActionableInsights(context, all),
                const SizedBox(height: 100), // Bottom padding for navigation
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.straighten), label: 'Distance'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Club'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.sports_golf), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Goals'),
        ],
        onDestinationSelected: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, '/distance');
          if (i == 1) Navigator.pushReplacementNamed(context, '/recommend');
          if (i == 2) Navigator.pushReplacementNamed(context, '/history');
          if (i == 4) Navigator.pushReplacementNamed(context, '/sessions');
          if (i == 5) Navigator.pushReplacementNamed(context, '/goals');
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save shots from the Distance screen to see your performance analytics and Mark Broadie-inspired insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/distance'),
              icon: const Icon(Icons.add),
              label: const Text('Start Tracking Shots'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Data-driven insights inspired by Mark Broadie\'s "Strokes Gained" methodology',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceOverview(BuildContext context, List<Shot> shots) {
    final totalShots = shots.length;
    final avgDistance = shots.map((s) => s.distance).reduce((a, b) => a + b) / totalShots;
    final recentShots = shots.take(10).toList();
    final recentAvg = recentShots.map((s) => s.distance).reduce((a, b) => a + b) / recentShots.length;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Performance Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Shots',
                    totalShots.toString(),
                    Icons.golf_course,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg Distance',
                    '${avgDistance.toStringAsFixed(0)} yd',
                    Icons.straighten,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Recent Avg',
                    '${recentAvg.toStringAsFixed(0)} yd',
                    Icons.timeline,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Trend',
                    recentAvg > avgDistance ? '↗ Improving' : '↘ Declining',
                    Icons.trending_up,
                    recentAvg > avgDistance ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStrokesGainedAnalysis(BuildContext context, List<Shot> shots) {
    // Simplified Strokes Gained calculation
    final clubPerformance = <String, List<double>>{};
    for (final shot in shots) {
      clubPerformance.putIfAbsent(shot.club, () => <double>[]).add(shot.distance);
    }

    final sgData = <String, double>{};
    for (final entry in clubPerformance.entries) {
      final distances = entry.value;
      if (distances.length < 2) continue; // Reduced from 3 to 2
      
      final stdDev = _calculateStdDev(distances);
      
      // Simplified SG: closer to target = better (lower std dev = better)
      sgData[entry.key] = stdDev;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Strokes Gained Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Shot consistency by club (lower = more consistent)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            if (sgData.isNotEmpty) ...[
              SizedBox(
                height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                            final clubs = sgData.keys.toList()..sort();
                  final idx = value.toInt();
                            if (idx < 0 || idx >= clubs.length) return const SizedBox.shrink();
                  return Transform.rotate(
                    angle: -0.6,
                              child: Text(
                                clubs[idx],
                                style: const TextStyle(fontSize: 11),
                              ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
                      for (var i = 0; i < sgData.keys.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                              toY: sgData.values.elementAt(i),
                    width: 16,
                    borderRadius: BorderRadius.circular(6),
                              color: sgData.values.elementAt(i) < 15 
                                  ? Colors.green 
                                  : sgData.values.elementAt(i) < 25 
                                      ? Colors.orange 
                                      : Colors.red,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLegendItem(context, Colors.green, 'Excellent (<15 yd)'),
                  _buildLegendItem(context, Colors.orange, 'Good (15-25 yd)'),
                  _buildLegendItem(context, Colors.red, 'Needs Work (>25 yd)'),
                ],
              ),
            ] else ...[
              const Center(
                child: Text('Need at least 2 shots per club for analysis'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildConsistencyMetrics(BuildContext context, List<Shot> shots) {
    final recent20 = shots.take(20).toList();
    if (recent20.length < 5) return const SizedBox.shrink();

    final distances = recent20.map((s) => s.distance).toList();
    final stdDev = _calculateStdDev(distances);
    final consistency = stdDev < 20 ? 'Excellent' : stdDev < 35 ? 'Good' : 'Needs Work';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Consistency Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Shot dispersion visualization
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildShotDispersionChart(context, recent20),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Standard Deviation',
                    '${stdDev.toStringAsFixed(1)} yd',
                    'Lower is better',
                    stdDev < 20 ? Colors.green : stdDev < 35 ? Colors.orange : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Consistency Rating',
                    consistency,
                    'Based on dispersion',
                    stdDev < 20 ? Colors.green : stdDev < 35 ? Colors.orange : Colors.red,
                  ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTrend(BuildContext context, List<Shot> shots) {
    final recent20 = shots.take(20).toList();
    if (recent20.length < 3) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (var i = 0; i < recent20.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent20[i].distance));
    }

    final minY = recent20.map((s) => s.distance).reduce(min);
    final maxY = recent20.map((s) => s.distance).reduce(max);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Practice Trend (Last ${recent20.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text(
                              '${value.toInt() + 1}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  minY: minY * 0.9,
                  maxY: maxY * 1.1,
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: spots,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3,
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      barWidth: 3,
                      color: Theme.of(context).primaryColor,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubPerformance(BuildContext context, List<Shot> shots) {
    final clubStats = <String, Map<String, dynamic>>{};
    
    for (final shot in shots) {
      if (!clubStats.containsKey(shot.club)) {
        clubStats[shot.club] = {
          'distances': <double>[],
          'count': 0,
        };
      }
      clubStats[shot.club]!['distances'].add(shot.distance);
      clubStats[shot.club]!['count']++;
    }

    final sortedClubs = clubStats.keys.toList()
      ..sort((a, b) => clubStats[b]!['count'].compareTo(clubStats[a]!['count']));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_golf, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Club Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sortedClubs.take(5).map((club) {
              final stats = clubStats[club]!;
              final distances = stats['distances'] as List<double>;
              final avg = distances.reduce((a, b) => a + b) / distances.length;
              final stdDev = _calculateStdDev(distances);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        club,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${avg.toStringAsFixed(0)} yd avg',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${stats['count']} shots',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (30 - stdDev) / 30, // Normalize for display
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              stdDev < 15 ? Colors.green : stdDev < 25 ? Colors.orange : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consistency: ${stdDev.toStringAsFixed(1)} yd',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionableInsights(BuildContext context, List<Shot> shots) {
    final insights = <String>[];
    
    // Analyze data for insights
    final clubStats = <String, List<double>>{};
    for (final shot in shots) {
      clubStats.putIfAbsent(shot.club, () => <double>[]).add(shot.distance);
    }

    // Find most inconsistent club
    String? mostInconsistentClub;
    double maxStdDev = 0;
    for (final entry in clubStats.entries) {
      if (entry.value.length >= 3) {
        final stdDev = _calculateStdDev(entry.value);
        if (stdDev > maxStdDev) {
          maxStdDev = stdDev;
          mostInconsistentClub = entry.key;
        }
      }
    }

    if (mostInconsistentClub != null && maxStdDev > 25) {
      insights.add('Focus practice on your $mostInconsistentClub - consistency needs improvement (${maxStdDev.toStringAsFixed(1)} yd dispersion)');
    }

    // Check recent trend
    final recent10 = shots.take(10).toList();
    if (recent10.length >= 5) {
      final recentAvg = recent10.map((s) => s.distance).reduce((a, b) => a + b) / recent10.length;
      final older10 = shots.skip(10).take(10).toList();
      if (older10.length >= 5) {
        final olderAvg = older10.map((s) => s.distance).reduce((a, b) => a + b) / older10.length;
        if (recentAvg > olderAvg + 5) {
          insights.add('Great improvement! Your recent shots are ${(recentAvg - olderAvg).toStringAsFixed(0)} yards longer on average.');
        } else if (recentAvg < olderAvg - 5) {
          insights.add('Consider focusing on distance control - recent shots are shorter than usual.');
        }
      }
    }

    // Check for practice frequency
    if (shots.length >= 20) {
      insights.add('Excellent practice consistency! Keep tracking to see long-term trends.');
    } else if (shots.length >= 10) {
      insights.add('Good start! Try to practice regularly to build meaningful data.');
    }

    if (insights.isEmpty) {
      insights.add('Keep practicing to unlock personalized insights based on your performance data.');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[600]),
                const SizedBox(width: 8),
                Text(
                  'Actionable Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Based on Mark Broadie\'s methodology, focus on consistency over distance for better scoring.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShotDispersionChart(BuildContext context, List<Shot> shots) {
    if (shots.isEmpty) return const Center(child: Text('No shots to display'));
    
    final distances = shots.map((s) => s.distance).toList();
    final minDist = distances.reduce((a, b) => a < b ? a : b);
    final maxDist = distances.reduce((a, b) => a > b ? a : b);
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Shot Dispersion',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: ShotDispersionPainter(
                shots: shots,
                minDist: minDist,
                maxDist: maxDist,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${minDist.round()}yd - ${maxDist.round()}yd range',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold<double>(0, (acc, v) => acc + pow(v - mean, 2)) / (values.length - 1);
    return sqrt(variance);
  }
}

class ShotDispersionPainter extends CustomPainter {
  final List<Shot> shots;
  final double minDist;
  final double maxDist;

  ShotDispersionPainter({
    required this.shots,
    required this.minDist,
    required this.maxDist,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final range = maxDist - minDist;
    if (range == 0) {
      // All shots same distance - draw them in center
      for (int i = 0; i < shots.length; i++) {
        final x = size.width / 2;
        final y = size.height / 2;
        canvas.drawCircle(Offset(x, y), 4, paint);
      }
      return;
    }

    for (final shot in shots) {
      final x = ((shot.distance - minDist) / range) * size.width;
      final y = size.height / 2;
      
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
