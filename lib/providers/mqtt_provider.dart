import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';
import 'dart:async';

class MqttProvider extends ChangeNotifier {
  // MQTT Client
  late MqttServerClient _client;
  
  // Connection Status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Sensor Data - dengan default values untuk demo
  double _temperature = 28.5;
  double _turbidityNTU = 150.0; // Dalam NTU (Nephelometric Turbidity Units)
  double _tempOffset = 0.0; // Offset kalibrasi suhu
  
  double get temperature => _temperature;
  double get turbidityNTU => _turbidityNTU;
  double get tempOffset => _tempOffset;
  
  // Device Status
  bool _heaterStatus = false;
  String _heaterMode = 'AUTO'; // AUTO, ON, OFF
  
  bool get heaterStatus => _heaterStatus;
  String get heaterMode => _heaterMode;
  
  // History Data (untuk chart) - dengan demo data
  List<ChartData> _temperatureHistory = [];
  
  List<ChartData> get temperatureHistory => _temperatureHistory;
  
  // Timer untuk demo data
  Timer? _demoTimer;
  
  // Error message
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  // MQTT Configuration
  final String _broker = 'broker.hivemq.com';
  final int _port = 1883;
  final String _clientId = 'FlutterAquarium_${DateTime.now().millisecondsSinceEpoch}';
  
