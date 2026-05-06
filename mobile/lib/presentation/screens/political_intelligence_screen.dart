import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../data/services/intelligence_service.dart';

double _n(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

/// Safely parse a field that may be a native List OR a JSON-encoded string
List<String> _parseStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
  }
  return [];
}

/// Parse a List<Map> that may be JSON-encoded
List<Map<String, dynamic>> _parseMapList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  if (v is String) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) return decoded.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (_) {}
  }
  return [];
}

class PoliticalIntelligenceScreen extends StatefulWidget {
  const PoliticalIntelligenceScreen({super.key});
  @override
  State<PoliticalIntelligenceScreen> createState() => _PoliticalIntelligenceScreenState();
}

class _PoliticalIntelligenceScreenState extends State<PoliticalIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late IntelligenceService _svc;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _svc = IntelligenceService(ApiService());
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Political Intelligence', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(child: Icon(Icons.how_to_vote_rounded, size: 50, color: Colors.white12)),
              ),
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.amberAccent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.pie_chart_rounded, size: 18), text: 'Voter Segments'),
                Tab(icon: Icon(Icons.shield_rounded, size: 18), text: 'Opposition Intel'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _VoterSegmentsTab(svc: _svc),
            _OppositionIntelTab(svc: _svc),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// VOTER SEGMENTS TAB
// ─────────────────────────────────────────────────────────────────
class _VoterSegmentsTab extends StatefulWidget {
  final IntelligenceService svc;
  const _VoterSegmentsTab({required this.svc});
  @override
  State<_VoterSegmentsTab> createState() => _VoterSegmentsTabState();
}

class _VoterSegmentsTabState extends State<_VoterSegmentsTab> {
  String _priorityFilter = 'all';

  Color _supportColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'strong_support': case 'strong support': return AppTheme.successColor;
      case 'leaning_support': case 'leaning support': return const Color(0xFF86EFAC);
      case 'swing': case 'undecided': return AppTheme.warningColor;
      case 'leaning_opposition': return const Color(0xFFFCA5A5);
      case 'opposition': return AppTheme.errorColor;
      default: return AppTheme.mediumGrey;
    }
  }

  Color _priorityColor(String? p) {
    switch (p?.toLowerCase()) {
      case 'critical': return AppTheme.errorColor;
      case 'high': return const Color(0xFFEA580C);
      case 'medium': return AppTheme.warningColor;
      default: return AppTheme.successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.svc.getVoterSegments(limit: 50),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();
        final filtered = _priorityFilter == 'all'
            ? all
            : all.where((s) => s['priority_level']?.toString().toLowerCase() == _priorityFilter).toList();

        // Summary stats
        final totalVoters = all.fold<int>(0, (s, r) => s + (_n(r['total_voters']).toInt()));
        final swingCount = all.where((r) => r['support_level']?.toString().toLowerCase().contains('swing') ?? false).length;
        final highPriority = all.where((r) => r['priority_level']?.toString().toLowerCase() == 'high' || r['priority_level']?.toString().toLowerCase() == 'critical').length;
        final avgEngagement = all.isEmpty ? 0.0 : all.map((r) => _n(r['engagement_score'])).reduce((a, b) => a + b) / all.length;

        return CustomScrollView(
          slivers: [
            // Summary banner
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Row(children: [
                  _kpi('${all.length}', 'Segments', Icons.donut_large_rounded, Colors.amberAccent),
                  _kpi(_fmtNum(totalVoters), 'Total Voters', Icons.people_rounded, const Color(0xFF64B5F6)),
                  _kpi('$swingCount', 'Swing', Icons.swap_horiz_rounded, AppTheme.warningColor),
                  _kpi('$highPriority', 'High Priority', Icons.priority_high_rounded, AppTheme.errorColor),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                  const SizedBox(width: 8),
                  const Text('Avg Engagement Score:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text('${avgEngagement.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  SizedBox(width: 100, child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (avgEngagement / 100).clamp(0.0, 1.0), minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    ),
                  )),
                ]),
              ]),
            )),
            // Filter chips
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                for (final f in ['all', 'critical', 'high', 'medium', 'low'])
                  Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
                    label: Text(f == 'all' ? 'All (${all.length})' : '${f[0].toUpperCase()}${f.substring(1)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _priorityFilter == f ? _priorityColor(f) : AppTheme.textSecondary)),
                    selected: _priorityFilter == f,
                    onSelected: (_) => setState(() => _priorityFilter = f),
                    selectedColor: _priorityColor(f).withValues(alpha: 0.12),
                  )),
              ])),
            )),
            // Segment cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeInUp(
                  delay: Duration(milliseconds: i * 50),
                  duration: const Duration(milliseconds: 300),
                  child: _SegmentCard(segment: filtered[i], supportColor: _supportColor, priorityColor: _priorityColor),
                ),
                childCount: filtered.length,
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _kpi(String val, String lbl, IconData icon, Color color) => Expanded(child: Column(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(height: 3),
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
    Text(lbl, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
  ]));

  String _fmtNum(int v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}K' : '$v';
}

