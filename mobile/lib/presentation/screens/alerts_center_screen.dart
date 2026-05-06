import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/alerts_crisis_service.dart';
import '../../data/services/intelligence_service.dart';
import '../../core/services/api_service.dart';
import 'raise_alert_screen.dart';

double _n(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

class AlertsCenterScreen extends ConsumerStatefulWidget {
  const AlertsCenterScreen({super.key});
  @override
  ConsumerState<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends ConsumerState<AlertsCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AlertsCrisisService _service;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service = AlertsCrisisService(ApiService());
    _intelService = IntelligenceService(ApiService());
  }

  late IntelligenceService _intelService;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _sevColor(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'critical': return AppTheme.errorColor;
      case 'high':     return const Color(0xFFEA580C);
      case 'medium':   return AppTheme.warningColor;
      default:         return AppTheme.successColor;
    }
  }

  IconData _sevIcon(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'critical': return Icons.crisis_alert_rounded;
      case 'high':     return Icons.warning_rounded;
      case 'medium':   return Icons.info_rounded;
      default:         return Icons.check_circle_rounded;
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'law_order': return Icons.gavel_rounded;
      case 'infrastructure': return Icons.construction_rounded;
      case 'health': return Icons.local_hospital_rounded;
      case 'water': return Icons.water_drop_rounded;
      case 'election': return Icons.how_to_vote_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Alerts & Crisis Centre'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Active'),
            Tab(icon: Icon(Icons.alarm_rounded, size: 18), text: 'Reminders'),
            Tab(icon: Icon(Icons.escalator_warning_rounded, size: 18), text: 'Escalations'),
            Tab(icon: Icon(Icons.crisis_alert_rounded, size: 18), text: 'Crisis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertsTab(service: _service, isReminders: false, sevColor: _sevColor, sevIcon: _sevIcon, catIcon: _categoryIcon),
          _AlertsTab(service: _service, isReminders: true,  sevColor: _sevColor, sevIcon: _sevIcon, catIcon: _categoryIcon),
          _EscalationsTab(intelService: _intelService),
          _CrisisTab(service: _service),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseAlertScreen()));
          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text('Alert submitted')]),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Raise Alert', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

// ─── Alerts Tab ──────────────────────────────────────────────────────────────
class _AlertsTab extends StatefulWidget {
  final AlertsCrisisService service;
  final bool isReminders;
  final Color Function(String?) sevColor;
  final IconData Function(String?) sevIcon;
  final IconData Function(String?) catIcon;
  const _AlertsTab({required this.service, required this.isReminders, required this.sevColor, required this.sevIcon, required this.catIcon});

  @override
  State<_AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<_AlertsTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.isReminders ? widget.service.getReminders() : widget.service.getActiveAlerts(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 12), height: 110,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
        if (snap.hasError) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Failed to load', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
          ]));
        }

        final all = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();
        // Sort critical first, take top 10
        final sevOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
        final sorted = [...all]..sort((a, b) =>
          (sevOrder[a['severity']?.toLowerCase()] ?? 4).compareTo(sevOrder[b['severity']?.toLowerCase()] ?? 4));
        final alerts = sorted.take(10).toList();

        if (alerts.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline_rounded, size: 72, color: AppTheme.successColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(widget.isReminders ? 'No reminders' : 'No active alerts',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ]));
        }

        // Severity summary counts
        final counts = <String, int>{};
        for (final a in alerts) {
          final s = a['severity']?.toString().toLowerCase() ?? 'low';
          counts[s] = (counts[s] ?? 0) + 1;
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              // Summary bar
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Text('Top ${alerts.length} alerts', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary)),
                    const Spacer(),
                    for (final sev in ['critical', 'high', 'medium', 'low'])
                      if ((counts[sev] ?? 0) > 0)
                        _SevBadge(label: sev, count: counts[sev]!, color: widget.sevColor(sev)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 60),
                      duration: const Duration(milliseconds: 350),
                      child: _AlertCard(alert: alerts[i], sevColor: widget.sevColor, sevIcon: widget.sevIcon, catIcon: widget.catIcon),
                    ),
                    childCount: alerts.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SevBadge extends StatelessWidget {
  final String label; final int count; final Color color;
  const _SevBadge({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text('$count ${label[0].toUpperCase()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

// ─── Alert Card ──────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Color Function(String?) sevColor;
  final IconData Function(String?) sevIcon;
  final IconData Function(String?) catIcon;
  const _AlertCard({required this.alert, required this.sevColor, required this.sevIcon, required this.catIcon});

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity']?.toString() ?? 'low';
    final color    = sevColor(severity);
    final title    = alert['title']?.toString() ?? 'Untitled Alert';
    final desc     = alert['description']?.toString() ?? '';
    final ward     = alert['location_ward']?.toString() ?? '';
    final category = alert['alert_category']?.toString() ?? '';
    final urgency  = alert['urgency']?.toString().replaceAll('_', ' ') ?? '';
    final affected = alert['estimated_voters_affected'];
    final polRisk  = alert['political_risk_score'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _AlertDetailSheet(alert: alert, sevColor: sevColor, catIcon: catIcon),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(sevIcon(severity), color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(severity.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color))),
              ]),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (ward.isNotEmpty)     _Chip(Icons.location_on_rounded, ward),
                if (category.isNotEmpty) _Chip(catIcon(category), category.replaceAll('_', ' ')),
                if (urgency.isNotEmpty)  _Chip(Icons.schedule_rounded, urgency),
                if (affected != null)    _Chip(Icons.people_rounded, '${_n(affected).toInt()} voters'),
              ]),
              if (polRisk != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Political Risk ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _n(polRisk) / 100, minHeight: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _n(polRisk) > 70 ? AppTheme.errorColor :
                        _n(polRisk) > 40 ? AppTheme.warningColor : AppTheme.successColor),
                    ))),
                  const SizedBox(width: 6),
                  Text('${_n(polRisk).toInt()}', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _n(polRisk) > 70 ? AppTheme.errorColor : AppTheme.textSecondary)),
                ]),
              ],
            ])),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon; final String label;
  const _Chip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: AppTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]),
  );
}

