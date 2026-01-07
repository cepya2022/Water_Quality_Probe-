import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../constants.dart';


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
            style: ElevatedButton.styleFrom(
                    foregroundColor: primaryColor,
                )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("r"),
            child: Text("Off"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("k"),
            child: Text("Ok"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("a"),
            child: Text("Cancelar"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("n"),
            child: Text("15"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("o"),
            child: Text("1'"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("h"),
            child: Text("5'"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("q"),
            child: Text("15'"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("t"),
            child: Text("30'"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
        ];
      case 2:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("c"),
            child: Text("Cal pH"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("%"),
            child: Text("Set pH"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("v"),
            child: Text("m pH"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("O"),
            child: Text("Cal OD"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("d"),
            child: Text("Cal EC"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("D"),
            child: Text("EC 1 pto"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          ElevatedButton(
            onPressed: () => provider.sendMessage("k"),
            child: Text("Ok"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("a"),
            child: Text("Cancelar"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
        ];
      case 3:
        return[
          ElevatedButton(
            onPressed: () => provider.sendMessage("-"),
            child: Text("pH: On"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("@"),
            child: Text("OD: On"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("#"),
            child: Text("EC: On"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("&"),
            child: Text("Todos Off"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
        ];
      case 4:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("P"),
            child: Text("pH"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("X"),
            child: Text("OD"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("Z"),
            child: Text("EC"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("T"),
            child: Text("Temp"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
      ];
      case 5:
        return[
          ElevatedButton(
            onPressed: () => provider.sendMessage("y"),
            child: Text("Datos"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("w"),
            child: Text("Todo"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("e"),
            child: Text("Eliminar"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          // SizedBox(width: 8),
        ];
      default:
        return [
          ElevatedButton(
            onPressed: () => provider.sendMessage("?"),
            child: Text("Estado"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("y"),
            child: Text("Datos"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => provider.sendMessage("R"),
            child: Text("Reloj"),
              style: ElevatedButton.styleFrom(
                foregroundColor: primaryColor,
              )
          ),
        ];
    }
  }
}

