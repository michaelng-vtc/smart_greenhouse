import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 5,
                        getDrawingHorizontalLine: (value) {
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
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (maxY - minY) / 5,
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
                      minX: 0,
                      maxX: historyData.length > 1
                          ? (historyData.length - 1).toDouble()
                          : 1,
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _buildSpots(),
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
    return historyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      // Extract value from the data
      double value = 0.0;
      if (data[valueKey] != null) {
        value = (data[valueKey] is num)
            ? (data[valueKey] as num).toDouble()
            : 0.0;
      }

      return FlSpot(index.toDouble(), value);
    }).toList();
  }
}
