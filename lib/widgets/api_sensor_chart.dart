import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApiSensorChart extends StatelessWidget {
  final List<Map<String, dynamic>> historyData;
  final String valueKey;
  final String title;
  final Color color;
  final double minY;
  final double maxY;

  const ApiSensorChart({
    super.key,
    required this.historyData,
    required this.valueKey,
    required this.title,
    required this.color,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    double minX = 0;
    double maxX = 1;
    double effectiveMinY = minY;
    double effectiveMaxY = maxY;

    if (spots.isNotEmpty) {
      minX = spots.first.x;
      maxX = spots.last.x;
      if (minX == maxX) {
        maxX = minX + 1000; // Avoid division by zero
      }
      
      // Auto-expand Y axis if data is out of bounds
      final dataMinY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      final dataMaxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      
      if (dataMinY < effectiveMinY) effectiveMinY = dataMinY - 5;
      if (dataMaxY > effectiveMaxY) effectiveMaxY = dataMaxY + 5;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: historyData.isEmpty
                ? const Center(child: Text('Waiting for data...'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        verticalInterval: (maxX - minX) / 4,
                        horizontalInterval: (effectiveMaxY - effectiveMinY) / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: (maxX - minX) / 4,
                            getTitlesWidget: (value, meta) {
                              if (value < minX || value > maxX) {
                                return const SizedBox.shrink();
                              }
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('HH:mm').format(date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (effectiveMaxY - effectiveMinY) / 5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: minX,
                      maxX: maxX,
                      minY: effectiveMinY,
                      maxY: effectiveMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    if (valueKey == 'temp') {
      print('Chart building spots for $valueKey. Data count: ${historyData.length}');
      if (historyData.isNotEmpty) {
        print('First data point: ${historyData.first}');
      }
    }

    final spots = historyData.map((data) {
      double value = 0.0;
      if (data[valueKey] != null) {
        value =
            (data[valueKey] is num) ? (data[valueKey] as num).toDouble() : 0.0;
      }

      DateTime ts = DateTime.now();
      if (data['timestamp'] != null) {
        ts = DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now();
      }

      return FlSpot(ts.millisecondsSinceEpoch.toDouble(), value);
    }).toList();

    // Sort spots by timestamp to ensure the line is drawn correctly
    spots.sort((a, b) => a.x.compareTo(b.x));

    // Show only the recent 10 data points
    if (spots.length > 10) {
      return spots.sublist(spots.length - 10);
    }
    
    return spots;
  }
}
