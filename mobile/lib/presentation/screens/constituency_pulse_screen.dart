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

/// Safely cast any Map to Map<String,dynamic> — handles Flutter Web's Map<dynamic,dynamic>
Map<String, dynamic> _asMap(dynamic v) {
  if (v == null) return {};
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return {};
}

/// Safely cast any value to List of Maps
List<Map<String, dynamic>> _asList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => _asMap(e)).toList();
  return [];
}

class ConstituencyPulseScreen extends StatefulWidget {
  const ConstituencyPulseScreen({super.key});
  @override
  State<ConstituencyPulseScreen> createState() => _ConstituencyPulseScreenState();
}

class _ConstituencyPulseScreenState extends State<ConstituencyPulseScreen>
    with SingleTickerProviderStateMixin {
  late IntelligenceService _svc;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _svc = IntelligenceService(ApiService());
    _tabs = TabController(length: 3, vsync: this);
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
            expandedHeight: 110,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 8, 16, 48),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Constituency Pulse',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.location_city_rounded, size: 16), text: 'Ward Intel'),
                Tab(icon: Icon(Icons.monitor_heart_rounded, size: 16), text: 'Monitoring'),
                Tab(icon: Icon(Icons.bar_chart_rounded, size: 16), text: 'KPI Trends'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _WardIntelTab(svc: _svc),
            _MonitoringTab(svc: _svc),
            _KpiTrendsTab(svc: _svc),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WARD INTELLIGENCE TAB
// ─────────────────────────────────────────────────────────────────
class _WardIntelTab extends StatefulWidget {
  final IntelligenceService svc;
  const _WardIntelTab({required this.svc});
  @override
  State<_WardIntelTab> createState() => _WardIntelTabState();
}

class _WardIntelTabState extends State<_WardIntelTab> {
  String _riskFilter = 'all';

  Color _riskColor(String? r) {
    switch (r?.toLowerCase()) {
      case 'critical': return AppTheme.errorColor;
      case 'high': return const Color(0xFFEA580C);
      case 'medium': return AppTheme.warningColor;
      default: return AppTheme.successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.svc.getWardIntelligence(limit: 50),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = _asList(snap.data?['data']);
        final filtered = _riskFilter == 'all' ? all
            : all.where((w) => w['risk_level']?.toString().toLowerCase() == _riskFilter).toList();

        final critCount  = all.where((w) => w['risk_level']?.toString().toLowerCase() == 'critical').length;
        final highCount  = all.where((w) => w['risk_level']?.toString().toLowerCase() == 'high').length;
        final attnCount  = all.where((w) => (w['attention_required'] == true || w['attention_required'] == 1)).length;
        final avgHealth  = all.isEmpty ? 0.0 : all.map((w) => _n(w['overall_health_score'])).reduce((a,b)=>a+b)/all.length;

        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Row(children: [
                _kpi('${all.length}', 'Wards', Icons.location_city_rounded, Colors.white),
                _kpi('$critCount', 'Critical', Icons.crisis_alert_rounded, const Color(0xFFFCA5A5)),
                _kpi('$highCount', 'High Risk', Icons.warning_rounded, const Color(0xFFFBBF24)),
                _kpi('$attnCount', 'Needs Attention', Icons.notifications_active_rounded, const Color(0xFFA5F3FC)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.favorite_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 8),
                const Text('Avg Health Score:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(width: 6),
                Text('${avgHealth.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const Text(' / 100', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                SizedBox(width: 120, child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (avgHealth / 100).clamp(0.0, 1.0), minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5EEAD4)),
                  ),
                )),
              ]),
            ]),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final f in ['all', 'critical', 'high', 'medium', 'low'])
                Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
                  label: Text(f == 'all' ? 'All' : '${f[0].toUpperCase()}${f.substring(1)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _riskFilter == f ? _riskColor(f) : AppTheme.textSecondary)),
                  selected: _riskFilter == f,
                  onSelected: (_) => setState(() => _riskFilter = f),
                  selectedColor: _riskColor(f).withValues(alpha: 0.12),
                )),
            ])),
          )),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => FadeInUp(
                delay: Duration(milliseconds: i * 40),
                duration: const Duration(milliseconds: 300),
                child: _WardCard(ward: filtered[i], riskColor: _riskColor),
              ),
              childCount: filtered.length,
            )),
          ),
        ]);
      },
    );
  }

  Widget _kpi(String val, String lbl, IconData icon, Color color) => Expanded(child: Column(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(height: 3),
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
    Text(lbl, style: const TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center, maxLines: 2),
  ]));
}

