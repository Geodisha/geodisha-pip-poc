/// GeoDisha Design System — reusable professional widgets
library gd_widgets;

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GD STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class GDStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? trend;
  final int delay;

  const GDStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (trend != null)
                    _TrendBadge(trend: trend!),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double trend;
  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isPositive = trend >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10, color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class GDSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const GDSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
        ],
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              foregroundColor: AppTheme.accentColor,
            ),
            child: Text(actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class GDStatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const GDStatusBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD PROGRESS ROW
// ─────────────────────────────────────────────────────────────────────────────
class GDProgressRow extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final Color? color;
  final String? valueLabel;

  const GDProgressRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
              Text(
                valueLabel ?? '${(value * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: value.clamp(0.0, 1.0),
            backgroundColor: c.withValues(alpha: 0.12),
            progressColor: c,
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 800,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD ALERT CARD
// ─────────────────────────────────────────────────────────────────────────────
class GDAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final int index;

  const GDAlertCard({super.key, required this.alert, required this.index});

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity']?.toString() ?? 'low';
    final color = AppTheme.statusColor(severity);
    final title = alert['title']?.toString() ?? 'Alert';
    final desc = alert['description']?.toString() ?? '';
    final category = alert['alert_category']?.toString().replaceAll('_', ' ') ?? '';
    final ward = alert['location_ward']?.toString() ?? '';
    final urgency = alert['urgency']?.toString() ?? '';

    return FadeInLeft(
      delay: Duration(milliseconds: index * 60),
      duration: const Duration(milliseconds: 350),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ),
                  GDStatusBadge(label: severity, color: color),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (category.isNotEmpty) _chip(category, Icons.category),
                  if (ward.isNotEmpty) _chip(ward, Icons.location_on),
                  if (urgency.isNotEmpty) _chip(urgency, Icons.timer),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppTheme.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GD SHIMMER LOADER
// ─────────────────────────────────────────────────────────────────────────────
class GDShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const GDShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 60,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class GDShimmerCard extends StatelessWidget {
  const GDShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GDShimmerBox(height: 14, width: 140),
            const SizedBox(height: 8),
            const GDShimmerBox(height: 10),
            const SizedBox(height: 6),
            GDShimmerBox(height: 10, width: 200),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD ERROR VIEW
// ─────────────────────────────────────────────────────────────────────────────
class GDErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const GDErrorView({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppTheme.errorColor),
            ),
            const SizedBox(height: 16),
            const Text('Unable to load data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              error?.toString().replaceAll('Exception: ', '') ?? 'Please check connection',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD MINI BAR CHART
// ─────────────────────────────────────────────────────────────────────────────
class GDMiniBarChart extends StatelessWidget {
  final String title;
  final Map<String, double> data;
  final Color barColor;

  const GDMiniBarChart({
    super.key,
    required this.title,
    required this.data,
    this.barColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            entries[i].key.length > 6 ? '${entries[i].key.substring(0, 5)}…' : entries[i].key,
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: barColor,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD DONUT CHART
// ─────────────────────────────────────────────────────────────────────────────
class GDDonutChart extends StatefulWidget {
  final String title;
  final Map<String, double> data;
  final List<Color>? colors;
  final String? centerText;

  const GDDonutChart({
    super.key,
    required this.title,
    required this.data,
    this.colors,
    this.centerText,
  });

  @override
  State<GDDonutChart> createState() => _GDDonutChartState();
}

class _GDDonutChartState extends State<GDDonutChart> {
  int _touchedIndex = -1;

  static const _defaultColors = [
    AppTheme.primaryColor, AppTheme.accentColor, AppTheme.successColor,
    AppTheme.warningColor, AppTheme.errorColor, AppTheme.infoColor,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final colors = widget.colors ?? _defaultColors;
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 32,
                    pieTouchData: PieTouchData(
                      touchCallback: (_, res) => setState(() {
                        _touchedIndex = res?.touchedSection?.touchedSectionIndex ?? -1;
                      }),
                    ),
                    sections: entries.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      return PieChartSectionData(
                        value: e.value.value,
                        color: colors[e.key % colors.length],
                        radius: isTouched ? 42 : 36,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value.key,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(e.value.value / total * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: colors[e.key % colors.length],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD SCROLLING TICKER (news/alerts marquee)
// ─────────────────────────────────────────────────────────────────────────────
class GDScrollingTicker extends StatefulWidget {
  final List<String> messages;
  final Color? backgroundColor;

  const GDScrollingTicker({super.key, required this.messages, this.backgroundColor});

  @override
  State<GDScrollingTicker> createState() => _GDScrollingTickerState();
}

class _GDScrollingTickerState extends State<GDScrollingTicker>
    with SingleTickerProviderStateMixin {
  late ScrollController _sc;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    _tick();
  }

  void _tick() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) break;
      setState(() => _current = (_current + 1) % widget.messages.length);
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 34,
      color: widget.backgroundColor ?? AppTheme.primaryDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.accentColor,
            child: const Row(
              children: [
                Icon(Icons.campaign, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
                child: child,
              ),
              child: Padding(
                key: ValueKey(_current),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.messages[_current],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GD MODULE CARD (dashboard quick access)
// ─────────────────────────────────────────────────────────────────────────────
class GDModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final int? badge;
  final int delay;

  const GDModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badge,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 380),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle grid / mesh overlay for depth
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(painter: _GridPainter()),
                ),
              ),
              // Top-right glow circle
              Positioned(
                top: -18, right: -18,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        if (badge != null && badge! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge! > 99 ? '99+' : '$badge',
                              style: TextStyle(
                                color: gradient.colors.first,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 10),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
