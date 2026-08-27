import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/reading.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/readings_chart.dart';
import '../widgets/sensa_ui.dart';
import 'app_shell.dart';
import 'chart_fullscreen.dart';

/// Gráficos: one parameter at a time, over a chosen range, with tap-to-read
/// and a landscape fullscreen mode.
class VisualizeScreen extends StatefulWidget {
  const VisualizeScreen({Key? key}) : super(key: key);

  @override
  State<VisualizeScreen> createState() => _VisualizeScreenState();
}

class _VisualizeScreenState extends State<VisualizeScreen> {
  final GlobalKey _chartBoundary = GlobalKey();

  ParamKey _param = ParamKey.od;
  DataRange _range = DataRange.week;

  /// `null` means "the most recent sample", which is what the screen opens on
  /// and falls back to whenever the window changes.
  int? _selected;

  int _resolveIndex(int length) {
    final int index = _selected ?? length - 1;
    return index.clamp(0, length - 1).toInt();
  }

  Future<void> _exportChart() async {
    final AppStrings s = context.s;
    try {
      final RenderObject? renderObject =
          _chartBoundary.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return;

      final ui.Image image = await renderObject.toImage(pixelRatio: 3);
      final ByteData? bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/sensa_grafico.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await Share.shareXFiles(<XFile>[XFile(file.path)]);
      if (mounted) showSensaToast(context, s.chartExported);
    } catch (_) {
      if (mounted) showSensaToast(context, s.chartExported);
    }
  }

  Future<void> _openFullscreen(
    List<Reading> readings,
    ParamDef param,
    int decimals,
    String footer,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChartFullscreenPage(
          readings: readings,
          param: param,
          decimals: decimals,
          initialIndex: _resolveIndex(readings.length),
          footer: footer,
          onSelected: (int index) {
            if (mounted) setState(() => _selected = index);
          },
          onParamChanged: (ParamDef next) {
            if (mounted) setState(() => _param = next.key);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;
    final BluetoothProvider bluetooth = context.watch<BluetoothProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();

    final List<Reading> all = bluetooth.readings;
    if (all.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          EmptyState(
            icon: Icons.show_chart,
            title: s.noData,
            message: s.noDataHint,
            action: SensaChip(
              label: s.fetchNewData,
              selected: true,
              onTap: () =>
                  ShellScope.maybeOf(context)?.goToTab(ShellTab.control),
            ),
          ),
        ],
      );
    }

    final List<Reading> rows = _range.apply(all);
    final ParamDef param = paramFor(_param);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        ChipStrip(
          children: <Widget>[
            for (final ParamDef option in kParams)
              SensaChip(
                label: option.short,
                selected: option.key == _param,
                dotColor: option.color,
                onTap: () => setState(() => _param = option.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ChipStrip(
          children: <Widget>[
            for (final DataRange range in DataRange.values)
              SensaChip(
                label: range.label(s),
                selected: range == _range,
                onTap: () => setState(() {
                  _range = range;
                  _selected = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (rows.length < 2)
          SensaCard(
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  s.notEnoughData,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ),
            ),
          )
        else
          ..._buildChart(rows, param, settings.decimals, s, c),
      ],
    );
  }

  List<Widget> _buildChart(
    List<Reading> rows,
    ParamDef param,
    int decimals,
    AppStrings s,
    SensaColors c,
  ) {
    final int index = _resolveIndex(rows.length);
    final Reading selected = rows[index];
    final ChartStats stats = ChartStats.of(rows, param.key);
    final String footer = s.chartFooter(
      rows.length,
      rows.first.fecha,
      rows.last.fecha,
    );

    return <Widget>[
      RepaintBoundary(
        key: _chartBoundary,
        child: SensaCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            param.axisLabel(s),
                            style: TextStyle(fontSize: 11, color: c.muted),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${param.format(selected.valueOf(param.key), decimals)} ${param.unit}',
                                    style: monoStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${selected.hora} · ${selected.fecha}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SquareIconButton(
                      icon: Icons.fullscreen,
                      size: 34,
                      radius: 11,
                      iconSize: 17,
                      onTap: () =>
                          _openFullscreen(rows, param, decimals, footer),
                    ),
                    const SizedBox(width: 6),
                    SquareIconButton(
                      icon: Icons.ios_share,
                      size: 34,
                      radius: 11,
                      iconSize: 17,
                      onTap: _exportChart,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: ReadingsLineChart(
                  readings: rows,
                  param: param,
                  decimals: decimals,
                  selectedIndex: index,
                  onSelected: (int value) => setState(() => _selected = value),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  s.tapChartHint,
                  style: TextStyle(fontSize: 10, color: c.muted),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: <Widget>[
          _StatCard(
            label: s.statMin,
            value: param.format(stats.min, decimals),
          ),
          const SizedBox(width: 9),
          _StatCard(
            label: s.statAvg,
            value: param.format(stats.average, decimals),
          ),
          const SizedBox(width: 9),
          _StatCard(
            label: s.statMax,
            value: param.format(stats.max, decimals),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          footer,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: c.muted),
        ),
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({Key? key, required this.label, required this.value})
      : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Expanded(
      child: SensaCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.6,
                color: c.muted,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: monoStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }
}
