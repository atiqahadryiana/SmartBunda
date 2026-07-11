/// SmartBunda — Admin Dashboard chart wrappers
///
/// Thin, pink-palette wrappers around `fl_chart` so analytics charts stay
/// consistent, responsive, and theme-aware. Each wrapper reads colors from
/// [AppTheme] / the active [ColorScheme] and renders interactive tooltips.
library smartbunda.admin_charts;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:smartbunda/theme/app_theme.dart';

/// A single named series of integer data points.
class ChartSeries {
  const ChartSeries({required this.label, required this.values, this.color});

  final String label;
  final List<int> values;
  final Color? color;
}

/// Smooth line chart with optional gradient area fill.
class AdminLineChart extends StatelessWidget {
  const AdminLineChart({
    super.key,
    required this.values,
    this.labels,
    this.color,
    this.filled = true,
    this.height = 200,
  });

  final List<int> values;
  final List<String>? labels;
  final Color? color;
  final bool filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = color ?? AppTheme.darkPink;
    final maxY = _niceMax(values);
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i].toDouble()),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.353),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: labels != null,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (labels == null || i < 0 || i >= labels!.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels![i],
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => lineColor,
              getTooltipItems: (touched) => touched
                  .map((s) => LineTooltipItem(
                        s.y.toInt().toString(),
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: filled,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.235),
                    lineColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical bar chart.
class AdminBarChart extends StatelessWidget {
  const AdminBarChart({
    super.key,
    required this.values,
    this.labels,
    this.color,
    this.height = 200,
  });

  final List<int> values;
  final List<String>? labels;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = color ?? AppTheme.darkPink;
    final maxY = _niceMax(values);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.353),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: labels != null,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (labels == null || i < 0 || i >= labels!.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels![i],
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => barColor,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        barColor.withValues(alpha: 0.627),
                        barColor,
                      ],
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

/// Donut chart with a side legend.
class AdminDonutChart extends StatelessWidget {
  const AdminDonutChart({
    super.key,
    required this.data,
    this.colors,
    this.size = 180,
  });

  final Map<String, int> data;
  final List<Color>? colors;
  final double size;

  static const _defaultColors = [
    AppTheme.darkPink,
    AppTheme.primaryPink,
    AppTheme.info,
    AppTheme.healthcareTeal,
    AppTheme.warning,
    AppTheme.success,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = colors ?? _defaultColors;
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: total == 0
              ? Center(
                  child: Text('No data',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                )
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: size * 0.28,
                    sections: [
                      for (var i = 0; i < entries.length; i++)
                        PieChartSectionData(
                          value: entries[i].value.toDouble(),
                          color: palette[i % palette.length],
                          radius: size * 0.18,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entries[i].value}',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rounds a max value up to a clean axis bound (never 0, to avoid /0).
double _niceMax(List<int> values) {
  final maxV = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
  if (maxV <= 0) return 4;
  final magnitude = maxV <= 8 ? 2 : (maxV <= 40 ? 5 : 10);
  return (((maxV / magnitude).ceil()) * magnitude).toDouble();
}
