import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ground_reality_service.dart';
import '../../data/services/intelligence_service.dart';
import '../../core/services/api_service.dart';

class VisitsListScreenEnhanced extends ConsumerStatefulWidget {
  const VisitsListScreenEnhanced({super.key});

  @override
  ConsumerState<VisitsListScreenEnhanced> createState() => _VisitsListScreenEnhancedState();
}

class _VisitsListScreenEnhancedState extends ConsumerState<VisitsListScreenEnhanced> {
  late GroundRealityService _groundRealityService;
  
  @override
  void initState() {
    super.initState();
    _groundRealityService = GroundRealityService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _groundRealityService.getVisitsEnhanced(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Visit Records')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading visit records...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Visit Records')),
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
        final visits = response?['data'] as List?;
        
        if (visits == null || visits.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Visit Records')),
            body: const Center(child: Text('No visit records available')),
          );
        }

        return _buildContent(visits);
      },
    );
  }

  Widget _buildContent(List<dynamic> visits) {
    final _statsService = IntelligenceService(ApiService());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Records'),
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.primaryGradient)),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor.withValues(alpha: 0.05), AppTheme.backgroundLight],
            begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── LIVE Statistics Cards ──────────────────────────────────────
            FutureBuilder<Map<String, dynamic>>(
              future: _statsService.getVisitStats(),
              builder: (ctx, snap) {
                final stat = (snap.data?['data'] as List? ?? []);
                final latest = stat.isNotEmpty ? stat.first as Map<String, dynamic> : <String, dynamic>{};
                final totalVisits  = _sv(latest['total_visits']);
                final totalAtt     = _sv(latest['total_attendance']);
                final avgAtt       = _sv(latest['average_attendance_per_visit']);
                final wardsCov     = _sv(latest['wards_covered']);
                final covPct       = _sv(latest['coverage_pct']);
                final griev        = _sv(latest['total_grievances_collected']);
                final grievRes     = _sv(latest['grievances_resolved']);
                final sentPos      = _sv(latest['positive_sentiment_pct']);
                final visitsType   = latest['visits_by_type'];

                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _buildStatCard('Total Visits', totalVisits > 0 ? '${totalVisits.toInt()}' : '—',
                      totalAtt > 0 ? '${_fmt(totalAtt)} attendees' : 'This month', Icons.location_on_rounded, AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Avg Attendees', avgAtt > 0 ? '${avgAtt.toStringAsFixed(0)}' : '—',
                      'Per visit', Icons.people_rounded, AppTheme.successColor)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _buildStatCard('Ward Coverage', wardsCov > 0 ? '${wardsCov.toInt()} wards' : '—',
                      covPct > 0 ? '${covPct.toStringAsFixed(0)}% covered' : '', Icons.pie_chart_rounded, AppTheme.secondaryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Grievance Res.', grievRes > 0 ? '${grievRes.toInt()}/${griev.toInt()}' : '—',
                      sentPos > 0 ? '${sentPos.toStringAsFixed(0)}% positive mood' : 'Resolved', Icons.check_circle_rounded, AppTheme.accentColor)),
                  ]),
                  if (visitsType is Map) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0,2))]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Visits by Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 10),
                        ...((visitsType as Map).entries.map((e) {
                          final count = e.value is num ? (e.value as num).toDouble() : double.tryParse(e.value.toString()) ?? 0;
                          final maxVal = (visitsType.values.map((v) => v is num ? (v as num).toDouble() : double.tryParse(v.toString()) ?? 0).reduce((a,b) => a>b?a:b));
                          return Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [
                            SizedBox(width: 120, child: Text(e.key.toString().replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                              value: maxVal > 0 ? (count / maxVal).clamp(0.0, 1.0) : 0,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ))),
                            const SizedBox(width: 8),
                            Text('${count.toInt()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                          ]));
                        })),
                      ]),
                    ),
                  ],
                ]);
              },
            ),
            const SizedBox(height: 24),

            // Visit Trend Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visit Trend (Last 7 Days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Daily visit frequency',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 5,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        days[value.toInt()],
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
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2, color: AppTheme.primaryColor, width: 20)]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: AppTheme.primaryColor, width: 20)]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1, color: AppTheme.primaryColor, width: 20)]),
                            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4, color: AppTheme.primaryColor, width: 20)]),
                            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 2, color: AppTheme.primaryColor, width: 20)]),
                            BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 3, color: AppTheme.primaryColor, width: 20)]),
                            BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 1, color: AppTheme.primaryColor, width: 20)]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Visits List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Visits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Visit'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...visits.take(10).map((visit) => _buildVisitCard(visit as Map<String, dynamic>)).toList(),

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
                            '🎉 Live Visit Records from BigQuery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Showing ${visits.length} visit records from field operations',
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
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    // Map actual API fields
    final visitType    = visit['visit_type']?.toString() ?? visit['type']?.toString() ?? 'general';
    final title        = '${(visitType).replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ')} — ${visit['location_ward']?.toString() ?? 'N/A'}';
    final date         = visit['visit_date']?.toString() ?? visit['date']?.toString() ?? 'Date TBD';
    final time         = visit['visit_time']?.toString() ?? '';
    final ward         = visit['location_ward']?.toString() ?? '';
    final leaderName   = visit['leader_name']?.toString() ?? '';
    final leaderRole   = visit['leader_role']?.toString() ?? '';
    final attendance   = visit['total_attendance'] ?? visit['attendees'] ?? 0;
    final sentiment    = visit['public_sentiment']?.toString() ?? '';
    final sentimentScr = (visit['sentiment_score'] is num) ? (visit['sentiment_score'] as num).toDouble() : double.tryParse(visit['sentiment_score']?.toString() ?? '') ?? 0.0;
    final grievances   = visit['grievances_count'] ?? 0;
    final resolved     = visit['grievances_resolved_on_spot'] ?? 0;
    final media        = visit['media_coverage']?.toString() ?? 'no';
    final verified     = visit['verification_status']?.toString() ?? 'pending';
    final category     = visit['visit_category']?.toString() ?? '';

    Color typeColor = _getTypeColor(visitType);

    final Color sentColor = sentiment == 'positive'
        ? AppTheme.successColor
        : sentiment == 'negative'
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: typeColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Icon(_getTypeIcon(visitType), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 11, color: AppTheme.textSecondary),
                const SizedBox(width: 3),
                Text('$date${time.isNotEmpty ? '  •  $time' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: verified == 'verified'
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(verified.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: verified == 'verified' ? AppTheme.successColor : AppTheme.warningColor,
                  )),
              ),
              if (category.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(category.replaceAll('_', ' '), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeColor)),
                ),
              ],
            ]),
          ]),
          const SizedBox(height: 10),
          // Leader info
          if (leaderName.isNotEmpty)
            Row(children: [
              const Icon(Icons.person_rounded, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('$leaderName${leaderRole.isNotEmpty ? '  •  $leaderRole' : ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ]),
          const SizedBox(height: 8),
          // Stats chips row
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (ward.isNotEmpty)
              _visitChip(Icons.location_on_rounded, ward, AppTheme.textSecondary),
            _visitChip(Icons.people_rounded, '$attendance attendees', AppTheme.infoColor),
            if ((grievances as num) > 0)
              _visitChip(Icons.report_problem_rounded, '$grievances grievances ($resolved resolved)', AppTheme.warningColor),
            if (media == 'yes')
              _visitChip(Icons.videocam_rounded, 'Media Coverage', AppTheme.successColor),
            if (sentiment.isNotEmpty)
              _visitChip(
                sentiment == 'positive' ? Icons.sentiment_satisfied_rounded : sentiment == 'negative' ? Icons.sentiment_dissatisfied_rounded : Icons.sentiment_neutral_rounded,
                '$sentiment${sentimentScr > 0 ? ' (${(sentimentScr * 100).toStringAsFixed(0)}%)' : ''}',
                sentColor,
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _visitChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
  double _sv(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _fmt(double v) => v >= 100000 ? '${(v/100000).toStringAsFixed(1)}L' : v >= 1000 ? '${(v/1000).toStringAsFixed(0)}K' : v.toStringAsFixed(0);

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'public_meeting': case 'community_meeting': return AppTheme.primaryColor;
      case 'infrastructure_review': case 'field_visit': return AppTheme.successColor;
      case 'consultation': case 'grievance_camp': return AppTheme.warningColor;
      case 'program_launch': case 'inauguration': return AppTheme.accentColor;
      case 'emergency': return AppTheme.errorColor;
      case 'survey': return AppTheme.infoColor;
      default: return AppTheme.mediumGrey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'public_meeting': case 'community_meeting': return Icons.groups_rounded;
      case 'infrastructure_review': return Icons.engineering_rounded;
      case 'field_visit': return Icons.directions_walk_rounded;
      case 'consultation': return Icons.chat_rounded;
      case 'grievance_camp': return Icons.report_problem_rounded;
      case 'program_launch': case 'inauguration': return Icons.celebration_rounded;
      case 'emergency': return Icons.crisis_alert_rounded;
      case 'survey': return Icons.assignment_rounded;
      default: return Icons.event_note_rounded;
    }
  }
}
