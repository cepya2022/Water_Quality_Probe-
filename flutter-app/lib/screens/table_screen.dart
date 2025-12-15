import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';

class TableScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Datos"),
          actions: [
            // Consumer<BluetoothProvider>(
            //   builder: (context, provider, _) {
            //     return IconButton(
            //       icon: Icon(Icons.cloud_upload),
            //       onPressed: () {
            //       }
            //     );
            //   },
            // ),
            Consumer<BluetoothProvider>(
              builder: (context, provider, _) {
                return IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      provider.shareCsv();
                    }
                );
              },
            ),
            // Consumer<BluetoothProvider>(
            //   builder: (context, provider, _) {
            //     return IconButton(
            //         icon: Icon(Icons.download),
            //         onPressed: () {
            //         }
            //     );
            //   },
            // ),
            Consumer<BluetoothProvider>(
              builder: (context, provider, _) {
                return IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      provider.clearData();
                    }
                );
              },
            ),
            Consumer<BluetoothProvider>(
              builder: (context, provider, _) {
                return IconButton(
                    icon: Icon(Icons.filter_list_alt),
                    onPressed: () {
                      // provider.clearData();
                    }
                );
              },
            ),
          ]
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical, // Habilita el desplazamiento vertical
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Habilita el desplazamiento horizontal
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('Oxígeno Disuelto [%]')),
                  DataColumn(label: Text('Conductividad [µS/cm]')),
                  DataColumn(label: Text('TDS [mg/l]')),
                  DataColumn(label: Text('pH [UpH]')),
                  DataColumn(label: Text('Temperatura [°C]')),
                  DataColumn(label: Text('Punto')),
                ],
                rows: provider.dataBuffer
                    .where((row) => row.length == 8)
                    .map((row) {
                  return DataRow(
                    cells: row.map((cell) => DataCell(Text(cell))).toList(),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