class _WardCard extends StatelessWidget {
  final Map<String, dynamic> ward;
  final Color Function(String?) riskColor;
  const _WardCard({required this.ward, required this.riskColor});

  @override
  Widget build(BuildContext context) {
    final name         = ward['ward_name']?.toString() ?? 'Unknown Ward';
    final risk         = ward['risk_level']?.toString() ?? 'low';
    final health       = _n(ward['overall_health_score']);
    final infra        = _n(ward['infrastructure_score']);
    final safety       = _n(ward['safety_score']);
    final satisfaction = _n(ward['satisfaction_score']);
    final development  = _n(ward['development_score']);
    final visibility   = _n(ward['leader_visibility_score']);
    final volunteers   = _n(ward['active_volunteers']).toInt();
    final oppLevel     = ward['opposition_activity_level']?.toString() ?? 'low';
    final compThreat   = _n(ward['competitive_threat_score']);
    final voters       = _n(ward['total_voters']).toInt();
    final attention    = ward['attention_required'] == true || ward['attention_required'] == 1;
    final lastVisit    = ward['last_leader_visit_date']?.toString() ?? '—';
    final rColor       = riskColor(risk);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: rColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.location_city_rounded, color: rColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                if (attention) const Icon(Icons.notifications_active_rounded, color: AppTheme.errorColor, size: 16),
              ]),
              const SizedBox(height: 2),
              Text('${_fmtV(voters)} voters  •  Last Visit: $lastVisit',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: rColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(risk.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: rColor)),
              ),
              const SizedBox(height: 4),
              Text('${health.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: rColor)),
              const Text('health', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 12),
          // Score grid
          Row(children: [
            _scoreBox('Infra', infra, const Color(0xFF0EA5E9)),
            _scoreBox('Safety', safety, const Color(0xFF8B5CF6)),
            _scoreBox('Satisfaction', satisfaction, AppTheme.successColor),
            _scoreBox('Development', development, AppTheme.warningColor),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _chip(Icons.visibility_rounded, 'Leader Visibility: ${visibility.toStringAsFixed(0)}%', AppTheme.primaryColor),
            const SizedBox(width: 8),
            _chip(Icons.volunteer_activism_rounded, '$volunteers volunteers', AppTheme.successColor),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _chip(Icons.shield_rounded, 'Opp: $oppLevel', oppLevel == 'high' ? AppTheme.errorColor : AppTheme.warningColor),
            const SizedBox(width: 8),
            _chip(Icons.bar_chart_rounded, 'Threat: ${compThreat.toStringAsFixed(0)}', compThreat > 70 ? AppTheme.errorColor : AppTheme.textSecondary),
          ]),
        ]),
      ),
    );
  }

  Widget _scoreBox(String label, double val, Color color) => Expanded(child: Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: [
      Text('${val.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
      Text(label, style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.8)), textAlign: TextAlign.center),
    ]),
  ));

  Widget _chip(IconData icon, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  ]);

  String _fmtV(int v) => v >= 100000 ? '${(v/100000).toStringAsFixed(1)}L' : v >= 1000 ? '${(v/1000).toStringAsFixed(0)}K' : '$v';
}

// ─────────────────────────────────────────────────────────────────
// MONITORING DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────
// MONITORING TAB
// ─────────────────────────────────────────────────────────────────
class _MonitoringTab extends StatefulWidget {
  final IntelligenceService svc;
  const _MonitoringTab({required this.svc});
  @override
  State<_MonitoringTab> createState() => _MonitoringTabState();
}

