import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/animated_kpi_card.dart';
import '../widgets/animated_progress_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/command_center_service.dart';
import '../../data/services/intelligence_service.dart';
import '../../core/services/api_service.dart';

class ExecutiveOverviewScreen extends ConsumerStatefulWidget {
  const ExecutiveOverviewScreen({super.key});

  @override
  ConsumerState<ExecutiveOverviewScreen> createState() => _ExecutiveOverviewScreenState();
}

class _ExecutiveOverviewScreenState extends ConsumerState<ExecutiveOverviewScreen> {
  late CommandCenterService _commandCenterService;
  late IntelligenceService _intelService;

  static double _n(dynamic v, [double d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? d;
  }
  
  @override
  void initState() {
    super.initState();
    _commandCenterService = CommandCenterService(ApiService());
    _intelService = IntelligenceService(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _commandCenterService.getConstituencyOverview(),
      builder: (context, snapshot) {
        // Loading state with skeleton
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Executive Overview'),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Constituency header skeleton
                  CardSkeleton(),
                  const SizedBox(height: 16),
                  // KPI cards skeleton
                  Row(
                    children: [
                      Expanded(child: CardSkeleton()),
                      const SizedBox(width: 12),
                      Expanded(child: CardSkeleton()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: CardSkeleton()),
                      const SizedBox(width: 12),
                      Expanded(child: CardSkeleton()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CardSkeleton(),
                ],
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Executive Overview'),
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
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

        // Get data
        final response = snapshot.data;
        final data = response?['data'] as List?;
        
        // Empty state
        if (data == null || data.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Executive Overview'),
              elevation: 0,
            ),
            body: const Center(
              child: Text('No data available'),
            ),
          );
        }

        // Success! Use first constituency
        final overview = data[0];
        
        return _buildContent(context, overview);
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> overview) {
    return Scaffold(
      appBar: AppBar(title: const Text('Executive Overview'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Constituency header ───────────────────────────────────────
          FadeInDown(child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF1E40AF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(overview['constituency_name']?.toString() ?? 'Constituency',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('ID: ${overview['constituency_id'] ?? ''} · Risk: ${(overview['risk_level'] ?? 'N/A').toString().toUpperCase()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  _oBadge('Pop: ${_fmtN(_n(overview['total_population']))}'),
                  _oBadge('Voters: ${_fmtN(_n(overview['total_voters']))}'),
                  _oBadge('Visits/30d: ${_n(overview['visit_frequency_30d']).toInt()}'),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${_n(overview['health_score']).toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                const Text('Health', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ]),
          )),
          const SizedBox(height: 20),

          // ── KPI Cards ────────────────────────────────────────────────
          _buildKPICards(overview),
          const SizedBox(height: 20),

          // ── Issues & Promises grid ───────────────────────────────────
          FadeInUp(delay: const Duration(milliseconds: 100), child: Row(children: [
            Expanded(child: _miniCard('Active Issues',    '${_n(overview['active_issues']).toInt()}',    Icons.warning_rounded, AppTheme.warningColor)),
            const SizedBox(width: 10),
            Expanded(child: _miniCard('Resolved 30d',    '${_n(overview['resolved_issues_30d']).toInt()}', Icons.check_circle_rounded, AppTheme.successColor)),
            const SizedBox(width: 10),
            Expanded(child: _miniCard('Pending',         '${_n(overview['pending_issues']).toInt()}',   Icons.pending_rounded, AppTheme.infoColor)),
          ])),
          const SizedBox(height: 10),
          FadeInUp(delay: const Duration(milliseconds: 150), child: Row(children: [
            Expanded(child: _miniCard('Promises Total',  '${_n(overview['promises_total']).toInt()}',    Icons.task_alt_rounded, AppTheme.primaryColor)),
            const SizedBox(width: 10),
            Expanded(child: _miniCard('Completed',       '${_n(overview['promises_completed']).toInt()}',Icons.done_all_rounded, AppTheme.successColor)),
            const SizedBox(width: 10),
            Expanded(child: _miniCard('Grievances 30d',  '${_n(overview['grievances_30d']).toInt()}',    Icons.feedback_rounded, AppTheme.errorColor)),
          ])),
          const SizedBox(height: 20),

          // ── Satisfaction & Alerts ────────────────────────────────────
          FadeInUp(delay: const Duration(milliseconds: 200), child: Column(children: [
            AnimatedProgressBar(
              value: _n(overview['satisfaction_score']) / 100,
              label: 'Voter Satisfaction Score',
              showPercentage: true,
            ),
            const SizedBox(height: 10),
            AnimatedProgressBar(
              value: (_n(overview['promises_completed']) / (_n(overview['promises_total'], 1))).clamp(0.0, 1.0),
              label: 'Promise Completion Rate',
              showPercentage: true,
            ),
          ])),
          const SizedBox(height: 20),

          // ── Executive Summary (AI-generated) ─────────────────────────
          _buildExecutiveSummarySection(),
          const SizedBox(height: 20),

          // ── Quick Stats (population/voters) ─────────────────────────
          _buildQuickStats(overview),
          const SizedBox(height: 20),

          // ── Live data banner ─────────────────────────────────────────
          _buildSuccessBanner(overview),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _oBadge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Widget _miniCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), maxLines: 2),
    ]),
  );

  String _fmtN(double v) {
    if (v >= 10000000) return '${(v/10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '${(v/1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildExecutiveSummarySection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _intelService.getExecutiveSummary(limit: 1),
      builder: (ctx, snap) {
        final rows = snap.data?['data'] as List? ?? [];
        if (rows.isEmpty) return const SizedBox.shrink();
        final s = rows.first as Map<String, dynamic>;
        final achievements = (s['key_achievements'] as List? ?? []).cast<String>().take(3).toList();
        final critIssues   = (s['critical_issues'] as List? ?? []).cast<String>().take(3).toList();
        final topOpps      = (s['top_opportunities'] as List? ?? []).cast<String>().take(2).toList();
        final actions      = (s['immediate_actions'] as List? ?? []).cast<String>().take(2).toList();
        final mood         = s['constituency_mood']?.toString() ?? '';
        final polTemp      = s['political_temperature']?.toString() ?? '';
        final score        = double.tryParse(s['overall_health_score']?.toString() ?? '') ?? 0;

        return FadeInUp(delay: const Duration(milliseconds: 250), child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Icon(Icons.summarize_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('AI Executive Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                const Spacer(),
                if (mood.isNotEmpty) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('Mood: $mood', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Political temperature + health
              Row(children: [
                _tempChip(polTemp),
                const SizedBox(width: 8),
                _tempChip('Health: ${score.toStringAsFixed(0)}/100'),
              ]),
              const SizedBox(height: 12),

              if (achievements.isNotEmpty) ...[
                _summarySection('✅ Key Achievements', achievements, AppTheme.successColor),
                const SizedBox(height: 10),
              ],
              if (critIssues.isNotEmpty) ...[
                _summarySection('⚠️ Critical Issues', critIssues, AppTheme.errorColor),
                const SizedBox(height: 10),
              ],
              if (topOpps.isNotEmpty) ...[
                _summarySection('🎯 Top Opportunities', topOpps, AppTheme.infoColor),
                const SizedBox(height: 10),
              ],
              if (actions.isNotEmpty)
                _summarySection('⚡ Immediate Actions', actions, AppTheme.warningColor),
            ])),
          ]),
        ));
      },
    );
  }

  Widget _tempChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(t.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
  );

  Widget _summarySection(String header, List<String> items, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(header, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 5),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          Expanded(child: Text(item, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4))),
        ]),
      )),
    ],
  );

  Widget _buildKPICards(Map<String, dynamic> overview) {
    final healthScore = (overview['health_score'] is num)
        ? (overview['health_score'] as num).toDouble()
        : double.tryParse(overview['health_score']?.toString() ?? '0') ?? 0.0;
    final activeIssues = (overview['active_issues'] is num)
        ? (overview['active_issues'] as num).toInt()
        : int.tryParse(overview['active_issues']?.toString() ?? '0') ?? 0;
    final satisfactionScore = (overview['satisfaction_score'] is num)
        ? (overview['satisfaction_score'] as num).toDouble()
        : double.tryParse(overview['satisfaction_score']?.toString() ?? '0') ?? 0.0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedKpiCard(
                title: 'Health Score',
                value: '$healthScore',
                subtitle: 'Risk: ${overview['risk_level'] ?? 'Unknown'}',
                icon: Icons.favorite,
                color: healthScore >= 80 ? AppTheme.successColor : 
                       healthScore >= 60 ? AppTheme.secondaryColor : AppTheme.warningColor,
                trend: healthScore >= 70 ? 'up' : 'down',
                trendValue: healthScore >= 70 ? '+${healthScore - 70}' : '${healthScore - 70}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedKpiCard(
                title: 'Active Issues',
                value: '$activeIssues',
                subtitle: 'Resolved: ${overview['resolved_issues_30d'] ?? 0}',
                icon: Icons.warning,
                color: activeIssues < 30 ? AppTheme.successColor : 
                       activeIssues < 50 ? AppTheme.warningColor : AppTheme.errorColor,
                trend: activeIssues < 50 ? 'neutral' : 'down',
                trendValue: activeIssues < 50 ? 'Normal' : 'High',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedKpiCard(
                title: 'Satisfaction',
                value: '$satisfactionScore%',
                subtitle: '${overview['total_voters'] ?? 0} voters',
                icon: Icons.people,
                color: AppTheme.primaryColor,
                trend: satisfactionScore >= 70 ? 'up' : 'down',
                trendValue: satisfactionScore >= 70 ? '+${satisfactionScore - 70}%' : '${satisfactionScore - 70}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedKpiCard(
                title: 'Population',
                value: '${((overview['total_population'] ?? 0) / 1000000).toStringAsFixed(2)}M',
                subtitle: 'Voters: ${((overview['total_voters'] ?? 0) / 1000000).toStringAsFixed(2)}M',
                icon: Icons.group,
                color: AppTheme.secondaryColor,
                trend: 'neutral',
              ),
            ),
          ],
        ),
        
        // Add Progress Bars for key metrics
        const SizedBox(height: 24),
        AnimatedProgressBar(
          value: healthScore / 100,
          label: 'Constituency Health',
          showPercentage: true,
        ),
        const SizedBox(height: 16),
        AnimatedProgressBar(
          value: satisfactionScore / 100,
          label: 'Voter Satisfaction',
          showPercentage: true,
        ),
      ],
    );
  }

  Widget _buildSuccessBanner(Map<String, dynamic> overview) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.cloud_done_rounded, color: AppTheme.successColor, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Live Real-Time Data', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.successColor, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Last updated: ${overview['last_updated']?.toString() ?? 'Just now'} · Critical alerts: ${overview['critical_alerts'] ?? 0}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Constituency Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildStatCard('Total Voters', _fmtN(_n(overview['total_voters'])), 'Registered voters', Icons.how_to_vote_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Population', _fmtN(_n(overview['total_population'])), 'Total population', Icons.people_alt_rounded)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildStatCard('In Progress', '${_n(overview['promises_in_progress']).toInt()}', 'Promises in progress', Icons.engineering_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Alerts', '${_n(overview['critical_alerts']).toInt()}', 'Critical alerts', Icons.crisis_alert_rounded)),
        ]),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
