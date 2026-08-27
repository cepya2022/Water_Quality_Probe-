import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_result_tile.dart';
import '../widgets/sensa_ui.dart';
import '../widgets/system_device_tile.dart';

/// Dispositivos: the connected probe on top, everything else discoverable
/// underneath.
class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  DateTime? _lastScan;

  Future<void> _scan() async {
    final BluetoothProvider bluetooth = context.read<BluetoothProvider>();
    if (bluetooth.isScanning) return;

    setState(() => _lastScan = DateTime.now());
    showSensaToast(context, context.s.searchingDevices);
    await bluetooth.startScanning();
  }

  String _clock(DateTime time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;
    final BluetoothProvider bluetooth = context.watch<BluetoothProvider>();

    final String? connectedName = bluetooth.connectedDeviceName;
    final String? connectedId = bluetooth.connectedDeviceId;
    final List<ScanResult> results = bluetooth.scanResults
        .where((ScanResult r) => r.device.remoteId.toString() != connectedId)
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _scan,
      color: c.accent,
      backgroundColor: c.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          if (connectedName != null)
            DeviceRow(
              name: connectedName,
              identifier: connectedId ?? '',
              highlighted: true,
              actionLabel: s.disconnect,
              onAction: () {
                bluetooth.disconnectDevice();
                showSensaToast(context, s.disconnected);
              },
            )
          else
            _NoConnectionCard(
              lastDeviceName: bluetooth.lastKnownDeviceName,
              busy: bluetooth.isConnecting,
              onConnect: bluetooth.connectToLastDevice,
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: SectionLabel(
                  s.otherDevices,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                ),
              ),
              InkWell(
                onTap: _scan,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.refresh, size: 16, color: c.accent),
                      const SizedBox(width: 6),
                      Text(
                        s.search,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final BluetoothDevice device in bluetooth.systemDevices)
            if (device.remoteId.toString() != connectedId)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SystemDeviceTile(
                  device: device,
                  onConnect: () => bluetooth.connectToDevice(device),
                ),
              ),
          for (final ScanResult result in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ScanResultTile(
                result: result,
                onTap: () => bluetooth.connectToDevice(result.device),
              ),
            ),
          if (results.isEmpty &&
              bluetooth.systemDevices.isEmpty &&
              !bluetooth.isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  s.noDevicesFound,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              bluetooth.isScanning
                  ? s.searching
                  : _lastScan == null
                      ? s.pullToRefresh
                      : '${s.pullToRefresh} · ${_clock(_lastScan!)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the connected-device card when nothing is paired yet.
class _NoConnectionCard extends StatelessWidget {
  const _NoConnectionCard({
    Key? key,
    required this.lastDeviceName,
    required this.busy,
    required this.onConnect,
  }) : super(key: key);

  final String? lastDeviceName;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final SensaColors c = context.colors;
    final AppStrings s = context.s;

    return SensaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Icon(Icons.bluetooth_disabled, size: 22, color: c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  s.noDeviceConnected,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastDeviceName ?? s.connectLastDevice,
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
          if (lastDeviceName != null)
            Material(
              color: c.accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: busy ? null : onConnect,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: busy
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(c.accentInk),
                          ),
                        )
                      : Text(
                          s.connect,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.accentInk,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
