import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/side_menu.dart';
import '../widgets/buttons.dart';

class ConfigScreen extends StatefulWidget {
  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {

  Widget buildBluetoothOffIcon(BuildContext context) {
    return const Icon(
      Icons.settings,
      size: 200.0,
      color: Colors.white54,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configuración"),
        // actions: [
        //   Consumer<BluetoothProvider>(
        //     builder: (context, provider, _) {
        //       return IconButton(
        //         icon: Icon(Icons.bluetooth_searching),
        //         onPressed: () {},
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildBluetoothOffIcon(context),
          ],
        ),
      ),
    );
  }
}