class _AlertDetailSheet extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Color Function(String?) sevColor;
  final IconData Function(String?) catIcon;
  const _AlertDetailSheet({required this.alert, required this.sevColor, required this.catIcon});

  @override
  Widget build(BuildContext context) {
    final sev = alert['severity']?.toString() ?? 'low';
    final color = sevColor(sev);
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.92, minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
            Row(children: [
              Container(width: 50, height: 50,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.crisis_alert_rounded, color: color, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(alert['title']?.toString() ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(sev.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
              ])),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _Row('Category',       alert['alert_category']?.toString().replaceAll('_', ' ') ?? '—'),
            _Row('Ward',           alert['location_ward']?.toString() ?? '—'),
            _Row('Urgency',        alert['urgency']?.toString().replaceAll('_', ' ') ?? '—'),
            _Row('Type',           alert['alert_type']?.toString() ?? '—'),
            _Row('Reported by',    alert['reported_by']?.toString() ?? '—'),
            _Row('Voters affected','${_n(alert['estimated_voters_affected']).toInt()}'),
            _Row('People affected','${_n(alert['estimated_people_affected']).toInt()}'),
            _Row('Political risk', '${_n(alert['political_risk_score']).toInt()} / 100'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            Text(alert['description']?.toString() ?? '—',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Acknowledge'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Escalate'),
              )),
            ]),
          ])),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );
}

// ─── Crisis Tab ───────────────────────────────────────────────────────────────
class _CrisisTab extends StatefulWidget {
  final AlertsCrisisService service;
  const _CrisisTab({required this.service});
  @override State<_CrisisTab> createState() => _CrisisTabState();
}

class _CrisisTabState extends State<_CrisisTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  Color _c(String? s) {
    switch (s?.toLowerCase()) {
      case 'critical': case 'severe': return AppTheme.errorColor;
      case 'high': return const Color(0xFFEA580C);
      case 'moderate': return AppTheme.warningColor;
      default: return AppTheme.successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.service.getCrisisDashboard(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
        ]));

        final crises = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>().take(5).toList();

        if (crises.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shield_outlined, size: 72, color: AppTheme.successColor.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('No active crises', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const Text('Constituency is stable', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ]));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: crises.length,
          itemBuilder: (ctx, i) {
            final cr = crises[i];
            final sev = cr['severity_level']?.toString() ?? 'low';
            final color = _c(sev);
            final impact = (cr['impact_metrics'] is Map) ? cr['impact_metrics'] as Map : <String, dynamic>{};
            return FadeInUp(
              delay: Duration(milliseconds: i * 80),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.crisis_alert_rounded, color: color, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cr['crisis_name']?.toString() ?? 'Crisis',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(cr['crisis_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? '',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(sev.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color))),
                        const SizedBox(height: 4),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.infoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text((cr['status']?.toString() ?? '').toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.infoColor))),
                      ]),
                    ]),
                    const SizedBox(height: 10),
                    Text(cr['description']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (impact.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(children: [
                        _IStat('Affected', _fmtK(_n(impact['people_affected'])), Icons.people_rounded),
                        _IStat('Voters',   _fmtK(_n(impact['voters_affected'])), Icons.how_to_vote_rounded),
                        _IStat('Duration', '${_n(cr['duration_hours']).toStringAsFixed(0)}h', Icons.timer_rounded),
                      ]),
                    ],
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }
  String _fmtK(double v) => v >= 1000 ? '${(v/1000).toStringAsFixed(1)}K' : '${v.toInt()}';
}

class _IStat extends StatelessWidget {
  final String label, value; final IconData icon;
  const _IStat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 14, color: AppTheme.textSecondary),
    const SizedBox(width: 4),
    Column(children: [
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
    ]),
  ]));
}

