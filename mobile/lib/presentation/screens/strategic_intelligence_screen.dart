import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_intelligence_service.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/animated_charts.dart';
import '../widgets/animated_progress_bar.dart';

double _n(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

class StrategicIntelligenceScreen extends ConsumerStatefulWidget {
  const StrategicIntelligenceScreen({super.key});

  @override
  ConsumerState<StrategicIntelligenceScreen> createState() => _StrategicIntelligenceScreenState();
}

class _StrategicIntelligenceScreenState extends ConsumerState<StrategicIntelligenceScreen> {
  late AIIntelligenceService _aiService;
  
  @override
  void initState() {
    super.initState();
    _aiService = AIIntelligenceService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _aiService.getInfluencerMap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading strategic intelligence...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
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
          );
        }

        final response = snapshot.data;
        final influencers = response?['data'] as List?;
        
        if (influencers == null || influencers.isEmpty) {
          return const Center(child: Text('No strategic intelligence available'));
        }

        return _buildContent(influencers);
      },
    );
  }

  Widget _buildContent(List<dynamic> influencers) {
    // Process data for charts
    final influenceScores = _getInfluenceScoresData(influencers);
    final networkAnalysis = _getNetworkAnalysisData(influencers);
    final alignmentData = _getAlignmentData(influencers);
    
    // Calculate metrics
    final alignedCount = influencers.where((i) => (i['alignment'] ?? 'neutral') == 'aligned').length;
    final riskCount = influencers.where((i) => (i['risk_level'] ?? 'low') == 'high').length;
    final neutralCount = influencers.where((i) => (i['alignment'] ?? 'neutral') == 'neutral').length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategic Intelligence'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with Network Intelligence Branding
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Colors.deepPurple],
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
                      Icons.hub,
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
                          'Strategic Intelligence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Network analysis • ${influencers.length} key stakeholders',
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

            // Enhanced Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedSummaryCard(
                    '$alignedCount',
                    'Aligned Leaders',
                    AppTheme.successColor,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedSummaryCard(
                    '$riskCount',
                    'High Risk',
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
                  child: _buildEnhancedSummaryCard(
                    '$neutralCount',
                    'Neutral/Unknown',
                    Colors.orange,
                    Icons.help_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedSummaryCard(
                    '${influencers.length}',
                    'Total Tracked',
                    AppTheme.primaryColor,
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Influence Scores Bar Chart
            AnimatedBarChart(
              title: 'Top Influencer Power Scores',
              data: influenceScores,
              maxY: 100,
              barColor: Colors.deepPurple,
            ),
            const SizedBox(height: 20),

            // Alignment Distribution Pie Chart
            AnimatedPieChart(
              title: 'Stakeholder Alignment Analysis',
              data: alignmentData,
              colors: const [
                AppTheme.successColor,
                AppTheme.errorColor,
                Colors.orange,
                Colors.grey,
              ],
            ),
            const SizedBox(height: 20),

            // Network Analysis Progress Bars
            _buildNetworkAnalysisSection(networkAnalysis),
            const SizedBox(height: 24),

            // Enhanced Influencer Power Mapping Section
            _buildEnhancedSectionHeader(
              icon: Icons.hub,
              title: 'Key Influencer Network',
              subtitle: 'Strategic stakeholder mapping',
              badge: 'AI Analyzed',
            ),
            const SizedBox(height: 16),

            // Top 10 influencers sorted by influence_score desc
            ...(() {
              final sorted = [...influencers]..sort((a, b) =>
                _n(b['influence_score']).compareTo(_n(a['influence_score'])));
              return sorted.take(10).toList().asMap().entries.map((entry) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEnhancedInfluencerCard(context, entry.value, entry.key),
                ));
            })(),
            const SizedBox(height: 24),

            // Network Intelligence Insights
            _buildNetworkInsightsCard(),
            const SizedBox(height: 20),

            // Success banner with live data
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
                            '🎉 Real-time Strategic Intelligence',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Live network analysis of ${influencers.length} key stakeholders',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Influencer'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String value, String label, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
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
              label,
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

  Widget _buildInfluencerCard(BuildContext context, Map<String, dynamic> inf) {
    final name = inf['name']?.toString() ?? 'Unknown';
    final category = inf['category']?.toString() ?? 'General';
    final influence = inf['influence']?.toString() ?? 'Medium';
    final loyalty = inf['loyalty']?.toString() ?? 'Neutral';
    final score = inf['score'] is int ? inf['score'] as int : int.tryParse(inf['score']?.toString() ?? '0') ?? 0;
    final lastContact = inf['lastContact']?.toString() ?? 'Never';
    
    Color loyaltyColor = _getLoyaltyColor(loyalty);
    Color scoreColor = _getScoreColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: loyaltyColor.withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: loyaltyColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$influence Influence',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: loyaltyColor.withOpacity(0.1),
                        border: Border.all(color: loyaltyColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        loyalty,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: loyaltyColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Last contact: $lastContact',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone, size: 14),
                    label: const Text('Contact', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.event, size: 14),
                    label: const Text('Schedule Meeting', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildVisitPlanCard(BuildContext context, Map<String, dynamic> visit) {
    final area = visit['area']?.toString() ?? 'Unknown Area';
    final priority = visit['priority']?.toString() ?? 'Medium';
    final roi = visit['roi']?.toString() ?? 'Medium ROI';
    final score = visit['score']?.toString() ?? '0';
    final reason = visit['reason']?.toString() ?? 'No reason provided';
    final lastVisit = visit['lastVisit']?.toString() ?? 'Never';
    
    Color priorityColor = _getPriorityColor(priority);
    Color roiColor = _getROIColor(roi);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: priorityColor.withOpacity(0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              priorityColor.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                area,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: roiColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                roi,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: roiColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$priority Priority',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Score: $score',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'AI Recommendation:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.history, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Last visited: $lastVisit',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Add to Calendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: priorityColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLoyaltyColor(String loyalty) {
    switch (loyalty) {
      case 'Aligned':
        return Colors.green;
      case 'Drifting':
        return Colors.red;
      case 'Neutral':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  // Enhanced section header with badge
  Widget _buildEnhancedSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
      ],
    );
  }

  // Enhanced summary card with icons and better styling
  Widget _buildEnhancedSummaryCard(String value, String title, Color color, IconData icon) {
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

  // Network analysis section with progress bars
  Widget _buildNetworkAnalysisSection(Map<String, double> networkData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.deepPurple, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Network Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...networkData.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedProgressBar(
              title: entry.key,
              value: entry.value / 100,
              color: _getNetworkColor(entry.key),
              showPercentage: true,
            ),
          ),
        ).toList(),
      ],
    );
  }

  // Derive political title from category/sub_category
  String _influencerTitle(dynamic influencer) {
    final cat    = influencer['category']?.toString().toLowerCase() ?? '';
    final subCat = influencer['sub_category']?.toString().toLowerCase() ?? '';
    final level  = influencer['influence_level']?.toString().toLowerCase() ?? '';
    if (cat == 'political' || subCat.contains('political')) {
      if (level == 'high' || level == 'very_high') return 'Senior Political Leader';
      return 'Political Leader';
    }
    if (subCat.contains('mptc') || subCat.contains('zptc')) return 'MPTC/ZPTC';
    if (cat == 'government' && subCat.contains('local')) return 'Corporator';
    if (cat == 'government') return 'Chair Person';
    if (cat == 'religious' || cat == 'community' || subCat.contains('community')) return 'Community Leader';
    if (cat == 'business') return 'Business Influencer';
    if (cat == 'media') return 'Media Personality';
    if (cat == 'youth') return 'Youth Leader';
    if (cat == 'women') return 'Women Leader';
    if (cat == 'farmer' || subCat.contains('farmer')) return 'Farmer Leader';
    if (cat == 'caste_community' || subCat.contains('caste')) return 'Community Leader';
    if (level == 'high' || level == 'very_high') return 'Key Influencer';
    return 'Local Influencer';
  }

  // Icon for influencer category
  IconData _influencerIcon(dynamic influencer) {
    final cat = influencer['category']?.toString().toLowerCase() ?? '';
    switch (cat) {
      case 'political': return Icons.account_balance_rounded;
      case 'government': return Icons.gavel_rounded;
      case 'religious': return Icons.temple_hindu_rounded;
      case 'community': return Icons.groups_rounded;
      case 'business': return Icons.business_center_rounded;
      case 'media': return Icons.campaign_rounded;
      case 'youth': return Icons.groups_2_rounded;
      case 'women': return Icons.person_rounded;
      case 'farmer': return Icons.agriculture_rounded;
      default: return Icons.star_rounded;
    }
  }

  // Enhanced animated influencer card
  Widget _buildEnhancedInfluencerCard(BuildContext context, dynamic influencer, int index) {
    final name      = influencer['name']?.toString().replaceAll('_', ' ') ?? 'Unknown';
    final title     = _influencerTitle(influencer);
    final influence = _n(influencer['influence_score']);
    final category  = influencer['category']?.toString() ?? 'other';
    final ward      = influencer['location_ward']?.toString() ?? '';
    final mandal    = influencer['location_mandal']?.toString() ?? '';
    final reach     = _n(influencer['reach_estimate']);
    final relStr    = influencer['relationship_strength']?.toString() ?? 'unknown';
    final leaning   = influencer['political_leaning']?.toString() ?? 'unknown';
    final keyIssues = (influencer['key_issues'] as List? ?? []).take(2).toList();

    // Color based on relationship strength
    final Color relColor = relStr == 'strong'
        ? AppTheme.successColor
        : relStr == 'moderate'
            ? AppTheme.warningColor
            : relStr == 'weak' || relStr == 'none'
                ? AppTheme.errorColor
                : AppTheme.mediumGrey;

    // Badge color based on political leaning
    final Color leanColor = leaning == 'aligned' || leaning == 'supportive'
        ? AppTheme.successColor
        : leaning == 'opposition'
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: relColor.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Avatar with category icon
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [relColor.withValues(alpha: 0.8), relColor.withValues(alpha: 0.5)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_influencerIcon(influencer), color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    // Political Title badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    if (ward.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text('$ward${mandal.isNotEmpty ? ', $mandal' : ''}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    // Influence score gauge
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${influence.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                        const Text('score', style: TextStyle(fontSize: 7, color: AppTheme.textSecondary)),
                      ])),
                    ),
                  ]),
                ]),
                const SizedBox(height: 10),
                // Influence bar
                Row(children: [
                  const Text('Influence ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                    value: (influence / 100).clamp(0.0, 1.0), minHeight: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      influence >= 80 ? AppTheme.successColor : influence >= 60 ? AppTheme.warningColor : AppTheme.errorColor),
                  ))),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: leanColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(leaning.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: leanColor)),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _mChip(Icons.people_rounded, _fmtReach(reach)),
                  _mChip(Icons.handshake_rounded, relStr, color: relColor),
                  ...keyIssues.map((i) => _mChip(Icons.tag_rounded, i.toString())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.phone_rounded, size: 13, color: relColor),
                    label: Text('Contact', style: TextStyle(fontSize: 11, color: relColor)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: BorderSide(color: relColor.withValues(alpha: 0.5)),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bolt_rounded, size: 13),
                    label: const Text('Engage', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtReach(double v) => v >= 100000 ? '${(v/100000).toStringAsFixed(1)}L reach' : v >= 1000 ? '${(v/1000).toStringAsFixed(0)}K reach' : '${v.toInt()} reach';

  Widget _mChip(IconData icon, String label, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: (color ?? AppTheme.textSecondary).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color ?? AppTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10, color: color ?? AppTheme.textSecondary, fontWeight: FontWeight.w500)),
    ]),
  );

  // Metric badge widget
  Widget _buildMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // Network insights card — derived from live influencer data
  Widget _buildNetworkInsightsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _aiService.getInfluencerMap(),
      builder: (ctx, snap) {
        final all = (snap.data?['data'] as List? ?? []);
        final total = all.length;
        final aligned = all.where((i) => i['political_leaning']?.toString().toLowerCase() == 'aligned' || i['political_leaning']?.toString().toLowerCase() == 'supportive').length;
        final highRisk = all.where((i) => i['relationship_strength']?.toString().toLowerCase() == 'weak' || i['relationship_strength']?.toString().toLowerCase() == 'none').length;
        final neutral = all.where((i) => i['political_leaning']?.toString().toLowerCase() == 'neutral').length;
        final totalReach = all.fold<double>(0, (s, i) { final v = i['reach_estimate']; if (v == null) return s; if (v is num) return s + v.toDouble(); return s + (double.tryParse(v.toString()) ?? 0); });
        final avgScore = total > 0 ? all.fold<double>(0, (s, i) { final v = i['influence_score']; if (v == null) return s; if (v is num) return s + v.toDouble(); return s + (double.tryParse(v.toString()) ?? 0); }) / total : 0.0;

        final pctAligned = total > 0 ? (aligned / total * 100).toStringAsFixed(0) : '—';
        final reachFmt = totalReach >= 100000 ? '${(totalReach/100000).toStringAsFixed(1)}L' : totalReach >= 1000 ? '${(totalReach/1000).toStringAsFixed(0)}K' : totalReach.toStringAsFixed(0);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.deepPurple.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.lightbulb, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                const Text('Network Intelligence Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
                ),
              ]),
              const SizedBox(height: 12),
              _buildInsightItem('🎯 $pctAligned% of $total influencers show positive alignment', AppTheme.successColor),
              const SizedBox(height: 8),
              _buildInsightItem('⚠️ $highRisk high-risk stakeholders need immediate attention', AppTheme.errorColor),
              const SizedBox(height: 8),
              _buildInsightItem('📡 Total network reach: $reachFmt people across constituency', Colors.deepPurple),
              const SizedBox(height: 8),
              _buildInsightItem('📈 Avg influence score: ${avgScore.toStringAsFixed(1)} / 100', AppTheme.infoColor),
              const SizedBox(height: 8),
              _buildInsightItem('💡 $neutral neutral stakeholders can be converted this week', Colors.orange),
            ]),
          ),
        );
      },
    );
  }

  // Insight item widget
  Widget _buildInsightItem(String text, Color color) {
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
  Map<String, double> _getInfluenceScoresData(List<dynamic> influencers) {
    final Map<String, double> data = {};
    final sortedInfluencers = List.from(influencers);
    sortedInfluencers.sort((a, b) => _n(b['influence_score']).compareTo(_n(a['influence_score'])));
    
    for (int i = 0; i < 8 && i < sortedInfluencers.length; i++) {
      final influencer = sortedInfluencers[i];
      final name = influencer['name'] ?? 'Unknown';
      final score = _n(influencer['influence_score']);
      data[name.split(' ').first] = score;
    }
    
    return data;
  }

  Map<String, double> _getNetworkAnalysisData(List<dynamic> influencers) {
    if (influencers.isEmpty) return {};
    final total = influencers.length;
    final avgInfluence = influencers.fold<double>(0, (s, i) => s + _n(i['influence_score'])) / total;
    final strongRelCount = influencers.where((i) => i['relationship_strength']?.toString().toLowerCase() == 'strong').length;
    final verifiedCount  = influencers.where((i) => i['verified'] == true || i['verified'] == 1).length;
    final alignedCount   = influencers.where((i) => i['political_leaning']?.toString().toLowerCase() == 'aligned' || i['political_leaning']?.toString().toLowerCase() == 'supportive').length;
    final highLvlCount   = influencers.where((i) => i['influence_level']?.toString().toLowerCase() == 'high' || i['influence_level']?.toString().toLowerCase() == 'very_high').length;
    return {
      'Avg Influence Score':  avgInfluence,
      'Strong Relationships': (strongRelCount / total * 100),
      'Verified Contacts':    (verifiedCount  / total * 100),
      'Aligned / Supportive': (alignedCount   / total * 100),
      'High-Level Influencers': (highLvlCount  / total * 100),
    };
  }

  Map<String, double> _getAlignmentData(List<dynamic> influencers) {
    final alignedCount = influencers.where((i) => (i['alignment'] ?? 'neutral') == 'aligned').length.toDouble();
    final opposedCount = influencers.where((i) => (i['alignment'] ?? 'neutral') == 'opposed').length.toDouble();
    final neutralCount = influencers.where((i) => (i['alignment'] ?? 'neutral') == 'neutral').length.toDouble();
    final unknownCount = influencers.where((i) => (i['alignment'] ?? 'neutral') == 'unknown').length.toDouble();
    
    return {
      'Aligned': alignedCount,
      'Opposed': opposedCount,
      'Neutral': neutralCount,
      'Unknown': unknownCount,
    };
  }

  // Color coding methods
  Color _getAlignmentColor(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'aligned':
        return AppTheme.successColor;
      case 'opposed':
        return AppTheme.errorColor;
      case 'neutral':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  Color _getNetworkColor(String metric) {
    switch (metric) {
      case 'Avg Influence Score':     return Colors.blue;
      case 'Strong Relationships':    return Colors.green;
      case 'Verified Contacts':       return Colors.purple;
      case 'Aligned / Supportive':    return Colors.indigo;
      case 'High-Level Influencers':  return Colors.teal;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  Color _getROIColor(String roi) {
    if (roi.contains('Very High')) return const Color(0xFF10B981);
    if (roi.contains('High')) return const Color(0xFF3B82F6);
    return const Color(0xFF6B7280);
  }
}
