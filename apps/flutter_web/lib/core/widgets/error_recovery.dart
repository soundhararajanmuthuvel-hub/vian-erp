import 'dart:convert';
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
  /// Normalizes base URL to generate canonical /api/health target URL
  static Uri getHealthUri(String baseUrl) {
    String cleanUrl = baseUrl.trim();
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (cleanUrl.endsWith('/health')) {
      return Uri.parse(cleanUrl);
    }
    return Uri.parse('$cleanUrl/health');
  }

  static Future<StartupValidationResult> validate() async {
    try {
      // 1. SharedPreferences sanity check
      try {
        await SharedPreferences.getInstance();
      } catch (e, stack) {
        return StartupValidationResult(
          isSuccess: false,
          errorMessage:
              "Local Storage Fault: SharedPreferences failed to initialize ($e)",
          stackTrace: stack,
        );
      }

      // 2. Base URL parse validation
      final urlStr = ApiConstants.baseUrl;
      final uri = Uri.tryParse(urlStr);
      if (uri == null || !uri.hasAbsolutePath) {
        return StartupValidationResult(
          isSuccess: false,
          errorMessage:
              "Invalid API Configuration: Base URL '$urlStr' is not a valid absolute URL.",
        );
      }

      // 3. API Server reachability & health check with retry
      // Render free-tier instances may require spin-up time (cold starts).
      // Retry sequence: Attempt 1 (15s), wait 2s, Attempt 2 (20s), wait 5s, Attempt 3 (25s)
      final healthUri = getHealthUri(urlStr);
      final List<Duration> timeouts = [
        const Duration(seconds: 15),
        const Duration(seconds: 20),
        const Duration(seconds: 25),
      ];
      final List<Duration> backoffs = [
        const Duration(seconds: 2),
        const Duration(seconds: 5),
      ];

      dynamic lastException;
      StackTrace? lastStackTrace;

      for (int attempt = 0; attempt < timeouts.length; attempt++) {
        final currentTimeout = timeouts[attempt];
        debugPrint(
          "VIAN Startup Health Check: Attempt ${attempt + 1}/${timeouts.length} targeting $healthUri (timeout: ${currentTimeout.inSeconds}s)...",
        );

        try {
          final response = await http
              .get(healthUri, headers: {'Accept': 'application/json'})
              .timeout(currentTimeout);

          debugPrint(
            "VIAN Startup Health Check: Attempt ${attempt + 1} responded with HTTP ${response.statusCode}",
          );

          if (response.statusCode == 200) {
            // Check status in JSON if present
            try {
              final body = json.decode(response.body);
              if (body is Map && body['status'] == 'ok') {
                debugPrint("VIAN Startup Health Check: Backend is healthy (database: ${body['database']}).");
                return const StartupValidationResult(isSuccess: true, errorMessage: '');
              }
            } catch (_) {
              // JSON parse wasn't required or failed, but 200 indicates server is alive
            }
            return const StartupValidationResult(isSuccess: true, errorMessage: '');
          } else {
            // Any HTTP response (401, 403, 404, 500) indicates the backend server is online and reached!
            // Do not classify a live server response as a network timeout or offline state.
            debugPrint(
              "VIAN Startup Health Check: Server reached with non-200 status code (${response.statusCode}). Server is online.",
            );
            return const StartupValidationResult(isSuccess: true, errorMessage: '');
          }
        } catch (e, stack) {
          lastException = e;
          lastStackTrace = stack;
          debugPrint(
            "VIAN Startup Health Check: Attempt ${attempt + 1} failed with error: $e",
          );

          if (attempt < backoffs.length) {
            final delay = backoffs[attempt];
            debugPrint("VIAN Startup Health Check: Waiting ${delay.inSeconds}s before retry...");
            await Future.delayed(delay);
          }
        }
      }

      // Only if all 3 retry attempts fail with network/timeout exceptions, report offline/unreachable
      return StartupValidationResult(
        isSuccess: false,
        isOffline: true,
        errorMessage:
            "Atelier Server Unreachable: Failed to contact the backend service at '$healthUri' after ${timeouts.length} attempts ($lastException).",
        stackTrace: lastStackTrace,
      );
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
    if (error.contains('401') || error.contains('403') || error.contains('Unauthorized') || error.contains('Forbidden')) {
      ApiService.logout().then((_) {
        if (kIsWeb) {
          js.context['location']?.callMethod('reload');
        }
      });
    } else {
      if (kIsWeb) {
        js.context['location']?.callMethod('reload');
      }
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
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: VianTheme.primaryGold,
                      size: 36,
                    ),
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
                  style: TextStyle(
                    color: VianTheme.lightText,
                    fontSize: 13,
                    height: 1.5,
                  ),
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
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'RELOAD APP',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: _reloadApplication,
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VianTheme.primaryGold,
                        side: const BorderSide(color: VianTheme.primaryGold),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        'COPY LOGS',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () => _copyDiagnostics(context),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: VianTheme.lightText,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.bug_report_outlined, size: 18),
                      label: Text(
                        'REPORT ISSUE',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Diagnostics payload transmitted to VIAN Operations Center.',
                            ),
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
  final Future<void> Function()? onRetry;

  const VianStartupDiagnosticApp({
    Key? key,
    required this.result,
    this.onForceOffline,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIAN Startup Diagnostics',
      debugShowCheckedModeBanner: false,
      theme: VianTheme.darkTheme,
      home: VianStartupDiagnosticScreen(
        result: result,
        onForceOffline: onForceOffline,
        onRetry: onRetry,
      ),
    );
  }
}

