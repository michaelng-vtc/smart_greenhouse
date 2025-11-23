import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/greenhouse_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/sensor_chart.dart';
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
      length: 4,
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
            final history = provider.history;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Last Updated: ${DateFormat('HH:mm:ss').format(data.timestamp)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    SensorCard(
                      title: 'Temperature',
                      value: data.temperature.toString(),
                      unit: '°C',
                      icon: Icons.thermostat,
                      color: Colors.orange,
                    ),
                    SensorCard(
                      title: 'Humidity',
                      value: data.humidity.toString(),
                      unit: '%',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                    ),
                    SensorCard(
                      title: 'Soil Moisture',
                      value: data.soilMoisture.toString(),
                      unit: '%',
                      icon: Icons.grass,
                      color: Colors.green,
                    ),
                    SensorCard(
                      title: 'Light Level',
                      value: data.lightLevel.toString(),
                      unit: 'lx',
                      icon: Icons.wb_sunny,
                      color: Colors.amber,
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
                        tabs: const [
                          Tab(text: 'Temp'),
                          Tab(text: 'Hum'),
                          Tab(text: 'Soil'),
                          Tab(text: 'Light'),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SensorChart(
                                history: history,
                                getValue: (d) => d.temperature,
                                title: 'Temperature History',
                                color: Colors.orange,
                                minY: 15,
                                maxY: 30,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SensorChart(
                                history: history,
                                getValue: (d) => d.humidity,
                                title: 'Humidity History',
                                color: Colors.blue,
                                minY: 40,
                                maxY: 80,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SensorChart(
                                history: history,
                                getValue: (d) => d.soilMoisture,
                                title: 'Soil Moisture History',
                                color: Colors.green,
                                minY: 20,
                                maxY: 60,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SensorChart(
                                history: history,
                                getValue: (d) => d.lightLevel,
                                title: 'Light Level History',
                                color: Colors.amber,
                                minY: 0,
                                maxY: 1000,
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
