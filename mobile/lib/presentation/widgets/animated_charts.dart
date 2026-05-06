import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

/// Animated Line Chart for trends and time series data
class AnimatedLineChart extends StatefulWidget {
  final List<FlSpot> dataPoints;
  final String title;
  final Color? lineColor;
  final Color? gradientStartColor;
  final Color? gradientEndColor;
  final bool showGrid;
  final bool showDots;
  final double minY;
  final double maxY;
  final List<String>? xLabels; // Optional labels for X axis

  const AnimatedLineChart({
    super.key,
    required this.dataPoints,
    required this.title,
    this.lineColor,
    this.gradientStartColor,
    this.gradientEndColor,
    this.showGrid = true,
    this.showDots = true,
    this.minY = 0,
    this.maxY = 100,
    this.xLabels,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.lineColor ?? AppTheme.primaryColor;
    final gradientStart = widget.gradientStartColor ?? lineColor.withOpacity(0.5);
    final gradientEnd = widget.gradientEndColor ?? lineColor.withOpacity(0.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      minY: widget.minY,
                      maxY: widget.maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: widget.dataPoints
                              .map((spot) => FlSpot(
                                    spot.x,
                                    spot.y * _animation.value,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: lineColor,
                          barWidth: 3,
                          dotData: FlDotData(show: widget.showDots),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [gradientStart, gradientEnd],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mediumGrey,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: widget.xLabels != null,
                            getTitlesWidget: (value, meta) {
                              if (widget.xLabels == null ||
                                  value.toInt() >= widget.xLabels!.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  widget.xLabels![value.toInt()],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.mediumGrey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: widget.showGrid,
                        drawVerticalLine: false,
                        horizontalInterval: (widget.maxY - widget.minY) / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.lightGrey,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: lineColor,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(1)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Bar Chart for comparisons
class AnimatedBarChart extends StatefulWidget {
  final Map<String, double> data; // Label -> Value
  final String title;
  final Color? barColor;
  final double maxY;

  const AnimatedBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor,
    this.maxY = 100,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBarColor(double value) {
    if (widget.barColor != null) return widget.barColor!;
    
    final percentage = (value / widget.maxY) * 100;
    if (percentage >= 80) return AppTheme.successColor;
    if (percentage >= 60) return AppTheme.secondaryColor;
    if (percentage >= 40) return AppTheme.accentColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      maxY: widget.maxY,
                      barGroups: entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = entry.value.value * _animation.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: _getBarColor(entry.value.value),
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  _getBarColor(entry.value.value),
                                  _getBarColor(entry.value.value).withOpacity(0.7),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mediumGrey,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  entries[value.toInt()].key,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.mediumGrey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: widget.maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.lightGrey,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: AppTheme.textPrimary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${entries[group.x.toInt()].key}\n${rod.toY.toStringAsFixed(1)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Pie Chart for distribution data
class AnimatedPieChart extends StatefulWidget {
  final Map<String, double> data; // Label -> Value
  final String title;
  final List<Color>? colors;

  const AnimatedPieChart({
    super.key,
    required this.data,
    required this.title,
    this.colors,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _getDefaultColors() {
    return [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
      AppTheme.infoColor,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? _getDefaultColors();
    final entries = widget.data.entries.toList();
    final total = widget.data.values.fold<double>(0, (sum, val) => sum + val);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return PieChart(
                          PieChartData(
                            sections: entries.asMap().entries.map((entry) {
                              final index = entry.key;
                              final value = entry.value.value;
                              final percentage = (value / total) * 100;
                              final isTouched = index == touchedIndex;
                              
                              return PieChartSectionData(
                                value: value * _animation.value,
                                title: '${percentage.toStringAsFixed(1)}%',
                                color: colors[index % colors.length],
                                radius: isTouched ? 65 : 55,
                                titleStyle: TextStyle(
                                  fontSize: isTouched ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (response?.touchedSection != null) {
                                    touchedIndex = response!.touchedSection!.touchedSectionIndex;
                                  } else {
                                    touchedIndex = -1;
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: entries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final label = entry.value.key;
                      final value = entry.value.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    value.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.mediumGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