class _MonitoringTabState extends State<_MonitoringTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.svc.getMonitoringLatest();
  }

  void _retry() => setState(() {
    _future = widget.svc.getMonitoringLatest();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.mediumGrey),
                const SizedBox(height: 12),
                Text(
                  snap.hasError ? 'Failed to load monitoring data' : 'No data available',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (snap.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    snap.error.toString().split('\n').first,
                    style: const TextStyle(fontSize: 11, color: AppTheme.mediumGrey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ]),
            ),
          );
        }

        final data      = _asMap(snap.data!['data']);
        final alerts    = _asMap(data['alert_counts']);
        final crises    = _asMap(data['crisis_counts']);
        final perf      = _asMap(data['response_performance']);
        final health    = _asMap(data['health_scores']);
        final alertsByCat = _asMap(data['alerts_by_category']);
        final hotspots  = _asList(data['hotspot_wards']);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Alert counts banner
            _SectionHeader(icon: Icons.notifications_rounded, title: 'Live Alert Counts', color: AppTheme.errorColor),
            const SizedBox(height: 10),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3,
              children: [
                _MonCard('Total Active', '${alerts['total_active'] ?? 0}', AppTheme.errorColor, Icons.circle_notifications_rounded),
                _MonCard('Critical', '${alerts['critical'] ?? 0}', const Color(0xFFDC2626), Icons.crisis_alert_rounded),
                _MonCard('High', '${alerts['high'] ?? 0}', const Color(0xFFEA580C), Icons.warning_rounded),
                _MonCard('New 24h', '${alerts['new_24h'] ?? 0}', AppTheme.infoColor, Icons.add_alert_rounded),
                _MonCard('Resolved 24h', '${alerts['resolved_24h'] ?? 0}', AppTheme.successColor, Icons.check_circle_rounded),
                _MonCard('Medium', '${alerts['medium'] ?? 0}', AppTheme.warningColor, Icons.info_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Health scores
            _SectionHeader(icon: Icons.favorite_rounded, title: 'Health Scores', color: AppTheme.successColor),
            const SizedBox(height: 10),
            ...health.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BarTile(e.key.replaceAll('_', ' ').toUpperCase(), _n(e.value), 100, AppTheme.successColor),
            )),
            const SizedBox(height: 16),

            // Response performance
            _SectionHeader(icon: Icons.speed_rounded, title: 'Response Performance', color: AppTheme.infoColor),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.2)),
              ),
              child: Column(children: [
                _perfRow('Avg Response Time', '${_n(perf['avg_response_time_mins']).toStringAsFixed(0)} mins', Icons.timer_rounded),
                _perfRow('Avg Resolution Time', '${_n(perf['avg_resolution_time_hours']).toStringAsFixed(1)} hrs', Icons.timelapse_rounded),
                _perfRow('On-Time Resolution', '${(_n(perf['on_time_resolution_rate']) * 100).toStringAsFixed(0)}%', Icons.check_rounded),
                _perfRow('Escalation Rate', '${(_n(perf['escalation_rate']) * 100).toStringAsFixed(0)}%', Icons.escalator_warning_rounded),
              ]),
            ),
            const SizedBox(height: 16),

            // Crisis counts
            _SectionHeader(icon: Icons.local_fire_department_rounded, title: 'Crisis Status', color: const Color(0xFFDC2626)),
            const SizedBox(height: 10),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2,
              children: [
                _MonCard('Active Crises', '${crises['active_crises'] ?? 0}', AppTheme.errorColor, Icons.local_fire_department_rounded),
                _MonCard('Resolved 7d', '${crises['resolved_crises_7d'] ?? 0}', AppTheme.successColor, Icons.done_all_rounded),
                _MonCard('New 7d', '${crises['new_crises_7d'] ?? 0}', AppTheme.warningColor, Icons.new_releases_rounded),
                _MonCard('Avg Resolution', '${_n(crises['average_resolution_time_hours']).toStringAsFixed(0)}h', AppTheme.infoColor, Icons.hourglass_bottom_rounded),
              ],
            ),
            const SizedBox(height: 16),

            // Alerts by category
            if (alertsByCat.isNotEmpty) ...[
              _SectionHeader(icon: Icons.category_rounded, title: 'Alerts by Category', color: AppTheme.primaryColor),
              const SizedBox(height: 10),
              ...alertsByCat.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BarTile(e.key.replaceAll('_', ' '), _n(e.value), (alertsByCat.values.map((v) => _n(v)).reduce((a,b)=>a>b?a:b)), AppTheme.primaryColor),
              )),
              const SizedBox(height: 16),
            ],

            // Hotspot wards
            if (hotspots.isNotEmpty) ...[
              _SectionHeader(icon: Icons.location_on_rounded, title: 'Hotspot Wards', color: AppTheme.errorColor),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: hotspots.take(10).map((w) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_fire_department_rounded, size: 12, color: AppTheme.errorColor),
                  const SizedBox(width: 4),
                  Text('${w['ward'] ?? ''} (${w['active_alerts'] ?? 0})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.errorColor)),
                ]),
              )).toList()),
              const SizedBox(height: 80),
            ],
          ]),
        );
      },
    );
  }

  Widget _perfRow(String label, String val, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 14, color: AppTheme.infoColor),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
  ]);
}

