import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/reading.dart';
// import 'package:share/share.dart';

class BluetoothProvider extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothDevice? _lastDevice;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isData = false;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _messages = [];
  List<BluetoothDevice> systemDevices = [];
  List<ScanResult> scanResults = [];
  List<List<String>> _dataBuffer = [];
  String _buffer = ""; // Buffer para almacenar los datos parciales


  BluetoothProvider() {
    _restoreLastDevice();
  }

  String? _lastDeviceName;

  /// Bumped on every mutation of [_dataBuffer] so [readings] knows when its
  /// cached parse is stale.
  int _dataVersion = 0;
  int _readingsVersion = -1;
  List<Reading> _readingsCache = const <Reading>[];

  List<Map<String, dynamic>> get messages => _messages;
  List<List<String>> get dataBuffer => _dataBuffer;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  bool get isGenerating => _isGenerating;
  BluetoothDevice? get lastDevice => _lastDevice;
  bool get hasData => _dataBuffer.isNotEmpty;

  /// Name of the device currently connected, if any.
  String? get connectedDeviceName {
    final BluetoothDevice? device = _device;
    if (device == null || !_isConnected) return null;
    final String name = device.platformName;
    return name.isNotEmpty ? name : device.remoteId.toString();
  }

  /// Address of the device currently connected, if any. Derived from the live
  /// connection rather than from [lastDevice], which only tracks devices that
  /// went through [connectToDevice].
  String? get connectedDeviceId {
    final BluetoothDevice? device = _device;
    if (device == null || !_isConnected) return null;
    return device.remoteId.toString();
  }

  /// Name of the last device connected to, remembered across launches so the
  /// header and the "Conectar automáticamente" row can show it while offline.
  String? get lastKnownDeviceName => _lastDeviceName;

  /// [dataBuffer] parsed into typed rows, oldest first. Malformed lines are
  /// skipped rather than throwing while the UI builds.
  List<Reading> get readings {
    if (_readingsVersion != _dataVersion) {
      final List<Reading> parsed = <Reading>[];
      for (final List<String> row in _dataBuffer) {
        final Reading? reading = Reading.tryParse(row);
        if (reading != null) parsed.add(reading);
      }
      parsed.sort((Reading a, Reading b) => a.timestamp.compareTo(b.timestamp));
      _readingsCache = List<Reading>.unmodifiable(parsed);
      _readingsVersion = _dataVersion;
    }
    return _readingsCache;
  }

  /// Distinct sampling points present in the downloaded data.
  List<String> get samplingPoints {
    final Set<String> points = <String>{};
    for (final Reading reading in readings) {
      points.add(reading.punto);
    }
    final List<String> sorted = points.toList()..sort();
    return sorted;
  }

  Future<void> _restoreLastDevice() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('lastDevice');
      if (raw == null) return;
      final Map<String, dynamic> data =
          jsonDecode(raw) as Map<String, dynamic>;
      _lastDevice = BluetoothDevice.fromId(data['id'] as String);
      _lastDeviceName = data['name'] as String?;
      notifyListeners();
    } catch (e) {
      print('No se pudo restaurar el último dispositivo: $e');
    }
  }


  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _scanStateSubscription;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  BluetoothCharacteristic? _rxCharacteristic;

  void connectToHC08() async {
    await FlutterBluePlus.stopScan();
    _isConnecting = true;
    _isConnected = false;

    // Verificar si el Bluetooth está encendido, y pedir activarlo si no lo está
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    try {
      await _dataSubscription?.cancel(); // Cancelar suscripción de datos si está activa
      _dataSubscription = null;
      await _connectionSubscription?.cancel();
      _dataSubscription = null;
      await _device?.disconnect(); // Desconectar el dispositivo actual
      _device = null;
      _rxCharacteristic = null;
    } catch (e) {
      print("Error al reiniciar Bluetooth: $e");
    }
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      errorMessage("Conectando a HC-08");

      // await Future.delayed(const Duration(seconds: 10));

      FlutterBluePlus.scanResults.listen((results) async {
        for (var result in results) {
          if (result.device.platformName == "HC-08") {
            await FlutterBluePlus.stopScan();
            if (_device == null){
              await result.device.connect();
            }
            _device = result.device;
            _isConnected = true;
            _isConnecting = false;
            _listenToConnectionState();
            _discoverServices();
            String deviceName = result.device.platformName;
            // _messages.clear();
            errorMessage("Conectado a $deviceName");
            notifyListeners();
            return;
          }
        }
      });
      await Future.delayed(const Duration(seconds: 11));
      if (!_isConnected && _isConnecting) {
        _isConnecting = false;
        errorMessage("Conexión fallida");
        notifyListeners();
      }
    } catch (e) {
      _isConnecting = false;
      errorMessage("Error al conectar: $e");
      notifyListeners();
    } finally {
    }
  }

  Future<void> connectToLastDevice() async {
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
    try {
      // Cargar el último dispositivo conectado
      BluetoothDevice? device = await _loadLastDevice();
      if (device != null) {
        String deviceName = device.platformName;
        _isConnecting = true;
        errorMessage("Conectando a: $deviceName");
        await connectToDevice(device);
      } else {
        errorMessage('No existe el último dispositivo.');
      }
    } catch (e) {
      errorMessage('Error de conexión: $e');
    }
  }

  // Métodos privados para persistencia
  Future<void> _saveLastDevice(BluetoothDevice device) async {
    _lastDevice = device;
    _lastDeviceName = device.platformName;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDevice', jsonEncode({
      'id': device.remoteId.toString(),
      'name': device.platformName,
    }));
  }

  Future<BluetoothDevice?> _loadLastDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceString = prefs.getString('lastDevice');
    if (deviceString != null) {
      Map<String, dynamic> deviceData = jsonDecode(deviceString);
      return BluetoothDevice.fromId(deviceData['id']);
    }
    return null;
  }

  Future<void> startScanning() async {
    // Verificar si el Bluetooth está encendido, y pedir activarlo si no lo está
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
    try {
      _isScanning = true;
      notifyListeners();

      // Re-subscribe rather than stacking another listener on every scan, and
      // subscribe before starting so no early result is missed.
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();
      });

      await _scanStateSubscription?.cancel();
      _scanStateSubscription = FlutterBluePlus.isScanning.listen((scanning) {
        _isScanning = scanning;
        notifyListeners();
      });

      // Buscar dispositivos del sistema
      var withServices = [Guid("180f")]; // Ejemplo: Servicio de nivel de batería
      systemDevices = await FlutterBluePlus.systemDevices(withServices);

      // Inicia el escaneo. El estado real lo refleja FlutterBluePlus.isScanning.
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('Error during scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _device = device;
      _isConnected = true;
      _isConnecting = false;
      _listenToConnectionState();
      _discoverServices();
      String deviceName = device.platformName;
      // _messages.clear();
      errorMessage("Conectado a $deviceName");
      _saveLastDevice(device);
      notifyListeners();
    } catch (e) {
      errorMessage("Conexión fallida");
      _isConnecting = false;
    }
  }

  void _listenToConnectionState() {
    _connectionSubscription = _device?.connectionState.listen((state) {
      _isConnected = state == BluetoothConnectionState.connected;
      notifyListeners();
    });
  }

  void _discoverServices() async {
    if (_device != null) {
      List<BluetoothService> services = await _device!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == Guid("0000ffe1-0000-1000-8000-00805f9b34fb") &&
              characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _rxCharacteristic = characteristic;
            _listenToIncomingData();
          }
        }
      }
    }
  }

  void _listenToIncomingData() {
    _dataSubscription = _rxCharacteristic?.onValueReceived.listen((data) {
      String message = utf8.decode(data);
      _buffer += message;


      // Detectar si el mensaje termina con ';' o con un salto de línea
      if (_buffer.contains("\n") || _buffer.endsWith(";")) {
        List<String> messages = _buffer.split("\n");


        for (var msg in messages.sublist(0, messages.length - 1)) {
          // _addOrCombineMessage(msg);

          if (!_isData) {
            _addOrCombineMessage(msg);
          }
          if (_isData){
            _isGenerating = true;
            processData(msg);
          }
        }
        _buffer = messages.last;
      }

      notifyListeners();
    }, onError: (error) {
      errorMessage("Error al recibir datos: $error");
    });
  }

