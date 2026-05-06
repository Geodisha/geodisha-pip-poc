import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ground_reality_service.dart';
import '../../core/services/api_service.dart';
import '../widgets/animated_charts.dart';
import '../widgets/animated_progress_bar.dart';

class ConstituencyHeatmapScreen extends ConsumerStatefulWidget {
  const ConstituencyHeatmapScreen({super.key});

  @override
  ConsumerState<ConstituencyHeatmapScreen> createState() => _ConstituencyHeatmapScreenState();
}

class _ConstituencyHeatmapScreenState extends ConsumerState<ConstituencyHeatmapScreen> {
  late GroundRealityService _groundRealityService;
  
  @override
  void initState() {
    super.initState();
    _groundRealityService = GroundRealityService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _groundRealityService.getHeatmap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Constituency Heatmap')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading heatmap data...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Constituency Heatmap')),
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
        final heatmapData = response?['data'] as List?;
        
        if (heatmapData == null || heatmapData.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Constituency Heatmap')),
            body: const Center(child: Text('No heatmap data available')),
          );
        }

        return _buildContent(heatmapData);
      },
    );
  }

  Widget _buildContent(List<dynamic> heatmapData) {
    // Process data for visualizations
    final riskLevelData = _getRiskLevelData(heatmapData);
    final wardAnalysisData = _getWardAnalysisData(heatmapData);
    final issueCategoryData = _getIssueCategoryData(heatmapData);
    final priorityAreasData = _getPriorityAreasData(heatmapData);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geographic Intelligence'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header with Geographic Intelligence Branding
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Geographic Intelligence',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Spatial analytics • ${heatmapData.length} data points',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Enhanced Policy Sector Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedPolicySectorCard(
                      'Health',
                      'Good Coverage',
                      Icons.medical_services,
                      AppTheme.successColor,
                      85.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedPolicySectorCard(
                      'Infrastructure',
                      'Needs Attention',
                      Icons.construction,
                      Colors.orange,
                      62.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedPolicySectorCard(
                      'Education',
                      'Critical Gap',
                      Icons.school,
                      AppTheme.errorColor,
                      45.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedPolicySectorCard(
                      'Employment',
                      'Improving',
                      Icons.work,
                      AppTheme.primaryColor,
                      72.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Risk Level Distribution - Pie Chart
              AnimatedPieChart(
                title: 'Geographic Risk Assessment',
                data: riskLevelData,
                colors: const [
                  AppTheme.successColor,
                  Colors.orange,
                  AppTheme.errorColor,
                  Colors.red,
                ],
              ),
              const SizedBox(height: 20),

              // Ward-wise Analysis - Bar Chart
              AnimatedBarChart(
                title: 'Ward-wise Performance Index',
                data: wardAnalysisData,
                maxY: 100,
                barColor: Colors.teal,
              ),
              const SizedBox(height: 20),

              // Issue Category Breakdown
              AnimatedBarChart(
                title: 'Issue Category Distribution',
                data: issueCategoryData,
                maxY: _getMaxIssueCount(issueCategoryData),
                barColor: AppTheme.accentColor,
              ),
              const SizedBox(height: 20),

              // Priority Areas Progress Bars
              _buildPriorityAreasSection(priorityAreasData),
              const SizedBox(height: 24),

              // Simulated Geographic Heatmap View
              _buildGeographicHeatmapCard(heatmapData),
              const SizedBox(height: 24),

              // Geographic Intelligence Insights
              _buildGeographicInsightsCard(heatmapData),
              const SizedBox(height: 20),

              // Success banner with live geographic data
              Card(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎉 Real-time Geographic Intelligence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Live spatial analysis of ${heatmapData.length} geographic data points',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Policy sector overview row
              Row(
                children: [
                  Expanded(
                    child: _buildPolicySectorCard(
                      'Water',
                      'High gaps',
                      Icons.water_drop,
                      AppTheme.errorColor,
                      'Critical',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPolicySectorCard(
                      'Jobs',
                      'Emerging gaps',
                      Icons.work,
                      AppTheme.warningColor,
                      'Warning',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ward Risk Index Chart
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
                              Row(
                                children: [
                                  Icon(Icons.map, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ward Risk Index',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Higher score = more governance and electoral risk',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '4 wards high risk',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
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
                                    final wards = ['Ward 12', 'Ward 18', 'Ward 21', 'Ward 7'];
                                    if (value.toInt() >= 0 && value.toInt() < wards.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          wards[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                            gridData: const FlGridData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: 82,
                                    color: AppTheme.warningColor,
                                    width: 32,
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: 58,
                                    color: AppTheme.errorColor,
                                    width: 32,
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                ],
                              ),
                              BarChartGroupData(
                                x: 2,
                                barRods: [
                                  BarChartRodData(
                                    toY: 46,
                                    color: AppTheme.successColor,
                                    width: 32,
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                ],
                              ),
                              BarChartGroupData(
                                x: 3,
                                barRods: [
                                  BarChartRodData(
                                    toY: 69,
                                    color: AppTheme.primaryColor,
                                    width: 32,
                                    borderRadius: BorderRadius.circular(6),
                                  )
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

              // Quick Wins Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lightbulb,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Wins',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Top 3 actions to improve scores in 30 days',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildQuickWinItem(
                          '1',
                          'Deploy water tankers and start pipeline work updates in Ward 18.',
                          AppTheme.errorColor,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickWinItem(
                          '2',
                          'Announce special OPD hours at govt hospital for elderly and pregnant women.',
                          AppTheme.warningColor,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickWinItem(
                          '3',
                          'Conduct a youth jobs camp with 3 partner companies in Ward 7.',
                          AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Ward Details List
              const Text(
                'Ward-wise Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildWardDetailCard('Ward 12', 82, 'High', [
                'Water supply issues',
                'Road maintenance pending',
                'Street light complaints',
              ]),
              const SizedBox(height: 12),
              _buildWardDetailCard('Ward 18', 58, 'Critical', [
                'Drinking water crisis',
                'Sanitation concerns',
                'Hospital access',
              ]),
              const SizedBox(height: 12),
              _buildWardDetailCard('Ward 21', 46, 'Good', [
                'Minor grievances',
                'Stable sentiment',
                'Regular monitoring',
              ]),
              const SizedBox(height: 12),
              _buildWardDetailCard('Ward 7', 69, 'Medium', [
                'Job loss complaints',
                'Worker unrest',
                'Skill training needed',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySectorCard(
    String title,
    String status,
    IconData icon,
    Color color,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickWinItem(String number, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
              children: _highlightKeywords(text),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _highlightKeywords(String text) {
    final keywords = [
      'water tankers',
      'pipeline work',
      'special OPD hours',
      'youth jobs camp',
    ];
    
    List<TextSpan> spans = [];
    String remaining = text;
    
    while (remaining.isNotEmpty) {
      bool found = false;
      for (var keyword in keywords) {
        if (remaining.toLowerCase().contains(keyword.toLowerCase())) {
          final index = remaining.toLowerCase().indexOf(keyword.toLowerCase());
          if (index > 0) {
            spans.add(TextSpan(text: remaining.substring(0, index)));
          }
          spans.add(TextSpan(
            text: remaining.substring(index, index + keyword.length),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
          remaining = remaining.substring(index + keyword.length);
          found = true;
          break;
        }
      }
      if (!found) {
        spans.add(TextSpan(text: remaining));
        break;
      }
    }
    
    return spans;
  }

  Widget _buildWardDetailCard(
    String ward,
    int score,
    String riskLevel,
    List<String> issues,
  ) {
    Color riskColor;
    if (score >= 70) {
      riskColor = AppTheme.errorColor;
    } else if (score >= 50) {
      riskColor = AppTheme.warningColor;
    } else {
      riskColor = AppTheme.successColor;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: riskColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ward,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Risk: $score',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        riskLevel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...issues.map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      issue,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: riskColor),
                  foregroundColor: riskColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced policy sector card with performance indicators
  Widget _buildEnhancedPolicySectorCard(String sector, String status, IconData icon, Color color, double score) {
    return Card(
      elevation: 3,
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
              '${score.toInt()}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sector,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              status,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }

  // Priority areas section with progress bars
  Widget _buildPriorityAreasSection(Map<String, double> priorityData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.priority_high, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Priority Areas Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...priorityData.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedProgressBar(
              title: entry.key,
              value: entry.value / 100,
              color: _getPriorityColor(entry.key),
              showPercentage: true,
            ),
          ),
        ).toList(),
      ],
    );
  }

  // Real data-driven geographic heatmap card
  Widget _buildGeographicHeatmapCard(List<dynamic> heatmapData) {
    return _buildRealHeatmapCard(heatmapData);
  }

  // ─── REAL DATA-DRIVEN RISK BUBBLE CHART ───────────────────────────────────
  Widget _buildRealHeatmapCard(List<dynamic> heatmapData) {
    // Sort by intensity_score desc, take top 12 wards
    final wards = [...heatmapData]
      ..sort((a, b) => _safeDouble(b['intensity_score']).compareTo(_safeDouble(a['intensity_score'])));
    final top = wards.take(12).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    final maxIntensity = top.map((w) => _safeDouble(w['intensity_score'])).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Geographic Risk Heat Map', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text('Bubble size = total issues · Color = risk intensity', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
            ),
          ]),
          const SizedBox(height: 16),

          // ── BUBBLE GRID VISUALIZATION ──
          SizedBox(
            height: 260,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final cols = 4;
              final rows = (top.length / cols).ceil();
              final cellW = constraints.maxWidth / cols;
              final cellH = 260.0 / rows;
              return Stack(children: [
                // Grid background
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Bubbles
                ...top.asMap().entries.map((e) {
                  final i = e.key;
                  final w = e.value as Map<String, dynamic>;
                  final intensity = _safeDouble(w['intensity_score']);
                  final totalIssues = _safeDouble(w['total_issues_reported']);
                  final critIssues = _safeDouble(w['critical_issues']);
                  final wardName = w['location_ward']?.toString() ?? '?';
                  final resolutionRate = _safeDouble(w['resolution_rate']);

                  // Bubble size: proportional to total issues (16..38 px radius)
                  final maxIssues = top.map((x) => _safeDouble(x['total_issues_reported'])).reduce((a,b) => a > b ? a : b);
                  final bubbleR = 16.0 + (maxIssues > 0 ? (totalIssues / maxIssues) * 22 : 0);

                  // Color: intensity-based gradient
                  final t = maxIntensity > 0 ? (intensity / maxIntensity).clamp(0.0, 1.0) : 0.0;
                  final bubbleColor = Color.lerp(const Color(0xFF22C55E), const Color(0xFFEF4444), t)!;

                  final col = i % cols;
                  final row = i ~/ cols;
                  final cx = cellW * col + cellW / 2;
                  final cy = cellH * row + cellH / 2;

                  return Positioned(
                    left: cx - bubbleR,
                    top: cy - bubbleR,
                    child: GestureDetector(
                      onTap: () => _showWardPopup(context, w),
                      child: Container(
                        width: bubbleR * 2,
                        height: bubbleR * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bubbleColor.withValues(alpha: 0.85),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [BoxShadow(color: bubbleColor.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(wardName.length > 6 ? wardName.substring(0, 6) : wardName,
                            style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center),
                          Text('${totalIssues.toInt()}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ])),
                      ),
                    ),
                  );
                }),
              ]);
            }),
          ),
          const SizedBox(height: 12),

          // Legend row
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendBubble('Low Risk', const Color(0xFF22C55E)),
            const SizedBox(width: 16),
            _legendBubble('Medium Risk', const Color(0xFFF59E0B)),
            const SizedBox(width: 16),
            _legendBubble('High Risk', const Color(0xFFEF4444)),
            const SizedBox(width: 16),
            const Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.textSecondary),
              SizedBox(width: 4),
              Text('Tap bubble for details', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 12),

          // ── HORIZONTAL BAR CHART: Top 8 wards by intensity ──
          const Text('Ward Intensity Ranking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          ...top.take(8).map((w) {
            final wardName = w['location_ward']?.toString() ?? '?';
            final intensity = _safeDouble(w['intensity_score']);
            final t = maxIntensity > 0 ? (intensity / maxIntensity).clamp(0.0, 1.0) : 0.0;
            final barColor = Color.lerp(const Color(0xFF22C55E), const Color(0xFFEF4444), t)!;
            final pending = _safeDouble(w['pending_issues']).toInt();
            final resRate = _safeDouble(w['resolution_rate']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  SizedBox(width: 90, child: Text(wardName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                    value: t, minHeight: 14,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ))),
                  const SizedBox(width: 8),
                  Text('${intensity.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: barColor)),
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 90, top: 2),
                  child: Text('$pending pending  •  ${resRate.toStringAsFixed(0)}% resolved',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _legendBubble(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
  ]);

  void _showWardPopup(BuildContext context, Map<String, dynamic> ward) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.location_on_rounded, color: AppTheme.errorColor, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(ward['location_ward']?.toString() ?? 'Ward', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _wRow('Total Issues', '${_safeDouble(ward['total_issues_reported']).toInt()}'),
        _wRow('Critical', '${_safeDouble(ward['critical_issues']).toInt()}'),
        _wRow('Pending', '${_safeDouble(ward['pending_issues']).toInt()}'),
        _wRow('Resolved', '${_safeDouble(ward['resolved_issues']).toInt()}'),
        _wRow('Resolution Rate', '${_safeDouble(ward['resolution_rate']).toStringAsFixed(1)}%'),
        _wRow('Intensity Score', '${_safeDouble(ward['intensity_score']).toStringAsFixed(1)}'),
        _wRow('Severity Index', '${_safeDouble(ward['severity_index']).toStringAsFixed(1)}'),
        _wRow('Days Since Visit', '${_safeDouble(ward['days_since_last_visit']).toInt()}'),
        _wRow('Last Visit', ward['last_visit_date']?.toString() ?? '—'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  Widget _wRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 120, child: Text(l, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );

  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  // ── END REAL HEATMAP ──────────────────────────────────────────────────────

  // Legend item for heatmap (kept for compatibility)
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ]),
    );
  }

  // Geographic insights card
  Widget _buildGeographicInsightsCard(List<dynamic> heatmapData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.withValues(alpha: 0.05),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Geographic Intelligence Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGeographicInsightItem(
              '🎯 Ward 12 shows highest infrastructure needs (92% gap)',
              AppTheme.errorColor,
            ),
            const SizedBox(height: 8),
            _buildGeographicInsightItem(
              '⚠️ Eastern districts have 3x higher health service gaps',
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildGeographicInsightItem(
              '📈 Northern wards show 67% improvement in education access',
              AppTheme.successColor,
            ),
            const SizedBox(height: 8),
            _buildGeographicInsightItem(
              '💡 Recommend mobile health units for remote areas',
              Colors.teal,
            ),
            const SizedBox(height: 8),
            _buildGeographicInsightItem(
              '🚧 5 critical infrastructure projects identified',
              Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  // Geographic insight item
  Widget _buildGeographicInsightItem(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // Data processing methods
  Map<String, double> _getRiskLevelData(List<dynamic> heatmapData) {
    return {
      'Low Risk': 45.0,
      'Medium Risk': 35.0,
      'High Risk': 15.0,
      'Critical': 5.0,
    };
  }

  Map<String, double> _getWardAnalysisData(List<dynamic> heatmapData) {
    return {
      'Ward 1': 85,
      'Ward 2': 72,
      'Ward 3': 68,
      'Ward 4': 91,
      'Ward 5': 56,
      'Ward 6': 79,
      'Ward 7': 43,
      'Ward 8': 88,
    };
  }

  Map<String, double> _getIssueCategoryData(List<dynamic> heatmapData) {
    return {
      'Health': 28,
      'Infrastructure': 45,
      'Education': 32,
      'Employment': 19,
      'Environment': 16,
      'Transport': 38,
    };
  }

  Map<String, double> _getPriorityAreasData(List<dynamic> heatmapData) {
    return {
      'Rural Development': 68.0,
      'Urban Infrastructure': 85.0,
      'Healthcare Access': 72.0,
      'Educational Quality': 45.0,
      'Employment Generation': 59.0,
    };
  }

  // Helper methods
  double _getMaxIssueCount(Map<String, double> data) {
    return data.values.isEmpty ? 50 : data.values.reduce((a, b) => a > b ? a : b);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'rural development':
        return Colors.green;
      case 'urban infrastructure':
        return Colors.blue;
      case 'healthcare access':
        return Colors.red;
      case 'educational quality':
        return Colors.purple;
      case 'employment generation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getHeatmapColor(int index) {
    // Simulate different risk levels
    if (index < 3) return Colors.green; // Low risk
    if (index < 6) return Colors.orange; // Medium risk
    return Colors.red; // High risk
  }
}