  MqttProvider() {
    // Inisialisasi dengan demo data
    _initializeDemoData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMqtt();
    });
  }
  
  // Initialize demo data untuk tampilan awal
  void _initializeDemoData() {
    // Tambahkan beberapa data point untuk chart
    final now = DateTime.now();
    for (int i = 0; i < 10; i++) {
      _temperatureHistory.add(
        ChartData(
          now.subtract(Duration(seconds: (10 - i) * 5)),
          27.5 + (i % 3) * 0.5, // Variasi demo data
        ),
      );
    }
    
    // Mulai timer untuk update demo data jika tidak terkoneksi
    _demoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        _updateDemoData();
      }
    });
  }
  
  // Update demo data secara periodik
  void _updateDemoData() {
    // Simulasi perubahan suhu
    _temperature = 27.5 + (DateTime.now().second % 5) * 0.3;
    
    // Simulasi perubahan turbidity dalam NTU (0-3000 NTU)
    _turbidityNTU = 100.0 + (DateTime.now().second % 20) * 10.0;
    
    // Simulasi AUTO mode untuk heater
    if (_heaterMode == 'AUTO') {
      if (_temperature < 27.0 && !_heaterStatus) {
        _heaterStatus = true;
        debugPrint('🔥 Demo: Heater ON (temp < 27°C)');
      } else if (_temperature > 30.0 && _heaterStatus) {
        _heaterStatus = false;
        debugPrint('❄️ Demo: Heater OFF (temp > 30°C)');
      }
    }
    
    // Update history
    _addToHistory(_temperatureHistory, _temperature);
    
    notifyListeners();
  }
  
  // Initialize MQTT Client
  Future<void> _initializeMqtt() async {
    _client = MqttServerClient(_broker, _clientId);
    _client.port = _port;
    _client.keepAlivePeriod = 60;
    _client.logging(on: true);
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    _client.connectionMessage = connMessage;
    
    await _connect();
  }
  
  // Connect to MQTT Broker
  Future<void> _connect() async {
    try {
      debugPrint('🔌 Connecting to MQTT broker...');
      await _client.connect().timeout(
        const Duration(seconds: 5),
      );
    } on SocketException catch (e) {
      debugPrint('❌ Socket Exception: $e');
      _errorMessage = 'Network error: Check your internet connection';
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Other Exception: $e');
      _errorMessage = 'Connection error: $e';
      _isConnected = false;
      notifyListeners();
    }
  }
  
  void _onConnected() {
    debugPrint('✅ Connected to MQTT broker');
    _isConnected = true;
    _errorMessage = '';
    
    // Subscribe to topics
    _client.subscribe('heater/temperature', MqttQos.atLeastOnce);
    _client.subscribe('heater/turbidity', MqttQos.atLeastOnce);
    _client.subscribe('heater/status', MqttQos.atLeastOnce);
    _client.subscribe('heater/calibrate', MqttQos.atLeastOnce);
    
    // Listen to messages
    _client.updates!.listen(_onMessage);
    
    notifyListeners();
  }
  
  void _onDisconnected() {
    debugPrint('⚠️ Disconnected from MQTT broker');
    _isConnected = false;
    notifyListeners();
  }
  
  void _onSubscribed(String topic) {
    debugPrint('📥 Subscribed to: $topic');
  }
  
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> event) {
    final recMess = event[0].payload as MqttPublishMessage;
    final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    final topic = event[0].topic;
    
    debugPrint('📨 Received: $topic = $message');
    
    // Parse sensor data
    switch (topic) {
      case 'heater/temperature':
        _temperature = double.tryParse(message.trim()) ?? 0.0;
        _addToHistory(_temperatureHistory, _temperature);
        break;
      case 'heater/turbidity':
        // Turbidity dalam NTU dari ESP32
        _turbidityNTU = double.tryParse(message.trim()) ?? 0.0;
        break;
      case 'heater/status':
        final status = message.trim();
        if (status == 'ON' || status == 'OFF') {
          _heaterStatus = status == 'ON';
          _heaterMode = _heaterStatus ? 'MANUAL' : 'MANUAL';
        } else if (status == 'AUTO' || status == 'connected') {
          _heaterMode = 'AUTO';
        }
        break;
      case 'heater/calibrate':
        // Response kalibrasi dari ESP32
        if (message.startsWith('OK:')) {
          debugPrint('✅ Calibration response: $message');
        }
        break;
    }
    
    notifyListeners();
  }
  
  void _addToHistory(List<ChartData> history, double value) {
    history.add(ChartData(DateTime.now(), value));
    // Keep only last 20 data points
    if (history.length > 20) {
      history.removeAt(0);
    }
  }
  
  // Control devices
  void setHeaterMode(String mode) {
    // mode: 'ON', 'OFF', 'AUTO'
    _heaterMode = mode;
    
    if (_isConnected) {
      // Kirim ke ESP32 jika terkoneksi
      _publishMessage('heater/control', mode);
    } else {
      // Mode demo: update local state saja
      debugPrint('📝 Demo mode: Heater mode set to $mode (not connected to MQTT)');
    }
    
    if (mode == 'AUTO') {
      // Dalam mode AUTO, status heater dikontrol oleh ESP32 atau simulasi
      if (!_isConnected) {
        // Simulasi AUTO mode: nyalakan jika suhu < 27, matikan jika > 30
        _heaterStatus = _temperature < 27.0;
      }
    } else {
      _heaterStatus = mode == 'ON';
    }
    
    notifyListeners();
  }
  
  void toggleHeater() {
    final message = _heaterStatus ? 'OFF' : 'ON';
    setHeaterMode(message);
  }
  
  // Kalibrasi suhu
  void calibrateTemperature(double referenceTemp) {
    if (_isConnected) {
      // Format: CAL:25.5
      final message = 'CAL:$referenceTemp';
      _publishMessage('heater/calibrate', message);
      debugPrint('📡 Sending calibration: $message');
    } else {
      debugPrint('⚠️ Cannot calibrate: Not connected to MQTT');
    }
  }
  
  // Reset kalibrasi
  void resetCalibration() {
    if (_isConnected) {
      _publishMessage('heater/calibrate', 'RESET');
      _tempOffset = 0.0;
      debugPrint('🔄 Reset calibration');
      notifyListeners();
    } else {
      debugPrint('⚠️ Cannot reset: Not connected to MQTT');
    }
  }
  
  void _publishMessage(String topic, String message) {
    if (!_isConnected) {
      debugPrint('⚠️ Not connected to MQTT broker');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    debugPrint('📤 Published: $topic = $message');
  }
  
  // Reconnect
  Future<void> reconnect() async {
    if (_isConnected) {
      _client.disconnect();
    }
    await Future.delayed(const Duration(seconds: 1));
    await _connect();
  }
  
  @override
  void dispose() {
    _demoTimer?.cancel();
    if (_isConnected) {
      _client.disconnect();
    }
    super.dispose();
  }
}

// Data class for chart
class ChartData {
  final DateTime time;
  final double value;
  
  ChartData(this.time, this.value);
}