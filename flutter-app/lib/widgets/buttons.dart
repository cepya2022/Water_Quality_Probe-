import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// A single firmware command: what the button says, and the character the
/// probe listens for.
@immutable
class ProbeCommand {
  const ProbeCommand(this.label, this.code);

  final String label;
  final String code;
}

/// One tab of the terminal's command palette.
@immutable
class CommandSet {
  const CommandSet(this.id, this.label, this.commands);

  final String id;
  final String label;
  final List<ProbeCommand> commands;
}

/// The six command groups from the canvas, in canvas order. The codes match
/// the ones `Code_Water_Quality_Probe.ino` parses.
List<CommandSet> buildCommandSets(AppStrings s) {
  return <CommandSet>[
    CommandSet('estado', s.setStatus, <ProbeCommand>[
      ProbeCommand(s.cmdStatus, '?'),
      ProbeCommand(s.cmdClock, 'R'),
      ProbeCommand(s.cmdNewData, 'y'),
    ]),
    CommandSet('medicion', s.setMeasurement, <ProbeCommand>[
      ProbeCommand(s.cmdOn, 'g'),
      ProbeCommand(s.cmdOff, 'r'),
      ProbeCommand(s.cmdOk, 'k'),
      ProbeCommand(s.cmdCancel, 'a'),
      const ProbeCommand('15"', 'n'),
      const ProbeCommand("1'", 'o'),
      const ProbeCommand("5'", 'h'),
      const ProbeCommand("15'", 'q'),
      const ProbeCommand("30'", 't'),
    ]),
    CommandSet('calib', s.setCalibration, <ProbeCommand>[
      ProbeCommand(s.cmdCalPh, 'c'),
      ProbeCommand(s.cmdSetPh, '%'),
      ProbeCommand(s.cmdMPh, 'v'),
      ProbeCommand(s.cmdCalOd, 'O'),
      ProbeCommand(s.cmdCalEc, 'd'),
      ProbeCommand(s.cmdEcOnePoint, 'D'),
      ProbeCommand(s.cmdOk, 'k'),
      ProbeCommand(s.cmdCancel, 'a'),
    ]),
    CommandSet('sensores', s.setSensors, <ProbeCommand>[
      ProbeCommand(s.cmdPhOn, '-'),
      ProbeCommand(s.cmdOdOn, '@'),
      ProbeCommand(s.cmdEcOn, '#'),
      ProbeCommand(s.cmdAllOff, '&'),
    ]),
    CommandSet('lectura', s.setReading, <ProbeCommand>[
      const ProbeCommand('pH', 'P'),
      const ProbeCommand('OD', 'X'),
      const ProbeCommand('EC', 'Z'),
      ProbeCommand(s.shortTemp, 'T'),
    ]),
    CommandSet('datos', s.setData, <ProbeCommand>[
      ProbeCommand(s.cmdData, 'y'),
      ProbeCommand(s.cmdAll, 'w'),
      ProbeCommand(s.cmdErase, 'e'),
    ]),
  ];
}

/// The wrapping grid of command buttons under the terminal's tab strip: a
/// label with the raw command code underneath.
class CommandButtonGrid extends StatelessWidget {
  const CommandButtonGrid({
    Key? key,
    required this.commands,
    required this.onSend,
    this.enabled = true,
  }) : super(key: key);

  final List<ProbeCommand> commands;
  final ValueChanged<ProbeCommand> onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double spacing = 8;
        const double minWidth = 82;
        final int columns =
            ((constraints.maxWidth + spacing) / (minWidth + spacing))
                .floor()
                .clamp(2, 5)
                .toInt();
        final double width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final ProbeCommand command in commands)
              SizedBox(
                width: width,
                child: CommandButton(
                  command: command,
                  onTap: enabled ? () => onSend(command) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A single 52px command tile.
class CommandButton extends StatelessWidget {
  const CommandButton({
    Key? key,
    required this.command,
    required this.onTap,
    this.height = 52,
    this.radius = 15,
  }) : super(key: key);

  final ProbeCommand command;
  final VoidCallback? onTap;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final bool enabled = onTap != null;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                command.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: enabled ? c.text : c.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                command.code,
                style: monoStyle(
                  fontSize: 9,
                  color: c.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
