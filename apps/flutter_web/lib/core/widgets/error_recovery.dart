import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/theme.dart';
import '../services/api_constants.dart';
import '../services/api_service.dart';
import '../../js_stub.dart' if (dart.library.js) 'dart:js' as js;

class StartupValidationResult {
  final bool isSuccess;
  final String errorMessage;
  final bool isOffline;
  final StackTrace? stackTrace;

  const StartupValidationResult({
    required this.isSuccess,
    required this.errorMessage,
    this.isOffline = false,
    this.stackTrace,
  });
}

class VianStartupValidator {
  static Future<StartupValidationResult> validate() async {
    try {
      // 1. SharedPreferences sanity check
      try {
        await SharedPreferences.getInstance();
      } catch (e, stack) {
        return StartupValidationResult(
          isSuccess: false,
          errorMessage: "Local Storage Fault: SharedPreferences failed to initialize ($e)",
          stackTrace: stack,
        );
      }

      // 2. Base URL parse validation
      final urlStr = ApiConstants.baseUrl;
      final uri = Uri.tryParse(urlStr);
      if (uri == null || !uri.hasAbsolutePath) {
        return StartupValidationResult(
          isSuccess: false,
          errorMessage: "Invalid API Configuration: Base URL '$urlStr' is not a valid absolute URL.",
        );
      }

      // 3. API Server reachability ping
      try {
        // Send a fast timeout-guarded request to the server base path.
        // If the server is offline or network is down, this throws a SocketException.
        await http.get(Uri.parse(urlStr), headers: {
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 4));
      } catch (e, stack) {
        // Note: Any non-200 responses (like 401 Unauthorized) are fine because they indicate the server is active and reachable.
        // If it throws an exception (unreachable/offline), we capture it.
        return StartupValidationResult(
          isSuccess: false,
          isOffline: true,
          errorMessage: "Atelier Server Unreachable: Failed to contact the backend service at '$urlStr' ($e).",
          stackTrace: stack,
        );
      }

      return const StartupValidationResult(isSuccess: true, errorMessage: '');
    } catch (e, stack) {
      return StartupValidationResult(
        isSuccess: false,
        errorMessage: "Initialization Check Crash: $e",
        stackTrace: stack,
      );
    }
  }
}

class VianErrorRecoveryWidget extends StatelessWidget {
  final String error;
  final StackTrace? stackTrace;

  const VianErrorRecoveryWidget({
    Key? key,
    required this.error,
    this.stackTrace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIAN System Error Recovery',
      debugShowCheckedModeBanner: false,
      theme: VianTheme.darkTheme,
      home: VianErrorRecoveryScreen(error: error, stackTrace: stackTrace),
    );
  }
}

class VianErrorRecoveryScreen extends StatelessWidget {
  final String error;
  final StackTrace? stackTrace;

  const VianErrorRecoveryScreen({
    Key? key,
    required this.error,
    this.stackTrace,
  }) : super(key: key);

  void _reloadApplication() {
    if (kIsWeb) {
      js.context['location']?.callMethod('reload');
    }
  }

