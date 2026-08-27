import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'sensa_ui.dart';

/// Four ascending bars whose fill reflects RSSI, as on the canvas' device rows.
class SignalBars extends StatelessWidget {
  const SignalBars({Key? key, required this.rssi}) : super(key: key);

  final int rssi;

  /// Maps RSSI onto 1..4 lit bars.
  int get _strength {
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final int lit = _strength;

    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < 4; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 3,
              height: 6 + i * 4,
              decoration: BoxDecoration(
                color: i < lit ? c.accent : c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A discovered device: signal, name, address and a connect action.
class DeviceRow extends StatelessWidget {
  const DeviceRow({
    Key? key,
    required this.name,
    required this.identifier,
    required this.actionLabel,
    required this.onAction,
    this.rssi,
    this.highlighted = false,
    this.busy = false,
  }) : super(key: key);

  final String name;
  final String identifier;
  final String actionLabel;
  final VoidCallback? onAction;
  final int? rssi;
  final bool highlighted;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return SensaCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: highlighted ? c.accentSoft : null,
      borderColor: highlighted ? c.accent : null,
      child: Row(
        children: <Widget>[
          if (highlighted)
            Icon(Icons.bluetooth_connected, size: 22, color: c.accent)
          else if (rssi != null)
            SignalBars(rssi: rssi!)
          else
            Icon(Icons.bluetooth, size: 20, color: c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  identifier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: monoStyle(
                    fontSize: 11,
                    color: c.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RowAction(label: actionLabel, onTap: onAction, busy: busy),
        ],
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    Key? key,
    required this.label,
    required this.onTap,
    required this.busy,
  }) : super(key: key);

  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;

    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    valueColor: AlwaysStoppedAnimation<Color>(c.muted),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Adapts a [ScanResult] to a [DeviceRow].
class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, required this.onTap})
      : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  String _name(BuildContext context) {
    if (result.device.platformName.isNotEmpty) {
      return result.device.platformName;
    }
    if (result.advertisementData.advName.isNotEmpty) {
      return result.advertisementData.advName;
    }
    return context.s.unknownDevice;
  }

  @override
  Widget build(BuildContext context) {
    return DeviceRow(
      name: _name(context),
      identifier: '${result.device.remoteId} · ${result.rssi} dBm',
      rssi: result.rssi,
      actionLabel: context.s.connect,
      onAction: onTap,
    );
  }
}
