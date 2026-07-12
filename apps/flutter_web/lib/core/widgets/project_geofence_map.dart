import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

class ProjectGeofenceMap extends StatefulWidget {
  final String projectName;
  final double projectLatitude;
  final double projectLongitude;
  final double employeeLatitude;
  final double employeeLongitude;
  final double allowedRadius; // in meters

  const ProjectGeofenceMap({
    Key? key,
    required this.projectName,
    required this.projectLatitude,
    required this.projectLongitude,
    required this.employeeLatitude,
    required this.employeeLongitude,
    required this.allowedRadius,
  }) : super(key: key);

  @override
  State<ProjectGeofenceMap> createState() => _ProjectGeofenceMapState();
}

class _ProjectGeofenceMapState extends State<ProjectGeofenceMap> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _calculateDistance() {
    const R = 6371000; // Earth radius in meters
    final phi1 = widget.projectLatitude * math.pi / 180;
    final phi2 = widget.employeeLatitude * math.pi / 180;
    final deltaPhi = (widget.employeeLatitude - widget.projectLatitude) * math.pi / 180;
    final deltaLambda = (widget.employeeLongitude - widget.projectLongitude) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final isInside = distance <= widget.allowedRadius;

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Stack(
        children: [
          // The interactive coordinates grid canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: GeofenceMapPainter(
                    projectLat: widget.projectLatitude,
                    projectLng: widget.projectLongitude,
                    empLat: widget.employeeLatitude,
                    empLng: widget.employeeLongitude,
                    radius: widget.allowedRadius,
                    distance: distance,
                    pulseProgress: _pulseCtrl.value,
                  ),
                );
              },
            ),
          ),
          
          // Map Telemetry Dashboard Overlay (Glassmorphism)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E26).withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.projectName.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: VianTheme.primaryGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Geofence Radius: ${widget.allowedRadius.toInt()}m',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isInside ? const Color(0x1A10B981) : const Color(0x1AEF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isInside ? Colors.greenAccent.withOpacity(0.3) : VianTheme.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isInside ? Icons.gps_fixed : Icons.gps_off,
                          color: isInside ? Colors.greenAccent : VianTheme.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isInside 
                              ? '${distance.toStringAsFixed(1)}m (Inside)' 
                              : '${distance.toStringAsFixed(1)}m (Outside)',
                          style: GoogleFonts.poppins(
                            color: isInside ? Colors.greenAccent : VianTheme.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // GPS Compass Rose Indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: VianTheme.primaryGold,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GeofenceMapPainter extends CustomPainter {
  final double projectLat;
  final double projectLng;
  final double empLat;
  final double empLng;
  final double radius;
  final double distance;
  final double pulseProgress;

  GeofenceMapPainter({
    required this.projectLat,
    required this.projectLng,
    required this.empLat,
    required this.empLng,
    required this.radius,
    required this.distance,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 15);
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    // Draw Grid lines
    const gridSpacing = 30.0;
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += gridSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    // Scale calculations
    // Map geofence radius to 60px on screen
    final pixelsPerMeter = 60.0 / radius;

    // Allowed geofence circle
    final paintGeofence = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * pixelsPerMeter, paintGeofence);

    final paintGeofenceBorder = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * pixelsPerMeter, paintGeofenceBorder);

    // Draw geofence concentric dashboard rings
    final paintRings = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius * 0.5 * pixelsPerMeter, paintRings);
    canvas.drawCircle(center, radius * 1.5 * pixelsPerMeter, paintRings);

    // Animated geofence radar wave
    final radarPaint = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.15 * (1.0 - pulseProgress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 2.0 * pulseProgress * pixelsPerMeter, radarPaint);

    // Draw project center point (Hub)
    final hubPaint = Paint()
      ..color = VianTheme.primaryGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, hubPaint);
    
    final hubOuterPaint = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, hubOuterPaint);

    // Calculate relative employee coordinates
    // We assume 1 degree latitude = 111,000 meters, 1 degree longitude = 111,000 * cos(lat) meters
    final dLatM = (empLat - projectLat) * 111000.0;
    final dLngM = (empLng - projectLng) * 111000.0 * math.cos(projectLat * math.pi / 180);

    // Coordinate translation: longitude maps to x-axis, latitude maps to y-axis (negative since screen y grows downwards)
    final empOffset = Offset(
      center.dx + dLngM * pixelsPerMeter,
      center.dy - dLatM * pixelsPerMeter,
    );

    // Clip employee position to fit within grid bounds nicely if simulated too far
    var constrainedEmpOffset = empOffset;
    final dx = empOffset.dx - center.dx;
    final dy = empOffset.dy - center.dy;
    final empDistancePixels = math.sqrt(dx * dx + dy * dy);
    final maxDistancePixels = radius * 2.0 * pixelsPerMeter;

    if (empDistancePixels > maxDistancePixels) {
      final ratio = maxDistancePixels / empDistancePixels;
      constrainedEmpOffset = Offset(
        center.dx + dx * ratio,
        center.dy + dy * ratio,
      );
    }

    // Connection Path line between site center and employee location
    final pathPaint = Paint()
      ..color = distance <= radius ? Colors.greenAccent.withOpacity(0.5) : VianTheme.danger.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw dashed connection line
    _drawDashedLine(canvas, center, constrainedEmpOffset, pathPaint);

    // Draw employee position marker
    final empPaint = Paint()
      ..color = distance <= radius ? Colors.greenAccent : VianTheme.danger
      ..style = PaintingStyle.fill;
    canvas.drawCircle(constrainedEmpOffset, 7, empPaint);

    final empRingPaint = Paint()
      ..color = (distance <= radius ? Colors.greenAccent : VianTheme.danger).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(constrainedEmpOffset, 14, empRingPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    final int count = (distance / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < count; i++) {
      final double t1 = i / count;
      final double t2 = (i + 0.5) / count;
      
      canvas.drawLine(
        Offset(p1.dx + dx * t1, p1.dy + dy * t1),
        Offset(p1.dx + dx * t2, p1.dy + dy * t2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