// ═══════════════════════════════════════════════════════════════════
// ESCALATIONS TAB  — CSV 23
// ═══════════════════════════════════════════════════════════════════
class _EscalationsTab extends StatefulWidget {
  final IntelligenceService intelService;
  const _EscalationsTab({required this.intelService});
  @override
  State<_EscalationsTab> createState() => _EscalationsTabState();
}

class _EscalationsTabState extends State<_EscalationsTab> {
  String _statusFilter = 'all';

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'resolved': return AppTheme.successColor;
      case 'in_progress': case 'in progress': return AppTheme.infoColor;
      case 'pending': case 'open': return AppTheme.warningColor;
      case 'escalated': return AppTheme.errorColor;
      default: return AppTheme.mediumGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.intelService.getAlertEscalations(limit: 50),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();
        final filtered = _statusFilter == 'all' ? all
            : all.where((e) => e['status']?.toString().toLowerCase() == _statusFilter).toList();

        final breached = all.where((e) => e['sla_breached'] == true || e['sla_breached'] == 1 || e['sla_breached']?.toString().toLowerCase() == 'true').length;
        final pending  = all.where((e) => e['status']?.toString().toLowerCase() == 'pending').length;
        final resolved = all.where((e) => e['status']?.toString().toLowerCase() == 'resolved').length;
        final critical = all.where((e) => e['priority']?.toString().toLowerCase() == 'critical').length;

        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              _kpiBox('${all.length}', 'Total', Colors.white, Icons.list_alt_rounded),
              _kpiBox('$breached', 'SLA Breach', const Color(0xFFFCA5A5), Icons.timer_off_rounded),
              _kpiBox('$pending', 'Pending', const Color(0xFFFBBF24), Icons.pending_rounded),
              _kpiBox('$resolved', 'Resolved', const Color(0xFF86EFAC), Icons.done_all_rounded),
              _kpiBox('$critical', 'Critical', const Color(0xFFF87171), Icons.crisis_alert_rounded),
            ]),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final f in ['all', 'pending', 'in_progress', 'resolved', 'escalated'])
                Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
                  label: Text(f == 'all' ? 'All' : f.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _statusFilter == f ? _statusColor(f) : AppTheme.textSecondary)),
                  selected: _statusFilter == f,
                  onSelected: (_) => setState(() => _statusFilter = f),
                  selectedColor: _statusColor(f).withValues(alpha: 0.12),
                )),
            ])),
          )),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final e = filtered[i];
                final status    = e['status']?.toString() ?? 'pending';
                final priority  = e['priority']?.toString() ?? 'medium';
                final issueType = e['issue_type']?.toString().replaceAll('_', ' ') ?? '';
                final category  = e['issue_category']?.toString().replaceAll('_', ' ') ?? '';
                final level     = e['escalation_level']?.toString() ?? '1';
                final slaBreached = e['sla_breached'] == true || e['sla_breached'] == 1 || e['sla_breached']?.toString().toLowerCase() == 'true';
                final daysSince = _n(e['days_since_reported']).toInt();
                final description = e['issue_description']?.toString() ?? '';
                final reason    = e['escalation_reason']?.toString() ?? '';
                final assignedTo = e['assigned_to']?.toString() ?? 'Unassigned';
                final sColor    = _statusColor(status);

                return FadeInUp(
                  delay: Duration(milliseconds: i * 40),
                  duration: const Duration(milliseconds: 280),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sColor.withValues(alpha: 0.25), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.escalator_warning_rounded, color: sColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(issueType, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Text('$category · Level $level escalation', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            _badge(status.replaceAll('_', ' ').toUpperCase(), sColor),
                            if (slaBreached) ...[const SizedBox(height: 4), _badge('SLA BREACH', AppTheme.errorColor)],
                          ]),
                        ]),
                        const SizedBox(height: 8),
                        if (description.isNotEmpty)
                          Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Wrap(spacing: 10, runSpacing: 4, children: [
                          _chip(Icons.timer_rounded, '$daysSince days old', daysSince > 14 ? AppTheme.errorColor : AppTheme.warningColor),
                          _chip(Icons.priority_high_rounded, priority, priority == 'critical' ? AppTheme.errorColor : AppTheme.warningColor),
                          _chip(Icons.person_pin_rounded, assignedTo, AppTheme.infoColor),
                        ]),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border(left: BorderSide(color: AppTheme.warningColor, width: 3)),
                            ),
                            child: Text('Reason: $reason', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ]),
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            )),
          ),
        ]);
      },
    );
  }

  Widget _kpiBox(String val, String lbl, Color color, IconData icon) => Expanded(child: Column(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(height: 2),
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
    Text(lbl, style: const TextStyle(color: Colors.white54, fontSize: 8), textAlign: TextAlign.center, maxLines: 2),
  ]));

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(t, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: c)),
  );

  Widget _chip(IconData icon, String t, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: c),
    const SizedBox(width: 3),
    Text(t, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600)),
  ]);
}
