import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/reading.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sensa_ui.dart';
import 'app_shell.dart';

/// Datos: the downloaded dump, filtered by range and sampling point, shown as
/// cards or as a table.
class TableScreen extends StatefulWidget {
  const TableScreen({Key? key}) : super(key: key);

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  static const String _allPoints = '__all__';

  DataRange _range = DataRange.week;
  String _point = _allPoints;
  bool _cards = true;

  List<Reading> _filter(List<Reading> readings) {
    final List<Reading> ranged = _range.apply(readings);
    if (_point == _allPoints) return ranged;
    return ranged
        .where((Reading r) => r.punto == _point)
        .toList(growable: false);
  }

  Future<void> _confirmClear(BluetoothProvider bluetooth) async {
    final AppStrings s = context.s;
    final SensaColors c = context.colors;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(s.clearData, style: const TextStyle(fontSize: 17)),
        content: Text(
          s.clearDataConfirm,
          style: TextStyle(fontSize: 13, color: c.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel, style: TextStyle(color: c.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              s.delete,
              style: const TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bluetooth.clearData();
      if (mounted) showSensaToast(context, s.dataCleared);
    }
  }

  void _openDetail(Reading reading) {
    final SensaColors c = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x80000000),
      builder: (BuildContext sheetContext) => _DetailSheet(
        reading: reading,
        decimals: context.read<SettingsProvider>().decimals,
        surface: c.surface,
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
            icon: Icons.table_rows_outlined,
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

    final List<Reading> rows = _filter(all);
    // Newest first, which is what an operator looks for after a download.
    final List<Reading> ordered = rows.reversed.toList(growable: false);
    final List<String> points = bluetooth.samplingPoints;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ChipStrip(
                  children: <Widget>[
                    for (final DataRange range in DataRange.values)
                      SensaChip(
                        label: range.label(s),
                        selected: _range == range,
                        onTap: () => setState(() => _range = range),
                      ),
                  ],
                ),
                if (points.length > 1) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Text(
                        s.point,
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ChipStrip(
                          children: <Widget>[
                            SensaChip(
                              label: s.allPoints,
                              selected: _point == _allPoints,
                              height: 30,
                              horizontalPadding: 12,
                              onTap: () => setState(() => _point = _allPoints),
                            ),
                            for (final String point in points)
                              SensaChip(
                                label: point,
                                selected: _point == point,
                                height: 30,
                                horizontalPadding: 12,
                                onTap: () => setState(() => _point = point),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        s.measurementCount(ordered.length),
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ),
                    SquareIconButton(
                      icon: Icons.ios_share,
                      size: 34,
                      radius: 11,
                      iconSize: 17,
                      tooltip: s.exportCsv,
                      onTap: () {
                        bluetooth.shareCsv();
                        showSensaToast(context, s.csvShared);
                      },
                    ),
                    const SizedBox(width: 6),
                    SquareIconButton(
                      icon: Icons.delete_outline,
                      size: 34,
                      radius: 11,
                      iconSize: 17,
                      tooltip: s.clearData,
                      onTap: () => _confirmClear(bluetooth),
                    ),
                    const SizedBox(width: 8),
                    SegmentedToggle(
                      labels: <String>[s.cardsView, s.tableView],
                      selectedIndex: _cards ? 0 : 1,
                      onSelect: (int index) =>
                          setState(() => _cards = index == 0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (ordered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  s.noDataInRange,
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ),
            ),
          )
        else if (_cards)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ReadingCard(
                    reading: ordered[index],
                    decimals: settings.decimals,
                    onTap: () => _openDetail(ordered[index]),
                  ),
                ),
                childCount: ordered.length,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ReadingTable(
                readings: ordered,
                decimals: settings.decimals,
              ),
            ),
          ),
      ],
    );
  }
}

/// One measurement as a card: timestamp header plus the five values.
class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    Key? key,
    required this.reading,
    required this.decimals,
    required this.onTap,
  }) : super(key: key);

  final Reading reading;
  final int decimals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    return SensaCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                reading.hora,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reading.fecha,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.pointLabel(reading.punto),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: c.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (final ParamDef param in kParams)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        param.short,
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.36,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          param.format(reading.valueOf(param.key), decimals),
                          style: monoStyle(
                            fontSize: 13,
                            color:
                                param.key == ParamKey.ph && reading.phOutOfRange
                                    ? const Color(0xFFF44336)
                                    : c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Table view with a pinned time column and horizontally scrolling values.
class _ReadingTable extends StatelessWidget {
  const _ReadingTable({
    Key? key,
    required this.readings,
    required this.decimals,
  }) : super(key: key);

  final List<Reading> readings;
  final int decimals;

  static const double _headerHeight = 38;
  static const double _rowHeight = 36;
  static const double _timeWidth = 74;
  static const double _valueWidth = 72;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    return SensaCard(
      radius: 18,
      padding: EdgeInsets.zero,
      clip: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Pinned first column.
          Container(
            width: _timeWidth,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(right: BorderSide(color: c.border)),
            ),
            child: Column(
              children: <Widget>[
                _cell(
                  s.time,
                  height: _headerHeight,
                  color: c.muted,
                  header: true,
                  borderColor: c.border,
                  align: Alignment.centerLeft,
                ),
                for (final Reading reading in readings)
                  _cell(
                    reading.hora,
                    height: _rowHeight,
                    color: c.muted,
                    borderColor: c.border,
                    align: Alignment.centerLeft,
                    mono: true,
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      for (final ParamDef param in kParams)
                        SizedBox(
                          width: _valueWidth,
                          child: _cell(
                            param.short,
                            height: _headerHeight,
                            color: c.muted,
                            header: true,
                            borderColor: c.border,
                          ),
                        ),
                    ],
                  ),
                  for (final Reading reading in readings)
                    Row(
                      children: <Widget>[
                        for (final ParamDef param in kParams)
                          SizedBox(
                            width: _valueWidth,
                            child: _cell(
                              param.format(
                                reading.valueOf(param.key),
                                decimals,
                              ),
                              height: _rowHeight,
                              color: param.key == ParamKey.ph &&
                                      reading.phOutOfRange
                                  ? const Color(0xFFF44336)
                                  : c.text,
                              borderColor: c.border,
                              mono: true,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    required double height,
    required Color color,
    required Color borderColor,
    bool header = false,
    bool mono = false,
    Alignment align = Alignment.centerRight,
  }) {
    return Container(
      height: height,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Text(
        header ? text.toUpperCase() : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: header
            ? TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: color,
              )
            : mono
                ? monoStyle(fontSize: 12, color: color)
                : TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

/// Bottom sheet with every parameter of a single measurement.
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    Key? key,
    required this.reading,
    required this.decimals,
    required this.surface,
  }) : super(key: key);

  final Reading reading;
  final int decimals;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${reading.hora} · ${reading.fecha}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              s.pointLabel(reading.punto),
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(height: 14),
            for (final ParamDef param in kParams)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      ColorDot(color: param.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          param.name(s),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        param.format(reading.valueOf(param.key), decimals),
                        style: monoStyle(fontSize: 15),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          param.unit,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ),
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