class _SegmentCard extends StatelessWidget {
  final Map<String, dynamic> segment;
  final Color Function(String?) supportColor;
  final Color Function(String?) priorityColor;
  const _SegmentCard({required this.segment, required this.supportColor, required this.priorityColor});

  // ── shared parsing so both build() and _showDetail() see the same values ──
  Map<String, dynamic> get _supportMap {
    final raw = segment['support_level'];
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String) {
      try { return (jsonDecode(raw) as Map).cast<String, dynamic>(); } catch (_) {}
    }
    return {};
  }
  String get _supportLabel {
    final m = _supportMap;
    final sf = _n(m['strong_favorable']);
    final op = _n(m['opposition']);
    return sf > op ? (sf > 50000 ? 'strong_support' : 'leaning_support')
        : op > sf ? 'opposition' : 'swing';
  }
  double get _engagement  => _n(segment['engagement_score']);
  double get _coverage    => _n(segment['contact_coverage_pct']);
  double get _loyalty     => _n(segment['loyalty_score']);
  String get _turnout     => segment['turnout_tendency']?.toString() ?? '';
  String get _topIssuesList => _parseMapList(segment['top_issues'])
      .map((i) => i['issue']?.toString() ?? '').where((s) => s.isNotEmpty).take(3).join(', ');
  String get _targetMsgList => _parseStringList(segment['target_message']).take(2).join(' · ');

  @override
  Widget build(BuildContext context) {
    final name         = segment['segment_name']?.toString().replaceAll('_', ' ') ?? '';
    final type         = segment['segment_type']?.toString().replaceAll('_', ' ') ?? '';
    final priority     = segment['priority_level']?.toString() ?? 'low';
    final supportMap   = _supportMap;
    final supportLabel = _supportLabel;
    final total        = _n(segment['total_voters']).toInt();
    final pct          = _n(segment['percentage_of_total']);
    final engagement   = _engagement;
    final coverage     = _coverage;
    final loyalty      = _loyalty;
    final turnout      = _turnout;
    final topIssuesList = _topIssuesList;
    final targetMsgList = _targetMsgList;
    final pColor       = priorityColor(priority);
    final sColor       = supportColor(supportLabel);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pColor.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [pColor, pColor.withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(type, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _badge(priority.toUpperCase(), pColor),
                const SizedBox(height: 4),
                _badge(supportLabel.replaceAll('_', ' '), sColor),
              ]),
            ]),
            const SizedBox(height: 10),
            // Key metrics
            Row(children: [
              _metric(Icons.people_rounded, '${_fmtV(total)} voters', AppTheme.infoColor),
              _metric(Icons.percent_rounded, '${pct.toStringAsFixed(1)}% share', AppTheme.primaryColor),
              _metric(Icons.trending_up_rounded, turnout.replaceAll('_', ' '), AppTheme.warningColor),
            ]),
            const SizedBox(height: 10),
            // Progress bars
            _bar('Engagement', engagement, 100, AppTheme.successColor),
            const SizedBox(height: 5),
            _bar('Coverage', coverage, 100, AppTheme.infoColor),
            const SizedBox(height: 5),
            _bar('Loyalty', loyalty, 100, AppTheme.warningColor),
            if (targetMsgList.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: Color(0xFF6366F1), width: 3)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.campaign_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(targetMsgList,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: c)),
  );

  Widget _metric(IconData icon, String label, Color color) => Expanded(child: Row(children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 3),
    Expanded(child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]));

  Widget _bar(String label, double val, double max, Color color) => Row(children: [
    SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
      value: (val / max).clamp(0.0, 1.0), minHeight: 5,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ))),
    const SizedBox(width: 6),
    Text('${val.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  ]);

  String _fmtV(int v) => v >= 100000 ? '${(v/100000).toStringAsFixed(1)}L' : v >= 1000 ? '${(v/1000).toStringAsFixed(0)}K' : '$v';

  void _showDetail(BuildContext context) {
    final supportMap    = _supportMap;
    final turnout       = _turnout;
    final loyalty       = _loyalty;
    final engagement    = _engagement;
    final coverage      = _coverage;
    final targetMsgList = _targetMsgList;
    final topIssuesList = _topIssuesList;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65, maxChildSize: 0.92, minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
              Text(segment['segment_name']?.toString().replaceAll('_', ' ') ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _dRow('Type', segment['segment_type']?.toString().replaceAll('_', ' ') ?? '—'),
              _dRow('Total Voters', _fmtV(_n(segment['total_voters']).toInt())),
              _dRow('Share', '${_n(segment['percentage_of_total']).toStringAsFixed(1)}%'),
              _dRow('Strong Favorable', _fmtV(_n(supportMap['strong_favorable']).toInt())),
              _dRow('Leaning Favorable', _fmtV(_n(supportMap['leaning_favorable']).toInt())),
              _dRow('Undecided', _fmtV(_n(supportMap['undecided']).toInt())),
              _dRow('Opposition', _fmtV(_n(supportMap['opposition']).toInt())),
              _dRow('Turnout', turnout.replaceAll('_', ' ')),
              _dRow('Loyalty Score', '${loyalty.toStringAsFixed(0)}'),
              _dRow('Engagement', '${engagement.toStringAsFixed(0)}%'),
              _dRow('Contact Coverage', '${coverage.toStringAsFixed(0)}%'),
              _dRow('Budget Allocated', '₹${_n(segment['budget_allocated']).toStringAsFixed(0)}'),
              _dRow('Volunteers', '${_n(segment['volunteers_assigned']).toInt()}'),
              _dRow('Events Planned', '${_n(segment['events_planned']).toInt()}'),
              if (targetMsgList.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Target Message', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(targetMsgList, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              ],
              if (topIssuesList.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Top Issues', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(topIssuesList, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 24),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _dRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 140, child: Text(l, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────
// OPPOSITION INTELLIGENCE TAB
// ─────────────────────────────────────────────────────────────────
class _OppositionIntelTab extends StatelessWidget {
  final IntelligenceService svc;
  const _OppositionIntelTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: svc.getOppositionIntelligence(limit: 30),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();

        // Summary stats
        final avgStrength = all.isEmpty ? 0.0 : all.map((r) => _n(r['overall_strength_score'])).reduce((a,b)=>a+b)/all.length;
        final growing = all.where((r) => r['trend']?.toString().toLowerCase() == 'growing').length;
        final declining = all.where((r) => r['trend']?.toString().toLowerCase() == 'declining').length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                _kpi('${all.length}', 'Parties', Icons.flag_rounded, Colors.white),
                _kpi('${avgStrength.toStringAsFixed(0)}', 'Avg Strength', Icons.bar_chart_rounded, const Color(0xFFFCA5A5)),
                _kpi('$growing', 'Growing', Icons.trending_up_rounded, const Color(0xFFFBBF24)),
                _kpi('$declining', 'Declining', Icons.trending_down_rounded, const Color(0xFF86EFAC)),
              ]),
            )),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeInRight(
                  delay: Duration(milliseconds: i * 60),
                  duration: const Duration(milliseconds: 350),
                  child: _OppositionCard(intel: all[i]),
                ),
                childCount: all.length,
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _kpi(String val, String lbl, IconData icon, Color color) => Expanded(child: Column(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(height: 3),
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
    Text(lbl, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center),
  ]));
}

