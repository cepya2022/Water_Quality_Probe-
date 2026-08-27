import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';

/// The sampling intervals offered on Control and Configuración, mapped to the
/// single-character commands the firmware listens for.
const List<String> kIntervals = <String>['15"', "1'", "5'", "15'", "30'"];

const Map<String, String> kIntervalCommands = <String, String>{
  '15"': 'n',
  "1'": 'o',
  "5'": 'h',
  "15'": 'q',
  "30'": 't',
};

/// Sensors the user can switch on and off, and the toggle command for each.
/// Temperature has no firmware toggle, so it is tracked locally only.
const Map<String, String?> kSensorCommands = <String, String?>{
  'ph': '-',
  'od': '@',
  'ec': '#',
  'temp': null,
};

/// Everything the user can configure, persisted across launches.
///
/// The canvas keeps all of this in component state; here it is a real
/// [ChangeNotifier] backed by `SharedPreferences` so the app comes back the way
/// it was left.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _load();
  }

  static const String _kDark = 'settings.darkMode';
  static const String _kEnglish = 'settings.english';
  static const String _kDecimals = 'settings.decimals';
  static const String _kInterval = 'settings.interval';
  static const String _kMeasuring = 'settings.measuring';
  static const String _kSensors = 'settings.sensors';
  static const String _kAutoConnect = 'settings.autoConnect';
  static const String _kPoint = 'settings.samplingPoint';
  static const String _kCalibration = 'settings.calibration';

  bool _darkMode = true;
  bool _english = false;
  int _decimals = 2;
  String _interval = "30'";
  bool _measuring = true;
  bool _autoConnect = true;
  String _samplingPoint = '3';
  Map<String, bool> _sensors = <String, bool>{
    'ph': true,
    'od': true,
    'ec': true,
    'temp': true,
  };

  /// Last calibration date per sensor key, formatted `dd/MM/yyyy`.
  Map<String, String> _calibration = <String, String>{};

  bool _loaded = false;

  bool get darkMode => _darkMode;
  bool get english => _english;
  int get decimals => _decimals;
  String get interval => _interval;
  bool get measuring => _measuring;
  bool get autoConnect => _autoConnect;
  String get samplingPoint => _samplingPoint;
  Map<String, bool> get sensors => Map<String, bool>.unmodifiable(_sensors);
  bool get isLoaded => _loaded;

  AppStrings get strings => AppStrings(_english);

  String? calibrationDate(String sensor) => _calibration[sensor];

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDark) ?? _darkMode;
    _english = prefs.getBool(_kEnglish) ?? _english;
    _decimals = prefs.getInt(_kDecimals) ?? _decimals;
    _measuring = prefs.getBool(_kMeasuring) ?? _measuring;
    _autoConnect = prefs.getBool(_kAutoConnect) ?? _autoConnect;
    _samplingPoint = prefs.getString(_kPoint) ?? _samplingPoint;

    final String? interval = prefs.getString(_kInterval);
    if (interval != null && kIntervals.contains(interval)) {
      _interval = interval;
    }

    _sensors = _decodeBoolMap(prefs.getString(_kSensors), _sensors);
    _calibration = _decodeStringMap(prefs.getString(_kCalibration));

    _loaded = true;
    notifyListeners();
  }

  Map<String, bool> _decodeBoolMap(String? raw, Map<String, bool> fallback) {
    if (raw == null) return fallback;
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return <String, bool>{
        for (final String key in fallback.keys)
          key: decoded[key] as bool? ?? fallback[key]!,
      };
    } catch (_) {
      return fallback;
    }
  }

  Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null) return <String, String>{};
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (String key, dynamic value) =>
            MapEntry<String, String>(key, value.toString()),
      );
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> _persist(void Function(SharedPreferences prefs) write) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    write(prefs);
  }

  set darkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setBool(_kDark, value));
  }

  set english(bool value) {
    if (_english == value) return;
    _english = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setBool(_kEnglish, value));
  }

  set decimals(int value) {
    if (_decimals == value) return;
    _decimals = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setInt(_kDecimals, value));
  }

  set interval(String value) {
    if (_interval == value) return;
    _interval = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setString(_kInterval, value));
  }

  set measuring(bool value) {
    if (_measuring == value) return;
    _measuring = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setBool(_kMeasuring, value));
  }

  set autoConnect(bool value) {
    if (_autoConnect == value) return;
    _autoConnect = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setBool(_kAutoConnect, value));
  }

  set samplingPoint(String value) {
    if (_samplingPoint == value) return;
    _samplingPoint = value;
    notifyListeners();
    _persist((SharedPreferences p) => p.setString(_kPoint, value));
  }

  void setSensor(String key, bool value) {
    if (_sensors[key] == value) return;
    _sensors = <String, bool>{..._sensors, key: value};
    notifyListeners();
    _persist(
      (SharedPreferences p) => p.setString(_kSensors, jsonEncode(_sensors)),
    );
  }

  /// Records that [sensor] finished a calibration run, so the Configuración row
  /// can show a real "Calibrado dd/MM/yyyy" subtitle.
  void markCalibrated(String sensor, DateTime when) {
    final String day = when.day.toString().padLeft(2, '0');
    final String month = when.month.toString().padLeft(2, '0');
    _calibration = <String, String>{
      ..._calibration,
      sensor: '$day/$month/${when.year}',
    };
    notifyListeners();
    _persist(
      (SharedPreferences p) =>
          p.setString(_kCalibration, jsonEncode(_calibration)),
    );
  }
}

extension AppStringsX on BuildContext {
  /// Shorthand for the active copy: `context.s.titleControl`.
  ///
  /// Backed by [AppStringsScope], so this is safe to call from event handlers
  /// as well as from `build`.
  AppStrings get s => AppStringsScope.of(this);
}
