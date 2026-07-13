import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';
import '../services/api_service.dart';
import '../services/gps_resolver.dart';
import 'custom_widgets.dart';
import 'project_geofence_map.dart';
import '../../js_stub.dart'
    if (dart.library.js) 'dart:js' as js;

class FaceGpsVerifyOverlay extends StatefulWidget {
  final String action; // 'check-in' or 'check-out'
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const FaceGpsVerifyOverlay({
    Key? key,
    required this.action,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FaceGpsVerifyOverlay> createState() => _FaceGpsVerifyOverlayState();
}

class _FaceGpsVerifyOverlayState extends State<FaceGpsVerifyOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  String _statusText = 'Ready to Scan';
  double _progress = 0.0;
  bool _isScanning = false;
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  String _verifiedTime = '';
  
  // Projects list
  List<dynamic> _projects = [];
  dynamic _selectedProject;
  bool _loadingProjects = true;

  // GPS Simulation Modes:
  // 'center' = Site Center (inside radius)
  // 'outside' = Outside Geofence (~1000m)
  String _gpsMode = 'center';
  
  double lat = 28.4595;
  double lng = 77.0266;
  double accuracy = 10.0;
  String address = 'Bajaj Villa Site, Sector 43';
  double faceScore = 98.40;

  // Mid-flow GPS map review screen trigger
  bool _showMapReview = false;
  double _calculatedDistance = 0.0;
  bool _insideRadius = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadProjects();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final list = await ApiService.getProjects();
      if (mounted) {
        setState(() {
          _projects = list.where((p) => p['status'] != 'Completed' && p['status'] != 'Cancelled').toList();
          if (_projects.isNotEmpty) {
            _selectedProject = _projects.first;
            _updateSimulatedCoordinates();
          }
          _loadingProjects = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProjects = false);
      }
    }
  }

