import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// The five measured quantities the probe reports, in the order they arrive on
/// the wire and in the order the canvas lists them.
enum ParamKey { od, ec, tds, ph, temp }

/// One row of the probe's data dump.
///
/// The device sends semicolon separated lines shaped like
/// `dd/MM/yyyy;HH:mm;od;ec;tds;ph;temp;punto`, which is what
/// [BluetoothProvider.dataBuffer] stores.
@immutable
class Reading {
  const Reading({
    required this.timestamp,
    required this.fecha,
    required this.hora,
    required this.od,
    required this.ec,
    required this.tds,
    required this.ph,
    required this.temp,
    required this.punto,
  });

  final DateTime timestamp;
  final String fecha;
  final String hora;
  final double od;
  final double ec;
  final double tds;
  final double ph;
  final double temp;
  final String punto;

  /// pH outside this band is drawn in red, as on the canvas' data cards.
  bool get phOutOfRange => ph < 6.5 || ph > 8.5;

  double valueOf(ParamKey key) {
    switch (key) {
      case ParamKey.od:
        return od;
      case ParamKey.ec:
        return ec;
      case ParamKey.tds:
        return tds;
      case ParamKey.ph:
        return ph;
      case ParamKey.temp:
        return temp;
    }
  }

  /// Parses one `dataBuffer` row, returning `null` for malformed lines so the
  /// UI can simply skip them instead of throwing mid-build.
  static Reading? tryParse(List<String> row) {
    if (row.length < 8) return null;

    final fecha = row[0].trim();
    final hora = row[1].trim();
    final od = double.tryParse(row[2].trim());
    final ec = double.tryParse(row[3].trim());
    final tds = double.tryParse(row[4].trim());
    final ph = double.tryParse(row[5].trim());
    final temp = double.tryParse(row[6].trim());
    final punto = row[7].trim();

    if (od == null || ec == null || tds == null || ph == null || temp == null) {
      return null;
    }

    final timestamp = _parseTimestamp(fecha, hora);
    if (timestamp == null) return null;

    return Reading(
      timestamp: timestamp,
      fecha: fecha,
      hora: hora,
      od: od,
      ec: ec,
      tds: tds,
      ph: ph,
      temp: temp,
      punto: punto.isEmpty ? '-' : punto,
    );
  }

  static DateTime? _parseTimestamp(String fecha, String hora) {
    final date = fecha.split('/');
    if (date.length != 3) return null;
    final day = int.tryParse(date[0]);
    final month = int.tryParse(date[1]);
    final year = int.tryParse(date[2]);
    if (day == null || month == null || year == null) return null;

    final time = hora.split(':');
    final hour = time.isNotEmpty ? int.tryParse(time[0]) ?? 0 : 0;
    final minute = time.length > 1 ? int.tryParse(time[1]) ?? 0 : 0;
    final second = time.length > 2 ? int.tryParse(time[2]) ?? 0 : 0;

    return DateTime(year, month, day, hour, minute, second);
  }
}

/// Display metadata for a [ParamKey]: the colours are the canvas' series
/// colours and the units are the ones the probe reports in.
@immutable
class ParamDef {
  const ParamDef(this.key, this.short, this.unit, this.color);

  final ParamKey key;
  final String short;
  final String unit;
  final Color color;

  String name(AppStrings s) {
    switch (key) {
      case ParamKey.od:
        return s.paramOd;
      case ParamKey.ec:
        return s.paramEc;
      case ParamKey.tds:
        return s.paramTds;
      case ParamKey.ph:
        return s.paramPh;
      case ParamKey.temp:
        return s.paramTemp;
    }
  }

  /// Label for the chart's y axis, e.g. "Temperatura (°C)".
  String axisLabel(AppStrings s) => s.axisFor(name(s), unit);

  /// How many decimals this parameter reads well at, given the user's
  /// "Decimales" preference. Conductivity and TDS are whole-number units, and
  /// dissolved oxygen carries one digit less than pH and temperature.
  int decimalsFor(int preference) {
    switch (key) {
      case ParamKey.ec:
      case ParamKey.tds:
        return 0;
      case ParamKey.od:
        return (preference - 1).clamp(0, 3).toInt();
      case ParamKey.ph:
      case ParamKey.temp:
        return preference;
    }
  }

  String format(double value, int preference) =>
      value.toStringAsFixed(decimalsFor(preference));
}

const List<ParamDef> kParams = <ParamDef>[
  ParamDef(ParamKey.od, 'OD', '%', Color(0xFF2196F3)),
  ParamDef(ParamKey.ec, 'EC', 'µS/cm', Color(0xFF4CAF50)),
  ParamDef(ParamKey.tds, 'TDS', 'mg/l', Color(0xFFFF9800)),
  ParamDef(ParamKey.ph, 'pH', 'UpH', Color(0xFF9C27B0)),
  ParamDef(ParamKey.temp, 'T', '°C', Color(0xFFF44336)),
];

ParamDef paramFor(ParamKey key) =>
    kParams.firstWhere((ParamDef p) => p.key == key);

/// The four presets behind the range chips on Datos and Gráficos.
enum DataRange { today, week, month, all }

extension DataRangeX on DataRange {
  String label(AppStrings s) {
    switch (this) {
      case DataRange.today:
        return s.rangeToday;
      case DataRange.week:
        return s.range7d;
      case DataRange.month:
        return s.range30d;
      case DataRange.all:
        return s.rangeAll;
    }
  }

  /// Filters relative to the newest reading rather than to "now", so the
  /// presets stay useful when looking at a dump downloaded days later.
  List<Reading> apply(List<Reading> readings) {
    if (this == DataRange.all || readings.isEmpty) return readings;

    final DateTime newest = readings.last.timestamp;
    late final DateTime from;
    switch (this) {
      case DataRange.today:
        from = DateTime(newest.year, newest.month, newest.day);
        break;
      case DataRange.week:
        from = newest.subtract(const Duration(days: 7));
        break;
      case DataRange.month:
        from = newest.subtract(const Duration(days: 30));
        break;
      case DataRange.all:
        return readings;
    }
    return readings
        .where((Reading r) => !r.timestamp.isBefore(from))
        .toList(growable: false);
  }
}