class _MonCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MonCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
      Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
        textAlign: TextAlign.center, maxLines: 2),
    ]),
  );
}

class _BarTile extends StatelessWidget {
  final String label;
  final double val;
  final double max;
  final Color color;
  const _BarTile(this.label, this.val, this.max, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
      value: max > 0 ? (val / max).clamp(0.0, 1.0) : 0,
      minHeight: 8,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(color),
    ))),
    const SizedBox(width: 8),
    Text('${val.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
  ]);
}

// ─────────────────────────────────────────────────────────────────
// KPI TRENDS TAB
// ─────────────────────────────────────────────────────────────────
class _KpiTrendsTab extends StatelessWidget {
  final IntelligenceService svc;
  const _KpiTrendsTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: svc.getConstituencyTrends(limit: 60),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = _asList(snap.data?['data']);
        final Map<String, List<Map<String, dynamic>>> byMetric = {};
        for (final r in all) {
          final m = r['metric_name']?.toString() ?? 'unknown';
          byMetric.putIfAbsent(m, () => []).add(r);
        }

        return ListView(padding: const EdgeInsets.all(16), children: [
          ...byMetric.entries.take(10).map((e) => FadeInLeft(
            duration: const Duration(milliseconds: 400),
            child: _TrendCard(metric: e.key, rows: e.value),
          )),
          const SizedBox(height: 80),
        ]);
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String metric;
  final List<Map<String, dynamic>> rows;
  const _TrendCard({required this.metric, required this.rows});

  @override
  Widget build(BuildContext context) {
    final latest = rows.isNotEmpty ? rows.first : <String, dynamic>{};
    final current   = _n(latest['current_value']);
    final previous  = _n(latest['previous_value']);
    final change    = _n(latest['change_value']);
    final changePct = _n(latest['change_percentage']);
    final direction = latest['trend_direction']?.toString() ?? 'stable';
    final benchmark = _n(latest['benchmark_value']);
    final period    = latest['analysis_period']?.toString() ?? '';

    final Color dirColor = direction == 'up' ? AppTheme.successColor
        : direction == 'down' ? AppTheme.errorColor : AppTheme.warningColor;
    final IconData dirIcon = direction == 'up' ? Icons.trending_up_rounded
        : direction == 'down' ? Icons.trending_down_rounded : Icons.trending_flat_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dirColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(metric.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.textSecondary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: dirColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(dirIcon, size: 12, color: dirColor),
              const SizedBox(width: 3),
              Text(direction.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: dirColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${current.toStringAsFixed(1)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: dirColor)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} (${changePct.toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dirColor)),
              Text('vs prev: ${previous.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ]),
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Benchmark', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            Text('${benchmark.toStringAsFixed(1)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            if (period.isNotEmpty) Text(period, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
          ]),
        ]),
        const SizedBox(height: 8),
        // Progress against benchmark
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
          value: benchmark > 0 ? (current / benchmark).clamp(0.0, 1.0) : 0,
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(dirColor),
        )),
        const SizedBox(height: 4),
        Text('${((current / (benchmark > 0 ? benchmark : 1)) * 100).toStringAsFixed(0)}% of benchmark',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ]),
    );
  }
}
