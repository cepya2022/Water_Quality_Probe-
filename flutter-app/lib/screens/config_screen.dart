import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/reading.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/sensa_ui.dart';

/// Configuración: sampling, sensors, calibration, units, device and
/// appearance, in the order the canvas lays them out.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  bool _send(String code) {
    final BluetoothProvider bluetooth = context.read<BluetoothProvider>();
    if (!bluetooth.isConnected) {
      showSensaToast(context, context.s.notConnectedWarning);
      return false;
    }
    bluetooth.sendMessage(code);
    return true;
  }

  Future<void> _editSamplingPoint(SettingsProvider settings) async {
    final AppStrings s = context.s;
    final SensaColors c = context.colors;
    final TextEditingController controller =
        TextEditingController(text: settings.samplingPoint);

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(s.samplingPoint, style: const TextStyle(fontSize: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: monoStyle(fontSize: 16, color: c.text),
          cursorColor: c.accent,
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.accent),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel, style: TextStyle(color: c.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(s.save, style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );

    controller.dispose();
    if (value != null && value.isNotEmpty) settings.samplingPoint = value;
  }

  /// Runs one sensor's calibration commands from a sheet, recording the date
  /// when the operator confirms.
  Future<void> _calibrate(
    SettingsProvider settings,
    String sensorKey,
    String title,
    List<ProbeCommand> commands,
  ) async {
    final AppStrings s = context.s;
    final SensaColors c = context.colors;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => Container(
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
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.calibrationHint,
                style: TextStyle(fontSize: 12, color: c.muted, height: 1.5),
              ),
              const SizedBox(height: 16),
              CommandButtonGrid(
                commands: commands,
                onSend: (ProbeCommand command) => _send(command.code),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CommandButton(
                      command: ProbeCommand(s.cmdCancel, 'a'),
                      onTap: () {
                        _send('a');
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          if (!_send('k')) return;
                          settings.markCalibrated(sensorKey, DateTime.now());
                          Navigator.of(sheetContext).pop();
                        },
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: Text(
                              s.cmdOk,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.accentInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final BluetoothProvider bluetooth = context.watch<BluetoothProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        _Section(
          title: s.secMeasurement,
          children: <Widget>[
            _SettingRow(
              label: s.samplingInterval,
              sub: s.samplingIntervalSub,
              options: <Widget>[
                for (final String option in kIntervals)
                  SensaChip(
                    label: option,
                    selected: settings.interval == option,
                    height: 32,
                    onTap: () {
                      final String? code = kIntervalCommands[option];
                      if (code == null || !_send(code)) return;
                      settings.interval = option;
                      showSensaToast(context, s.intervalSet(option));
                    },
                  ),
              ],
            ),
            _SettingRow(
              icon: Icons.place,
              label: s.samplingPoint,
              valueText: settings.samplingPoint,
              chevron: true,
              onTap: () => _editSamplingPoint(settings),
            ),
            _SettingRow(
              icon: Icons.schedule,
              label: s.autoMeasurement,
              toggle: settings.measuring,
              onToggle: (bool value) {
                if (!_send(value ? 'g' : 'r')) return;
                settings.measuring = value;
              },
            ),
          ],
        ),
        _Section(
          title: s.secSensors,
          children: <Widget>[
            _sensorRow(settings, 'ph', s.paramPh, Icons.science),
            _sensorRow(settings, 'od', s.sensorOd, Icons.bubble_chart),
            _sensorRow(settings, 'ec', s.paramEc, Icons.waves),
            _sensorRow(settings, 'temp', s.paramTemp, Icons.thermostat),
          ],
        ),
        _Section(
          title: s.secCalibration,
          children: <Widget>[
            _calibrationRow(settings, 'ph', s.paramPh, <ProbeCommand>[
              ProbeCommand(s.cmdCalPh, 'c'),
              ProbeCommand(s.cmdSetPh, '%'),
              ProbeCommand(s.cmdMPh, 'v'),
            ]),
            _calibrationRow(settings, 'od', s.sensorOd, <ProbeCommand>[
              ProbeCommand(s.cmdCalOd, 'O'),
            ]),
            _calibrationRow(settings, 'ec', s.paramEc, <ProbeCommand>[
              ProbeCommand(s.cmdCalEc, 'd'),
              ProbeCommand(s.cmdEcOnePoint, 'D'),
            ]),
          ],
        ),
        _Section(
          title: s.secUnits,
          children: <Widget>[
            _SettingRow(
              label: s.decimals,
              options: <Widget>[
                for (final int value in <int>[1, 2, 3])
                  SensaChip(
                    label: '$value',
                    selected: settings.decimals == value,
                    height: 32,
                    onTap: () => settings.decimals = value,
                  ),
              ],
            ),
            _SettingRow(
              icon: Icons.thermostat,
              label: s.paramTemp,
              valueText: paramFor(ParamKey.temp).unit,
            ),
            _SettingRow(
              icon: Icons.waves,
              label: s.paramEc,
              valueText: paramFor(ParamKey.ec).unit,
            ),
          ],
        ),
        _Section(
          title: s.secDevice,
          children: <Widget>[
            _SettingRow(
              icon: Icons.bluetooth,
              label: s.autoConnect,
              sub: bluetooth.lastKnownDeviceName != null
                  ? s.autoConnectSub(bluetooth.lastKnownDeviceName!)
                  : s.autoConnectNoDevice,
              toggle: settings.autoConnect,
              onToggle: (bool value) => settings.autoConnect = value,
            ),
          ],
        ),
        _Section(
          title: s.secAppearance,
          children: <Widget>[
            _SettingRow(
              icon: Icons.light_mode,
              label: s.lightMode,
              sub: s.lightModeSub,
              toggle: !settings.darkMode,
              onToggle: (bool value) => settings.darkMode = !value,
            ),
            _SettingRow(
              icon: Icons.language,
              label: s.language,
              options: <Widget>[
                SensaChip(
                  label: 'ES',
                  selected: !settings.english,
                  height: 32,
                  onTap: () => settings.english = false,
                ),
                SensaChip(
                  label: 'EN',
                  selected: settings.english,
                  height: 32,
                  onTap: () => settings.english = true,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            s.footer,
            style: TextStyle(fontSize: 11, color: c.muted),
          ),
        ),
      ],
    );
  }

  Widget _sensorRow(
    SettingsProvider settings,
    String key,
    String label,
    IconData icon,
  ) {
    final bool value = settings.sensors[key] ?? true;
    final String? command = kSensorCommands[key];

    return _SettingRow(
      icon: icon,
      label: label,
      toggle: value,
      onToggle: (bool next) {
        // Temperature has no firmware toggle, so it is a local preference only.
        if (command != null && !_send(command)) return;
        settings.setSensor(key, next);
      },
    );
  }

  Widget _calibrationRow(
    SettingsProvider settings,
    String key,
    String label,
    List<ProbeCommand> commands,
  ) {
    final AppStrings s = context.s;
    final String? date = settings.calibrationDate(key);

    return _SettingRow(
      icon: Icons.straighten,
      label: label,
      sub: date == null ? s.notCalibrated : s.calibratedOn(date),
      chevron: true,
      onTap: () => _calibrate(settings, key, label, commands),
    );
  }
}

/// Titled group of rows sharing one rounded surface.
class _Section extends StatelessWidget {
  const _Section({Key? key, required this.title, required this.children})
      : super(key: key);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionLabel(
            title,
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          ),
          SensaCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: c.border),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One configuration row: icon, label, optional subtitle, and exactly one of a
/// toggle, a value, a chevron, or a strip of chip options underneath.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    Key? key,
    required this.label,
    this.icon,
    this.sub,
    this.toggle,
    this.onToggle,
    this.valueText,
    this.chevron = false,
    this.onTap,
    this.options,
  }) : super(key: key);

  final String label;
  final IconData? icon;
  final String? sub;
  final bool? toggle;
  final ValueChanged<bool>? onToggle;
  final String? valueText;
  final bool chevron;
  final VoidCallback? onTap;
  final List<Widget>? options;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              SizedBox(
                width: 22,
                child: Icon(icon, size: 19, color: c.muted),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (sub != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (toggle != null)
              SensaSwitch(value: toggle!, onChanged: onToggle),
            if (valueText != null)
              Text(
                valueText!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.accent,
                ),
              ),
            if (chevron) ...<Widget>[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: c.muted),
            ],
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (onTap != null) InkWell(onTap: onTap, child: row) else row,
        if (options != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(spacing: 7, runSpacing: 7, children: options!),
          ),
      ],
    );
  }
}
