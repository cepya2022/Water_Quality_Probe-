import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:share/share.dart';

class BluetoothProvider extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothDevice? _lastDevice;
  BluetoothConnectionState _deviceState = BluetoothConnectionState.disconnected;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isData = false;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _messages = [];
  List<BluetoothDevice> systemDevices = [];
  List<ScanResult> scanResults = [];
  List<List<String>> _dataBuffer = [
    ["01/02/2025", "2.1", "3.4", "1.9", "2.7", "3.0", "2.5", "3.3"],
    ["02/02/2025", "1.8", "2.2", "2.9", "1.6", "2.1", "2.3", "2.7"],
    ["03/02/2025", "3.5", "3.1", "2.8", "3.3", "2.9", "3.0", "2.7"],
    ["04/02/2025", "1.9", "2.0", "1.8", "2.2", "2.5", "1.7", "2.1"],
    ["05/02/2025", "2.3", "2.9", "2.6", "2.7", "2.8", "3.0", "2.4"],
    ["06/02/2025", "3.1", "3.3", "3.0", "3.2", "2.9", "3.5", "3.4"],
    ["07/02/2025", "2.0", "2.2", "2.1", "2.0", "2.3", "2.4", "2.2"],
    ["08/02/2025", "1.7", "1.9", "2.0", "1.8", "1.6", "2.1", "1.9"],
    ["09/02/2025", "3.0", "2.8", "3.2", "2.7", "2.6", "3.1", "2.9"],
    ["10/02/2025", "2.4", "2.5", "2.3", "2.6", "2.7", "2.2", "2.1"]];
  String _buffer = ""; // Buffer para almacenar los datos parciales


  List<Map<String, dynamic>> get messages => _messages;
  List<List<String>> get dataBuffer => _dataBuffer;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isGenerating => _isGenerating;
  BluetoothDevice? get lastDevice => _lastDevice;


  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  BluetoothCharacteristic? _rxCharacteristic;

  void connectToHC08() async {
    await FlutterBluePlus.stopScan();
    _isConnecting = true;
    _isConnected = false;

    // Verificar si el Bluetooth está encendido, y pedir activarlo si no lo está
    if (_deviceState != BluetoothAdapterState.on) {
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
    if (_deviceState != BluetoothAdapterState.on) {
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
    if (_deviceState != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
    try {
      _isConnecting = true;
      notifyListeners();

      // Buscar dispositivos del sistema
      var withServices = [Guid("180f")]; // Ejemplo: Servicio de nivel de batería
      systemDevices = await FlutterBluePlus.systemDevices(withServices);

      // Inicia el escaneo
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));


      // Escucha resultados de escaneo
      FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();
      });
    } catch (e) {
      print('Error during scan: $e');
    } finally {
      await Future.delayed(const Duration(seconds: 10));
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isConnecting = false;
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
      _deviceState = state;
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
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/sensa.csv';
      final file = File(filePath);
      await file.writeAsString(_dataBuffer.map((row) => row.join(";")).join("\n"));

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
    super.dispose();
  }
}

