import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/reading.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/readings_chart.dart';
import '../widgets/sensa_ui.dart';

/// The canvas' rotated fullscreen plot, done natively: the page forces
/// landscape while it is on screen and restores portrait on the way out.
///
/// Selection and parameter changes are reported back through callbacks, so the
/// Gráficos screen stays on whatever the operator was looking at here.
class ChartFullscreenPage extends StatefulWidget {
  const ChartFullscreenPage({
    Key? key,
    required this.readings,
    required this.param,
    required this.decimals,
    required this.initialIndex,
    required this.footer,
    required this.onSelected,
    required this.onParamChanged,
  }) : super(key: key);

  final List<Reading> readings;
  final ParamDef param;
  final int decimals;
  final int initialIndex;
  final String footer;

  /// Kept in sync with the Gráficos screen so leaving fullscreen preserves
  /// whatever the operator was looking at.
  final ValueChanged<int> onSelected;
  final ValueChanged<ParamDef> onParamChanged;

  @override
  State<ChartFullscreenPage> createState() => _ChartFullscreenPageState();
}

class _ChartFullscreenPageState extends State<ChartFullscreenPage> {
  late int _selected = widget.initialIndex;
  late ParamDef _param = widget.param;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;
    final Reading selected =
        widget.readings[_selected.clamp(0, widget.readings.length - 1)];
    final ChartStats stats = ChartStats.of(widget.readings, _param.key);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 196,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _param.axisLabel(s),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.footer,
                      style: TextStyle(
                        fontSize: 10,
                        color: c.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_param.format(selected.valueOf(_param.key), widget.decimals)} ${_param.unit}',
                      style: monoStyle(fontSize: 28, letterSpacing: -0.56),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selected.hora} · ${selected.fecha}',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final ParamDef param in kParams)
                          SensaChip(
                            label: param.short,
                            selected: param.key == _param.key,
                            dotColor: param.color,
                            height: 28,
                            fontSize: 11,
                            horizontalPadding: 10,
                            onTap: () {
                              setState(() => _param = param);
                              widget.onParamChanged(param);
                            },
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        _StatBox(
                          label: s.statMin,
                          value: _param.format(stats.min, widget.decimals),
                        ),
                        const SizedBox(width: 6),
                        _StatBox(
                          label: s.statAvg,
                          value: _param.format(stats.average, widget.decimals),
                        ),
                        const SizedBox(width: 6),
                        _StatBox(
                          label: s.statMax,
                          value: _param.format(stats.max, widget.decimals),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    SquareIconButton(
                      icon: Icons.close_fullscreen,
                      size: 34,
                      radius: 12,
                      iconSize: 19,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ReadingsLineChart(
                          readings: widget.readings,
                          param: _param,
                          decimals: widget.decimals,
                          selectedIndex: _selected,
                          bottomTickCount: 6,
                          onSelected: (int index) {
                            setState(() => _selected = index);
                            widget.onSelected(index);
                          },
                        ),
                      ),
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

class _StatBox extends StatelessWidget {
  const _StatBox({Key? key, required this.label, required this.value})
      : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Expanded(
      child: SensaCard(
        radius: 12,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.45,
                color: c.muted,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: monoStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