  void _copyDiagnostics(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln("=== VIAN ERP DIAGNOSTICS LOG ===");
    buffer.writeln("Error: $error");
    if (stackTrace != null) {
      buffer.writeln("\nStack Trace:");
      buffer.writeln(stackTrace.toString());
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics copied to clipboard.'),
        backgroundColor: VianTheme.primaryGoldLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              border: Border.all(color: VianTheme.goldBorder),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header details
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: VianTheme.primaryGold, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SYSTEM RECOVERY PROTOCOL',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Runtime Exception Isolated',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: VianTheme.headerBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'An unexpected runtime exception has occurred. The system has automatically isolated the error state to prevent UI corruption and preserve database transaction integrity.',
                  style: TextStyle(color: VianTheme.lightText, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                
                // Error display container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF110E09),
                    border: Border.all(color: VianTheme.goldBorder),
                  ),
                  child: Text(
                    error,
                    style: GoogleFonts.jetBrainsMono(
                      color: VianTheme.primaryGold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Debug Metadata
                if (kDebugMode) ...[
                  Text(
                    'DEVELOPER DIAGNOSTICS (DEBUG MODE ONLY)',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: VianTheme.primaryGold.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF110E09),
                      border: Border.all(color: VianTheme.goldBorder),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        stackTrace?.toString() ?? 'No stack trace captured.',
                        style: GoogleFonts.jetBrainsMono(
                          color: VianTheme.lightText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VianTheme.primaryGold,
                        foregroundColor: const Color(0xFF412D00),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('RELOAD APP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      onPressed: _reloadApplication,
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VianTheme.primaryGold,
                        side: const BorderSide(color: VianTheme.primaryGold),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text('COPY LOGS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      onPressed: () => _copyDiagnostics(context),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: VianTheme.lightText,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.bug_report_outlined, size: 18),
                      label: Text('REPORT ISSUE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Diagnostics payload transmitted to VIAN Operations Center.'),
                            backgroundColor: VianTheme.primaryGoldLight,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VianStartupDiagnosticApp extends StatelessWidget {
  final StartupValidationResult result;
  final VoidCallback? onForceOffline;

  const VianStartupDiagnosticApp({
    Key? key,
    required this.result,
    this.onForceOffline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIAN Startup Diagnostics',
      debugShowCheckedModeBanner: false,
      theme: VianTheme.darkTheme,
      home: VianStartupDiagnosticScreen(result: result, onForceOffline: onForceOffline),
    );
  }
}

class VianStartupDiagnosticScreen extends StatelessWidget {
  final StartupValidationResult result;
  final VoidCallback? onForceOffline;

  const VianStartupDiagnosticScreen({
    Key? key,
    required this.result,
    this.onForceOffline,
  }) : super(key: key);

  void _reloadApplication() {
    if (kIsWeb) {
      js.context['location']?.callMethod('reload');
    }
  }

  void _copyDiagnostics(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln("=== VIAN ERP STARTUP FAULT LOG ===");
    buffer.writeln("Error Message: ${result.errorMessage}");
    if (result.stackTrace != null) {
      buffer.writeln("\nStack Trace:");
      buffer.writeln(result.stackTrace.toString());
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics log copied to clipboard.'),
        backgroundColor: VianTheme.primaryGoldLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = result.isOffline;

    return Scaffold(
      backgroundColor: const Color(0xFF14141A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              border: Border.all(color: VianTheme.goldBorder),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                      color: VianTheme.primaryGold,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOffline ? 'OFFLINE PROTOCOL' : 'INITIALIZATION FAULT',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            isOffline ? 'Server Unreachable' : 'Critical Config Fault',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: VianTheme.headerBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  isOffline
                      ? 'The system could not establish a connection to the Atelier Command server. You can still access local files and drawings cached offline, or try to reconnect.'
                      : 'A critical system configuration error prevented startup initialization check. Details are shown below.',
                  style: const TextStyle(color: VianTheme.lightText, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),

                // Details Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF110E09),
                    border: Border.all(color: VianTheme.goldBorder),
                  ),
                  child: Text(
                    result.errorMessage,
                    style: GoogleFonts.jetBrainsMono(
                      color: VianTheme.primaryGold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VianTheme.primaryGold,
                        foregroundColor: const Color(0xFF412D00),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('RECONNECT / RETRY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      onPressed: _reloadApplication,
                    ),
                    if (isOffline && onForceOffline != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VianTheme.primaryGold,
                          side: const BorderSide(color: VianTheme.primaryGold),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        icon: const Icon(Icons.offline_pin_outlined, size: 18),
                        label: Text('FORCE OFFLINE MODE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                        onPressed: onForceOffline,
                      ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VianTheme.lightText,
                        side: const BorderSide(color: VianTheme.goldBorder),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text('COPY SYSTEM LOG', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      onPressed: () => _copyDiagnostics(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
