import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/reading.dart';
import '../theme/app_theme.dart';

/// Line plot of one parameter over a list of readings.
///
/// Mirrors the canvas chart: filled area under a straight-segment line, a
/// dashed crosshair on the selected sample, and mono axis labels. Tapping
/// anywhere selects the nearest sample.
class ReadingsLineChart extends StatelessWidget {
  const ReadingsLineChart({
    Key? key,
    required this.readings,
    required this.param,
    required this.decimals,
    required this.selectedIndex,
    required this.onSelected,
    this.showBottomTitles = true,
    this.bottomTickCount = 4,
  }) : super(key: key);

  final List<Reading> readings;
  final ParamDef param;
  final int decimals;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showBottomTitles;
  final int bottomTickCount;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    final List<double> values = readings
        .map((Reading r) => r.valueOf(param.key))
        .toList(growable: false);

    double lo = values.reduce(math.min);
    double hi = values.reduce(math.max);
    // 15% headroom on each side, as the canvas does, so the line never touches
    // the frame. Flat series still need a non-zero span.
    final double pad = (hi - lo) * 0.15;
    lo -= pad == 0 ? 1 : pad;
    hi += pad == 0 ? 1 : pad;

    final int safeIndex = selectedIndex.clamp(0, readings.length - 1).toInt();
    final double horizontalInterval = (hi - lo) / 4;
    final double bottomInterval = math.max(
      1,
      ((readings.length - 1) / math.max(1, bottomTickCount - 1))
          .floorToDouble(),
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (readings.length - 1).toDouble(),
        minY: lo,
        maxY: hi,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval <= 0 ? 1 : horizontalInterval,
          getDrawingHorizontalLine: (double value) =>
              FlLine(color: c.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: horizontalInterval <= 0 ? 1 : horizontalInterval,
              getTitlesWidget: (double value, TitleMeta meta) =>
                  SideTitleWidget(
                axisSide: meta.axisSide,
                space: 6,
                child: Text(
                  param.format(value, decimals),
                  style: monoStyle(
                    fontSize: 9,
                    color: c.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showBottomTitles,
              reservedSize: 24,
              interval: bottomInterval,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.round();
                if (index < 0 || index >= readings.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    readings[index].hora,
                    style: monoStyle(
                      fontSize: 9,
                      color: c.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchSpotThreshold: 40,
          getTouchedSpotIndicator: (
            LineChartBarData barData,
            List<int> indexes,
          ) {
            return indexes.map((int index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: c.muted,
                  strokeWidth: 1,
                  dashArray: <int>[3, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (
                    FlSpot spot,
                    double percent,
                    LineChartBarData bar,
                    int i,
                  ) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: param.color,
                    strokeWidth: 2.5,
                    strokeColor: c.surface,
                  ),
                ),
              );
            }).toList();
          },
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            final List<LineBarSpot>? spots = response?.lineBarSpots;
            if (spots == null || spots.isEmpty) return;
            onSelected(spots.first.spotIndex);
          },
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: <FlSpot>[
              for (int i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: false,
            color: param.color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            dotData: const FlDotData(show: false),
            showingIndicators: <int>[safeIndex],
            belowBarData: BarAreaData(
              show: true,
              color: param.color.withAlpha(33),
            ),
          ),
        ],
      ),
    );
  }
}

/// Min / average / max over the plotted window.
class ChartStats {
  const ChartStats(this.min, this.average, this.max);

  final double min;
  final double average;
  final double max;

  static ChartStats of(List<Reading> readings, ParamKey key) {
    final List<double> values =
        readings.map((Reading r) => r.valueOf(key)).toList(growable: false);
    final double sum = values.reduce((double a, double b) => a + b);
    return ChartStats(
      values.reduce(math.min),
      sum / values.length,
      values.reduce(math.max),
    );
  }
}
