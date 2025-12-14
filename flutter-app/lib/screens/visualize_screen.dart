import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/bluetooth_provider.dart';
import 'package:intl/intl.dart';

class VisualizeScreen extends StatefulWidget {
  @override
  _VisualizeScreenState createState() => _VisualizeScreenState();
}

class _VisualizeScreenState extends State<VisualizeScreen> {
  DateTimeRange? selectedDateRange;
  String _parametro = "Oxígeno Disuelto";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Visualización de Datos"),
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(Icons.date_range),
                onPressed: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    // firstDate: provider.dataBuffer.isNotEmpty ? DateFormat('dd/MM/yyyy').parse(provider.dataBuffer.first[0]) : DateTime(2000),
                    // lastDate: provider.dataBuffer.isNotEmpty ? DateFormat('dd/MM/yyyy').parse(provider.dataBuffer.last[0]) : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDateRange = picked;
                    });
                  }
                },
              );
            },
          ),
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () {}
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, _) {
          final filteredData = _filterDataByDateRange(provider.getMappedData());

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButton(
                    value: _parametro,
                    items: ['Oxígeno Disuelto','Conductividad','TDS','pH','Temperatura'].map((variable) {
                      return DropdownMenuItem<String>(
                        value: variable,
                        child: Text(variable),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _parametro = newValue!;
                  });
                },),
                Text(
                  "Gráfico",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Flexible(
                  flex: 2,
                  child: Column(
                    children: [
                      // Nombre del eje Y (vertical)
                      Expanded(
                        child: Row(
                          children: [
                            // Eje Y
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                'Concentración (mg/L)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 200, // Podés ajustar este valor
                                  child: LineChart(
                                    LineChartData(
                                      lineBarsData: _generateLineBarsData(filteredData, _parametro),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: true),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40, // MÁS espacio para que entren los textos
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              if (index >= 0 && index < filteredData.length) {
                                                final dateStr = filteredData[index]['Fecha'] + ':' + filteredData[index]['Hora'];
                                                try {
                                                  DateFormat('dd/MM/yyyy').parse(dateStr);
                                                  return Text(
                                                    dateStr,
                                                    style: TextStyle(fontSize: 8), // achicamos fuente
                                                  );
                                                } catch (e) {
                                                  return Text('');
                                                }
                                              }
                                              return Text('');
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: true),
                                      gridData: FlGridData(show: true),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Espacio para el eje X (horizontal)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Fecha', // ← eje X
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          );

          // return filteredData.isNotEmpty
          //     ? Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Column(
          //     children: [
          //       DropdownButton(
          //           value: _parametro,
          //           items: ['Oxígeno Disuelto','Conductividad','TDS','pH','Temperatura'].map((variable) {
          //             return DropdownMenuItem<String>(
          //               value: variable,
          //               child: Text(variable),
          //             );
          //           }).toList(),
          //       onChanged: (String? newValue) {
          //         setState(() {
          //           _parametro = newValue!;
          //         });
          //       },),
          //       Text(
          //         "Gráfico",
          //         style: TextStyle(
          //             fontSize: 20, fontWeight: FontWeight.bold),
          //       ),
          //       SizedBox(height: 16),
          //       Expanded(
          //         child: LineChart(
          //           LineChartData(
          //             lineBarsData: _generateLineBarsData(filteredData, _parametro),
          //             titlesData: FlTitlesData(
          //               leftTitles: AxisTitles(
          //                 sideTitles: SideTitles(showTitles: true),
          //               ),
          //               bottomTitles: AxisTitles(
          //                 sideTitles: SideTitles(
          //                   showTitles: true,
          //                   interval: 15, // Intervalo entre etiquetas
          //
          //                   getTitlesWidget: (value, meta) {
          //                     final index = value.toInt();
          //                     if (index >= 0 && index < filteredData.length) {
          //                       final dateStr = filteredData[index]['Fecha'] + ':' + filteredData[index]['Hora'];
          //                       try {
          //                         final parsedDate = DateFormat('dd/MM/yyyy').parse(dateStr);
          //                         return Text(
          //                           // DateFormat('dd/MM/yyyy').format(parsedDate),
          //                           dateStr,
          //                           style: TextStyle(fontSize: 10),
          //                         );
          //                       } catch (e) {
          //                         return Text('');
          //                       }
          //                     }
          //                     return Text('');
          //                   },
          //                 ),
          //               ),
          //               rightTitles: AxisTitles(
          //                 sideTitles: SideTitles(showTitles: false),
          //               ),
          //               topTitles: AxisTitles(
          //                 sideTitles: SideTitles(showTitles: false),
          //               ),
          //             ),
          //             borderData: FlBorderData(show: true),
          //             gridData: FlGridData(show: true),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // )
          //     : Center(
          //   child: Text("No hay datos disponibles para visualizar."),
          // );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterDataByDateRange(
      List<Map<String, dynamic>> dataBuffer) {
    if (selectedDateRange == null) return dataBuffer;

    return dataBuffer.where((row) {
      if (row.containsKey('Fecha') && row['Fecha'] is String) {
        final date = DateFormat('dd/MM/yyyy').parse(row['Fecha']);
        return date.isAfter(selectedDateRange!.start.subtract(Duration(days: 1))) &&
            date.isBefore(selectedDateRange!.end.add(Duration(days: 1)));
      }
      return false;
    }).toList();
  }

  List<LineChartBarData> _generateLineBarsData(
      List<Map<String, dynamic>> filteredData, column) {
    final List<String> columns = [
      'Oxígeno Disuelto',
      'Conductividad',
      'TDS',
      'pH',
      'Temperatura',
    ];

    return [LineChartBarData(
            spots: _generateFlSpots(filteredData, column),
            isCurved: true,
            color:
              _getColorForColumn(column),
            barWidth: 3,
            dotData: FlDotData(show: false),
          )];

    // return columns.map((column) {
    //   return LineChartBarData(
    //     spots: _generateFlSpots(filteredData, column),
    //     isCurved: true,
    //     color:
    //       _getColorForColumn(column),
    //     barWidth: 3,
    //     dotData: FlDotData(show: false),
    //   );
    // }).toList();
  }

  List<FlSpot> _generateFlSpots(
      List<Map<String, dynamic>> filteredData, String column) {
    List<FlSpot> spots = [];

    for (int i = 0; i < filteredData.length; i++) {
      final row = filteredData[i];
      if (row.containsKey(column) && row[column] != null) {
        final value = double.tryParse(row[column].toString());
        if (value != null) {
          spots.add(FlSpot(i.toDouble(), value));
        }
      }
    }
    return spots;
  }

  Color _getColorForColumn(String column) {
    switch (column) {
      case 'Oxígeno Disuelto':
        return Colors.blue;
      case 'Conductividad':
        return Colors.green;
      case 'TDS':
        return Colors.orange;
      case 'pH':
        return Colors.purple;
      case 'Temperatura':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