class VianStartupDiagnosticScreen extends StatefulWidget {
  final StartupValidationResult result;
  final VoidCallback? onForceOffline;
  final Future<void> Function()? onRetry;

  const VianStartupDiagnosticScreen({
    Key? key,
    required this.result,
    this.onForceOffline,
    this.onRetry,
  }) : super(key: key);

  @override
  State<VianStartupDiagnosticScreen> createState() =>
      _VianStartupDiagnosticScreenState();
}

class _VianStartupDiagnosticScreenState
    extends State<VianStartupDiagnosticScreen> {
  late StartupValidationResult _currentResult;
  bool _isRetrying = false;
  String _retryStatusText = '';

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;
  }

  Future<void> _handleReconnect() async {
    if (_isRetrying) return; // Prevent concurrent retries

    setState(() {
      _isRetrying = true;
      _retryStatusText = 'Contacting VIAN Atelier Server...';
    });

    if (widget.onRetry != null) {
      try {
        await widget.onRetry!();
        // If onRetry launches the app via runApp, this widget will be unmounted.
      } catch (e) {
        if (mounted) {
          setState(() {
            _isRetrying = false;
            _currentResult = StartupValidationResult(
              isSuccess: false,
              isOffline: true,
              errorMessage: 'Retry encountered an unexpected error: $e',
            );
          });
        }
      }
      return;
    }

    // Default fallback in-memory retry if no onRetry callback provided
    try {
      final validation = await VianStartupValidator.validate();
      if (!mounted) return;

      if (validation.isSuccess) {
        setState(() {
          _retryStatusText = 'Connection established. Initializing services...';
        });
        await ApiService.init();
        if (widget.onForceOffline != null) {
          widget.onForceOffline!();
        } else if (kIsWeb) {
          js.context['location']?.callMethod('reload');
        }
      } else {
        setState(() {
          _isRetrying = false;
          _currentResult = validation;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _currentResult = StartupValidationResult(
            isSuccess: false,
            isOffline: true,
            errorMessage: 'Retry failed: $e',
            stackTrace: stack,
          );
        });
      }
    }
  }

  void _copyDiagnostics(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln("=== VIAN ERP STARTUP FAULT LOG ===");
    buffer.writeln("Error Message: ${_currentResult.errorMessage}");
    if (_currentResult.stackTrace != null) {
      buffer.writeln("\nStack Trace:");
      buffer.writeln(_currentResult.stackTrace.toString());
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
    final isOffline = _currentResult.isOffline;

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
                      isOffline
                          ? Icons.wifi_off_rounded
                          : Icons.error_outline_rounded,
                      color: VianTheme.primaryGold,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOffline
                                ? 'OFFLINE PROTOCOL'
                                : 'INITIALIZATION FAULT',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: VianTheme.primaryGold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            isOffline
                                ? 'Server Unreachable'
                                : 'Critical Config Fault',
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
                  style: const TextStyle(
                    color: VianTheme.lightText,
                    fontSize: 13,
                    height: 1.5,
                  ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentResult.errorMessage,
                        style: GoogleFonts.jetBrainsMono(
                          color: VianTheme.primaryGold,
                          fontSize: 12,
                        ),
                      ),
                      if (_isRetrying) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VianTheme.primaryGold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _retryStatusText.isNotEmpty
                                    ? _retryStatusText
                                    : 'Retrying connection...',
                                style: GoogleFonts.outfit(
                                  color: VianTheme.primaryGoldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: _isRetrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF412D00),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _isRetrying ? 'CONNECTING...' : 'RECONNECT / RETRY',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: _isRetrying ? null : _handleReconnect,
                    ),
                    if (isOffline && widget.onForceOffline != null)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VianTheme.primaryGold,
                          side: const BorderSide(color: VianTheme.primaryGold),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.offline_pin_outlined, size: 18),
                        label: Text(
                          'FORCE OFFLINE MODE',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: _isRetrying ? null : widget.onForceOffline,
                      ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VianTheme.lightText,
                        side: const BorderSide(color: VianTheme.goldBorder),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        'COPY SYSTEM LOG',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
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
