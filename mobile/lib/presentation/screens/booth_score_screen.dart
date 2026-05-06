import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/services/election_war_room_service.dart';
import '../../core/services/api_service.dart';
import '../widgets/animated_charts.dart';
import '../widgets/animated_progress_bar.dart';
import '../../core/theme/app_theme.dart';

/// Safe numeric extraction — handles String, int, double, null from API
double _n(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

class BoothScoreScreen extends ConsumerStatefulWidget {
  const BoothScoreScreen({super.key});

  @override
  ConsumerState<BoothScoreScreen> createState() => _BoothScoreScreenState();
}

class _BoothScoreScreenState extends ConsumerState<BoothScoreScreen> {
  late ElectionWarRoomService _electionService;
  
  @override
  void initState() {
    super.initState();
    _electionService = ElectionWarRoomService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _electionService.getBoothScores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booth Score Analytics')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading booth scores...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booth Score Analytics')),
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
        final boothScores = response?['data'] as List?;
        
        if (boothScores == null || boothScores.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booth Score Analytics')),
            body: const Center(child: Text('No booth scores available')),
          );
        }

        return _buildContent(boothScores);
      },
    );
  }

  Widget _buildContent(List<dynamic> boothScores) {
    // Calculate summary stats
    final avgScore = boothScores.fold<double>(0, (sum, b) => sum + _n(b['booth_score'])) / boothScores.length;
    final strongBooths = boothScores.where((b) => _n(b['booth_score']) > 75).length;
    final weakBooths = boothScores.where((b) => _n(b['booth_score']) < 50).length;
    final swingBooths = boothScores.where((b) => _n(b['booth_score']) >= 50 && _n(b['booth_score']) <= 75).length;
    
    // Process data for charts
    final topBoothsData = _getTopBoothsData(boothScores);
    final partyComparisonData = _getPartyComparisonData(boothScores);
    final scoreTrendData = _getScoreTrendData(boothScores);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth Score Analytics'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedScoreCard(
                    'Average Score',
                    '${avgScore.toStringAsFixed(0)}',
                    '${boothScores.length} booths',
                    AppTheme.primaryColor,
                    Icons.assessment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedScoreCard(
                    'Strong Booths',
                    '$strongBooths',
                    'Score > 75',
                    AppTheme.successColor,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedScoreCard(
                    'Weak Booths',
                    '$weakBooths',
                    'Score < 50',
                    AppTheme.errorColor,
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedScoreCard(
                    'Swing Booths',
                    '$swingBooths',
                    'Score 50-75',
                    Colors.orange,
                    Icons.compare_arrows,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top 10 Booth Scores - Animated Bar Chart
            AnimatedBarChart(
              title: 'Top 10 Booth Scores',
              data: topBoothsData,
              maxY: 100,
              barColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 20),

            // Party-wise Performance Comparison
            AnimatedBarChart(
              title: 'Party-wise Booth Performance',
              data: partyComparisonData,
              maxY: 100,
              barColor: AppTheme.accentColor,
            ),
            const SizedBox(height: 20),

            // Score Trends Over Time
            if (scoreTrendData.isNotEmpty)
              AnimatedLineChart(
                title: 'Booth Score Trends',
                dataPoints: scoreTrendData,
                lineColor: AppTheme.primaryColor,
                xLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
                showGrid: true,
                showDots: true,
              ),
            const SizedBox(height: 20),

            // Overall Performance Progress
            AnimatedProgressBar(
              title: 'Overall Election Readiness',
              value: avgScore / 100,
              color: _getReadinessColor(avgScore),
              showPercentage: true,
            ),
            const SizedBox(height: 24),

            // Score Distribution Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Score Distribution by Booth',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Color-coded by performance tier',
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
                                  const booths = ['101', '102', '116', '120'];
                                  if (value.toInt() >= 0 && value.toInt() < booths.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        booths[value.toInt()],
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
                                  toY: 78,
                                  color: Colors.green,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: 62,
                                  color: Colors.orange,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: 49,
                                  color: Colors.red,
                                  width: 40,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: 88,
                                  color: Colors.green,
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
            const SizedBox(height: 24),

            // Enhanced Color-Coded Booth Analysis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detailed Booth Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.how_to_vote, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Election Ready',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Critical Booths (Low Scores)
            ...boothScores.where((booth) => _n(booth['booth_score']) < 50).take(3).map((booth) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEnhancedBoothCard(
                  boothNo: booth['booth_number']?.toString() ?? 'N/A',
                  score: _n(booth['booth_score']).toInt(),
                  voters: booth['voters'] ?? 0,
                  turnout: booth['turnout'] ?? 0.0,
                  lastElection: booth['last_election'] ?? 0.0,
                  concerns: (booth['concerns'] as List?)?.cast<String>() ?? ['Infrastructure needs attention'],
                  priority: 'Critical',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Strong Booths (High Scores)
            if (strongBooths > 0) ...[
              const Text(
                'Top Performing Booths',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 12),
              ...boothScores.where((booth) => _n(booth['booth_score']) > 75).take(3).map((booth) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEnhancedBoothCard(
                    boothNo: booth['booth_number']?.toString() ?? 'N/A',
                    score: _n(booth['booth_score']).toInt(),
                    voters: booth['voters'] ?? 0,
                    turnout: booth['turnout'] ?? 0.0,
                    lastElection: booth['last_election'] ?? 0.0,
                    concerns: (booth['concerns'] as List?)?.cast<String>() ?? ['Maintain excellence'],
                    priority: 'Strong',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoothCard({
    required String boothNo,
    required int score,
    required int voters,
    required double turnout,
    required double lastElection,
    required List<String> concerns,
    bool isTopPerformer = false,
  }) {
    Color scoreColor = score >= 75
        ? Colors.green
        : (score >= 60 ? Colors.orange : Colors.red);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isTopPerformer ? Icons.star : Icons.warning,
                    color: scoreColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boothNo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$voters voters',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetric('Turnout', '${turnout.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetric('Last Election', '${lastElection.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetric(
                    'Trend',
                    '${(turnout - lastElection) >= 0 ? '+' : ''}${(turnout - lastElection).toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Key Concerns:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: concerns.map((concern) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    concern,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.map, size: 16),
                label: const Text('View on Map', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Enhanced score card with icons
  Widget _buildEnhancedScoreCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
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
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced booth card with color coding and priority indicators
  Widget _buildEnhancedBoothCard({
    required String boothNo,
    required int score,
    required int voters,
    required double turnout,
    required double lastElection,
    required List<String> concerns,
    required String priority,
  }) {
    final Color priorityColor = _getPriorityColor(priority);
    final Color scoreColor = _getScoreColor(score);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priorityColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booth number and score
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.how_to_vote, color: priorityColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        boothNo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Score: $score',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Metrics row
            Row(
              children: [
                Expanded(child: _buildMetric('Voters', voters.toString())),
                Expanded(child: _buildMetric('Turnout', '${turnout.toStringAsFixed(1)}%')),
                Expanded(child: _buildMetric('Last Election', '${lastElection.toStringAsFixed(1)}%')),
              ],
            ),
            const SizedBox(height: 12),
            
            // Concerns/Issues
            if (concerns.isNotEmpty) ...[
              Text(
                priority == 'Critical' ? 'Key Issues:' : 'Focus Areas:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: concerns.take(3).map((concern) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: priorityColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    concern,
                    style: TextStyle(
                      fontSize: 10,
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.map, size: 16, color: priorityColor),
                    label: Text(
                      'View Details',
                      style: TextStyle(fontSize: 12, color: priorityColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: priorityColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (priority == 'Critical')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.warning, size: 16),
                      label: const Text('Take Action', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Data processing methods
  Map<String, double> _getTopBoothsData(List<dynamic> boothScores) {
    final sortedBooths = List.from(boothScores);
    sortedBooths.sort((a, b) => _n(b['booth_score']).compareTo(_n(a['booth_score'])));
    
    final Map<String, double> data = {};
    for (int i = 0; i < 10 && i < sortedBooths.length; i++) {
      final booth = sortedBooths[i];
      data['${booth['booth_number'] ?? 'B${i+1}'}'] = _n(booth['booth_score']);
    }
    return data;
  }

  Map<String, double> _getPartyComparisonData(List<dynamic> boothScores) {
    // Simulate party performance data
    return {
      'Party A': 72.5,
      'Party B': 68.3,
      'Party C': 65.8,
      'Independent': 58.2,
    };
  }

  List<FlSpot> _getScoreTrendData(List<dynamic> boothScores) {
    // Simulate trend data over 5 months
    final avgScore = boothScores.fold<double>(0, (sum, b) => sum + _n(b['booth_score'])) / boothScores.length;
    return [
      FlSpot(0, avgScore - 5),
      FlSpot(1, avgScore - 2),
      FlSpot(2, avgScore + 1),
      FlSpot(3, avgScore + 3),
      FlSpot(4, avgScore),
    ];
  }

  Color _getReadinessColor(double avgScore) {
    if (avgScore >= 75) return AppTheme.successColor;
    if (avgScore >= 60) return Colors.orange;
    return AppTheme.errorColor;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppTheme.errorColor;
      case 'Strong':
        return AppTheme.successColor;
      case 'Swing':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return AppTheme.successColor;
    if (score >= 50) return Colors.orange;
    return AppTheme.errorColor;
  }
}
