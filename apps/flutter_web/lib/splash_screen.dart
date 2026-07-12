import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'core/services/api_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _blueprintController;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  
  double _loadingProgress = 0.0;
  String _loadingText = 'Initializing Core ERP Systems...';
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // Controller for drawing the blueprint lines (runs for 4 seconds)
    _blueprintController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    // Controller for the logo zoom, rotation and pulse
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Controller for transition fade out
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Simulate progress and loading status
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    const steps = 40;
    const duration = Duration(milliseconds: 100);
    int currentStep = 0;

    _progressTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;

      currentStep++;
      setState(() {
        _loadingProgress = currentStep / steps;

        if (_loadingProgress < 0.25) {
          _loadingText = 'Initializing Core ERP Systems...';
        } else if (_loadingProgress < 0.50) {
          _loadingText = 'Establishing Secure DB Handshake...';
        } else if (_loadingProgress < 0.75) {
          _loadingText = 'Syncing Offline Cache & Assets...';
        } else if (_loadingProgress < 0.90) {
          _loadingText = 'Loading Predictive AI Modules...';
        } else {
          _loadingText = 'Welcome to VIAN Architects';
        }
      });

      if (currentStep >= steps) {
        timer.cancel();
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    // Wait a brief moment at 100% for smooth transition
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Fade out splash
    await _fadeController.forward();
    if (!mounted) return;

    final isLoggedIn = ApiService.isLoggedIn;
    if (isLoggedIn) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _blueprintController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0C), // Ultra deep charcoal/black
        body: Stack(
          children: [
            // 1. Moving Blueprint Custom Paint Background
            AnimatedBuilder(
              animation: _blueprintController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: BlueprintPainter(
                    animationValue: _blueprintController.value,
                  ),
                );
              },
            ),

            // 2. Glassmorphic Screen Tint Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x770A0A0C),
                      Color(0xCC0E0E12),
                      Color(0xFB0A0A0C),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Central Brand & Loading Indicators
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Scale & Rotational Animation
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      final scale = 0.8 + (0.2 * Curves.elasticOut.transform(_logoController.value));
                      final angle = (1.0 - _logoController.value) * math.pi * 0.25;
                      return Transform.scale(
                        scale: scale,
                        child: Transform.rotate(
                          angle: angle,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: VianTheme.primaryGold.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: VianTheme.primaryGold.withOpacity(0.08 * _logoController.value),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/logo.png',
                                height: 72,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.architecture,
                                  color: VianTheme.primaryGold,
                                  size: 72,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // Company Title
                  Text(
                    'VIAN ERP',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline with Fade-In
                  AnimatedOpacity(
                    opacity: _blueprintController.value > 0.3 ? 1.0 : 0.0,
                    duration: const Duration(seconds: 1),
                    child: Column(
                      children: [
                        Text(
                          'Engineering Excellence',
                          style: GoogleFonts.poppins(
                            color: VianTheme.primaryGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Project Management Platform',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Loading Progress Card
                  Container(
                    width: math.min(size.width * 0.8, 420),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0x11FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _loadingText,
                                style: GoogleFonts.poppins(
                                  color: VianTheme.lightText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_loadingProgress * 100).toInt()}%',
                              style: GoogleFonts.outfit(
                                color: VianTheme.primaryGold,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _loadingProgress,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. Version & Powered By Credits
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'VIAN ERP GOLD EDITION v1.2.0-beta',
                    style: GoogleFonts.poppins(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Powered by VIAN Architects',
                    style: GoogleFonts.poppins(
                      color: VianTheme.primaryGold.withOpacity(0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
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

/// CustomPainter that renders the blueprints & floor plan drafting animation
class BlueprintPainter extends CustomPainter {
  final double animationValue;

  BlueprintPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = const Color(0xFF0F1B29).withOpacity(0.18) // Steel blue drafting grid
      ..strokeWidth = 1.0;

    final paintAccent = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.15 * animationValue)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintBlueprint = Paint()
      ..color = const Color(0xFF1E3A8A).withOpacity(0.08 * animationValue)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double step = 40.0;

    // Draw main square grids
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Draw compass circles and drafting elements
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;
    
    // Draw drafting circles
    if (animationValue > 0.2) {
      canvas.drawCircle(center, maxRadius * 0.8 * animationValue, paintBlueprint);
      canvas.drawCircle(center, maxRadius * 0.5 * animationValue, paintGrid);
    }

    // Draw architectural floor plan blueprint overlay (mock lines)
    if (animationValue > 0.4) {
      final double progress = (animationValue - 0.4) / 0.6;
      final double padX = size.width * 0.15;
      final double padY = size.height * 0.2;
      
      final rect = Rect.fromPoints(
        Offset(padX, padY),
        Offset(size.width - padX, size.height - padY),
      );

      // Drawing wall borders
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left, 
          rect.top, 
          rect.left + (rect.width * progress), 
          rect.top + (rect.height * progress)
        ), 
        paintBlueprint
      );

      // Rooms divider lines
      if (progress > 0.5) {
        final double midX = rect.left + rect.width / 2;
        final double midY = rect.top + rect.height / 2;
        canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.top + (rect.height * (progress - 0.5) * 2)), paintBlueprint);
        canvas.drawLine(Offset(rect.left, midY), Offset(rect.left + (rect.width * (progress - 0.5) * 2), midY), paintBlueprint);
      }
    }

    // Draw diagonal project construction coordinate lines
    if (animationValue > 0.1) {
      canvas.drawLine(
        Offset(0, 0),
        Offset(size.width * animationValue, size.height * animationValue),
        paintAccent,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width * (1.0 - animationValue), size.height * animationValue),
        paintAccent,
      );
    }

    // Draw drafting dimensions markers
    if (animationValue > 0.8) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "SCALE: 1:50  |  DRAFT AREA: ${size.width.toInt()}x${size.height.toInt()}",
          style: GoogleFonts.courierPrime(
            color: VianTheme.primaryGold.withOpacity(0.25),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(24, size.height - 24));
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
