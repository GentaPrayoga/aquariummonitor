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
  
  // Sensor Data
  double _temp1 = 0.0;
  double _temp2 = 0.0;
  double _waterLevel = 0.0;
  int _turbidity = 0;
  
  double get temp1 => _temp1;
  double get temp2 => _temp2;
  double get waterLevel => _waterLevel;
  int get turbidity => _turbidity;
  
  // Device Status
  bool _pump1Status = false;
  bool _pump2Status = false;
  bool _heaterStatus = false;
  
  bool get pump1Status => _pump1Status;
  bool get pump2Status => _pump2Status;
  bool get heaterStatus => _heaterStatus;
  
  // History Data (untuk chart)
  List<ChartData> _temp1History = [];
  List<ChartData> _temp2History = [];
  
  List<ChartData> get temp1History => _temp1History;
  List<ChartData> get temp2History => _temp2History;
  
  // Error message
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  // MQTT Configuration
  final String _broker = 'broker.hivemq.com';
  final int _port = 1883;
  final String _clientId = 'FlutterAquarium_${DateTime.now().millisecondsSinceEpoch}';
  
  MqttProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMqtt();
    });
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
    _client.subscribe('aquarium/temp1', MqttQos.atLeastOnce);
    _client.subscribe('aquarium/temp2', MqttQos.atLeastOnce);
    _client.subscribe('aquarium/waterlevel', MqttQos.atLeastOnce);
    _client.subscribe('aquarium/turbidity', MqttQos.atLeastOnce);
    _client.subscribe('aquarium/pump1/status', MqttQos.atLeastOnce);
    _client.subscribe('aquarium/pump2/status', MqttQos.atLeastOnce);
    _client.subscribe('aquarium/heater/status', MqttQos.atLeastOnce);
    
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
      case 'aquarium/temp1':
        _temp1 = double.tryParse(message.trim()) ?? 0.0;
        _addToHistory(_temp1History, _temp1);
        break;
      case 'aquarium/temp2':
        _temp2 = double.tryParse(message.trim()) ?? 0.0;
        _addToHistory(_temp2History, _temp2);
        break;
      case 'aquarium/waterlevel':
        _waterLevel = double.tryParse(message.trim()) ?? 0.0;
        break;
      case 'aquarium/turbidity':
        _turbidity = int.tryParse(message.trim()) ?? 0;
        break;
      case 'aquarium/pump1/status':
        _pump1Status = message.trim() == 'ON';
        break;
      case 'aquarium/pump2/status':
        _pump2Status = message.trim() == 'ON';
        break;
      case 'aquarium/heater/status':
        _heaterStatus = message.trim() == 'ON';
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
  void togglePump1() {
    final message = _pump1Status ? 'OFF' : 'ON';
    _publishMessage('aquarium/pump1/control', message);
  }
  
  void togglePump2() {
    final message = _pump2Status ? 'OFF' : 'ON';
    _publishMessage('aquarium/pump2/control', message);
  }
  
  void toggleHeater() {
    final message = _heaterStatus ? 'OFF' : 'ON';
    _publishMessage('aquarium/heater/control', message);
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
    _client.disconnect();
    super.dispose();
  }
}

// Data class for chart
class ChartData {
  final DateTime time;
  final double value;
  
  ChartData(this.time, this.value);
}