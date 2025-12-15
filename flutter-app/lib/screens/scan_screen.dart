import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
// import 'device_screen.dart';

class ScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!bluetoothProvider.isConnecting) {
            await bluetoothProvider.startScanning();
          }
        },
        child: ListView(
          children: [
            ...bluetoothProvider.systemDevices.map(
                  (device) => SystemDeviceTile(
                device: device,
                onOpen: () => {},
                onConnect: () => bluetoothProvider.connectToDevice(device),
              ),
            ),
            ...bluetoothProvider.scanResults.map(
                  (result) => ScanResultTile(
                result: result,
                onTap: () => bluetoothProvider.connectToDevice(result.device),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: bluetoothProvider.isConnecting
          ? FloatingActionButton(
        onPressed: bluetoothProvider.stopScan,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      )
          : FloatingActionButton(
        onPressed: bluetoothProvider.startScanning,
        child: const Text("SCAN"),
      ),
    );
  }
}
