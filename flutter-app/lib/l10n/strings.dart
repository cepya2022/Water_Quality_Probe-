import 'package:flutter/widgets.dart';

/// UI copy for the two languages offered by the "Idioma" row on the
/// Configuración screen. Spanish is the source of truth: the canvas is written
/// in Spanish, so the `es` values are the literal strings from
/// `ProbeApp.dc.html`.
class AppStrings {
  const AppStrings(this.isEnglish);

  final bool isEnglish;

  String _t(String es, String en) => isEnglish ? en : es;

  // ---- shell -------------------------------------------------------------
  String get brand => 'SENSA';
  String get navControl => _t('Control', 'Control');
  String get navDevices => _t('Equipo', 'Device');
  String get navData => _t('Datos', 'Data');
  String get navCharts => _t('Gráficos', 'Charts');
  String get navSettings => _t('Ajustes', 'Settings');

  String get titleControl => _t('Control', 'Control');
  String get titleDevices => _t('Dispositivos', 'Devices');
  String get titleData => _t('Datos', 'Data');
  String get titleCharts => _t('Gráficos', 'Charts');
  String get titleSettings => _t('Configuración', 'Settings');

  String get notConnected => _t('Sin conexión', 'Not connected');
  String get connect => _t('Conectar', 'Connect');
  String get disconnect => _t('Desconectar', 'Disconnect');
  String get disconnected => _t('Desconectado', 'Disconnected');
  String connectedTo(String name) =>
      _t('Conectado a $name', 'Connected to $name');

  // ---- control -----------------------------------------------------------
  String get tabReadings => _t('Lecturas', 'Readings');
  String get tabTerminal => _t('Terminal', 'Terminal');
  String get autoMeasurement => _t('Medición automática', 'Automatic sampling');
  String everyInterval(String value) => _t('Cada $value', 'Every $value');
  String get stopped => _t('Detenida', 'Stopped');
  String get interval => _t('Intervalo', 'Interval');
  String get instantRead => _t('Lectura instantánea', 'Instant reading');
  String get actions => _t('Acciones', 'Actions');
  String get fetchNewData => _t('Traer datos nuevos', 'Fetch new data');
  String get sinceLastDownload =>
      _t('Desde la última descarga', 'Since the last download');
  String get calibrateSensors => _t('Calibrar sensores', 'Calibrate sensors');
  String get exportCsv => _t('Exportar CSV', 'Export CSV');
  String get console => _t('Consola', 'Console');
  String lineCount(int n) => _t('$n líneas', '$n lines');
  String get manualCommand => _t('Comando manual…', 'Manual command…');
  String get clearConsole => _t('Limpiar consola', 'Clear console');
  String readingParam(String param) => _t('Leyendo $param…', 'Reading $param…');
  String get csvShared => _t('CSV compartido', 'CSV shared');
  String get noDataToExport =>
      _t('No hay datos para exportar', 'No data to export');
  String get generatingCsv => _t('Generando CSV…', 'Generating CSV…');

  // ---- devices -----------------------------------------------------------
  String get otherDevices => _t('Otros dispositivos', 'Other devices');
  String get search => _t('Buscar', 'Search');
  String get searching => _t('Buscando…', 'Searching…');
  String get searchingDevices =>
      _t('Buscando dispositivos…', 'Searching for devices…');
  String get pullToRefresh =>
      _t('Deslizá para actualizar', 'Pull down to refresh');
  String get noDevicesFound =>
      _t('No se encontraron dispositivos', 'No devices found');
  String get noDeviceConnected =>
      _t('Ningún equipo conectado', 'No device connected');
  String get connectLastDevice =>
      _t('Conectar al último equipo', 'Connect to the last device');
  String get unknownDevice => _t('Desconocido', 'Unknown');

  // ---- data --------------------------------------------------------------
  String get rangeToday => _t('Hoy', 'Today');
  String get range7d => _t('7 días', '7 days');
  String get range30d => _t('30 días', '30 days');
  String get rangeAll => _t('Todo', 'All');
  String get point => _t('Punto', 'Point');
  String get allPoints => _t('Todos', 'All');
  String measurementCount(int n) =>
      _t('$n mediciones', n == 1 ? '1 measurement' : '$n measurements');
  String get cardsView => _t('Tarjetas', 'Cards');
  String get tableView => _t('Tabla', 'Table');
  String pointLabel(String p) => _t('Punto $p', 'Point $p');
  String get noData => _t('Todavía no hay mediciones', 'No measurements yet');
  String get noDataHint => _t(
        'Traé los datos del equipo desde Control.',
        'Fetch data from the probe on the Control tab.',
      );
  String get noDataInRange => _t(
        'No hay mediciones en este rango',
        'No measurements in this range',
      );
  String get clearData => _t('Borrar datos', 'Clear data');
  String get clearDataConfirm => _t(
        'Se van a borrar todas las mediciones descargadas.',
        'Every downloaded measurement will be deleted.',
      );
  String get cancel => _t('Cancelar', 'Cancel');
  String get delete => _t('Borrar', 'Delete');
  String get dataCleared => _t('Datos borrados', 'Data cleared');
  String get time => _t('Hora', 'Time');