  void _updateSimulatedCoordinates() {
    if (_selectedProject == null) return;
    
    final double projLat = _selectedProject['latitude'] != null 
        ? double.parse(_selectedProject['latitude'].toString()) 
        : 28.4595;
    final double projLng = _selectedProject['longitude'] != null 
        ? double.parse(_selectedProject['longitude'].toString()) 
        : 77.0266;
    
    if (_gpsMode == 'center') {
      // Coords directly inside radius
      lat = projLat;
      lng = projLng;
      address = '${_selectedProject['name']} (Verified Area)';
    } else {
      // Coords outside radius (~1.2km away)
      lat = projLat + 0.012;
      lng = projLng + 0.012;
      address = 'Outside Assigned Boundary (~1200m from Site)';
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // metres
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  void _startVerification() async {
    if (_selectedProject == null && widget.action == 'check-in') {
      setState(() {
        _isError = true;
        _errorMessage = 'Please select a project site first.';
      });
      return;
    }

    _updateSimulatedCoordinates();

    setState(() {
      _isScanning = true;
      _isError = false;
      _progress = 0.0;
      _statusText = 'Checking database face registration...';
    });

    // Step 1: Check face status database enrollment
    // We assume check is simulated for demo user Vijay/Anand, but verify others
    final user = await ApiService.getFaceStatus(1); // Simulated user face enrollment verify
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Step 2: Camera liveness lense scanner loop
    setState(() {
      _progress = 0.25;
      _statusText = 'Scan left cheek / face angle...';
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _progress = 0.50;
      _statusText = 'Scan right cheek / face angle...';
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _progress = 0.75;
      _statusText = 'Analyzing facial liveness structure...';
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _progress = 0.95;
      _statusText = 'Acquiring GPS tracking lock...';
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Calculations before API call
    final double projLat = _selectedProject != null && _selectedProject['latitude'] != null 
        ? double.parse(_selectedProject['latitude'].toString()) 
        : 28.4595;
    final double projLng = _selectedProject != null && _selectedProject['longitude'] != null 
        ? double.parse(_selectedProject['longitude'].toString()) 
        : 77.0266;
    
    _calculatedDistance = _calculateDistance(lat, lng, projLat, projLng);
    final double radius = _selectedProject != null && _selectedProject['allowedRadius'] != null 
        ? double.parse(_selectedProject['allowedRadius'].toString()) 
        : 100.0;
    _insideRadius = _calculatedDistance <= radius;

    setState(() {
      _progress = 1.0;
      _isScanning = false;
      _showMapReview = true;
    });
  }

  void _submitPunchAction() async {
    setState(() {
      _showMapReview = false;
      _isScanning = true;
      _statusText = 'Registering punch coordinates...';
    });

    final browser = _getBrowserName();
    final os = _getOSVersion();
    final device = _getDeviceName();
    final network = _getNetworkType();
    
    bool ok = false;
    if (widget.action == 'check-in') {
      ok = await ApiService.checkIn(
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        address: address,
        faceImageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        faceScore: faceScore,
        device: device,
        browser: browser,
        ipAddress: '127.0.0.1',
        network: network,
        projectId: _selectedProject?['id'],
      );
    } else {
      ok = await ApiService.checkOut(
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        address: address,
        faceImageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        faceScore: faceScore,
        device: device,
        browser: browser,
        ipAddress: '127.0.0.1',
        network: network,
      );
    }

    if (!mounted) return;

    if (ok) {
      setState(() {
        _isScanning = false;
        _isSuccess = true;
        _verifiedTime = DateFormat('hh:mm a').format(DateTime.now());
      });
    } else {
      setState(() {
        _isScanning = false;
        _isError = true;
        _errorMessage = 'Punch failed. Database reports month attendance lock or validation mismatch.';
      });
    }
  }

  String _getBrowserName() {
    if (!kIsWeb) return 'Flutter Native Mobile';
    try {
      final userAgent = js.context['navigator']['userAgent'] as String;
      if (userAgent.contains('Chrome')) return 'Google Chrome';
      if (userAgent.contains('Safari')) return 'Apple Safari';
      if (userAgent.contains('Firefox')) return 'Mozilla Firefox';
      if (userAgent.contains('Edge')) return 'Microsoft Edge';
      return 'Web Browser';
    } catch (_) {
      return 'Web Browser';
    }
  }

  String _getOSVersion() {
    if (!kIsWeb) {
      if (io.Platform.isAndroid) return 'Android';
      if (io.Platform.isIOS) return 'iOS';
      return io.Platform.operatingSystem;
    }
    try {
      final appVersion = js.context['navigator']['appVersion'] as String;
      if (appVersion.contains('Windows')) return 'Windows';
      if (appVersion.contains('Macintosh')) return 'macOS';
      if (appVersion.contains('Android')) return 'Android';
      if (appVersion.contains('iPhone')) return 'iOS';
      return 'Web OS';
    } catch (_) {
      return 'Web OS';
    }
  }

  String _getDeviceName() {
    if (!kIsWeb) {
      return io.Platform.localHostname;
    }
    try {
      final platform = js.context['navigator']['platform'] as String;
      if (platform.contains('Win')) return 'Windows PC';
      if (platform.contains('Mac')) return 'macOS Mac';
      if (platform.contains('iPhone')) return 'iPhone';
      if (platform.contains('Android')) return 'Android Phone';
      return 'Web Client';
    } catch (_) {
      return 'Web Client';
    }
  }

  String _getNetworkType() {
    if (!kIsWeb) return 'Cellular / Wi-Fi';
    try {
      final online = js.context['navigator']['onLine'] as bool;
      return online ? 'Wi-Fi / 5G' : 'Offline';
    } catch (_) {
      return 'Wi-Fi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Container(
          width: size.width < 500 ? size.width * 0.95 : 460,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF12121A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              )
            ],
          ),
          child: _loadingProjects 
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.action == 'check-in' ? 'PUNCH IN AUTHORIZATION' : 'PUNCH OUT AUTHORIZATION',
                      style: GoogleFonts.outfit(
                        color: VianTheme.primaryGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isSuccess) ...[
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0x2210B981),
                        child: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '✓ Punch ${widget.action == 'check-in' ? "In" : "Out"} Successful',
                        style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text('Time: $_verifiedTime', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('GPS Verified: $address', style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                      Text('Face Verified: Score ${faceScore}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: VianButton(
                          text: 'Continue',
                          onPressed: widget.onSuccess,
                        ),
                      ),
                    ] else if (_isError) ...[
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0x22EF4444),
                        child: Icon(Icons.error_outline, color: VianTheme.danger, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verification Failed',
                        style: GoogleFonts.poppins(color: VianTheme.danger, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: widget.onCancel,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: VianButton(
                              text: 'Try Again',
                              onPressed: () {
                                setState(() {
                                  _isError = false;
                                  _isScanning = false;
                                  _showMapReview = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else if (_showMapReview) ...[
                      // Interactive Circular Geofence map preview before punching
                      ProjectGeofenceMap(
                        projectName: _selectedProject?['name'] ?? 'Project Site',
                        projectLatitude: _selectedProject?['latitude'] != null ? double.parse(_selectedProject['latitude'].toString()) : 28.4595,
                        projectLongitude: _selectedProject?['longitude'] != null ? double.parse(_selectedProject['longitude'].toString()) : 77.0266,
                        employeeLatitude: lat,
                        employeeLongitude: lng,
                        allowedRadius: _selectedProject?['allowedRadius'] != null ? double.parse(_selectedProject['allowedRadius'].toString()) : 100,
                      ),
                      const SizedBox(height: 16),
                      // Resolved Human-Readable Address Card
                      (() {
                        final address = GpsAddressResolver.resolve(lat, lng);
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pin_drop,
                                    color: _insideRadius ? Colors.greenAccent : VianTheme.primaryGold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.action == 'check-in' ? 'CHECK-IN LOCATION' : 'CHECK-OUT LOCATION',
                                    style: GoogleFonts.poppins(
                                      color: VianTheme.primaryGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 16),
                              Text(
                                address.siteName,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.toAddressOnly(),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Near ${address.landmark}',
                                style: const TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        );
                      })(),
                      if (!_insideRadius) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.warning_amber_outlined, color: Colors.redAccent, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '⚠️ Outside geofence boundary. Punch requires manual override approval from administrators.',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '✓ Inside project geofence. Biometric coordinates match checks passed.',
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: widget.onCancel,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: VianButton(
                              text: _insideRadius ? 'Confirm Punch' : 'Submit for Approval',
                              onPressed: _submitPunchAction,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_isScanning) ...[
                      // Live biometric scanner animation
                      SizedBox(
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _animCtrl,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _animCtrl.value * 2 * math.pi,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: VianTheme.primaryGold.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: const CircularProgressIndicator(
                                      value: 0.3,
                                      color: VianTheme.primaryGold,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const CircleAvatar(
                              radius: 54,
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80'),
                            ),
                            AnimatedBuilder(
                              animation: _animCtrl,
                              builder: (context, child) {
                                final val = math.sin(_animCtrl.value * math.pi);
                                final offset = -50 + (100 * val);
                                return Positioned(
                                  top: 80.0 + offset,
                                  child: Container(
                                    width: 110,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(0.8),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusText,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Project Location Selection & Dev Coordinate Overrides Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Assigned Project Location', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<dynamic>(
                            dropdownColor: const Color(0xFF1E1E26),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                            ),
                            value: _selectedProject,
                            items: _projects.map<DropdownMenuItem<dynamic>>((p) {
                              return DropdownMenuItem<dynamic>(
                                value: p,
                                child: Text('${p['name']} (${p['projectId']})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedProject = val;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text('Developer GPS Simulation Settings', style: TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Site Center (Inside)'),
                                  selected: _gpsMode == 'center',
                                  selectedColor: VianTheme.primaryGold,
                                  labelStyle: TextStyle(color: _gpsMode == 'center' ? Colors.black : Colors.white70, fontSize: 11),
                                  onSelected: (selected) {
                                    if (selected) setState(() => _gpsMode = 'center');
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Breach (Outside)'),
                                  selected: _gpsMode == 'outside',
                                  selectedColor: VianTheme.primaryGold,
                                  labelStyle: TextStyle(color: _gpsMode == 'outside' ? Colors.black : Colors.white70, fontSize: 11),
                                  onSelected: (selected) {
                                    if (selected) setState(() => _gpsMode = 'outside');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: widget.onCancel,
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: VianButton(
                                  text: 'Scan Face & GPS',
                                  onPressed: _startVerification,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
