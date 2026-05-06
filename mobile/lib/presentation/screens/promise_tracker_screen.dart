import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/promises_service.dart';
import '../../core/services/api_service.dart';

double _n(dynamic v, [double d = 0]) {
  if (v == null) return d;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? d;
}

class PromiseTrackerScreen extends ConsumerStatefulWidget {
  const PromiseTrackerScreen({super.key});
  @override
  ConsumerState<PromiseTrackerScreen> createState() => _PromiseTrackerScreenState();
}

class _PromiseTrackerScreenState extends ConsumerState<PromiseTrackerScreen> {
  late PromisesService _service;
  String _filter = 'all';
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _service = PromisesService(ApiService());
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'completed':  return AppTheme.successColor;
      case 'in_progress':return AppTheme.infoColor;
      case 'delayed':    return AppTheme.errorColor;
      case 'at_risk':    return AppTheme.warningColor;
      default:           return AppTheme.mediumGrey;
    }
  }

  IconData _categoryIcon(String? c) {
    switch (c?.toLowerCase()) {
      case 'infrastructure': return Icons.construction_rounded;
      case 'healthcare':     return Icons.local_hospital_rounded;
      case 'education':      return Icons.school_rounded;
      case 'water':          return Icons.water_drop_rounded;
      case 'welfare':        return Icons.volunteer_activism_rounded;
      case 'agriculture':    return Icons.agriculture_rounded;
      case 'employment':     return Icons.work_rounded;
      default:               return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Promise Tracker'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getPromisesDashboard(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Failed to load promises'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
            ]));
          }

          final all = (snap.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();
          final filtered = _filter == 'all'
              ? all
              : all.where((p) => p['status']?.toString().toLowerCase() == _filter).toList();

          // Sort: delayed > at_risk > in_progress > announced > completed
          final statusOrder = {'delayed': 0, 'at_risk': 1, 'in_progress': 2, 'announced': 3, 'completed': 4};
          final sorted = [...filtered]..sort((a, b) =>
            (statusOrder[a['status']?.toLowerCase()] ?? 5)
              .compareTo(statusOrder[b['status']?.toLowerCase()] ?? 5));

          final displayLimit = _showAll ? sorted.length : 10;
          final promises = sorted.take(displayLimit).toList();

          // Stats
          final total      = all.length;
          final completed  = all.where((p) => p['status']?.toLowerCase() == 'completed').length;
          final inProgress = all.where((p) => p['status']?.toLowerCase() == 'in_progress').length;
          final delayed    = all.where((p) => p['status']?.toLowerCase() == 'delayed').length;
          final avgPct     = all.isEmpty ? 0.0 : all.map((p) => _n(p['completion_percentage'])).reduce((a,b)=>a+b)/all.length;

          return CustomScrollView(
            slivers: [
              // Header summary
              SliverToBoxAdapter(child: Container(
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(children: [
                  Row(children: [
                    _KpiBox('Total', '$total', Icons.flag_rounded, Colors.white),
                    _KpiBox('Completed', '$completed', Icons.check_circle_rounded, const Color(0xFF4CAF50)),
                    _KpiBox('In Progress', '$inProgress', Icons.pending_rounded, const Color(0xFF64B5F6)),
                    _KpiBox('Delayed', '$delayed', Icons.schedule_rounded, const Color(0xFFFF6B6B)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        const Text('Overall Completion', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const Spacer(),
                        Text('${avgPct.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                        value: (avgPct / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          avgPct >= 70 ? Colors.greenAccent : avgPct >= 40 ? Colors.orangeAccent : Colors.redAccent),
                      )),
                    ]),
                  ),
                ]),
              )),
              // Filter chips
              SliverToBoxAdapter(child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                  for (final f in ['all', 'delayed', 'in_progress', 'announced', 'completed'])
                    Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
                      label: Text(f == 'all' ? 'All' : f.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _filter == f ? AppTheme.primaryColor : AppTheme.textSecondary)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() { _filter = f; _showAll = false; }),
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                    )),
                ])),
              )),
              // Promise cards
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    duration: const Duration(milliseconds: 350),
                    child: _PromiseCard(promise: promises[i], statusColor: _statusColor, categoryIcon: _categoryIcon),
                  ),
                  childCount: promises.length,
                )),
              ),
              if (sorted.length > 10)
                SliverToBoxAdapter(child: Center(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showAll ? 'Show less' : 'View all ${sorted.length} promises'),
                  ),
                ))),
            ],
          );
        },
      ),
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String label, value; final IconData icon; final Color iconColor;
  const _KpiBox(this.label, this.value, this.icon, this.iconColor);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.only(right: 8, top: 12),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9), textAlign: TextAlign.center),
    ]),
  ));
}

