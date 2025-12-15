import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnalogGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String title;
  final String unit;
  final Color color;
  final String? systemName;
  final bool? isSystemActive;
  final String? secondarySystemName;
  final bool? isSecondarySystemActive;

  const AnalogGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.title,
    required this.unit,
    required this.color,
    this.systemName,
    this.isSystemActive,
    this.secondarySystemName,
    this.isSecondarySystemActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: value,
                      min: min,
                      max: max,
                      color: color,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: size * 0.25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: size * 0.18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              unit,
                              style: TextStyle(
                                fontSize: size * 0.1,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (systemName != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSystemStatus(systemName!, isSystemActive ?? false),
                if (secondarySystemName != null) ...[
                  const SizedBox(width: 4),
                  _buildSystemStatus(
                    secondarySystemName!,
                    isSecondarySystemActive ?? false,
                  ),
                ],
              ],
            )
          else
            const SizedBox(
              height: 20,
            ), // Spacer to align with cards that have system info
        ],
      ),
    );
  }

  Widget _buildSystemStatus(String name, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.power_settings_new : Icons.circle_outlined,
            size: 8,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 2),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final startAngle = 135 * math.pi / 180;
    final sweepAngle = 270 * math.pi / 180;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final clampedValue = value.clamp(min, max);
    final valueSweepAngle = ((clampedValue - min) / (max - min)) * sweepAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      valueSweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
