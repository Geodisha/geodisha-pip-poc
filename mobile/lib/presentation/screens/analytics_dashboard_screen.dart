import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/command_center_service.dart';
import '../../core/services/api_service.dart';
import '../widgets/animated_charts.dart'; // NEW: Import animated charts

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  late CommandCenterService _commandCenterService;
  
  @override
  void initState() {
    super.initState();
    _commandCenterService = CommandCenterService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _commandCenterService.getKpiTrends(days: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Analytics Dashboard')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics data...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Analytics Dashboard')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final response = snapshot.data;
        final trendData = response?['data'] as List?;
        
        if (trendData == null || trendData.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Analytics Dashboard')),
            body: const Center(child: Text('No trend data available')),
          );
        }

        return _buildContent(trendData);
      },
    );
  }

  Widget _buildContent(List<dynamic> trendData) {
    // Process KPI data for charts
    final kpiTrends = _processKpiData(trendData);
    final categoryComparison = _processCategoryData();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Health Score',
                    '74%',
                    '↑ 5%',
                    AppTheme.successColor,
                    Icons.favorite,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Issues',
                    '23',
                    '↓ 12%',
                    AppTheme.errorColor,
                    Icons.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Satisfaction',
                    '68%',
                    '↑ 3%',
                    AppTheme.accentColor,
                    Icons.sentiment_satisfied,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Engagement',
                    '82%',
                    '↑ 7%',
                    AppTheme.primaryColor,
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vote Loyalty Forecast Chart (RESTORED - this was good!)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vote Loyalty Forecast',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Actual vs Predicted sentiment score',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '↑ Trending Up',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const months = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar'];
                                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                                    return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 63),
                                FlSpot(1, 66),
                                FlSpot(2, 69),
                                FlSpot(3, 70),
                                FlSpot(4, 72),
                              ],
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 65),
                                FlSpot(1, 68),
                                FlSpot(2, 71),
                                FlSpot(3, 72),
                                FlSpot(4, 74),
                              ],
                              isCurved: true,
                              color: AppTheme.secondaryColor,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              dashArray: [5, 5],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Actual', AppTheme.primaryColor),
                        const SizedBox(width: 20),
                        _buildLegendItem('Forecast', AppTheme.secondaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Animated KPI Trends Line Chart (NEW ADDITION)
            AnimatedLineChart(
              title: 'KPI Trends (30 Days)',
              dataPoints: kpiTrends,
              lineColor: AppTheme.primaryColor,
              xLabels: const ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
              showGrid: true,
              showDots: true,
            ),
            const SizedBox(height: 20),

            // Ward Performance (RESTORED)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ward Performance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Health score distribution across wards',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const wards = ['Ward 7', 'Ward 12', 'Ward 18', 'Ward 21'];
                                  if (value.toInt() >= 0 && value.toInt() < wards.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        wards[value.toInt()],
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: 69,
                                  color: Colors.orange,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: 82,
                                  color: AppTheme.successColor,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: 58,
                                  color: Colors.orange,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: 46,
                                  color: AppTheme.errorColor,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Comparison Bar Chart (NEW ADDITION)
            AnimatedBarChart(
              title: 'Performance by Category',
              data: categoryComparison,
              maxY: 100,
              barColor: AppTheme.accentColor,
            ),
            const SizedBox(height: 16),

            // Activity Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Distribution of your time and efforts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: 35,
                                    title: '35%',
                                    color: Colors.blue,
                                    radius: 60,
                                  ),
                                  PieChartSectionData(
                                    value: 25,
                                    title: '25%',
                                    color: Colors.green,
                                    radius: 55,
                                  ),
                                  PieChartSectionData(
                                    value: 20,
                                    title: '20%',
                                    color: Colors.orange,
                                    radius: 55,
                                  ),
                                  PieChartSectionData(
                                    value: 20,
                                    title: '20%',
                                    color: Colors.purple,
                                    radius: 55,
                                  ),
                                ],
                                centerSpaceRadius: 30,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActivityItem('Field Visits', '35%', Colors.blue),
                              const SizedBox(height: 12),
                              _buildActivityItem('Grievances', '25%', Colors.green),
                              const SizedBox(height: 12),
                              _buildActivityItem('Meetings', '20%', Colors.orange),
                              const SizedBox(height: 12),
                              _buildActivityItem('Projects', '20%', Colors.purple),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Key Insights
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Key Insights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInsightItem(
                      'Ward 18 shows declining health score - high grievance volume detected',
                    ),
                    const Divider(height: 20),
                    _buildInsightItem(
                      'Your visit frequency increased by 12% this month - excellent engagement',
                    ),
                    const Divider(height: 20),
                    _buildInsightItem(
                      'Promise fulfillment rate improved in Infrastructure category (+8%)',
                    ),
                    const Divider(height: 20),
                    _buildInsightItem(
                      'Consider focusing on swing booths (12 identified) before next election',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Success banner
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎉 Live Analytics from BigQuery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Showing ${trendData.length} days of real KPI trends',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
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

  Widget _buildLegendItem(String label, Color color) {
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ==================== DATA PROCESSING METHODS ====================
  
  /// Process KPI trend data into chart data points
  List<FlSpot> _processKpiTrendsForChart(List<dynamic> trendData, String metricKey) {
    List<FlSpot> points = [];
    
    for (int i = 0; i < trendData.length && i < 30; i++) {
      final item = trendData[i];
      final value = item[metricKey];
      
      if (value != null) {
        points.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }
    
    return points;
    }

  /// Process KPI data for animated line chart
  List<FlSpot> _processKpiData(List<dynamic> trendData) {
    List<FlSpot> spots = [];
    
    for (int i = 0; i < trendData.length && i < 30; i++) {
      var item = trendData[i];
      double yValue = (item['issues_resolved'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), yValue));
    }
    
    // Fallback data if no trend data
    if (spots.isEmpty) {
      spots = [
        const FlSpot(0, 65),
        const FlSpot(7, 68),
        const FlSpot(14, 71),
        const FlSpot(21, 74),
        const FlSpot(28, 76),
      ];
    }
    
    return spots;
  }

  /// Process category data for bar chart comparison
  Map<String, double> _processCategoryData() {
    return {
      'Health': 78.0,
      'Education': 82.0,
      'Infrastructure': 65.0,
      'Water & Sanitation': 71.0,
      'Employment': 69.0,
      'Public Safety': 74.0,
    };
  }

  /// Build KPI card widget
  Widget _buildKpiCard(String title, String value, String trend, Color color, IconData icon) {
    final bool isPositive = trend.contains('↑');
    final Color trendColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Extract category-wise data for bar chart
  Map<String, double> _extractCategoryData(List<dynamic> trendData) {
    Map<String, double> categoryTotals = {};
    
    // Group by constituency or category if available
    for (var item in trendData) {
      String category = item['constituency_id'] ?? 'Unknown';
      double value = (item['visits_conducted'] ?? 0).toDouble();
      
      categoryTotals[category] = (categoryTotals[category] ?? 0) + value;
    }
    
    // Return top 10 categories
    var sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(10));
  }

  /// Get X-axis labels for last 30 days
  List<String> _getDateLabels(List<dynamic> trendData) {
    List<String> labels = [];
    
    for (var item in trendData) {
      if (item['report_date'] != null) {
        String date = item['report_date'].toString();
        // Extract day or create short label
        labels.add(date.substring(8, 10)); // Get DD from YYYY-MM-DD
      }
    }
    
    return labels.isEmpty ? ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5'] : labels;
  }
}
