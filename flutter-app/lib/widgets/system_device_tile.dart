import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../providers/settings_provider.dart';
import 'scan_result_tile.dart';

/// A device the OS already knows about (paired or connected elsewhere).
///
/// It reuses [DeviceRow] so system devices and freshly scanned ones look the
/// same in the list.
class SystemDeviceTile extends StatelessWidget {
  const SystemDeviceTile({
    Key? key,
    required this.device,
    required this.onConnect,
    this.onOpen,
    this.connected = false,
  }) : super(key: key);

  final BluetoothDevice device;
  final VoidCallback onConnect;
  final VoidCallback? onOpen;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final String name = device.platformName.isNotEmpty
        ? device.platformName
        : context.s.unknownDevice;

    return DeviceRow(
      name: name,
      identifier: device.remoteId.toString(),
      highlighted: connected,
      actionLabel: connected ? context.s.disconnect : context.s.connect,
      onAction: onConnect,
    );
  }
}
