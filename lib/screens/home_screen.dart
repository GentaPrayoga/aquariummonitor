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
              if (!mqttProvider.isConnected) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mqttProvider.errorMessage.isEmpty ? Icons.cloud_off : Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    if (mqttProvider.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          mqttProvider.errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      const Text('Connecting to MQTT broker...'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => mqttProvider.reconnect(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reconnect'),
                    ),
                  ],
                );
              }
              if (mqttProvider.errorMessage.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        mqttProvider.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => mqttProvider.reconnect(),
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                );
              }
              
              // Show loading state if not connected and no error
              if (!mqttProvider.isConnected && mqttProvider.errorMessage.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Connecting to MQTT broker...'),
                    ],
                  ),
                );
              }

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
                    // Error Message
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        if (mqtt.errorMessage.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mqtt.errorMessage,
                                    style: const TextStyle(color: Colors.red),
                                  ),
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
                    
                    // Temperature Sensors
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: SensorCard(
                                title: 'Temperature 1',
                                value: mqtt.temp1.toStringAsFixed(1),
                                unit: '°C',
                                icon: Icons.thermostat,
                                color: _getTempColor(mqtt.temp1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SensorCard(
                                title: 'Temperature 2',
                                value: mqtt.temp2.toStringAsFixed(1),
                                unit: '°C',
                                icon: Icons.thermostat,
                                color: _getTempColor(mqtt.temp2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Water Level & Turbidity
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: SensorCard(
                                title: 'Water Level',
                                value: mqtt.waterLevel.toStringAsFixed(1),
                                unit: 'cm',
                                icon: Icons.water,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SensorCard(
                                title: 'Turbidity',
                                value: mqtt.turbidity.toString(),
                                unit: 'NTU',
                                icon: Icons.opacity,
                                color: _getTurbidityColor(mqtt.turbidity),
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
                    
                    // Section: Controls
                    _buildSectionTitle(context, 'Device Control', Icons.settings_remote),
                    const SizedBox(height: 12),
                    
                    // Control Cards
                    Consumer<MqttProvider>(
                      builder: (context, mqtt, _) {
                        return Column(
                          children: [
                            ControlCard(
                              title: 'Water Pump 1',
                              icon: Icons.water_drop,
                              isActive: mqtt.pump1Status,
                              onToggle: mqtt.togglePump1,
                            ),
                            const SizedBox(height: 12),
                            ControlCard(
                              title: 'Water Pump 2',
                              icon: Icons.water_drop_outlined,
                              isActive: mqtt.pump2Status,
                              onToggle: mqtt.togglePump2,
                            ),
                            const SizedBox(height: 12),
                            ControlCard(
                              title: 'Water Heater',
                              icon: Icons.local_fire_department,
                              isActive: mqtt.heaterStatus,
                              onToggle: mqtt.toggleHeater,
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
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
    if (temp < 24) return Colors.blue;
    if (temp > 28) return Colors.red;
    return Colors.green;
  }
  
  Color _getTurbidityColor(int turbidity) {
    if (turbidity < 1000) return Colors.green;
    if (turbidity < 2000) return Colors.orange;
    return Colors.red;
  }
}