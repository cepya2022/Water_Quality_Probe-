import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/bluetooth_provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

Set<String> shownDates = {};

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

          final List<String> parametros = [
            'Oxígeno Disuelto',
            'Conductividad',
            'TDS',
            'pH',
            'Temperatura',
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: parametros.length,
            itemBuilder: (context, index) {
              final parametro = parametros[index];

              final int nYLabels = 6; // change to 4 or 6 if you want
              double minY = double.infinity;
              double maxY = -double.infinity;

              for (final row in filteredData) {
                final raw = row[parametro];

                if (raw == null) continue;

                final double? y = raw is num
                    ? raw.toDouble()
                    : double.tryParse(raw.toString());

                if (y == null) continue;

                minY = math.min(minY, y);
                maxY = math.max(maxY, y);
              }

              List<double> yTicks(int n, double minY, double maxY) {
                if (n < 2) return [minY];

                final step = (maxY - minY) / (n - 1);
                return List.generate(n, (i) => minY + step * i);
              }

              final double yInterval = (maxY - minY) / (nYLabels - 1);

              final yTickValues = yTicks(nYLabels, minY, maxY); // 4 or 6 also OK
              final interval = (maxY - minY) / (yTickValues.length - 1);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parametro,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      // padding: const EdgeInsets.only(left: 16),
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          // minY: minY,
                          // maxY: maxY,
                          lineBarsData: _generateLineBarsData(filteredData, parametro),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(

                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {

                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 6,
                                      child: Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                interval: 1, // important for index-based axes
                                getTitlesWidget: (value, meta) {
                                  final index = value.round();

                                  if (index < 0 || index >= filteredData.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final maxLabels = 6;
                                  final step = (filteredData.length / maxLabels)
                                      .ceil()
                                      .clamp(1, filteredData.length);

                                  // Only show every Nth label
                                  if (index % step != 0) {
                                    return const SizedBox.shrink();
                                  }

                                  final dateStr = filteredData[index]['Fecha'];

                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8,
                                    child: Transform.rotate(
                                      angle: -math.pi / 4,
                                      alignment: Alignment(1.0, 0.0),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  );
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
                    SizedBox(height: 4),
                    Text(
                      'Fecha',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
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