// Función para combinar mensajes si es necesario
  void _addOrCombineMessage(String newMessage) {
    if (_messages.isNotEmpty && !_messages.last["isSentByMe"]) {
      _messages.last["message"] += "\n" + newMessage;
    } else {
      _messages.add({"message": newMessage, "isSentByMe": false});
    }
  }

  void sendMessage(String message) async {
    if (_isConnected && _rxCharacteristic != null) {
      try {
        // Agregar un delimitador explícito (\n) al final del mensaje
        List<int> bytes = utf8.encode("$message\n");
        await _rxCharacteristic?.write(bytes, withoutResponse: true);
        if ( _messages.isEmpty || message != _messages.last["message"]){
          _messages.add({"message": message, "isSentByMe": true});
        }
        if (message == "y"){
          _isData = true;
          _dataBuffer = [];
          _dataVersion++;
        }else{
          _isData = false;
          _isGenerating = false;
        }

        notifyListeners();

        // Introducir una pequeña pausa para asegurar que el mensaje se procese
        await Future.delayed(Duration(milliseconds: 100));

      } catch (e) {
        errorMessage("Error al enviar mensaje: $e");
      }
    } else {
      errorMessage("No se puede enviar mensaje: Dispositivo no conectado o característica nula");
    }
  }

  void errorMessage(String message) async {
    _messages.add({"message": message, "isSentByMe": false});
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners(); // Notificar a los listeners para actualizar la UI
  }

  void clearData(){
    _dataBuffer.clear();
    _dataVersion++;
    notifyListeners();
  }

  Future<void> disconnectDevice() async {
    if (_device != null) {
      try {
        // Cancelar suscripción de datos si está activa
        await _dataSubscription?.cancel();
        _dataSubscription = null;

        // Cancelar suscripción de conexión si está activa
        await _connectionSubscription?.cancel();
        _connectionSubscription = null;

        // Cerrar la conexión con el dispositivo
        await _device?.disconnect();
        _device = null;

        // Limpiar estados
        _rxCharacteristic = null;
        _isConnected = false;
        _isConnecting = false;
        _buffer = "";

        // Notificar al usuario
        errorMessage("Desconectado exitosamente");
        // notifyListeners();
        _listenToConnectionState();
      } catch (e) {
        print("Error al desconectar el dispositivo: $e");
      }
    }
  }

  void processData(String data) {
    // Divide la cadena en líneas si llegan múltiples datos juntos
    // errorMessage("A procesar: $data");
    List<String> lines = data.split("\n");
    if (data.contains("Datos enviados.")){
      saveCsv("Datos");
      _isData = false;
      _isGenerating = false;
      errorMessage("Datos enviados.");
      notifyListeners();
      return;
    }
    if (data.contains("mando")){
      errorMessage("Ahi te mando.");
      return;
    }
    for (String line in lines) {
      if (line.isNotEmpty) {
        _dataBuffer.add(line.split(";"));
        _dataVersion++;
        // errorMessage(line);
      }
    }
    // _isData = false;
    // _isGenerating = false;
    // notifyListeners();
  }

  String generateCsv() {
    if (_dataBuffer.isEmpty) {
      return 'No data available';
    }

    // Construye el contenido del CSV
    List<String> csvContent = [
      "Fecha,Hora,Oxígeno Disuelto,Conductividad,TDS,pH,Temperatura,Punto de Muestreo"
    ];

    for (var row in _dataBuffer) {
      csvContent.add(row.join(","));
    }

    return csvContent.join("\n");
  }

  Future<File> saveCsv(String fileName) async {
    final file = File(fileName);
    String csvContent = generateCsv();
    return file.writeAsString(csvContent);
  }

  Future<void> shareCsv() async {
    if (_dataBuffer.isEmpty) {
      errorMessage("No hay datos para exportar");
      return;
    }
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/sensa.csv';
      final file = File(filePath);
      await file.writeAsString(generateCsv());

      await Share.shareXFiles([XFile(filePath)], text: "Aquí tienes los datos en formato CSV");
    } catch (e) {
      errorMessage("Error al compartir archivo: $e");
    }
  }

  List<Map<String, dynamic>> getMappedData() {
    const columnNames = [
      'Fecha',
      'Hora',
      'Oxígeno Disuelto',
      'Conductividad',
      'TDS',
      'pH',
      'Temperatura',
      'Punto',
    ];

    return _dataBuffer.map((row) {
      if (row.length != columnNames.length) return null;
      return Map.fromIterables(columnNames, row);
    }).where((row) => row != null).toList().cast<Map<String, dynamic>>();
  }


  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _scanStateSubscription?.cancel();
    super.dispose();
  }
}

