import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ai_intelligence_service.dart';
import '../../core/services/api_service.dart';

double _n(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});
  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  late AIIntelligenceService _service;
  String _filterPriority = 'all';
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _service = AIIntelligenceService(ApiService());
  }

  Color _priorityColor(String? p) {
    switch (p?.toLowerCase()) {
      case 'critical': return AppTheme.errorColor;
      case 'high':     return const Color(0xFFEA580C);
      case 'medium':   return AppTheme.warningColor;
      default:         return AppTheme.successColor;
    }
  }

  IconData _typeIcon(String? t) {
    switch (t?.toLowerCase()) {
      case 'visit_priority':    return Icons.place_rounded;
      case 'crisis_response':   return Icons.crisis_alert_rounded;
      case 'promise_follow_up': return Icons.task_alt_rounded;
      case 'community_outreach':return Icons.groups_rounded;
      case 'media_engagement':  return Icons.campaign_rounded;
      default:                  return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('AI Recommendations'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getRecommendations(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading AI insights...', style: TextStyle(color: AppTheme.textSecondary)),
            ]));
          }
          if (snap.hasError) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Failed to load recommendations'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
            ]));
          }

          final all = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();
          // filter
          final filtered = _filterPriority == 'all'
              ? all
              : all.where((r) => r['priority']?.toString().toLowerCase() == _filterPriority).toList();
          // sort: critical > high > medium > low, pending/in_progress first
          final statusOrder = {'pending': 0, 'in_progress': 1, 'completed': 2};
          final priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
          final sorted = [...filtered]..sort((a, b) {
            final sA = statusOrder[a['status']?.toLowerCase()] ?? 4;
            final sB = statusOrder[b['status']?.toLowerCase()] ?? 4;
            if (sA != sB) return sA.compareTo(sB);
            return (priorityOrder[a['priority']?.toLowerCase()] ?? 4)
                .compareTo(priorityOrder[b['priority']?.toLowerCase()] ?? 4);
          });

          final displayLimit = _showAll ? sorted.length : 8;
          final recs = sorted.take(displayLimit).toList();

          // summary stats
          final total     = all.length;
          final critical  = all.where((r) => r['priority']?.toLowerCase() == 'critical').length;
          final high      = all.where((r) => r['priority']?.toLowerCase() == 'high').length;
          final completed = all.where((r) => r['status']?.toLowerCase() == 'completed').length;
          final pending   = all.where((r) => r['status']?.toLowerCase() == 'pending' || r['status']?.toLowerCase() == 'in_progress').length;
          final avgConf   = all.isNotEmpty ? all.map((r) => _n(r['confidence_score'])).reduce((a, b) => a + b) / all.length : 0.0;

          return CustomScrollView(
            slivers: [
              // Summary header
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(children: [
                    Row(children: [
                      _SummCard('Total', '$total', Icons.psychology_rounded, Colors.white),
                      _SummCard('Critical', '$critical', Icons.crisis_alert_rounded, const Color(0xFFFF6B6B)),
                      _SummCard('Pending', '$pending', Icons.pending_actions_rounded, const Color(0xFFFFC107)),
                      _SummCard('Done', '$completed', Icons.check_circle_rounded, const Color(0xFF4CAF50)),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        const Text('Avg AI Confidence:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('${(avgConf * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        const Spacer(),
                        LinearProgressIndicator(
                          value: avgConf.clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          minHeight: 6,
                        ).let((w) => SizedBox(width: 80, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: w))),
                      ]),
                    ),
                  ]),
                ),
              ),
              // Filter chips
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                    for (final f in ['all', 'critical', 'high', 'medium', 'low'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f == 'all' ? 'All (${sorted.length})' : '${f[0].toUpperCase()}${f.substring(1)}'),
                          selected: _filterPriority == f,
                          onSelected: (_) => setState(() => _filterPriority = f),
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                          checkmarkColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: _filterPriority == f ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ])),
                ),
              ),
              // Recommendation cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 60),
                      duration: const Duration(milliseconds: 350),
                      child: _RecCard(
                        rec: recs[i],
                        priorityColor: _priorityColor,
                        typeIcon: _typeIcon,
                      ),
                    ),
                    childCount: recs.length,
                  ),
                ),
              ),
              // Show more button
              if (sorted.length > 8)
                SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                      label: Text(_showAll ? 'Show less' : 'Show all ${sorted.length} recommendations'),
                    ),
                  )),
                ),
            ],
          );
        },
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

class _SummCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  const _SummCard(this.label, this.value, this.icon, this.iconColor);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.only(right: 8, top: 12),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  ));
}

class _RecCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  final Color Function(String?) priorityColor;
  final IconData Function(String?) typeIcon;
  const _RecCard({required this.rec, required this.priorityColor, required this.typeIcon});

  @override
  Widget build(BuildContext context) {
    final priority   = rec['priority']?.toString() ?? 'low';
    final color      = priorityColor(priority);
    final status     = rec['status']?.toString() ?? '';
    final isComplete = status.toLowerCase() == 'completed';
    final title      = rec['title']?.toString() ?? 'Untitled';
    final desc       = rec['description']?.toString() ?? '';
    final type       = rec['recommendation_type']?.toString() ?? '';
    final confidence = _n(rec['confidence_score']);
    final impact     = _n(rec['impact_score']);
    final effort     = rec['effort_level']?.toString() ?? '';
    final timeline   = rec['estimated_timeline_days'];
    final outcomes   = rec['expected_outcomes'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.grey.shade200 : color.withValues(alpha: 0.25),
          width: isComplete ? 1 : 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: (isComplete ? Colors.grey : color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(typeIcon(type), color: isComplete ? Colors.grey : color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: isComplete ? Colors.grey : AppTheme.textPrimary,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(type.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(priority.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isComplete ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.infoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 8, fontWeight: FontWeight.w700,
                      color: isComplete ? AppTheme.successColor : AppTheme.infoColor))),
              ]),
            ]),
            const SizedBox(height: 10),
            Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            // Confidence + impact bars
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Confidence ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  Text('${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: confidence > 0.8 ? AppTheme.successColor : AppTheme.warningColor)),
                ]),
                const SizedBox(height: 3),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                  value: confidence.clamp(0.0, 1.0), minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    confidence > 0.8 ? AppTheme.successColor : AppTheme.warningColor),
                )),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Impact ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  Text('${impact.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                ]),
                const SizedBox(height: 3),
                ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                  value: (impact / 100).clamp(0.0, 1.0), minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                )),
              ])),
            ]),
            const SizedBox(height: 8),
            // Meta row
            Row(children: [
              if (effort.isNotEmpty) _chip(Icons.bolt_rounded, effort),
              if (timeline != null)  _chip(Icons.schedule_rounded, '${_n(timeline).toInt()} days'),
              const Spacer(),
              if (!isComplete)
                GestureDetector(
                  onTap: () => _showDetail(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Act Now', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: AppTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]),
  );

  void _showDetail(BuildContext context) {
    final outcomes = rec['expected_outcomes'] as List? ?? [];
    final risks    = rec['risks'] as List? ?? [];
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
              Text(rec['title']?.toString() ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(rec['description']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text('AI Reasoning', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(rec['ai_reasoning']?.toString() ?? '—', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4, fontStyle: FontStyle.italic)),
              if (outcomes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Expected Outcomes', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final o in outcomes)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.successColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text(o.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                  ]),
              ],
              if (risks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Risks', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final r in risks)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                  ]),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Mark as In Progress'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}
