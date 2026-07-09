import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/custom_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Mock API delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _success = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: VianTheme.headerBlack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33F5A623), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // VIAN LOGO
                Image.asset(
                  'assets/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      children: [
                        const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 48),
                        Text(
                          'VIAN ARCHITECTS',
                          style: GoogleFonts.poppins(
                            color: VianTheme.primaryGold,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Reset Your Password',
                  style: GoogleFonts.poppins(
                    color: VianTheme.primaryGold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _success 
                      ? 'Check your inbox for a recovery link'
                      : 'Enter your registered email to receive a password reset link',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: VianTheme.lightText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_success) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x114CAF50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Reset email sent successfully to ${_emailController.text}!',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: VianTheme.whiteText),
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: VianTheme.lightText),
                      prefixIcon: Icon(Icons.email_outlined, color: VianTheme.primaryGold),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0x22F5A623)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: VianTheme.primaryGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: VianButton(
                      text: _isLoading ? 'Sending Request...' : 'Reset Password',
                      onPressed: _isLoading ? () {} : _handleReset,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: VianTheme.primaryGold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
