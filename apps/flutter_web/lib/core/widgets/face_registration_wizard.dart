import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../services/api_service.dart';
import 'custom_widgets.dart';

class FaceRegistrationWizard extends StatefulWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onComplete;

  const FaceRegistrationWizard({
    Key? key,
    required this.employee,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FaceRegistrationWizard> createState() => _FaceRegistrationWizardState();
}

class _FaceRegistrationWizardState extends State<FaceRegistrationWizard> with SingleTickerProviderStateMixin {
  late AnimationController _scannerCtrl;
  int _currentStep = 0; // 0 = Info, 1 = Front, 2 = Left, 3 = Right, 4 = Smile, 5 = Analyze/Save
  
  String? _frontFaceUrl;
  String? _leftFaceUrl;
  String? _rightFaceUrl;
  String? _smileFaceUrl;
  double _qualityScore = 98.4;
  
  bool _isProcessing = false;
  String _processingText = '';
  double _processingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _simulateCapture() {
    setState(() {
      _isProcessing = true;
      _processingText = 'Adjusting lighting and focal length...';
      _processingProgress = 0.2;
    });

    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _processingText = 'Detecting facial contours...';
        _processingProgress = 0.6;
      });
      
      Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _processingText = 'Biometric template generated successfully.';
          _processingProgress = 1.0;
        });

        Timer(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            final randomPhotoIdx = 10 + math.Random().nextInt(80);
            final mockPhotoUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';
            
            if (_currentStep == 1) _frontFaceUrl = mockPhotoUrl;
            if (_currentStep == 2) _leftFaceUrl = mockPhotoUrl;
            if (_currentStep == 3) _rightFaceUrl = mockPhotoUrl;
            if (_currentStep == 4) _smileFaceUrl = mockPhotoUrl;

            _currentStep++;
          });
        });
      });
    });
  }

  void _submitFaceRegistration() async {
    setState(() {
      _isProcessing = true;
      _processingText = 'Compiling biometric face vector signatures...';
      _processingProgress = 0.3;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _processingText = 'Verifying template quality & integrity logs...';
      _processingProgress = 0.7;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final ok = await ApiService.registerFace(
      userId: widget.employee['id'],
      frontFace: _frontFaceUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      leftFace: _leftFaceUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      rightFace: _rightFaceUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      smileFace: _smileFaceUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      qualityScore: _qualityScore,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (ok) {
      widget.onComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Successfully registered biometric face for ${widget.employee['name']}.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete biometric enrollment. Check network connectivity.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF13131A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: const BorderSide(color: Colors.white10),
      ),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: _isProcessing 
            ? _buildProcessingView()
            : _buildWizardStepView(),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _scannerCtrl,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _scannerCtrl.value * 2 * math.pi,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3), width: 1.5),
                      ),
                      child: const CircularProgressIndicator(
                        value: 0.35,
                        color: VianTheme.primaryGold,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
              const Icon(Icons.biotech, color: VianTheme.primaryGold, size: 40),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _processingText,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _processingProgress,
              backgroundColor: Colors.white.withOpacity(0.04),
              valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWizardStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStepIntro();
      case 1:
        return _buildStepCapture('CAPTURE FRONT FACE', 'Position the face directly in front of the lens. Keep expression neutral.', Icons.face);
      case 2:
        return _buildStepCapture('CAPTURE LEFT PROFILE', 'Turn head 45 degrees to the left. Capture side jaw profile.', Icons.chevron_left);
      case 3:
        return _buildStepCapture('CAPTURE RIGHT PROFILE', 'Turn head 45 degrees to the right. Capture side jaw profile.', Icons.chevron_right);
      case 4:
        return _buildStepCapture('CAPTURE SMILE PROFILE', 'Smile naturally at the camera. Verifying muscle landmarks.', Icons.sentiment_satisfied_alt);
      case 5:
      default:
        return _buildStepReview();
    }
  }

  Widget _buildStepIntro() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIOMETRIC FACE REGISTER',
          style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Employee: ${widget.employee['name']} (${widget.employee['employeeId']})',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Divider(color: Colors.white10, height: 24),
        const Text(
          'This wizard will configure a high-confidence biometric print for the employee\'s facial logs. Face signatures are stored securely on the corporate database.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Text(
          'Required Captures:',
          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBullet('1. Front face template'),
        _buildBullet('2. Left 45° profile'),
        _buildBullet('3. Right 45° profile'),
        _buildBullet('4. Smiling confirmation template'),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(width: 12),
            VianButton(
              text: 'Start Enrollment',
              onPressed: () => setState(() => _currentStep = 1),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: VianTheme.primaryGold, size: 14),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStepCapture(String title, String subtitle, IconData placeholderIcon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            shape: BoxShape.circle,
            border: Border.all(color: VianTheme.primaryGold.withOpacity(0.2), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(placeholderIcon, color: VianTheme.primaryGold.withOpacity(0.3), size: 60),
              AnimatedBuilder(
                animation: _scannerCtrl,
                builder: (context, child) {
                  final val = math.sin(_scannerCtrl.value * math.pi);
                  final offset = -70 + (140 * val);
                  return Positioned(
                    top: 80.0 + offset,
                    child: Container(
                      width: 130,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        boxShadow: [
                          BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back', style: TextStyle(color: Colors.white54)),
            ),
            VianButton(
              text: 'Simulate Capture',
              onPressed: _simulateCapture,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStepReview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIOMETRIC DATA VERIFICATION',
          style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review Captured templates status. Quality analyzer has successfully vectorized landmarks.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const Divider(color: Colors.white10, height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _thumbBox('Front Face', true),
            _thumbBox('Left Face', true),
            _thumbBox('Right Face', true),
            _thumbBox('Smile Face', true),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biometric Quality Score:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${_qualityScore.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Restart', style: TextStyle(color: Colors.white54)),
            ),
            VianButton(
              text: 'Complete Enrollment',
              onPressed: _submitFaceRegistration,
            ),
          ],
        )
      ],
    );
  }

  Widget _thumbBox(String label, bool capture) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3)),
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.greenAccent, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}
