import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnalogGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String title;
  final String unit;
  final Color color;
  final IconData icon;
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
    required this.icon,
    this.systemName,
    this.isSystemActive,
    this.secondarySystemName,
    this.isSecondarySystemActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: size * 0.15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: size * 0.13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (systemName == null && secondarySystemName == null) {
      return const SizedBox(height: 32);
    }

    if (secondarySystemName != null) {
      return Row(
        children: [
          Expanded(
            child: _buildSystemStatus(
              systemName!,
              isSystemActive ?? false,
              _getSystemColor(systemName!),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSystemStatus(
              secondarySystemName!,
              isSecondarySystemActive ?? false,
              _getSystemColor(secondarySystemName!),
            ),
          ),
        ],
      );
    }

    return _buildSystemStatus(
      systemName!,
      isSystemActive ?? false,
      _getSystemColor(systemName!),
    );
  }

  Color _getSystemColor(String systemName) {
    switch (systemName) {
      case 'Heater':
        return Colors.red;
      case 'Mister':
        return Colors.blue;
      default:
        return color;
    }
  }

  Widget _buildSystemStatus(String name, bool isActive, Color systemColor) {
    Color bgColor = isActive ? systemColor : Colors.grey.withValues(alpha: 0.1);
    Color contentColor = isActive ? Colors.white : Colors.grey;
    IconData statusIcon = isActive ? Icons.settings : Icons.power_off_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, size: 12, color: contentColor),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: contentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    const startAngle = -90 * math.pi / 180;
    const sweepAngle = 360 * math.pi / 180;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
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
      ..strokeWidth = 12
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
