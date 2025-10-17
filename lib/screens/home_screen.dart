import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/control_card.dart';
import '../widgets/temperature_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure MQTT connection on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
      if (!mqttProvider.isConnected) {
        mqttProvider.reconnect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<MqttProvider>(
            builder: (context, mqttProvider, child) {
              // Selalu tampilkan UI, tidak peduli status koneksi
              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Smart Aquarium',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Consumer<MqttProvider>(
                    builder: (context, mqtt, _) {
                      return Row(
                        children: [
                          Icon(
                            mqtt.isConnected 
                                ? Icons.cloud_done 
                                : Icons.cloud_off,
                            color: mqtt.isConnected 
                                ? Colors.green 
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mqtt.isConnected ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: mqtt.isConnected 
                                  ? Colors.green 
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => mqtt.reconnect(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                  ),
                  
                  // Content
                  SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Connection Status Banner
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        // Tampilkan banner jika tidak terkoneksi
                        if (!mqtt.isConnected) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_off, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Disconnected from MQTT',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (mqtt.errorMessage.isNotEmpty)
                                        Text(
                                          mqtt.errorMessage,
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Showing demo data. Connect ESP32 to see real-time data.',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  color: Colors.orange,
                                  onPressed: () => mqtt.reconnect(),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    // Section: Sensors
                    _buildSectionTitle(context, 'Sensor Monitoring', Icons.sensors),
                    const SizedBox(height: 12),
                    
                    // Temperature & Turbidity
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: SensorCard(
                                title: 'Water Temperature',
                                value: mqtt.temperature.toStringAsFixed(1),
                                unit: '°C',
                                icon: Icons.thermostat,
                                color: _getTempColor(mqtt.temperature),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SensorCard(
                                title: 'Turbidity',
                                value: mqtt.turbidityNTU.toStringAsFixed(1),
                                unit: 'NTU',
                                icon: Icons.opacity,
                                color: _getTurbidityColor(mqtt.turbidityNTU),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Temperature Chart
                    _buildSectionTitle(context, 'Temperature Trend', Icons.show_chart),
                    const SizedBox(height: 12),
                    const TemperatureChart(),
                    
                    const SizedBox(height: 24),
                    
                    // Calibration Section
                    _buildSectionTitle(context, 'Calibration', Icons.tune),
                    const SizedBox(height: 12),
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.thermostat,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Temperature Calibration',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Offset: ${mqtt.tempOffset.toStringAsFixed(2)}°C',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: mqtt.isConnected
                                            ? () => _showCalibrationDialog(context, mqtt)
                                            : null,
                                        icon: const Icon(Icons.tune),
                                        label: const Text('Calibrate'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: mqtt.isConnected
                                          ? () => mqtt.resetCalibration()
                                          : null,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reset'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Section: Controls
                    _buildSectionTitle(context, 'Device Control', Icons.settings_remote),
                    const SizedBox(height: 12),
                    
                    // Control Cards
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        return ControlCard(
                          title: 'Water Heater',
                          icon: Icons.local_fire_department,
                          isActive: mqtt.heaterStatus,
                          mode: mqtt.heaterMode,
                          onToggle: mqtt.toggleHeater,
                          onModeChange: mqtt.setHeaterMode,
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                  ]),
                ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Color _getTempColor(double temp) {
    if (temp < 27) return Colors.blue;
    if (temp > 30) return Colors.red;
    return Colors.green;
  }
  
  Color _getTurbidityColor(double turbidity) {
    // Turbidity dalam NTU (0-3000 NTU)
    // Clean water: 0-5 NTU (hijau)
    // Slightly cloudy: 5-50 NTU (hijau muda)
    // Cloudy: 50-100 NTU (kuning)
    // Very cloudy: 100-500 NTU (orange)
    // Dirty: >500 NTU (merah)
    if (turbidity < 50) return Colors.green;
    if (turbidity < 100) return Colors.lightGreen;
    if (turbidity < 200) return Colors.orange;
    return Colors.red;
  }
  
  void _showCalibrationDialog(BuildContext context, MqttProvider mqtt) {
    final TextEditingController tempController = TextEditingController(
      text: mqtt.temperature.toStringAsFixed(2),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tune, color: Colors.blue),
            SizedBox(width: 8),
            Text('Temperature Calibration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the reference temperature from your calibrated thermometer:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tempController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Reference Temperature',
                suffixText: '°C',
                border: OutlineInputBorder(),
                helperText: 'e.g., 25.5',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current reading: ${mqtt.temperature.toStringAsFixed(2)}°C',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final refTemp = double.tryParse(tempController.text);
              if (refTemp != null && refTemp >= 15 && refTemp <= 40) {
                mqtt.calibrateTemperature(refTemp);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calibrating to ${refTemp.toStringAsFixed(2)}°C...'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid temperature. Enter value between 15-40°C'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }
}