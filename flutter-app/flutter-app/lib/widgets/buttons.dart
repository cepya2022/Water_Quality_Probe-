import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';

class ControlButtons extends StatelessWidget {
  final int buttonSet;

  const ControlButtons({Key? key, required this.buttonSet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BluetoothProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: _getButtonSet(provider),
      ),
    );
  }

  List<Widget> _getButtonSet(BluetoothProvider provider) {
    switch (buttonSet) {
      case 1:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("g"),
            child: Text("On"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("r"),
            child: Text("Off"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("k"),
            child: Text("Ok"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("a"),
            child: Text("Cancelar"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("n"),
            child: Text("15"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("o"),
            child: Text("1'"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("h"),
            child: Text("5'"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("q"),
            child: Text("15'"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("t"),
            child: Text("30'"),
          ),
        ];
      case 2:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("c"),
            child: Text("Cal pH"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("%"),
            child: Text("Set pH"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("v"),
            child: Text("m pH"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("O"),
            child: Text("Cal OD"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("d"),
            child: Text("Cal EC"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("D"),
            child: Text("EC 1 pto"),
          ),
          ElevatedButton(
            onPressed: () => provider.sendMessage("k"),
            child: Text("Ok"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("a"),
            child: Text("Cancelar"),
          ),
        ];
      case 3:
        return[
          ElevatedButton(
            onPressed: () => provider.sendMessage("-"),
            child: Text("pH: On"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("@"),
            child: Text("OD: On"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("#"),
            child: Text("EC: On"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("&"),
            child: Text("Todos Off"),
          ),
        ];
      case 4:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("P"),
            child: Text("pH"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("X"),
            child: Text("OD"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("Z"),
            child: Text("EC"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("T"),
            child: Text("Temp"),
          ),
      ];
      case 5:
        return[
          ElevatedButton(
            onPressed: () => provider.sendMessage("y"),
            child: Text("Datos"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("w"),
            child: Text("Todo"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("e"),
            child: Text("Eliminar"),
          ),
          // SizedBox(width: 8),
        ];
      default:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("?"),
            child: Text("Estado"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("y"),
            child: Text("Datos"),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("R"),
            child: Text("Reloj"),
          ),
        ];
    }
  }
}