  // ---- charts ------------------------------------------------------------
  String get tapChartHint => _t(
        'Tocá el gráfico para leer un punto',
        'Tap the chart to read a point',
      );
  String get statMin => _t('Mín', 'Min');
  String get statAvg => _t('Prom', 'Avg');
  String get statMax => _t('Máx', 'Max');
  String chartFooter(int n, String from, String to) =>
      _t('$n puntos · $from a $to', '$n points · $from to $to');
  String get chartExported =>
      _t('Gráfico exportado como PNG', 'Chart exported as PNG');
  String get notEnoughData => _t(
        'Se necesitan al menos dos mediciones',
        'At least two measurements are needed',
      );

  // ---- parameters --------------------------------------------------------
  String get paramOd => _t('Oxígeno Disuelto', 'Dissolved Oxygen');
  String get paramEc => _t('Conductividad', 'Conductivity');
  String get paramTds => _t('TDS', 'TDS');
  String get paramPh => _t('pH', 'pH');
  String get paramTemp => _t('Temperatura', 'Temperature');
  String get shortTemp => _t('Temp', 'Temp');
  String axisFor(String name, String unit) => '$name ($unit)';

  // ---- settings ----------------------------------------------------------
  String get secMeasurement => _t('Medición', 'Measurement');
  String get secSensors => _t('Sensores', 'Sensors');
  String get secCalibration => _t('Calibración', 'Calibration');
  String get secUnits => _t('Unidades y precisión', 'Units and precision');
  String get secDevice => _t('Dispositivo', 'Device');
  String get secAppearance => _t('Apariencia', 'Appearance');

  String get samplingInterval =>
      _t('Intervalo de muestreo', 'Sampling interval');
  String get samplingIntervalSub => _t(
        'Se guarda en la SD junto al estado',
        'Stored on the SD card along with the status',
      );
  String get samplingPoint => _t('Punto de muestreo', 'Sampling point');
  String get decimals => _t('Decimales', 'Decimals');
  String get autoConnect =>
      _t('Conectar automáticamente', 'Connect automatically');
  String autoConnectSub(String name) => _t(
        'Al último equipo usado ($name)',
        'To the last device used ($name)',
      );
  String get autoConnectNoDevice =>
      _t('Al último equipo usado', 'To the last device used');
  String get lightMode => _t('Modo claro', 'Light mode');
  String get lightModeSub =>
      _t('Pensado para uso al sol', 'Made for use in sunlight');
  String get language => _t('Idioma', 'Language');
  String get sensorOd => _t('Oxígeno disuelto', 'Dissolved oxygen');
  String get notCalibrated => _t('Sin calibrar', 'Not calibrated');
  String calibratedOn(String date) => _t('Calibrado $date', 'Calibrated $date');
  String get calibrationHint => _t(
        'Seguí las indicaciones del equipo en la consola y confirmá al terminar.',
        'Follow the probe instructions in the console and confirm when finished.',
      );
  String get footer => 'SENSA · Water Quality Probe';
  String get save => _t('Guardar', 'Save');
  String intervalSet(String value) => _t('Intervalo $value', 'Interval $value');
  String get commandSent =>
      _t('Comando enviado al equipo', 'Command sent to the probe');

  // ---- terminal command sets --------------------------------------------
  String get setStatus => _t('Estado', 'Status');
  String get setMeasurement => _t('Medición', 'Measurement');
  String get setCalibration => _t('Calibración', 'Calibration');
  String get setSensors => _t('Sensores', 'Sensors');
  String get setReading => _t('Sensado', 'Reading');
  String get setData => _t('Datos', 'Data');

  String get cmdStatus => _t('Estado', 'Status');
  String get cmdClock => _t('Reloj', 'Clock');
  String get cmdNewData => _t('Datos nuevos', 'New data');
  String get cmdOn => 'On';
  String get cmdOff => 'Off';
  String get cmdOk => 'Ok';
  String get cmdCancel => _t('Cancelar', 'Cancel');
  String get cmdCalPh => 'Cal pH';
  String get cmdSetPh => 'Set pH';
  String get cmdMPh => 'm pH';
  String get cmdCalOd => _t('Cal OD', 'Cal DO');
  String get cmdCalEc => 'Cal EC';
  String get cmdEcOnePoint => _t('EC 1 pto', 'EC 1 pt');
  String get cmdPhOn => 'pH: On';
  String get cmdOdOn => _t('OD: On', 'DO: On');
  String get cmdEcOn => 'EC: On';
  String get cmdAllOff => _t('Todos Off', 'All Off');
  String get cmdData => _t('Datos', 'Data');
  String get cmdAll => _t('Todo', 'All');
  String get cmdErase => _t('Eliminar', 'Erase');

  String get notConnectedWarning => _t(
        'Conectate a un equipo para enviar comandos',
        'Connect to a probe to send commands',
      );
}

/// Publishes the active [AppStrings] to the subtree.
///
/// This is an InheritedWidget rather than a `Provider.of` lookup on purpose:
/// copy is read from event handlers (button taps, sheets, dialogs) as well as
/// from `build`, and a listening `Provider.of` asserts when called outside of a
/// build phase.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    Key? key,
    required this.strings,
    required Widget child,
  }) : super(key: key, child: child);

  final AppStrings strings;

  static AppStrings of(BuildContext context) {
    final AppStringsScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
    assert(scope != null, 'No AppStringsScope found in context');
    return scope?.strings ?? const AppStrings(false);
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.strings.isEnglish != strings.isEnglish;
}
