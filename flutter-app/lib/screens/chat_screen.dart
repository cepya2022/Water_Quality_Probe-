import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/reading.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/console.dart';
import '../widgets/sensa_ui.dart';
import 'app_shell.dart';

/// Control: live readings, sampling controls and the command console.
///
/// The canvas ships this screen in two variants — `readings` and `terminal`.
/// They are both here, behind the segmented control at the top.
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  BluetoothProvider? _observed;
  bool _terminalMode = false;
  bool _consoleOpen = false;
  String _commandSetId = 'estado';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _observed = Provider.of<BluetoothProvider>(context, listen: false)
        ..addListener(_scrollToBottom);
    });
  }

  @override
  void dispose() {
    _observed?.removeListener(_scrollToBottom);
    _input.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_logScroll.hasClients) return;
      _logScroll.animateTo(
        _logScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Sends a raw command, refusing early (with a toast) when offline so the
  /// transcript does not fill up with connection errors.
  bool _send(String code) {
    final BluetoothProvider bluetooth = context.read<BluetoothProvider>();
    if (!bluetooth.isConnected) {
      showSensaToast(context, context.s.notConnectedWarning);
      return false;
    }
    bluetooth.sendMessage(code);
    _scrollToBottom();
    return true;
  }

  void _sendTyped() {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    if (_send(text)) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedToggle(
              labels: <String>[s.tabReadings, s.tabTerminal],
              selectedIndex: _terminalMode ? 1 : 0,
              onSelect: (int index) =>
                  setState(() => _terminalMode = index == 1),
            ),
          ),
        ),
        Expanded(
          child: _terminalMode ? _buildTerminal(s) : _buildReadings(s),
        ),
      ],
    );
  }

  // ---- readings variant ---------------------------------------------------

  Widget _buildReadings(AppStrings s) {
    final BluetoothProvider bluetooth = context.watch<BluetoothProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final List<Reading> readings = bluetooth.readings;
    final Reading? last = readings.isEmpty ? null : readings.last;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        _LiveTileGrid(last: last, decimals: settings.decimals),
        const SizedBox(height: 14),
        _MeasurementCard(
          measuring: settings.measuring,
          interval: settings.interval,
          onToggle: (bool value) {
            if (!_send(value ? 'g' : 'r')) return;
            settings.measuring = value;
          },
          onInterval: (String value) {
            final String? code = kIntervalCommands[value];
            if (code == null || !_send(code)) return;
            settings.interval = value;
            showSensaToast(context, s.intervalSet(value));
          },
        ),
        const SizedBox(height: 14),
        SectionLabel(s.instantRead),
        _InstantReads(
          onSend: (ProbeCommand command) {
            if (!_send(command.code)) return;
            showSensaToast(context, s.readingParam(command.label));
          },
        ),
        const SizedBox(height: 14),
        SectionLabel(s.actions),
        ActionRow(
          icon: Icons.download,
          label: s.fetchNewData,
          sub: s.sinceLastDownload,
          onTap: () {
            if (!_send('y')) return;
            ShellScope.maybeOf(context)?.goToTab(ShellTab.data);
          },
        ),
        const SizedBox(height: 8),
        ActionRow(
          icon: Icons.tune,
          label: s.calibrateSensors,
          sub: 'pH · OD · EC',
          onTap: () => ShellScope.maybeOf(context)?.goToTab(ShellTab.settings),
        ),
        const SizedBox(height: 8),
        ActionRow(
          icon: Icons.ios_share,
          label: s.exportCsv,
          sub: 'sensa.csv',
          onTap: () {
            if (!bluetooth.hasData) {
              showSensaToast(context, s.noDataToExport);
              return;
            }
            bluetooth.shareCsv();
            showSensaToast(context, s.csvShared);
          },
        ),
        const SizedBox(height: 14),
        _ConsoleCard(
          open: _consoleOpen,
          messages: bluetooth.messages,
          scrollController: _logScroll,
          isGenerating: bluetooth.isGenerating,
          input: _input,
          connected: bluetooth.isConnected,
          onToggle: () {
            setState(() => _consoleOpen = !_consoleOpen);
            if (_consoleOpen) _scrollToBottom();
          },
          onSend: _sendTyped,
          onClear: bluetooth.clearMessages,
        ),
      ],
    );
  }

  // ---- terminal variant ---------------------------------------------------

  Widget _buildTerminal(AppStrings s) {
    final BluetoothProvider bluetooth = context.watch<BluetoothProvider>();
    final SensaColors c = context.colors;
    final List<CommandSet> sets = buildCommandSets(s);
    final CommandSet active = sets.firstWhere(
      (CommandSet set) => set.id == _commandSetId,
      orElse: () => sets.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChipStrip(
            children: <Widget>[
              for (final CommandSet set in sets)
                SensaChip(
                  label: set.label,
                  selected: set.id == _commandSetId,
                  onTap: () => setState(() => _commandSetId = set.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CommandButtonGrid(
            commands: active.commands,
            onSend: (ProbeCommand command) => _send(command.code),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SensaCard(
              padding: EdgeInsets.zero,
              clip: true,
              child: ConsoleLog(
                messages: bluetooth.messages,
                controller: _logScroll,
                emptyLabel: bluetooth.isConnected
                    ? s.manualCommand
                    : s.notConnectedWarning,
              ),
            ),
          ),
          if (bluetooth.isGenerating)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.generatingCsv,
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
            ),
          const SizedBox(height: 12),
          ConsoleInput(
            controller: _input,
            hintText: s.manualCommand,
            enabled: bluetooth.isConnected,
            onSend: _sendTyped,
          ),
        ],
      ),
    );
  }
}