class _OppositionCard extends StatelessWidget {
  final Map<String, dynamic> intel;
  const _OppositionCard({required this.intel});

  @override
  Widget build(BuildContext context) {
    final party      = intel['opposition_party']?.toString() ?? 'Unknown';
    final strength   = _n(intel['overall_strength_score']);
    final voteShare  = _n(intel['estimated_vote_share']) * 100;
    final trend      = intel['trend']?.toString() ?? 'stable';
    final intensity  = intel['campaign_intensity']?.toString() ?? 'low';
    final cProfile   = intel['candidate_profile'];
    final Map<String, dynamic> candidate = (cProfile is Map) ? cProfile.cast<String, dynamic>() : {};
    final attacks    = _parseStringList(intel['attack_lines']).take(3).toList();
    final counters   = _parseStringList(intel['recommended_counter_actions']).take(2).toList();
    final strongAreas = _parseStringList(intel['strong_areas']).take(3).toList();

    final Color trendColor = trend == 'growing' ? AppTheme.errorColor
        : trend == 'declining' ? AppTheme.successColor : AppTheme.warningColor;

    final Color intensityColor = intensity == 'high' ? AppTheme.errorColor
        : intensity == 'medium' ? AppTheme.warningColor : AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trendColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flag_rounded, color: trendColor, size: 22),
          ),
          title: Text(party, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Wrap(spacing: 6, children: [
              _chip('Strength: ${strength.toStringAsFixed(0)}', const Color(0xFF7F1D1D)),
              _chip('Vote: ${voteShare.toStringAsFixed(1)}%', AppTheme.infoColor),
              _chip(trend.toUpperCase(), trendColor),
              _chip(intensity, intensityColor),
            ]),
          ),
          children: [
            // Strength bar
            _barRow('Strength', strength, 100, const Color(0xFF7F1D1D)),
            const SizedBox(height: 6),
            _barRow('Vote Share', voteShare, 100, AppTheme.infoColor),
            const SizedBox(height: 12),

            // Candidate profile
            if (candidate.isNotEmpty) ...[
              const Text('Candidate Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (candidate['name'] != null) Text(candidate['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (candidate['background'] != null) Text(candidate['background'].toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  if (candidate['popularity_score'] != null) ...[
                    const SizedBox(height: 6),
                    _barRow('Popularity', _n(candidate['popularity_score']), 100, AppTheme.warningColor),
                  ],
                ]),
              ),
              const SizedBox(height: 10),
            ],

            // Attack lines
            if (attacks.isNotEmpty) ...[
              const Text('Attack Lines to Counter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.errorColor)),
              const SizedBox(height: 6),
              ...attacks.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.gps_fixed_rounded, size: 12, color: AppTheme.errorColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(a, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                ]),
              )),
              const SizedBox(height: 8),
            ],

            // Counter actions
            if (counters.isNotEmpty) ...[
              const Text('Recommended Counter Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.successColor)),
              const SizedBox(height: 6),
              ...counters.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
                ]),
              )),
              const SizedBox(height: 8),
            ],

            // Strong areas
            if (strongAreas.isNotEmpty) ...[
              const Text('Their Strong Areas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: strongAreas.map((a) => _chip(a, AppTheme.warningColor)).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c)),
  );

  Widget _barRow(String label, double val, double max, Color color) => Row(children: [
    SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
      value: (val / max).clamp(0.0, 1.0), minHeight: 5,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ))),
    const SizedBox(width: 6),
    Text('${val.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  ]);
}
