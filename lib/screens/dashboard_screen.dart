import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/greenhouse_provider.dart';
import '../widgets/analog_gauge.dart';
import '../widgets/api_sensor_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start the simulation when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GreenhouseProvider>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Smart Greenhouse',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Consumer<GreenhouseProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.circle,
                    color: provider.isConnected ? Colors.green : Colors.red,
                    size: 12,
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<GreenhouseProvider>(
          builder: (context, provider, child) {
            final data = provider.data;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (provider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Last Updated: ${DateFormat('HH:mm:ss').format(data.timestamp)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                  children: [
                    AnalogGauge(
                      title: 'Temp',
                      value: data.temperature,
                      min: 0,
                      max: 50,
                      unit: '°C',
                      color: Colors.orange,
                      icon: Icons.thermostat,
                    ),
                    AnalogGauge(
                      title: 'VPD',
                      value: data.vpd,
                      min: 0,
                      max: 3.0,
                      unit: 'kPa',
                      color: Colors.blueGrey,
                      icon: Icons.opacity,
                      systemName: 'Heater',
                      isSystemActive: provider.systemStatus.isHeaterOn,
                      secondarySystemName: 'Mister',
                      isSecondarySystemActive: provider.systemStatus.isMisterOn,
                    ),
                    AnalogGauge(
                      title: 'Humidity',
                      value: data.humidity,
                      min: 0,
                      max: 100,
                      unit: '%',
                      color: Colors.blue,
                      icon: Icons.water_drop,
                    ),
                    AnalogGauge(
                      title: 'Light',
                      value: data.lightLevel,
                      min: 0,
                      max: 5000,
                      unit: 'lx',
                      color: Colors.amber,
                      icon: Icons.wb_sunny,
                      systemName: 'Curtain',
                      isSystemActive: provider.systemStatus.isCurtainOn,
                    ),
                    AnalogGauge(
                      title: 'CO2',
                      value: data.co2,
                      min: 0,
                      max: 2000,
                      unit: 'ppm',
                      color: Colors.teal,
                      icon: Icons.air,
                      systemName: 'Fan',
                      isSystemActive: provider.systemStatus.isFanOn,
                    ),
                    AnalogGauge(
                      title: 'Soil',
                      value: data.soilMoisture,
                      min: 0,
                      max: 100,
                      unit: '%',
                      color: Colors.green,
                      icon: Icons.grass,
                      systemName: 'Pump',
                      isSystemActive: provider.systemStatus.isPumpOn,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'History Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.green,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.green,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: 'Temp'),
                          Tab(text: 'Humidity'),
                          Tab(text: 'CO2'),
                          Tab(text: 'Light'),
                          Tab(text: 'Soil'),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ApiSensorChart(
                                historyData: provider.getHistory('temp'),
                                valueKey: 'temp',
                                title: 'Temperature History',
                                color: Colors.orange,
                                minY: 15,
                                maxY: 35,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ApiSensorChart(
                                historyData: provider.getHistory('humidity'),
                                valueKey: 'humidity',
                                title: 'Humidity History',
                                color: Colors.blue,
                                minY: 30,
                                maxY: 100,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ApiSensorChart(
                                historyData: provider.getHistory('co2'),
                                valueKey: 'co2',
                                title: 'CO2 History',
                                color: Colors.teal,
                                minY: 300,
                                maxY: 2000,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ApiSensorChart(
                                historyData: provider.getHistory('lux'),
                                valueKey: 'lux',
                                title: 'Light Level History',
                                color: Colors.amber,
                                minY: 0,
                                maxY: 1000,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ApiSensorChart(
                                historyData: provider.getHistory(
                                  'soil_percent',
                                ),
                                valueKey: 'soil_percent',
                                title: 'Soil Moisture History',
                                color: Colors.green,
                                minY: 0,
                                maxY: 100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