/// The 2x2 grid of latest values. TDS is intentionally absent: the canvas
/// shows the four quantities the operator watches live.
class _LiveTileGrid extends StatelessWidget {
  const _LiveTileGrid({Key? key, required this.last, required this.decimals})
      : super(key: key);

  final Reading? last;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final List<ParamDef> shown = kParams
        .where((ParamDef p) => p.key != ParamKey.tds)
        .toList(growable: false);

    final List<Widget> tiles = <Widget>[
      for (final ParamDef param in shown)
        _LiveTile(
          name: param.key == ParamKey.temp ? s.shortTemp : param.short,
          unit: param.unit,
          color: param.color,
          value: last == null
              ? '—'
              : param.format(last!.valueOf(param.key), decimals),
          note: last == null
              ? s.noData
              : '${last!.hora} · ${s.pointLabel(last!.punto).toLowerCase()}',
        ),
    ];

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: tiles[i]),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < tiles.length
                    ? tiles[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 10));
    }

    return Column(children: rows);
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({
    Key? key,
    required this.name,
    required this.unit,
    required this.color,
    required this.value,
    required this.note,
  }) : super(key: key);

  final String name;
  final String unit;
  final Color color;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return SensaCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              ColorDot(color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.66,
                    color: c.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: monoStyle(fontSize: 26, letterSpacing: -0.52),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(unit, style: TextStyle(fontSize: 11, color: c.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    Key? key,
    required this.measuring,
    required this.interval,
    required this.onToggle,
    required this.onInterval,
  }) : super(key: key);

  final bool measuring;
  final String interval;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onInterval;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    return SensaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.autoMeasurement,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      measuring ? s.everyInterval(interval) : s.stopped,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SensaSwitch(value: measuring, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          SectionLabel(s.interval, padding: const EdgeInsets.only(bottom: 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String option in kIntervals)
                SensaChip(
                  label: option,
                  selected: interval == option,
                  onTap: () => onInterval(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstantReads extends StatelessWidget {
  const _InstantReads({Key? key, required this.onSend}) : super(key: key);

  final ValueChanged<ProbeCommand> onSend;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final List<ProbeCommand> commands = <ProbeCommand>[
      const ProbeCommand('pH', 'P'),
      const ProbeCommand('OD', 'X'),
      const ProbeCommand('EC', 'Z'),
      ProbeCommand(s.shortTemp, 'T'),
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < commands.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: CommandButton(
              command: commands[i],
              radius: 16,
              onTap: () => onSend(commands[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// Collapsible transcript that keeps the console one tap away without giving
/// up the readings layout.
class _ConsoleCard extends StatelessWidget {
  const _ConsoleCard({
    Key? key,
    required this.open,
    required this.messages,
    required this.scrollController,
    required this.isGenerating,
    required this.input,
    required this.connected,
    required this.onToggle,
    required this.onSend,
    required this.onClear,
  }) : super(key: key);

  final bool open;
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final bool isGenerating;
  final TextEditingController input;
  final bool connected;
  final VoidCallback onToggle;
  final VoidCallback onSend;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    return SensaCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.terminal, size: 18, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.console,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      isGenerating
                          ? s.generatingCsv
                          : s.lineCount(messages.length),
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: c.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open) ...<Widget>[
            Divider(height: 1, color: c.border),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ConsoleLog(
                messages: messages,
                controller: scrollController,
                emptyLabel: s.manualCommand,
              ),
            ),
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ConsoleInput(
                      controller: input,
                      hintText: s.manualCommand,
                      enabled: connected,
                      height: 40,
                      radius: 12,
                      onSend: onSend,
                    ),
                  ),
                  if (messages.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
                    SquareIconButton(
                      icon: Icons.delete_outline,
                      size: 40,
                      radius: 12,
                      iconSize: 18,
                      tooltip: s.clearConsole,
                      onTap: onClear,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