class _PromiseCard extends StatelessWidget {
  final Map<String, dynamic> promise;
  final Color Function(String?) statusColor;
  final IconData Function(String?) categoryIcon;
  const _PromiseCard({required this.promise, required this.statusColor, required this.categoryIcon});

  @override
  Widget build(BuildContext context) {
    final title    = promise['promise_title']?.toString() ?? 'Untitled';
    final category = promise['promise_category']?.toString() ?? '';
    final status   = promise['status']?.toString() ?? '';
    final color    = statusColor(status);
    final pct      = _n(promise['completion_percentage']);
    final by       = promise['announced_by']?.toString() ?? '';
    final deadline = promise['target_completion_date']?.toString() ?? '';
    final locations = (promise['specific_locations'] as List? ?? []).take(3).join(', ');
    final milestones = promise['milestones'] as List? ?? [];
    final completedMs = milestones.where((m) => m['status']?.toString().toLowerCase() == 'completed').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(categoryIcon(category), color: color, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(category.replaceAll('_', ' '), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color))),
            ]),
            const SizedBox(height: 10),
            // Completion progress
            Row(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0), minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 70 ? AppTheme.successColor : pct >= 30 ? AppTheme.infoColor : AppTheme.warningColor),
              ))),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ]),
            const SizedBox(height: 8),
            // Meta
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (by.isNotEmpty)        _chip(Icons.person_rounded, by),
              if (deadline.isNotEmpty)  _chip(Icons.event_rounded, deadline),
              if (locations.isNotEmpty) _chip(Icons.location_on_rounded, locations),
              if (milestones.isNotEmpty) _chip(Icons.flag_rounded, '$completedMs/${milestones.length} milestones'),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: AppTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );

  void _showDetail(BuildContext context) {
    final milestones = (promise['milestones'] as List? ?? []).cast<Map>();
    final risks      = promise['risk_factors'] as List? ?? [];
    final pct        = _n(promise['completion_percentage']);
    final color      = statusColor(promise['status']?.toString() ?? '');
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
              Text(promise['promise_title']?.toString() ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(promise['promise_description']?.toString() ?? '',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 14),
              // Progress
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Completion', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 18)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                  value: (pct/100).clamp(0.0, 1.0), minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                )),
              ]),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _dRow('Announced by', promise['announced_by']?.toString() ?? '—'),
              _dRow('Category', promise['promise_category']?.toString().replaceAll('_', ' ') ?? '—'),
              _dRow('Type', promise['promise_type']?.toString().replaceAll('_', ' ') ?? '—'),
              _dRow('Target date', promise['target_completion_date']?.toString() ?? '—'),
              _dRow('Budget allocated', _fmtCurrency(_n(promise['budget_allocated']))),
              _dRow('Budget utilized', _fmtCurrency(_n(promise['budget_utilized']))),
              _dRow('Beneficiaries', '${_n(promise['estimated_beneficiaries_count']).toInt()}'),
              _dRow('Satisfaction', '${_n(promise['satisfaction_score'])}/100'),
              if (milestones.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Milestones', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final m in milestones)
                  _MilestoneTile(m),
              ],
              if (risks.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Risk Factors', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final r in risks)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                  ]),
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
      SizedBox(width: 130, child: Text(l, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );

  String _fmtCurrency(double v) {
    if (v >= 10000000) return '₹${(v/10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '₹${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '₹${(v/1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _MilestoneTile extends StatelessWidget {
  final Map m;
  const _MilestoneTile(this.m);
  @override
  Widget build(BuildContext context) {
    final status = m['status']?.toString().toLowerCase() ?? 'pending';
    final color = status == 'completed' ? AppTheme.successColor : status == 'in_progress' ? AppTheme.infoColor : AppTheme.mediumGrey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(status == 'completed' ? Icons.check_circle_rounded : status == 'in_progress' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['milestone_name']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (m['target_date'] != null)
            Text('Target: ${m['target_date']}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
    );
  }
}
