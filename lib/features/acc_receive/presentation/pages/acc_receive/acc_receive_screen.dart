import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// --- MQTT Configuration ---
const String mqttBroker = 'test.mosquitto.org'; // Example public test broker
const int mqttPort = 1883;
const String mqttTopic = 'esp32/accelerometer/data'; // The topic your ESP32 publishes to
const String clientId = 'flutter_accel_client_unique_id'; // Must be unique

class AccReceiveScreen extends StatefulWidget {
  const AccReceiveScreen({super.key});

  @override
  State<AccReceiveScreen> createState() => _AccReceiveScreenState();
}

class _AccReceiveScreenState extends State<AccReceiveScreen> {
  MqttServerClient? client;
  String _connectionStatus = 'Disconnected';
  Map<String, double> _accReceive = {'x': 0.0, 'y': 0.0, 'z': 0.0};

  @override
  void initState() {
    super.initState();
    _connect();
  }

  // --- MQTT Connection Setup ---
  void _connect() async {
    client = MqttServerClient(mqttBroker, clientId);
    client!.port = mqttPort;
    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    client!.onSubscribed = _onSubscribed;
    client!.autoReconnect = true;

    // Set connection message with Clean Session
    final connMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean().withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      setState(() => _connectionStatus = 'Connecting...');
      await client!.connect();
    } catch (e) {
      print('MQTT connection failed: $e');
      _disconnect();
    }

    // Set up the listener for incoming messages
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMessage = c[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      _onMessageReceived(c[0].topic, payload);
    });
  }

  // --- MQTT Callbacks ---

  void _onConnected() {
    setState(() => _connectionStatus = 'Connected');
    print('MQTT Client connected');
    client!.subscribe(mqttTopic, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    setState(() => _connectionStatus = 'Disconnected');
    print('MQTT Client disconnected');
  }

  void _onSubscribed(String topic) {
    setState(() => _connectionStatus = 'Subscribed to $topic');
    print('Subscribed to $topic');
  }

  void _disconnect() {
    client!.disconnect();
  }

  // --- Message Processing ---

  void _onMessageReceived(String topic, String payload) {
    if (topic == mqttTopic) {
      print('Received message on $topic: $payload');
      try {
        // The ESP32 is expected to send data as a JSON string like:
        // '{"x": 1.25, "y": 0.10, "z": 9.80}'
        final data = jsonDecode(payload);
        setState(() {
          _accReceive = {
            'x': (data['x'] as num).toDouble(),
            'y': (data['y'] as num).toDouble(),
            'z': (data['z'] as num).toDouble(),
          };
        });
      } catch (e) {
        print('Error decoding JSON payload: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Accelerometer Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Status Indicator
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'MQTT Connection Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _connectionStatus,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _connectionStatus.contains('Connected') ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Broker: $mqttBroker'),
                      Text('Topic: $mqttTopic'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Real-time Accelerometer Data',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Data Display Cards
              _buildDataCard('X-Axis', _accReceive['x']!),
              _buildDataCard('Y-Axis', _accReceive['y']!),
              _buildDataCard('Z-Axis', _accReceive['z']!),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _connectionStatus.startsWith('Connected') ? _disconnect : _connect,
        tooltip: _connectionStatus.startsWith('Connected') ? 'Disconnect' : 'Connect',
        backgroundColor: _connectionStatus.startsWith('Connected') ? Colors.red.shade600 : Colors.green.shade600,
        child: Icon(_connectionStatus.startsWith('Connected') ? Icons.power_off : Icons.wifi),
      ),
    );
  }

  Widget _buildDataCard(String axis, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            _getAxisIcon(axis),
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
          title: Text(
            axis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            value.toStringAsFixed(3), // Display value with 3 decimal places
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  IconData _getAxisIcon(String axis) {
    switch (axis) {
      case 'X-Axis':
        return Icons.arrow_right_alt;
      case 'Y-Axis':
        return Icons.arrow_upward;
      case 'Z-Axis':
        return Icons.vertical_align_center;
      default:
        return Icons.sensors;
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}
