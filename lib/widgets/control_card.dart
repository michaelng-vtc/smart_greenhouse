import 'package:flutter/material.dart';

class ControlCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String sensorLabel;
  final String sensorValue;
  final String sensorUnit;
  final double value; // Numeric value for animation
  final double min;
  final double max;
  final String? secondarySensorLabel;
  final String? secondarySensorValue;
  final String? secondarySensorUnit;
  final String systemName;
  final bool isSystemActive;
  final String activeText;
  final String inactiveText;

  const ControlCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.sensorLabel,
    required this.sensorValue,
    required this.sensorUnit,
    required this.value,
    required this.min,
    required this.max,
    this.secondarySensorLabel,
    this.secondarySensorValue,
    this.secondarySensorUnit,
    required this.systemName,
    required this.isSystemActive,
    this.activeText = 'Running',
    this.inactiveText = 'Idle',
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress for the gauge (0.0 to 1.0)
    final double progress = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSystemActive
            ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header: Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Center: Animated Gauge
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Circle
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          color.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Animated Progress Circle
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        );
                      },
                    ),
                    // Value Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sensorValue,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          sensorUnit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Secondary Sensor (if exists)
            if (secondarySensorLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$secondarySensorValue $secondarySensorUnit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

            // Footer: System Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSystemActive ? color : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSystemActive ? Icons.settings_suggest : Icons.power_off,
                    size: 14,
                    color: isSystemActive ? Colors.white : Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isSystemActive ? activeText : inactiveText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSystemActive ? Colors.white : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
