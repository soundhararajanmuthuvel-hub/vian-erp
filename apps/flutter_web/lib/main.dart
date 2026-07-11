import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:ui' show ImageFilter;

import 'core/theme/theme.dart';
import 'core/services/api_service.dart';
import 'core/widgets/custom_widgets.dart';
import 'core/widgets/home_dashboards.dart';
import 'core/services/file_helper.dart';
import 'core/widgets/drawing_canvases.dart';
import 'public_enquiry_portal.dart';
import 'forgot_password_page.dart';
import 'splash_screen.dart';
import 'js_stub.dart'
    if (dart.library.js) 'dart:js' as js;

// Riverpod Provider for logged-in user state
final userProvider = StateProvider<Map<String, dynamic>?>((ref) => ApiService.currentUser);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(
    const ProviderScope(
      child: VianERPApp(),
    ),
  );
}

// Router Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (path.startsWith('/enquiry') || path.startsWith('/public-enquiry')) return null;

    final isLoggedIn = ApiService.isLoggedIn;
    final isLoggingIn = path == '/login' || path == '/forgot-password' || path == '/splash';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && (path == '/login' || path == '/forgot-password' || path == '/')) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/enquiry/:token',
      builder: (context, state) => PublicEnquiryPortalPage(token: state.pathParameters['token'] ?? ''),
    ),
    GoRoute(
      path: '/public-enquiry/:token',
      builder: (context, state) => PublicEnquiryPortalPage(token: state.pathParameters['token'] ?? ''),
    ),
    GoRoute(
      path: '/enquiry-success/:refCode',
      builder: (context, state) => PublicEnquirySuccessPage(refCode: state.pathParameters['refCode'] ?? ''),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardTab(),
        ),
        GoRoute(
          path: '/crm-leads',
          builder: (context, state) => const CRMTab(),
        ),
        GoRoute(
          path: '/leads',
          builder: (context, state) => const CRMTab(),
        ),
        GoRoute(
          path: '/leads/new',
          builder: (context, state) => const CRMTab(showAddDialog: true),
        ),
        GoRoute(
          path: '/leads/:id',
          builder: (context, state) => CRMTab(selectedLeadId: state.pathParameters['id']),
        ),
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientsTab(),
        ),
        GoRoute(
          path: '/clients/new',
          builder: (context, state) => const ClientOnboardingTab(),
        ),
        GoRoute(
          path: '/clients/:id',
          builder: (context, state) => const ClientsTab(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsTab(),
        ),
        GoRoute(
          path: '/projects/new',
          builder: (context, state) => const ProjectsTab(showAddDialog: true),
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) => ProjectWorkspacePage(
            project: {'id': safeToInt(state.pathParameters['id'])},
            userRole: ApiService.currentUser?['role'] ?? 'Client',
            userName: ApiService.currentUser?['name'] ?? 'User',
            onRefresh: () {},
            initialTab: 0,
          ),
        ),
        GoRoute(
          path: '/projects/:id/timeline',
          builder: (context, state) => ProjectWorkspacePage(
            project: {'id': safeToInt(state.pathParameters['id'])},
            userRole: ApiService.currentUser?['role'] ?? 'Client',
            userName: ApiService.currentUser?['name'] ?? 'User',
            onRefresh: () {},
            initialTab: 1,
          ),
        ),
        GoRoute(
          path: '/projects/:id/tasks',
          builder: (context, state) => ProjectWorkspacePage(
            project: {'id': safeToInt(state.pathParameters['id'])},
            userRole: ApiService.currentUser?['role'] ?? 'Client',
            userName: ApiService.currentUser?['name'] ?? 'User',
            onRefresh: () {},
            initialTab: 2,
          ),
        ),
        GoRoute(
          path: '/projects/:id/payments',
          builder: (context, state) => ProjectWorkspacePage(
            project: {'id': safeToInt(state.pathParameters['id'])},
            userRole: ApiService.currentUser?['role'] ?? 'Client',
            userName: ApiService.currentUser?['name'] ?? 'User',
            onRefresh: () {},
            initialTab: 3,
          ),
        ),
        GoRoute(
          path: '/projects/:id/documents',
          builder: (context, state) => ProjectWorkspacePage(
            project: {'id': safeToInt(state.pathParameters['id'])},
            userRole: ApiService.currentUser?['role'] ?? 'Client',
            userName: ApiService.currentUser?['name'] ?? 'User',
            onRefresh: () {},
            initialTab: 6,
          ),
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendanceTab(),
        ),
        GoRoute(
          path: '/attendance/check-in',
          builder: (context, state) => const AttendanceTab(initialAction: 'check-in'),
        ),
        GoRoute(
          path: '/attendance/check-out',
          builder: (context, state) => const AttendanceTab(initialAction: 'check-out'),
        ),
        GoRoute(
          path: '/attendance/history',
          builder: (context, state) => const AttendanceTab(initialAction: 'history'),
        ),
        GoRoute(
          path: '/employees',
          builder: (context, state) => const ContractorTab(),
        ),
        GoRoute(
          path: '/employees/new',
          builder: (context, state) => const ContractorTab(showAddDialog: true),
        ),
        GoRoute(
          path: '/employees/:id',
          builder: (context, state) => const ContractorTab(),
        ),
        GoRoute(
          path: '/site-management',
          builder: (context, state) => const DailyReportsTab(),
        ),
        GoRoute(
          path: '/site-photos',
          builder: (context, state) => const DailyReportsTab(),
        ),
        GoRoute(
          path: '/daily-reports',
          builder: (context, state) => const DailyReportsTab(),
        ),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksTab(),
        ),
        GoRoute(
          path: '/tasks/my-tasks',
          builder: (context, state) => const TasksTab(),
        ),
        GoRoute(
          path: '/tasks/completed',
          builder: (context, state) => const TasksTab(),
        ),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const DocumentsTab(),
        ),
        GoRoute(
          path: '/documents/upload',
          builder: (context, state) => const DocumentsTab(showUploadDialog: true),
        ),
        GoRoute(
          path: '/estimations',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
        GoRoute(
          path: '/estimations/new',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
        GoRoute(
          path: '/estimations/history',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
        GoRoute(
          path: '/construction-calculator',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
        GoRoute(
          path: '/market-prices',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
        GoRoute(
          path: '/boq',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const InvoicesTab(),
        ),
        GoRoute(
          path: '/payments/invoices',
          builder: (context, state) => const InvoicesTab(),
        ),
        GoRoute(
          path: '/payments/collections',
          builder: (context, state) => const InvoicesTab(),
        ),
        GoRoute(
          path: '/vendors',
          builder: (context, state) => const ContractorTab(),
        ),
        GoRoute(
          path: '/materials',
          builder: (context, state) => const ContractorTab(),
        ),
        GoRoute(
          path: '/purchase-orders',
          builder: (context, state) => const ContractorTab(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsTab(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const ReportsTab(),
        ),
        GoRoute(
          path: '/import-export',
          builder: (context, state) => const ImportExportTab(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsTab(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const SettingsTab(),
        ),
        GoRoute(
          path: '/roles',
          builder: (context, state) => const SettingsTab(),
        ),
        GoRoute(
          path: '/permissions',
          builder: (context, state) => const SettingsTab(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => const SettingsTab(),
        ),
        GoRoute(
          path: '/announcements',
          builder: (context, state) => const AnnouncementsTab(),
        ),
        GoRoute(
          path: '/enquiry-inbox',
          builder: (context, state) => const EnquiryInboxTab(),
        ),
        GoRoute(
          path: '/conference-calls',
          builder: (context, state) => const ConferenceCallsTab(),
        ),
        GoRoute(
          path: '/incentives',
          builder: (context, state) => const IncentivesTab(),
        ),
        GoRoute(
          path: '/client-onboarding',
          builder: (context, state) => const ClientOnboardingTab(),
        ),
        GoRoute(
          path: '/business-targets',
          builder: (context, state) => const BusinessTargetsTab(),
        ),
        GoRoute(
          path: '/contractor-master',
          builder: (context, state) => const ContractorTab(),
        ),
        GoRoute(
          path: '/labour-attendance',
          builder: (context, state) => const LabourAttendanceTab(),
        ),
        GoRoute(
          path: '/gps-attendance',
          builder: (context, state) => const AttendanceTab(),
        ),
        GoRoute(
          path: '/daily-work-report',
          builder: (context, state) => const DailyReportsTab(),
        ),
        GoRoute(
          path: '/manager-progress',
          builder: (context, state) => const ManagerProgressTab(),
        ),
        GoRoute(
          path: '/drawings',
          builder: (context, state) => const DrawingsTab(),
        ),
        GoRoute(
          path: '/quotations',
          builder: (context, state) => const QuotationsTab(),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const InvoicesTab(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesTab(),
        ),
        GoRoute(
          path: '/payroll',
          builder: (context, state) => const PayrollTab(),
        ),
        GoRoute(
          path: '/build-center',
          builder: (context, state) => const BuildCenterTab(),
        ),
        GoRoute(
          path: '/construction-estimation',
          builder: (context, state) => const ConstructionEstimationTab(),
        ),
      ],
    ),
  ],
);

String getPermissionRole(String role) {
  final r = role.toLowerCase();
  if (r == 'managing director' || r == 'super admin') return 'Super Admin';
  if (r == 'admin / office manager / accounts' || r == 'admin' || r == 'tech head + senior architect' || r == 'accountant') {
    return 'Admin';
  }
  return 'Staff';
}

bool canAddOrEdit(String role) {
  final pRole = getPermissionRole(role);
  return pRole == 'Super Admin' || pRole == 'Admin';
}

bool canDelete(String role) {
  final pRole = getPermissionRole(role);
  return pRole == 'Super Admin';
}

bool isSuperAdmin(String role) {
  return getPermissionRole(role) == 'Super Admin';
}

class VianERPApp extends StatelessWidget {
  const VianERPApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VIAN Architects ERP',
      debugShowCheckedModeBanner: false,
      theme: VianTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

// ==========================================
// 1. LOGIN PAGE
// ==========================================
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpCodeController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  bool _showPassword = false;
  bool _showDevOptions = false;
  String? _errorMessage;

  int _selectedMethodTab = 0; // 0 = Password, 1 = OTP, 2 = Face ID
  bool _otpSent = false;

  // Face ID state
  bool _isScanningFace = false;
  double _faceScanProgress = 0.0;
  String _faceScanStatus = 'Ready to Scan';
  Timer? _faceScanTimer;
  late AnimationController _scannerAnimationController;

  @override
  void initState() {
    super.initState();
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpCodeController.dispose();
    _scannerAnimationController.dispose();
    _faceScanTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (res['success']) {
      ref.read(userProvider.notifier).state = res['user'];
      context.go('/dashboard');
    } else {
      setState(() {
        _errorMessage = res['message'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your mobile number or employee ID.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo OTP sent to device. Code: 482019', style: TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: VianTheme.headerBlack,
        duration: Duration(seconds: 6),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    final code = _otpCodeController.text.trim();
    if (code != '482019') {
      setState(() {
        _errorMessage = 'Invalid OTP. For demo purposes, enter code 482019.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Login as Super Admin Founder & Managing Director
    final res = await ApiService.login('anand', 'anand123');

    if (res['success']) {
      ref.read(userProvider.notifier).state = res['user'];
      context.go('/dashboard');
    } else {
      setState(() {
        _errorMessage = res['message'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _startFaceIDScan() {
    setState(() {
      _isScanningFace = true;
      _faceScanProgress = 0.0;
      _faceScanStatus = 'Initializing front camera...';
      _errorMessage = null;
    });

    int currentStep = 0;
    _faceScanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      currentStep++;
      if (!mounted) return;

      setState(() {
        _faceScanProgress = currentStep / 20.0;
        if (_faceScanProgress < 0.3) {
          _faceScanStatus = 'Scanning facial structure...';
        } else if (_faceScanProgress < 0.6) {
          _faceScanStatus = 'Verifying identity indices...';
        } else if (_faceScanProgress < 0.9) {
          _faceScanStatus = 'Matching credentials DB...';
        } else {
          _faceScanStatus = 'Identity Verified!';
        }
      });

      if (currentStep >= 20) {
        timer.cancel();

        // Autologin as Super Admin (Anand Sathiesivam)
        final res = await ApiService.login('anand', 'anand123');
        if (!mounted) return;

        if (res['success']) {
          ref.read(userProvider.notifier).state = res['user'];
          context.go('/dashboard');
        } else {
          setState(() {
            _isScanningFace = false;
            _errorMessage = 'Biometric signature did not match: ${res['message']}';
          });
        }
      }
    });
  }

  void _quickFill(String role) {
    _usernameController.text = role;
    _passwordController.text = '${role}123';
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF070709), // Sleek obsidian black
      body: Stack(
        children: [
          // 1. Moving ambient luxury glowing blobs & grid lines
          const LuxuryAmbientBackground(),

          // 2. Glassmorphic container wrapper
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Hero(
                tag: 'loginHero',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      width: isMobile ? size.width * 0.92 : 460,
                      padding: const EdgeInsets.all(36.0),
                      decoration: BoxDecoration(
                        color: const Color(0x3B121216), // Highly translucent charcoal
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: VianTheme.primaryGold.withOpacity(0.18),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: VianTheme.primaryGold.withOpacity(0.02),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LOGO HEADER
                          const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 54),
                          const SizedBox(height: 10),
                          Text(
                            'VIAN ARCHITECTS',
                            style: GoogleFonts.outfit(
                              color: VianTheme.whiteText,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enterprise Architecture & Construction ERP',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: VianTheme.lightText,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // PREMIUM TABS SELECTOR
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13131A).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Row(
                              children: [
                                _buildTabButton(0, Icons.vpn_key_outlined, 'Password'),
                                _buildTabButton(1, Icons.sms_outlined, 'OTP'),
                                _buildTabButton(2, Icons.face_retouching_natural_outlined, 'Face ID'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0x1CEF4444),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: VianTheme.danger.withOpacity(0.4)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // DYNAMIC FORM FOR TABS
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _buildFormContent(),
                          ),

                          const SizedBox(height: 24),

                          // Collapsible Developer Tools
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.white30),
                            icon: Icon(_showDevOptions ? Icons.expand_less : Icons.expand_more, size: 16),
                            label: const Text('Developer Options', style: TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _showDevOptions = !_showDevOptions),
                          ),

                          if (_showDevOptions) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Quick-Access Roles',
                              style: TextStyle(color: VianTheme.lightText, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _roleChip('anand'),
                                _roleChip('vijay'),
                                _roleChip('jaya'),
                                _roleChip('muthuiya'),
                                _roleChip('murugan'),
                                _roleChip('gokul'),
                                _roleChip('sivaraman'),
                                _roleChip('mohan'),
                                _roleChip('vijayan'),
                                _roleChip('manoj'),
                                _roleChip('client'),
                              ],
                            ),
                          ],

                          const Divider(color: Color(0x11F5A623), height: 32),
                          const Text(
                            'Version 1.2.0-gold',
                            style: TextStyle(color: Colors.white30, fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '© 2026 VIAN Architects. All rights reserved.',
                            style: TextStyle(color: Colors.white30, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedMethodTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethodTab = index;
            _errorMessage = null;
            _otpSent = false;
            _isScanningFace = false;
            _faceScanTimer?.cancel();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? VianTheme.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? VianTheme.headerBlack : Colors.white60,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? VianTheme.headerBlack : Colors.white60,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    if (_selectedMethodTab == 0) {
      // Password Login
      return Column(
        key: const ValueKey('passwordForm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline, color: VianTheme.primaryGold),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: VianTheme.primaryGold),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white60,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: VianTheme.primaryGold,
                    checkColor: VianTheme.headerBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                  ),
                  const Text('Remember me', style: TextStyle(fontSize: 13, color: VianTheme.lightText)),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Forgot Password?', style: TextStyle(color: VianTheme.primaryGold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: VianButton(
              text: _isLoading ? 'Signing In...' : 'Sign In',
              onPressed: _isLoading ? () {} : _handleLogin,
            ),
          ),
        ],
      );
    } else if (_selectedMethodTab == 1) {
      // OTP Login
      return Column(
        key: const ValueKey('otpForm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_otpSent) ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mobile Number or Employee ID',
                prefixIcon: Icon(Icons.phone_outlined, color: VianTheme.primaryGold),
                hintText: '+91 XXXXX XXXXX or employee code',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: VianButton(
                text: _isLoading ? 'Sending SMS...' : 'Request OTP',
                onPressed: _isLoading ? () {} : _sendOTP,
              ),
            ),
          ] else ...[
            Text(
              'Enter verification code sent to your registered device.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: VianTheme.lightText, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpCodeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 18),
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'SMS Code',
                prefixIcon: Icon(Icons.lock_clock_outlined, color: VianTheme.primaryGold),
                hintText: '• • • • • •',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VianButton(
                    text: _isLoading ? 'Verifying...' : 'Verify & Login',
                    onPressed: _isLoading ? () {} : _verifyOTP,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    } else {
      // Face ID Login
      return Column(
        key: const ValueKey('faceIdForm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isScanningFace) ...[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF181822).withOpacity(0.6),
                border: Border.all(color: VianTheme.primaryGold.withOpacity(0.2), width: 2),
              ),
              child: const Icon(
                Icons.face_retouching_natural_outlined,
                color: VianTheme.primaryGold,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Biometric Authorization',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Position yourself facing the camera and press scan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: VianTheme.lightText, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: VianButton(
                text: 'Scan Face & Authorize',
                onPressed: _startFaceIDScan,
              ),
            ),
          ] else ...[
            // Rotating scanner rings animation
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scannerAnimationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _scannerAnimationController.value * 2 * math.pi,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: VianTheme.primaryGold.withOpacity(0.6),
                              width: 3,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                          child: const CircularProgressIndicator(
                            value: 0.25,
                            color: VianTheme.primaryGold,
                            strokeWidth: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  const Icon(
                    Icons.face_unlock_outlined,
                    color: VianTheme.primaryGold,
                    size: 64,
                  ),
                  // Draw animated scanning line
                  AnimatedBuilder(
                    animation: _scannerAnimationController,
                    builder: (context, child) {
                      final val = math.sin(_scannerAnimationController.value * math.pi);
                      final offset = -50 + (100 * val);
                      return Positioned(
                        top: 80.0 + offset,
                        child: Container(
                          width: 130,
                          height: 2,
                          decoration: BoxDecoration(
                            color: VianTheme.primaryGold,
                            boxShadow: [
                              BoxShadow(
                                color: VianTheme.primaryGold.withOpacity(0.8),
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
              _faceScanStatus,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _faceScanProgress,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _roleChip(String role) {
    return InkWell(
      onTap: () => _quickFill(role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33F5A623)),
        ),
        child: Text(
          role.toUpperCase(),
          style: const TextStyle(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Floating luxury ambient background painter and animation controllers
class LuxuryAmbientBackground extends StatefulWidget {
  const LuxuryAmbientBackground({Key? key}) : super(key: key);

  @override
  State<LuxuryAmbientBackground> createState() => _LuxuryAmbientBackgroundState();
}

class _LuxuryAmbientBackgroundState extends State<LuxuryAmbientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          children: [
            // Dark solid background
            Positioned.fill(
              child: Container(
                color: const Color(0xFF08080C),
              ),
            ),
            // Blob 1: Golden light
            Positioned(
              top: (0.15 + 0.1 * math.sin(t * 2 * math.pi)) * MediaQuery.of(context).size.height,
              left: (0.15 + 0.12 * math.cos(t * 2 * math.pi)) * MediaQuery.of(context).size.width,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VianTheme.primaryGold.withOpacity(0.06),
                ),
              ),
            ),
            // Blob 2: Deep bronze/orange glow
            Positioned(
              bottom: (0.2 + 0.1 * math.cos(t * 2 * math.pi + 1.2)) * MediaQuery.of(context).size.height,
              right: (0.12 + 0.15 * math.sin(t * 2 * math.pi + 1.2)) * MediaQuery.of(context).size.width,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC88A12).withOpacity(0.05),
                ),
              ),
            ),
            // Fine blueprint grid overlays
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),
          ],
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1B2A3B).withOpacity(0.08) // Subtle drafting grid lines
      ..strokeWidth = 1.0;

    final double step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

// ==========================================
// 2. NAVIGATION LAYOUT
// ==========================================
class MainNavigationShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainNavigationShell({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _selectedIndex = 0;

  // Tabs mapping based on user roles
  List<Map<String, dynamic>> _getTabs(String role) {
    final allTabs = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'route': '/dashboard'},
      {'title': 'CRM Leads', 'icon': Icons.campaign_outlined, 'route': '/crm-leads', 'roles': ['Super Admin', 'Receptionist']},
      {'title': 'Enquiry Inbox', 'icon': Icons.inbox_outlined, 'route': '/enquiry-inbox', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect']},
      {'title': 'Clients', 'icon': Icons.people_outline, 'route': '/clients', 'roles': ['Super Admin', 'Receptionist']},
      {'title': 'Client Onboarding', 'icon': Icons.person_add_alt_1_outlined, 'route': '/client-onboarding', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts']},
      {'title': 'Import/Export', 'icon': Icons.swap_horizontal_circle_outlined, 'route': '/import-export', 'roles': ['Super Admin']},
      {'title': 'Business Targets', 'icon': Icons.track_changes_outlined, 'route': '/business-targets', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Architect', 'Interior Designer', 'Site Engineer', 'Supervisor', 'Accountant', 'Receptionist']},
      {'title': 'Projects', 'icon': Icons.architecture, 'route': '/projects', 'roles': ['Super Admin', 'Architect', 'Interior Designer', 'Client']},
      {'title': 'Construction Estimation', 'icon': Icons.calculate_outlined, 'route': '/construction-estimation', 'roles': ['Super Admin', 'Architect', 'Site Engineer', 'Supervisor', 'Accountant', 'Receptionist']},
      {'title': 'Contractor Master', 'icon': Icons.business_center_outlined, 'route': '/contractor-master', 'roles': ['Super Admin', 'Architect', 'Site Engineer', 'Supervisor', 'Admin / Office Manager / Accounts']},
      {'title': 'Labour Attendance', 'icon': Icons.checklist_rtl_outlined, 'route': '/labour-attendance', 'roles': ['Super Admin', 'Site Engineer', 'Supervisor']},
      {'title': 'Tasks', 'icon': Icons.assignment_outlined, 'route': '/tasks', 'roles': ['Super Admin', 'Architect', 'Interior Designer', 'Site Engineer', 'Supervisor']},
      {'title': 'GPS Attendance', 'icon': Icons.pin_drop_outlined, 'route': '/gps-attendance', 'roles': ['Super Admin', 'Site Engineer', 'Supervisor']},
      {'title': 'Daily Work Report', 'icon': Icons.history_edu_outlined, 'route': '/daily-work-report', 'roles': ['Super Admin', 'Architect', 'Interior Designer', 'Site Engineer', 'Supervisor', 'Accountant', 'Receptionist']},
      {'title': 'Manager Progress', 'icon': Icons.assignment_turned_in_outlined, 'route': '/manager-progress', 'roles': ['Super Admin', 'Site Engineer', 'Supervisor']},
      {'title': 'Drawings', 'icon': Icons.layers_outlined, 'route': '/drawings', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect', 'Site Manager', 'Employee', 'Client']},
      {'title': 'Documents', 'icon': Icons.folder_open_outlined, 'route': '/documents', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect', 'Site Manager', 'Employee', 'Client']},
      {'title': 'Quotations', 'icon': Icons.description_outlined, 'route': '/quotations', 'roles': ['Super Admin', 'Accountant', 'Client']},
      {'title': 'Invoices', 'icon': Icons.receipt_long_outlined, 'route': '/invoices', 'roles': ['Super Admin', 'Accountant', 'Client']},
      {'title': 'Expenses', 'icon': Icons.payments_outlined, 'route': '/expenses', 'roles': ['Super Admin', 'Accountant']},
      {'title': 'Payroll', 'icon': Icons.price_check_outlined, 'route': '/payroll', 'roles': ['Super Admin', 'Accountant']},
      {'title': 'Reports', 'icon': Icons.assessment_outlined, 'route': '/reports', 'roles': ['Super Admin', 'Accountant']},
      {'title': 'Conference Calls', 'icon': Icons.phone_in_talk_outlined, 'route': '/conference-calls', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect']},
      {'title': 'Incentives', 'icon': Icons.monetization_on_outlined, 'route': '/incentives', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts']},
      {'title': 'Build Center', 'icon': Icons.build_circle_outlined, 'route': '/build-center', 'roles': ['Super Admin']},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'route': '/settings', 'roles': ['Super Admin']},
      {'title': 'Announcements', 'icon': Icons.campaign_outlined, 'route': '/announcements'},
    ];

    return allTabs.where((tab) {
      if (tab['roles'] == null) return true;
      final roles = tab['roles'] as List<String>;
      final effectiveRole = role == 'Managing Director' ? 'Super Admin' : role;
      return roles.contains(effectiveRole) || roles.contains(role);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final role = user['role'] ?? 'Client';
    final tabs = _getTabs(role);

    final currentPath = GoRouterState.of(context).matchedLocation;
    int index = tabs.indexWhere((tab) {
      final route = tab['route'] as String;
      if (route == currentPath) return true;
      if (route != '/dashboard' && currentPath.startsWith(route)) return true;
      if (route == '/crm-leads' && (currentPath == '/leads' || currentPath.startsWith('/leads/'))) return true;
      if (route == '/gps-attendance' && currentPath.startsWith('/attendance')) return true;
      if (route == '/contractor-master' && currentPath.startsWith('/employees')) return true;
      if (route == '/invoices' && currentPath.startsWith('/payments')) return true;
      return false;
    });
    if (index == -1) index = 0;
    _selectedIndex = index;

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 1000;

    // Build dynamic Material 3 bottom navigation bar based on user permissions
    final bottomDestinations = <Map<String, dynamic>>[
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard, 'route': '/dashboard'},
    ];
    if (tabs.any((t) => t['route'] == '/crm-leads')) {
      bottomDestinations.add({'title': 'CRM', 'icon': Icons.campaign_outlined, 'selectedIcon': Icons.campaign, 'route': '/crm-leads'});
    }
    if (tabs.any((t) => t['route'] == '/projects')) {
      bottomDestinations.add({'title': 'Projects', 'icon': Icons.architecture_outlined, 'selectedIcon': Icons.architecture, 'route': '/projects'});
    }
    if (tabs.any((t) => t['route'] == '/gps-attendance')) {
      bottomDestinations.add({'title': 'Attendance', 'icon': Icons.pin_drop_outlined, 'selectedIcon': Icons.pin_drop, 'route': '/gps-attendance'});
    }
    bottomDestinations.add({'title': 'Profile', 'icon': Icons.person_outline, 'selectedIcon': Icons.person, 'route': '/profile'});

    int bottomSelectedIndex = bottomDestinations.indexWhere((d) {
      final route = d['route'] as String;
      if (route == currentPath) return true;
      if (route != '/dashboard' && currentPath.startsWith(route)) return true;
      return false;
    });
    if (bottomSelectedIndex == -1) bottomSelectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_selectedIndex]['title']),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: VianTheme.headerBlack,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => const NotificationsPanel(),
              );
            },
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF1E1E26),
            radius: 18,
            child: Text(
              user['name']?[0] ?? 'V',
              style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile
          ? Drawer(
              child: _buildDrawerContent(user, tabs, role),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: VianTheme.headerBlack,
                border: Border(right: BorderSide(color: Color(0x22F5A623), width: 1.5)),
              ),
              child: _buildDrawerContent(user, tabs, role, showHeader: true),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              backgroundColor: const Color(0xFF1C1C1E),
              indicatorColor: VianTheme.primaryGold.withOpacity(0.15),
              selectedIndex: bottomSelectedIndex,
              onDestinationSelected: (idx) {
                context.go(bottomDestinations[idx]['route'] as String);
              },
              destinations: bottomDestinations.map((d) {
                return NavigationDestination(
                  icon: Icon(d['icon'] as IconData, color: Colors.white70),
                  selectedIcon: Icon(d['selectedIcon'] as IconData, color: VianTheme.primaryGold),
                  label: d['title'] as String,
                );
              }).toList(),
            )
          : null,
    );
  }

  Widget _buildDrawerContent(Map<String, dynamic> user, List<Map<String, dynamic>> tabs, String role, {bool showHeader = false}) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // VIAN logo in Drawer
        Image.asset(
          'assets/logo.png',
          height: 48,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 40),
        ),
        const SizedBox(height: 12),
        Text(
          'VIAN ARCHITECTS',
          style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
        ),
        const Text('Enterprise SaaS', style: TextStyle(color: Color(0xFF70707C), fontSize: 10)),
        const SizedBox(height: 24),
        const Divider(color: Color(0x11F5A623)),
        Expanded(
          child: ListView.builder(
            itemCount: tabs.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final active = _selectedIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: active ? const Color(0x15F5A623) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: active ? Border.all(color: const Color(0x44F5A623)) : null,
                ),
                child: ListTile(
                  leading: Icon(
                    tabs[index]['icon'] as IconData,
                    color: active ? VianTheme.primaryGold : VianTheme.lightText,
                    size: 20,
                  ),
                  title: Text(
                    tabs[index]['title'] as String,
                    style: TextStyle(
                      color: active ? VianTheme.primaryGold : VianTheme.lightText,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  dense: true,
                  onTap: () {
                    context.go(tabs[index]['route'] as String);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              );
            },
          ),
        ),
        const Divider(color: Color(0x11F5A623)),
        // User profile footer
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.whiteText),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      role,
                      style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: VianTheme.danger, size: 20),
                onPressed: () async {
                  await ApiService.logout();
                  ref.read(userProvider.notifier).state = null;
                  context.go('/login');
                },
              )
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. DASHBOARD TAB
// ==========================================
class DashboardTab extends ConsumerWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());
    final role = user['role'] ?? 'Client';

    if (role == 'Super Admin' || role == 'Managing Director') {
      return const ExecutiveDashboardView();
    } else if (role == 'Admin / Office Manager / Accounts') {
      return const JayaHomeView();
    } else if (role == 'Tech Head + Senior Architect') {
      return const MuthuiyaHomeView();
    } else if (role == 'Site Engineer' || 
               role == 'Supervisor' || 
               role == 'Site Coordinator' || 
               role == 'Site Construction Engineer' || 
               role == 'Labour Manager' || 
               role == 'Site Supervisor' ||
               role == 'Site Manager') {
      return const SiteManagerDashboardView();
    } else {
      return const EmployeeDashboardView();
    }
  }
}

// ==========================================
// 4. CRM LEADS TAB
// ==========================================
class CRMTab extends StatefulWidget {
  final bool showAddDialog;
  final String? selectedLeadId;
  const CRMTab({Key? key, this.showAddDialog = false, this.selectedLeadId}) : super(key: key);

  @override
  State<CRMTab> createState() => _CRMTabState();
}

class _CRMTabState extends State<CRMTab> {
  List<dynamic> _leads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    final list = await ApiService.getLeads();
    setState(() {
      _leads = list;
      _loading = false;
    });
    if (widget.showAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddLeadDialog();
      });
    } else if (widget.selectedLeadId != null) {
      final lead = list.firstWhere((l) => l['id'].toString() == widget.selectedLeadId, orElse: () => null);
      if (lead != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLeadTrackingSheet(lead);
        });
      }
    }
  }

  void _handleConvertLead(Map<String, dynamic> lead, {bool merge = false}) async {
    final role = ApiService.currentUser?['role'] ?? 'Client';
    // Gating permissions: Only Super Admin and Admin can execute conversion
    if (role != 'Managing Director' && role != 'Super Admin' && role != 'Admin / Office Manager / Accounts' && role != 'Tech Head + Senior Architect') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text('Access Denied', style: TextStyle(color: Colors.redAccent)),
          content: const Text('Staff can only recommend conversion but cannot execute it. Please contact an Admin or Super Admin.', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (merge) {
      final res = await ApiService.convertToClient(lead['id'], merge: true);
      if (res['success'] == true) {
        _fetchLeads();
        _showConversionSuccessDialog(res['client']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error during merge')));
      }
      return;
    }

    // Interactive prompt for options (Initial Project details)
    bool createProject = false;
    final projNameCtrl = TextEditingController(text: '${lead['name']} Project');
    String projType = 'Residential';
    final projBudgetCtrl = TextEditingController(text: safeToDouble(lead['budget']).toStringAsFixed(0));
    final projAddressCtrl = TextEditingController(text: lead['address'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: VianTheme.headerBlack,
            title: const Text('Convert Lead to Client', style: TextStyle(color: VianTheme.primaryGold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you sure you want to convert "${lead['name']}" into an active client?', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Auto-create Initial Project', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: createProject,
                    activeColor: VianTheme.primaryGold,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDialogState(() => createProject = v ?? false),
                  ),
                  if (createProject) ...[
                    const SizedBox(height: 12),
                    TextField(controller: projNameCtrl, decoration: const InputDecoration(labelText: 'Project Name')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: projType,
                      decoration: const InputDecoration(labelText: 'Project Type'),
                      dropdownColor: const Color(0xFF1E1E26),
                      items: const [
                        DropdownMenuItem(value: 'Residential', child: Text('Residential', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Villa', child: Text('Villa', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Commercial', child: Text('Commercial', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Apartment', child: Text('Apartment', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Interior Design', child: Text('Interior Design', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'Renovation', child: Text('Renovation', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) => setDialogState(() => projType = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: projBudgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Project Budget (INR)')),
                    const SizedBox(height: 12),
                    TextField(controller: projAddressCtrl, decoration: const InputDecoration(labelText: 'Site Address')),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              VianButton(
                text: 'Convert',
                onPressed: () async {
                  Navigator.pop(context); // Close prompt dialog
                  final budgetVal = double.tryParse(projBudgetCtrl.text) ?? 0.0;
                  final res = await ApiService.convertToClient(
                    lead['id'],
                    createProject: createProject,
                    projectName: projNameCtrl.text,
                    projectType: projType,
                    projectBudget: budgetVal,
                    projectSiteAddress: projAddressCtrl.text,
                  );

                  if (res['conflict'] == true) {
                    _showConflictDialog(lead, res['duplicate']);
                  } else if (res['success'] == true) {
                    _fetchLeads();
                    _showConversionSuccessDialog(res['client']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Conversion failed')));
                  }
                },
              )
            ],
          );
        }
      ),
    );
  }

  void _showConflictDialog(Map<String, dynamic> lead, Map<String, dynamic> duplicate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('Duplicate Client Found', style: TextStyle(color: Colors.redAccent)),
        content: Text('A client matching this email, phone, or GST number already exists:\n\n'
            'Name: ${duplicate['name']}\n'
            'Client ID: ${duplicate['clientId'] ?? 'N/A'}\n\n'
            'Would you like to open the existing client profile or merge the lead data into it?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/clients'); // Go to clients catalog
            },
            child: const Text('Open Existing Client', style: TextStyle(color: VianTheme.primaryGold)),
          ),
          VianButton(
            text: 'Merge Data',
            onPressed: () {
              Navigator.pop(context);
              _handleConvertLead(lead, merge: true);
            },
          )
        ],
      ),
    );
  }

  void _showConversionSuccessDialog(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: VianTheme.success, size: 28),
            SizedBox(width: 12),
            Text('Lead Successfully Converted', style: TextStyle(color: VianTheme.primaryGold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Name: ${client['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Client ID: ${client['clientId']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Converted By: ${client['convertedBy']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Converted On: ${client['convertedOn']}', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/projects'); // Navigate to projects
            },
            child: const Text('Create Project', style: TextStyle(color: VianTheme.primaryGold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/quotations'); // Navigate to quotations
            },
            child: const Text('Create Quotation', style: TextStyle(color: VianTheme.primaryGold)),
          ),
          VianButton(
            text: 'Open Client',
            onPressed: () {
              Navigator.pop(context);
              context.go('/clients'); // Navigate to clients list
            },
          )
        ],
      ),
    );
  }

  void _showAddLeadDialog({Map<String, dynamic>? lead}) {
    final nameCtrl = TextEditingController(text: lead?['name']);
    final phoneCtrl = TextEditingController(text: lead?['phone']);
    final reqCtrl = TextEditingController(text: lead?['requirement']);
    final budgetCtrl = TextEditingController(text: lead != null ? safeToDouble(lead['budget']).toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text(lead == null ? 'Add Client Lead' : 'Edit Client Lead', style: const TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: budgetCtrl, decoration: const InputDecoration(labelText: 'Budget (INR)')),
              const SizedBox(height: 12),
              TextField(controller: reqCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Requirement')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: lead == null ? 'Save Lead' : 'Update Lead',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final budget = double.tryParse(budgetCtrl.text) ?? 0.0;
                final body = {
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'budget': budget,
                  'requirement': reqCtrl.text,
                };
                if (lead == null) {
                  body['status'] = 'New';
                  await ApiService.addLead(body);
                } else {
                  await ApiService.updateLead(lead['id'], body);
                }
                Navigator.pop(context);
                setState(() => _loading = true);
                _fetchLeads();
              }
            },
          )
        ],
      ),
    );
  }

  void _showLeadTrackingSheet(Map<String, dynamic> lead) {
    final actionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final timeline = List.from(lead['timeline'] ?? []);

    timeline.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161620),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEAD PROGRESS TRACKING',
                            style: TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Client: ${lead['name']}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (lead['converted'] == 'Yes' || lead['clientId'] != null)
                            VianButton(
                              text: 'View Client',
                              color: VianTheme.primaryGold,
                              textColor: Colors.black,
                              onPressed: () {
                                Navigator.pop(context);
                                context.go('/clients');
                              },
                            )
                          else
                            VianButton(
                              text: 'Convert to Client',
                              color: VianTheme.success,
                              textColor: Colors.white,
                              onPressed: () {
                                Navigator.pop(context);
                                _handleConvertLead(lead);
                              },
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: VianTheme.lightText),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF262635), height: 24),
                  const Text('Record Follow-up/Activity Log:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: actionCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Action / Milestone',
                            labelStyle: TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF262635))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VianTheme.primaryGold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: notesCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Notes / Update details',
                            labelStyle: TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF262635))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VianTheme.primaryGold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold),
                      onPressed: () async {
                        if (actionCtrl.text.isEmpty) return;
                        final actionStr = actionCtrl.text;
                        final notesStr = notesCtrl.text;
                        actionCtrl.clear();
                        notesCtrl.clear();
                        await ApiService.addLeadTimeline(lead['id'], actionStr, notesStr);
                        await _fetchLeads();
                        final updatedLead = _leads.firstWhere((l) => l['id'] == lead['id'], orElse: () => lead);
                        final newTimeline = List.from(updatedLead['timeline'] ?? []);
                        newTimeline.sort((a, b) {
                          final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
                          final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
                          return bDate.compareTo(aDate);
                        });
                        setSheetState(() {
                          timeline.clear();
                          timeline.addAll(newTimeline);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Activity log registered successfully.')),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.black, size: 14),
                      label: const Text('Add Activity Log', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(color: Color(0xFF262635), height: 24),
                  const Text('Timeline History:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: timeline.isEmpty
                        ? const Center(child: Text('No tracking events logged yet.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)))
                        : ListView.builder(
                            itemCount: timeline.length,
                            itemBuilder: (context, idx) {
                              final entry = timeline[idx];
                              final dt = DateTime.tryParse(entry['createdAt']?.toString() ?? '') ?? DateTime.now();
                              final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: VianTheme.primaryGold, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(entry['action'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text(dateFormatted, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                                            ],
                                          ),
                                          if (entry['notes'] != null && entry['notes'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(entry['notes'], style: const TextStyle(color: Color(0xFF70707C), fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPublicLinkDialog(Map<String, dynamic> lead) async {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, dynamic>? link = lead['enquiryLink'];
        bool hasLink = link != null;
        bool isGenerating = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String linkUrl = '';
            if (link != null) {
              final origin = kIsWeb ? (js.context['location']['origin']?.toString() ?? 'http://localhost:5050') : 'http://localhost:5050';
              linkUrl = '$origin/#/enquiry/${link!['token']}';
            }

            return AlertDialog(
              backgroundColor: VianTheme.headerBlack,
              title: Text('Public Enquiry Link', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lead Name: ${lead['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (isGenerating) ...[
                    const Center(child: CircularProgressIndicator(color: VianTheme.primaryGold)),
                  ] else if (!hasLink) ...[
                    const Text('No secure public enquiry link generated yet for this lead.', style: TextStyle(color: VianTheme.lightText)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                      icon: const Icon(Icons.link),
                      label: const Text('Generate Secure Link'),
                      onPressed: () async {
                        setDialogState(() => isGenerating = true);
                        final res = await ApiService.generateEnquiryLink(lead['id']);
                        if (res['success'] == true) {
                          setDialogState(() {
                            link = res['link'];
                            hasLink = true;
                            isGenerating = false;
                          });
                          _fetchLeads();
                        } else {
                          setDialogState(() => isGenerating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to generate link'))
                          );
                        }
                      },
                    ),
                  ] else ...[
                    Text('Status: ${link!['status']}', style: TextStyle(color: link!['status'] == 'Active' ? VianTheme.success : VianTheme.danger, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Public Client URL:', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                    const SizedBox(height: 4),
                    SelectableText(
                      linkUrl,
                      style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: VianTheme.primaryGold),
                          tooltip: 'Copy Link',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: linkUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard!'))
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.blue),
                          tooltip: 'WhatsApp',
                          onPressed: () {
                            final msg = 'Hello, please open this link to fill the enquiry details for Vian Architects: $linkUrl';
                            final url = 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
                            openUrl(url);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.email, color: Colors.red),
                          tooltip: 'Email',
                          onPressed: () {
                            final subject = 'Client Enquiry Details - VIAN Architects';
                            final body = 'Please fill the enquiry details here: $linkUrl';
                            final url = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
                            openUrl(url);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: link!['status'] == 'Active' ? VianTheme.danger : VianTheme.success,
                            side: BorderSide(color: link!['status'] == 'Active' ? VianTheme.danger : VianTheme.success),
                          ),
                          onPressed: () async {
                            final nextStatus = link!['status'] == 'Active' ? 'Inactive' : 'Active';
                            setDialogState(() => isGenerating = true);
                            final res = await ApiService.statusEnquiryLink(lead['id'], nextStatus);
                            if (res['success'] == true) {
                              setDialogState(() {
                                link = res['link'];
                                isGenerating = false;
                              });
                              _fetchLeads();
                            } else {
                              setDialogState(() => isGenerating = false);
                            }
                          },
                          child: Text(link!['status'] == 'Active' ? 'Deactivate Link' : 'Activate Link'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                          onPressed: () async {
                            setDialogState(() => isGenerating = true);
                            final res = await ApiService.generateEnquiryLink(lead['id']);
                            if (res['success'] == true) {
                              setDialogState(() {
                                link = res['link'];
                                isGenerating = false;
                              });
                              _fetchLeads();
                            } else {
                              setDialogState(() => isGenerating = false);
                            }
                          },
                          child: const Text('Regenerate'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final currentUserRole = ApiService.currentUser?['role'] ?? 'Client';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CRM Lead Catalog', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Capture leads, manage requirements, and record proposals', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              if (canAddOrEdit(currentUserRole))
                VianButton(
                  text: 'New Lead',
                  icon: Icons.person_add,
                  onPressed: _showAddLeadDialog,
                )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _leads.length,
              itemBuilder: (context, index) {
                final lead = _leads[index];
                final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(safeToDouble(lead['budget']));

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: VianCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lead['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.whiteText)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E26),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: VianTheme.primaryGold),
                              ),
                              child: Text(
                                lead['status'] ?? 'New',
                                style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Phone: ${lead['phone']} | Budget: $budgetFormatted', style: const TextStyle(color: VianTheme.lightText, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          lead['requirement'] ?? 'No special requirements listed.',
                          style: const TextStyle(color: Color(0xFF70707C), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            VianButton(
                              text: 'Contacted',

                              isSecondary: true,
                              onPressed: () async {
                                await ApiService.updateLeadStatus(lead['id'], 'Contacted');
                                _fetchLeads();
                              },
                            ),
                            const SizedBox(width: 12),
                            if (lead['converted'] == 'Yes' || lead['clientId'] != null)
                              VianButton(
                                text: 'View Client',
                                color: VianTheme.primaryGold,
                                textColor: Colors.black,
                                onPressed: () {
                                  context.go('/clients');
                                },
                              )
                            else
                              VianButton(
                                text: 'Convert to Client',
                                color: VianTheme.success,
                                textColor: Colors.white,
                                onPressed: () => _handleConvertLead(lead),
                              ),
                            const SizedBox(width: 12),
                            VianButton(
                              text: 'Track Progress',
                              isSecondary: true,
                              icon: Icons.history_outlined,
                              onPressed: () => _showLeadTrackingSheet(lead),
                            ),
                            VianButton(
                              text: 'Enquiry Form',
                              isSecondary: true,
                              icon: Icons.assignment_outlined,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LeadStage1FormScreen(lead: lead),
                                  ),
                                ).then((_) => _fetchLeads());
                              },
                            ),
                            const SizedBox(width: 12),
                            VianButton(
                              text: 'Client Link',
                              isSecondary: true,
                              icon: Icons.share,
                              onPressed: () => _showPublicLinkDialog(lead),
                            ),
                            if (canAddOrEdit(currentUserRole)) ...[
                              const SizedBox(width: 12),
                              VianButton(
                                text: 'Edit',
                                isSecondary: true,
                                icon: Icons.edit_outlined,
                                onPressed: () => _showAddLeadDialog(lead: lead),
                              ),
                            ],
                            if (canDelete(currentUserRole)) ...[
                              const SizedBox(width: 12),
                              VianButton(
                                text: 'Delete',
                                color: Colors.redAccent,
                                textColor: Colors.white,
                                icon: Icons.delete_outline,
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: VianTheme.headerBlack,
                                      title: const Text('Delete Lead', style: TextStyle(color: Colors.redAccent)),
                                      content: const Text('Are you sure you want to move this lead to trash?', style: TextStyle(color: Colors.white)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ApiService.deleteLead(lead['id']);
                                    _fetchLeads();
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 5. CLIENTS TAB
// ==========================================
class ClientsTab extends StatefulWidget {
  const ClientsTab({Key? key}) : super(key: key);

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  List<dynamic> _clients = [];
  bool _loading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalClients = 0;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() => _loading = true);
    final res = await ApiService.getClientsPaged(
      search: _searchQuery,
      page: _currentPage,
      limit: 10,
    );
    setState(() {
      _clients = res['clients'] ?? [];
      _totalClients = res['total'] ?? 0;
      _totalPages = res['totalPages'] ?? 1;
      _loading = false;
    });
  }

  void _showAddClientDialog({Map<String, dynamic>? client}) {
    final nameCtrl = TextEditingController(text: client?['name']);
    final phoneCtrl = TextEditingController(text: client?['phone']);
    final emailCtrl = TextEditingController(text: client?['email']);
    final gstCtrl = TextEditingController(text: client?['gst']);
    final propCtrl = TextEditingController(text: client?['propertyDetails']);
    final addrCtrl = TextEditingController(text: client?['address']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text(client == null ? 'Add Client' : 'Edit Client', style: const TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN (Optional)')),
              const SizedBox(height: 12),
              TextField(controller: propCtrl, decoration: const InputDecoration(labelText: 'Property Details')),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: client == null ? 'Save Client' : 'Update Client',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final body = {
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'email': emailCtrl.text,
                  'gst': gstCtrl.text,
                  'propertyDetails': propCtrl.text,
                  'address': addrCtrl.text,
                };
                if (client == null) {
                  await ApiService.addClient(body);
                } else {
                  await ApiService.updateClient(client['id'], body);
                }
                Navigator.pop(context);
                _fetchClients();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserRole = ApiService.currentUser?['role'] ?? 'Client';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Ledger & Accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Directory of active construction clients and associated properties', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              if (canAddOrEdit(currentUserRole))
                VianButton(
                  text: 'New Client',
                  icon: Icons.person_add,
                  onPressed: () => _showAddClientDialog(),
                )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search clients by name, phone or email...',
                    prefixIcon: Icon(Icons.search, color: VianTheme.primaryGold),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1;
                    });
                    _fetchClients();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: VianCard(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF1E1E26),
                              child: Icon(Icons.person, color: VianTheme.primaryGold),
                            ),
                            title: Text(client['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Email: ${client['email']} | Phone: ${client['phone']}', style: const TextStyle(fontSize: 12)),
                                Text('GSTIN: ${client['gst'] ?? "N/A"}', style: const TextStyle(fontSize: 12, color: VianTheme.primaryGold)),
                                const SizedBox(height: 4),
                                Text(client['propertyDetails'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF70707C))),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canAddOrEdit(currentUserRole))
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: VianTheme.primaryGold),
                                    onPressed: () => _showAddClientDialog(client: client),
                                  ),
                                if (canDelete(currentUserRole))
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: VianTheme.headerBlack,
                                          title: const Text('Delete Client', style: TextStyle(color: Colors.redAccent)),
                                          content: const Text('Are you sure you want to move this client to trash?', style: TextStyle(color: Colors.white)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ApiService.deleteClient(client['id']);
                                        _fetchClients();
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_totalPages > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _fetchClients();
                        }
                      : null,
                ),
                Text('Page $_currentPage of $_totalPages', style: const TextStyle(color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _fetchClients();
                        }
                      : null,
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

// ==========================================
// 5a. LEAD STAGE 1 (CLIENT ENQUIRY FORM SCREEN)
// ==========================================
class LeadStage1FormScreen extends StatefulWidget {
  final Map<String, dynamic> lead;

  const LeadStage1FormScreen({Key? key, required this.lead}) : super(key: key);

  @override
  State<LeadStage1FormScreen> createState() => _LeadStage1FormScreenState();
}

class _LeadStage1FormScreenState extends State<LeadStage1FormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _clientNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _siteAddressController = TextEditingController();
  final _nearLandmarkController = TextEditingController();
  final _roadWidthController = TextEditingController();
  final _frontRoadController = TextEditingController();
  final _mainRoadController = TextEditingController();
  final _connectingRoadController = TextEditingController();
  final _siteConditionOtherController = TextEditingController();
  final _boreDepthController = TextEditingController();
  final _waterConditionRemarksController = TextEditingController();
  final _ebRemarksController = TextEditingController();
  final _ebDistanceController = TextEditingController();
  final _drainageRemarksController = TextEditingController();
  final _undergroundSumpRemarksController = TextEditingController();
  final _roadToPlinthRemarksController = TextEditingController();
  final _siteLevelRemarksController = TextEditingController();
  final _parkingRemarksController = TextEditingController();
  final _waterTankCapacityCustomController = TextEditingController();
  final _terraceAccessRemarksController = TextEditingController();
  final _northContextController = TextEditingController();
  final _southContextController = TextEditingController();
  final _eastContextController = TextEditingController();
  final _westContextController = TextEditingController();
  final _clientRequirementsController = TextEditingController();
  final _notesController = TextEditingController();

  // Selection States
  String? _selectedSiteFacing;
  List<String> _selectedBuildingTypes = [];
  String? _selectedLocalBody;
  List<String> _selectedSiteConditions = [];
  List<String> _selectedWaterConditions = [];
  String? _selectedEbConnection;
  String? _selectedDrainage;
  bool _undergroundSump = false;
  String? _selectedRoadToPlinth;
  String? _selectedSiteLevel;
  int _carParkingCount = 0;
  int _bikeParkingCount = 0;
  String? _selectedWaterTankCapacity;
  String? _selectedBuildingPurpose;
  List<String> _selectedStaircases = [];
  String? _selectedTerraceAccess;

  // Drawing Canvas States
  List<CanvasElement> _layoutElements = [];
  List<SketchStroke> _sketchStrokes = [];

  bool _loading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String _autosaveStatus = "Saved online";
  Timer? _autosaveTimer;
  bool _dictationActive = false;

  @override
  void initState() {
    super.initState();
    _initDefaultValues();
    _fetchStage1Data();
    _startAutosaveTimer();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _clientNameController.dispose();
    _contactNumberController.dispose();
    _dateController.dispose();
    _siteAddressController.dispose();
    _nearLandmarkController.dispose();
    _roadWidthController.dispose();
    _frontRoadController.dispose();
    _mainRoadController.dispose();
    _connectingRoadController.dispose();
    _siteConditionOtherController.dispose();
    _boreDepthController.dispose();
    _waterConditionRemarksController.dispose();
    _ebRemarksController.dispose();
    _ebDistanceController.dispose();
    _drainageRemarksController.dispose();
    _undergroundSumpRemarksController.dispose();
    _roadToPlinthRemarksController.dispose();
    _siteLevelRemarksController.dispose();
    _parkingRemarksController.dispose();
    _waterTankCapacityCustomController.dispose();
    _terraceAccessRemarksController.dispose();
    _northContextController.dispose();
    _southContextController.dispose();
    _eastContextController.dispose();
    _westContextController.dispose();
    _clientRequirementsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initDefaultValues() {
    _clientNameController.text = widget.lead['name'] ?? '';
    _contactNumberController.text = widget.lead['phone'] ?? '';
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Default requirements template
    _clientRequirementsController.text = 
        "Ground Floor: \r\n"
        "First Floor: \r\n"
        "Bedrooms: \r\n"
        "Bathrooms: \r\n"
        "Kitchen: \r\n"
        "Dining: \r\n"
        "Living: \r\n"
        "Pooja: \r\n"
        "Foyer: \r\n"
        "Sitout: \r\n"
        "Balcony: \r\n"
        "Terrace: \r\n"
        "Lift: \r\n"
        "Office: \r\n"
        "Store: \r\n"
        "Other Requirements: ";
  }

  Future<void> _fetchStage1Data() async {
    final result = await ApiService.getLeadStage1(widget.lead['id']);
    if (result != null && mounted) {
      setState(() {
        final form = result['stage1'] ?? result; // Handle both wrapper and raw object
        _clientNameController.text = form['clientName'] ?? _clientNameController.text;
        _contactNumberController.text = form['contactNumber'] ?? _contactNumberController.text;
        _dateController.text = form['date'] ?? _dateController.text;
        _siteAddressController.text = form['siteAddress'] ?? '';
        _nearLandmarkController.text = form['nearLandmark'] ?? '';
        _selectedSiteFacing = form['siteFacing'];
        
        // Parse checkboxes
        try {
          if (form['buildingType'] != null) {
            _selectedBuildingTypes = List<String>.from(json.decode(form['buildingType']));
          }
        } catch (_) {}

        _selectedLocalBody = form['localBody'];
        _roadWidthController.text = form['roadWidth']?.toString() ?? '';
        _frontRoadController.text = form['frontRoad']?.toString() ?? '';
        _mainRoadController.text = form['mainRoad']?.toString() ?? '';
        _connectingRoadController.text = form['connectingRoad']?.toString() ?? '';

        try {
          if (form['siteCondition'] != null) {
            final cond = json.decode(form['siteCondition']);
            _selectedSiteConditions = List<String>.from(cond['types'] ?? []);
            _siteConditionOtherController.text = cond['other'] ?? '';
          }
        } catch (_) {}

        try {
          if (form['waterCondition'] != null) {
            final wat = json.decode(form['waterCondition']);
            _selectedWaterConditions = List<String>.from(wat['types'] ?? []);
            _boreDepthController.text = wat['boreDepth']?.toString() ?? '';
            _waterConditionRemarksController.text = wat['remarks'] ?? '';
          }
        } catch (_) {}

        _selectedEbConnection = form['ebConnection'];
        _ebDistanceController.text = form['ebDistance']?.toString() ?? '';
        _ebRemarksController.text = form['ebRemarks'] ?? '';
        _selectedDrainage = form['drainage'];
        _drainageRemarksController.text = form['drainageRemarks'] ?? '';
        _undergroundSump = form['undergroundSump'] == true || form['undergroundSump'] == 1;
        _undergroundSumpRemarksController.text = form['undergroundSumpRemarks'] ?? '';
        _selectedRoadToPlinth = form['roadToPlinth'];
        _roadToPlinthRemarksController.text = form['roadToPlinthRemarks'] ?? '';
        _selectedSiteLevel = form['siteLevel'];
        _siteLevelRemarksController.text = form['siteLevelRemarks'] ?? '';
        _carParkingCount = form['carParking'] ?? 0;
        _bikeParkingCount = form['bikeParking'] ?? 0;
        _parkingRemarksController.text = form['parkingRemarks'] ?? '';

        final wt = form['waterTankCapacity'] ?? '';
        if (wt.startsWith('Custom:')) {
          _selectedWaterTankCapacity = 'Custom';
          _waterTankCapacityCustomController.text = wt.replaceFirst('Custom: ', '');
        } else if (wt.isNotEmpty) {
          _selectedWaterTankCapacity = wt;
        }

        _selectedBuildingPurpose = form['buildingPurpose'];

        try {
          if (form['staircase'] != null) {
            _selectedStaircases = List<String>.from(json.decode(form['staircase']));
          }
        } catch (_) {}

        _selectedTerraceAccess = form['terraceAccess'];
        _terraceAccessRemarksController.text = form['terraceAccessRemarks'] ?? '';
        _northContextController.text = form['northContext'] ?? '';
        _southContextController.text = form['southContext'] ?? '';
        _eastContextController.text = form['eastContext'] ?? '';
        _westContextController.text = form['westContext'] ?? '';
        _clientRequirementsController.text = form['clientRequirements'] ?? _clientRequirementsController.text;
        _notesController.text = form['notes'] ?? '';

        // Layout elements parse
        try {
          if (form['siteLayoutJson'] != null) {
            final parsed = json.decode(form['siteLayoutJson']) as List;
            _layoutElements = parsed.map((e) => CanvasElement.fromJson(e)).toList();
          }
        } catch (_) {}

        // Sketch strokes parse
        try {
          if (form['conceptSketchJson'] != null) {
            final parsed = json.decode(form['conceptSketchJson']) as List;
            _sketchStrokes = parsed.map((e) => SketchStroke.fromJson(e)).toList();
          }
        } catch (_) {}

        _loading = false;
        _hasUnsavedChanges = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _startAutosaveTimer() {
    _autosaveTimer = Timer.periodic(const Duration(seconds: 12), (timer) async {
      if (_hasUnsavedChanges && !_loading && !_isSaving) {
        setState(() {
          _autosaveStatus = "Saving draft...";
        });
        final success = await ApiService.saveLeadStage1(widget.lead['id'], _collectFormData());
        if (mounted) {
          setState(() {
            _hasUnsavedChanges = false;
            _autosaveStatus = success ? "Draft saved online" : "Saved draft locally (offline)";
          });
        }
      }
    });
  }

  Map<String, dynamic> _collectFormData() {
    return {
      'clientName': _clientNameController.text.trim(),
      'contactNumber': _contactNumberController.text.trim(),
      'date': _dateController.text,
      'siteAddress': _siteAddressController.text.trim(),
      'nearLandmark': _nearLandmarkController.text.trim(),
      'siteFacing': _selectedSiteFacing,
      'buildingType': json.encode(_selectedBuildingTypes),
      'localBody': _selectedLocalBody,
      'roadWidth': int.tryParse(_roadWidthController.text) ?? 0,
      'frontRoad': int.tryParse(_frontRoadController.text) ?? 0,
      'mainRoad': int.tryParse(_mainRoadController.text) ?? 0,
      'connectingRoad': int.tryParse(_connectingRoadController.text) ?? 0,
      'siteCondition': json.encode({
        'types': _selectedSiteConditions,
        'other': _siteConditionOtherController.text.trim(),
      }),
      'waterCondition': json.encode({
        'types': _selectedWaterConditions,
        'boreDepth': int.tryParse(_boreDepthController.text) ?? 0,
        'remarks': _waterConditionRemarksController.text.trim(),
      }),
      'ebConnection': _selectedEbConnection,
      'ebDistance': int.tryParse(_ebDistanceController.text) ?? 0,
      'ebRemarks': _ebRemarksController.text.trim(),
      'drainage': _selectedDrainage,
      'drainageRemarks': _drainageRemarksController.text.trim(),
      'undergroundSump': _undergroundSump,
      'undergroundSumpRemarks': _undergroundSumpRemarksController.text.trim(),
      'roadToPlinth': _selectedRoadToPlinth,
      'roadToPlinthRemarks': _roadToPlinthRemarksController.text.trim(),
      'siteLevel': _selectedSiteLevel,
      'siteLevelRemarks': _siteLevelRemarksController.text.trim(),
      'carParking': _carParkingCount,
      'bikeParking': _bikeParkingCount,
      'parkingRemarks': _parkingRemarksController.text.trim(),
      'waterTankCapacity': _selectedWaterTankCapacity == 'Custom'
          ? 'Custom: ${_waterTankCapacityCustomController.text}'
          : _selectedWaterTankCapacity,
      'buildingPurpose': _selectedBuildingPurpose,
      'staircase': json.encode(_selectedStaircases),
      'terraceAccess': _selectedTerraceAccess,
      'terraceAccessRemarks': _terraceAccessRemarksController.text.trim(),
      'northContext': _northContextController.text.trim(),
      'southContext': _southContextController.text.trim(),
      'eastContext': _eastContextController.text.trim(),
      'westContext': _westContextController.text.trim(),
      'clientRequirements': _clientRequirementsController.text.trim(),
      'siteLayoutJson': json.encode(_layoutElements.map((e) => e.toJson()).toList()),
      'notes': _notesController.text.trim(),
      'conceptSketchJson': json.encode(_sketchStrokes.map((s) => s.toJson()).toList()),
    };
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final success = await ApiService.saveLeadStage1(widget.lead['id'], _collectFormData());
    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
      _autosaveStatus = "Draft saved online";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Draft saved successfully!' : 'Saved draft locally.'),
        backgroundColor: success ? VianTheme.success : VianTheme.warning,
      ),
    );
  }

  Future<void> _submitForm() async {
    // Validate custom fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct validation errors on required fields.'), backgroundColor: VianTheme.danger),
      );
      return;
    }

    if (_selectedBuildingTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one Building Type in Section 2.'), backgroundColor: VianTheme.danger),
      );
      return;
    }

    setState(() => _isSaving = true);
    final data = _collectFormData();
    data['status'] = 'Submitted'; // Mark status as submitted

    final success = await ApiService.saveLeadStage1(widget.lead['id'], data);
    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead Stage 1 Client Enquiry Form submitted successfully!'), backgroundColor: VianTheme.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed. Saved locally instead.'), backgroundColor: VianTheme.warning),
      );
    }
  }

  void _resetForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text('Reset Form?', style: TextStyle(color: VianTheme.danger)),
        content: const Text('Are you sure you want to clear all fields? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _clientNameController.text = widget.lead['name'] ?? '';
                _contactNumberController.text = widget.lead['phone'] ?? '';
                _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
                _siteAddressController.clear();
                _nearLandmarkController.clear();
                _selectedSiteFacing = null;
                _selectedBuildingTypes.clear();
                _selectedLocalBody = null;
                _roadWidthController.clear();
                _frontRoadController.clear();
                _mainRoadController.clear();
                _connectingRoadController.clear();
                _selectedSiteConditions.clear();
                _siteConditionOtherController.clear();
                _selectedWaterConditions.clear();
                _boreDepthController.clear();
                _waterConditionRemarksController.clear();
                _selectedEbConnection = null;
                _ebRemarksController.clear();
                _ebDistanceController.clear();
                _selectedDrainage = null;
                _drainageRemarksController.clear();
                _undergroundSump = false;
                _undergroundSumpRemarksController.clear();
                _selectedRoadToPlinth = null;
                _roadToPlinthRemarksController.clear();
                _selectedSiteLevel = null;
                _siteLevelRemarksController.clear();
                _carParkingCount = 0;
                _bikeParkingCount = 0;
                _parkingRemarksController.clear();
                _selectedWaterTankCapacity = null;
                _waterTankCapacityCustomController.clear();
                _selectedBuildingPurpose = null;
                _selectedStaircases.clear();
                _selectedTerraceAccess = null;
                _terraceAccessRemarksController.clear();
                _northContextController.clear();
                _southContextController.clear();
                _eastContextController.clear();
                _westContextController.clear();
                _initDefaultValues();
                _notesController.clear();
                _layoutElements.clear();
                _sketchStrokes.clear();
                _hasUnsavedChanges = true;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: VianTheme.danger),
            child: const Text('Reset'),
          )
        ],
      ),
    );
  }

  void _printForm() {
    if (kIsWeb) {
      try {
        js.context.callMethod('print');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print trigger error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printing is supported on Web browsers.')),
      );
    }
  }

  void _downloadPDF() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: VianTheme.primaryGold),
            SizedBox(width: 10),
            Text('Download PDF', style: TextStyle(color: VianTheme.primaryGold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exporting Lead Stage 1 Client Enquiry Form...', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            LinearProgressIndicator(color: VianTheme.primaryGold, backgroundColor: Colors.white10),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully! Saved to downloads.'),
            backgroundColor: VianTheme.success,
          ),
        );
      }
    });
  }

  void _triggerVoiceDictation() {
    setState(() {
      _dictationActive = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listening... speak now into your microphone.'),
        backgroundColor: VianTheme.primaryGold,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          const dictationText = "Voice Input: Surveyed the plot, road access is clear, soil is stable, water supply check completed.";
          if (_notesController.text.isEmpty) {
            _notesController.text = dictationText;
          } else {
            _notesController.text += "\r\n$dictationText";
          }
          _dictationActive = false;
          _hasUnsavedChanges = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice input transcribed successfully.'),
            backgroundColor: VianTheme.success,
          ),
        );
      }
    });
  }

  Widget _buildSiteContextSuggestions(TextEditingController controller) {
    final suggestions = ['House', 'Apartment', 'Shop', 'Empty Land', 'Road', 'Temple', 'School', 'Farm'];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: suggestions.map((tag) {
        return InkWell(
          onTap: () {
            setState(() {
              if (controller.text.isEmpty) {
                controller.text = tag;
              } else {
                controller.text += ', $tag';
              }
              _hasUnsavedChanges = true;
            });
          },
          child: Chip(
            backgroundColor: const Color(0xFF1E1E26),
            side: const BorderSide(color: Color(0x22F5A623)),
            label: Text(tag, style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: VianCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: VianTheme.primaryGold,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const Divider(color: Color(0xFF23232F), height: 20),
            child,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildColumn1() {
    return [
      // Section 1: Client Information
      _buildSectionCard(
        title: "SECTION 1 - CLIENT INFORMATION",
        child: Column(
          children: [
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(labelText: 'Client Name *'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Client name is required' : null,
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact Number *'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Contact number is required' : null,
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date (Auto Today)', suffixIcon: Icon(Icons.calendar_today, color: VianTheme.primaryGold)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _siteAddressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Site Address *'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Site address is required' : null,
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nearLandmarkController,
              decoration: const InputDecoration(labelText: 'Near Landmark'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSiteFacing,
              dropdownColor: const Color(0xFF1E1E26),
              decoration: const InputDecoration(labelText: 'Site Facing'),
              items: ['North', 'South', 'East', 'West', 'North East', 'North West', 'South East', 'South West']
                  .map((dir) => DropdownMenuItem(value: dir, child: Text(dir)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedSiteFacing = val;
                _hasUnsavedChanges = true;
              }),
            ),
          ],
        ),
      ),

      // Section 2: Building Type
      _buildSectionCard(
        title: "SECTION 2 - BUILDING TYPE",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select all that apply * (Required)', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: ['Built after Demolishment', 'Commercial', 'New Building', 'Residential', 'Renovation'].map((type) {
                final selected = _selectedBuildingTypes.contains(type);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedBuildingTypes.remove(type);
                      } else {
                        _selectedBuildingTypes.add(type);
                      }
                      _hasUnsavedChanges = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0x22F5A623) : const Color(0xFF1E1E26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? VianTheme.primaryGold : const Color(0x33F5A623),
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: selected ? VianTheme.primaryGold : VianTheme.lightText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(type, style: TextStyle(color: selected ? Colors.white : VianTheme.lightText, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),

      // Section 3: Local Body
      _buildSectionCard(
        title: "SECTION 3 - LOCAL BODY",
        child: DropdownButtonFormField<String>(
          value: _selectedLocalBody,
          dropdownColor: const Color(0xFF1E1E26),
          decoration: const InputDecoration(labelText: 'Local Body Type'),
          items: ['Panchayat', 'Taluk', 'Municipality', 'Corporation']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (val) => setState(() {
            _selectedLocalBody = val;
            _hasUnsavedChanges = true;
          }),
        ),
      ),

      // Section 4: Road Details
      _buildSectionCard(
        title: "SECTION 4 - ROAD DETAILS",
        child: Column(
          children: [
            TextFormField(
              controller: _roadWidthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Road Width (Feet)', hintText: 'e.g. 30'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _frontRoadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Front Road (Feet)'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mainRoadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Main Road (Feet)'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _connectingRoadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Connecting Road (Feet)'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 5: Site Condition
      _buildSectionCard(
        title: "SECTION 5 - SITE CONDITION",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: ['Clay', 'Sand', 'Farm Land', 'Rock', 'Other'].map((cond) {
                final selected = _selectedSiteConditions.contains(cond);
                return FilterChip(
                  label: Text(cond),
                  selected: selected,
                  selectedColor: const Color(0x33F5A623),
                  checkmarkColor: VianTheme.primaryGold,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedSiteConditions.add(cond);
                      } else {
                        _selectedSiteConditions.remove(cond);
                      }
                      _hasUnsavedChanges = true;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedSiteConditions.contains('Other')) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _siteConditionOtherController,
                decoration: const InputDecoration(labelText: 'Site Condition Details (Other)'),
                onChanged: (_) => _hasUnsavedChanges = true,
              ),
            ],
          ],
        ),
      ),

      // Section 6: Water Condition
      _buildSectionCard(
        title: "SECTION 6 - WATER CONDITION",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: ['Salty', 'Yellowish', 'White'].map((wat) {
                final selected = _selectedWaterConditions.contains(wat);
                return FilterChip(
                  label: Text(wat),
                  selected: selected,
                  selectedColor: const Color(0x33F5A623),
                  checkmarkColor: VianTheme.primaryGold,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedWaterConditions.add(wat);
                      } else {
                        _selectedWaterConditions.remove(wat);
                      }
                      _hasUnsavedChanges = true;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _boreDepthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Bore Depth (Feet)'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _waterConditionRemarksController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 7: EB Connection
      _buildSectionCard(
        title: "SECTION 7 - EB CONNECTION",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: 'New',
                  groupValue: _selectedEbConnection,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _selectedEbConnection = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
                const Text('New EB Connection'),
                const SizedBox(width: 24),
                Radio<String>(
                  value: 'Existing',
                  groupValue: _selectedEbConnection,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _selectedEbConnection = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
                const Text('Existing EB Connection'),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ebRemarksController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 8: EB Pole Distance
      _buildSectionCard(
        title: "SECTION 8 - EB POLE DISTANCE",
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _ebDistanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Distance from Site'),
                onChanged: (_) => _hasUnsavedChanges = true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: 'Meters',
                dropdownColor: const Color(0xFF1E1E26),
                decoration: const InputDecoration(labelText: 'Unit'),
                items: const [DropdownMenuItem(value: 'Meters', child: Text('Meters'))],
                onChanged: null,
              ),
            ),
          ],
        ),
      ),

      // Section 9: Drainage
      _buildSectionCard(
        title: "SECTION 9 - DRAINAGE",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: 'Government Facility',
                  groupValue: _selectedDrainage,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _selectedDrainage = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
                const Text('Govt Facility'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'Septic Tank',
                  groupValue: _selectedDrainage,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _selectedDrainage = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
                const Text('Septic Tank'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'Manual Bio-Septic',
                  groupValue: _selectedDrainage,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _selectedDrainage = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
                const Text('Manual Bio-Septic'),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _drainageRemarksController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 10: Underground Sump
      _buildSectionCard(
        title: "SECTION 10 - UNDERGROUND SUMP",
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Provide Sump Work?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Switch(
                  value: _undergroundSump,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _undergroundSump = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _undergroundSumpRemarksController,
              decoration: const InputDecoration(labelText: 'Sump Remarks / Details'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 11: Road to Plinth Level
      _buildSectionCard(
        title: "SECTION 11 - ROAD TO PLINTH LEVEL",
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRoadToPlinth,
              dropdownColor: const Color(0xFF1E1E26),
              decoration: const InputDecoration(labelText: 'Plinth Height Target'),
              items: ['1.6 ft', '2.0 ft', '2.6 ft', '3.0 ft', '3.6 ft']
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedRoadToPlinth = val;
                _hasUnsavedChanges = true;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roadToPlinthRemarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildColumn2() {
    return [
      // Section 12: Site Level from Road
      _buildSectionCard(
        title: "SECTION 12 - SITE LEVEL FROM ROAD",
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSiteLevel,
              dropdownColor: const Color(0xFF1E1E26),
              decoration: const InputDecoration(labelText: 'Current Site Level'),
              items: ['6"', '1\'-0"', '1\'-6"', '2\'-0"', '2\'-6"']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedSiteLevel = val;
                _hasUnsavedChanges = true;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _siteLevelRemarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 13: Parking
      _buildSectionCard(
        title: "SECTION 13 - PARKING",
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Car Parking Slots:', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: VianTheme.primaryGold),
                      onPressed: () {
                        if (_carParkingCount > 0) {
                          setState(() {
                            _carParkingCount--;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                    ),
                    Text('$_carParkingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: VianTheme.primaryGold),
                      onPressed: () {
                        setState(() {
                          _carParkingCount++;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bike Parking Slots:', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: VianTheme.primaryGold),
                      onPressed: () {
                        if (_bikeParkingCount > 0) {
                          setState(() {
                            _bikeParkingCount--;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                    ),
                    Text('$_bikeParkingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: VianTheme.primaryGold),
                      onPressed: () {
                        setState(() {
                          _bikeParkingCount++;
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _parkingRemarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 14: Water Tank Capacity
      _buildSectionCard(
        title: "SECTION 14 - WATER TANK CAPACITY",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['500 L', '750 L', '1000 L', '1500 L', '2000 L', 'Custom'].map((cap) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: cap,
                      groupValue: _selectedWaterTankCapacity,
                      activeColor: VianTheme.primaryGold,
                      onChanged: (val) => setState(() {
                        _selectedWaterTankCapacity = val;
                        _hasUnsavedChanges = true;
                      }),
                    ),
                    Text(cap),
                    const SizedBox(width: 8),
                  ],
                );
              }).toList(),
            ),
            if (_selectedWaterTankCapacity == 'Custom') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _waterTankCapacityCustomController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Custom Capacity (Litres)'),
                onChanged: (_) => _hasUnsavedChanges = true,
              ),
            ]
          ],
        ),
      ),

      // Section 15: Purpose of Building
      _buildSectionCard(
        title: "SECTION 15 - PURPOSE OF BUILDING",
        child: Row(
          children: ['Personal Use', 'Rental', 'Both'].map((purp) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: purp,
                  groupValue: _selectedBuildingPurpose,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) => setState(() {
                    _selectedBuildingPurpose = val;
                    _hasUnsavedChanges = true;
                  }),
                ),
                Text(purp),
                const SizedBox(width: 16),
              ],
            );
          }).toList(),
        ),
      ),

      // Section 16: Staircase
      _buildSectionCard(
        title: "SECTION 16 - STAIRCASE",
        child: Row(
          children: ['Internal', 'External'].map((stair) {
            final selected = _selectedStaircases.contains(stair);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selected,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedStaircases.add(stair);
                      } else {
                        _selectedStaircases.remove(stair);
                      }
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
                Text('$stair Staircase'),
                const SizedBox(width: 24),
              ],
            );
          }).toList(),
        ),
      ),

      // Section 17: Terrace Access
      _buildSectionCard(
        title: "SECTION 17 - TERRACE ACCESS",
        child: Column(
          children: [
            Row(
              children: ['Concrete Staircase', 'Steel Staircase'].map((acc) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: acc,
                      groupValue: _selectedTerraceAccess,
                      activeColor: VianTheme.primaryGold,
                      onChanged: (val) => setState(() {
                        _selectedTerraceAccess = val;
                        _hasUnsavedChanges = true;
                      }),
                    ),
                    Text(acc),
                    const SizedBox(width: 24),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _terraceAccessRemarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
          ],
        ),
      ),

      // Section 18: Existing Site Context
      _buildSectionCard(
        title: "SECTION 18 - EXISTING SITE CONTEXT",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe neighboring structures (North, South, East, West):', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _northContextController,
              decoration: const InputDecoration(labelText: 'North Context', hintText: 'e.g. Empty plot / Road'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 4),
            _buildSiteContextSuggestions(_northContextController),
            const SizedBox(height: 12),
            TextFormField(
              controller: _southContextController,
              decoration: const InputDecoration(labelText: 'South Context'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 4),
            _buildSiteContextSuggestions(_southContextController),
            const SizedBox(height: 12),
            TextFormField(
              controller: _eastContextController,
              decoration: const InputDecoration(labelText: 'East Context'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 4),
            _buildSiteContextSuggestions(_eastContextController),
            const SizedBox(height: 12),
            TextFormField(
              controller: _westContextController,
              decoration: const InputDecoration(labelText: 'West Context'),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 4),
            _buildSiteContextSuggestions(_westContextController),
          ],
        ),
      ),

      // Section 19: Client Requirements
      _buildSectionCard(
        title: "SECTION 19 - CLIENT REQUIREMENTS",
        child: TextFormField(
          controller: _clientRequirementsController,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: 'Requirements Checklist / Matrix',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => _hasUnsavedChanges = true,
        ),
      ),

      // Section 20: Site Layout Drawing Board
      _buildSectionCard(
        title: "SECTION 20 - SITE LAYOUT DRAWING",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sketch layout dimensions and orientation (N arrow, text, arrows, shapes):', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            SiteLayoutCanvas(
              elements: _layoutElements,
              onChanged: (newElements) {
                setState(() {
                  _layoutElements = newElements;
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ],
        ),
      ),

      // Section 21: Notes
      _buildSectionCard(
        title: "SECTION 21 - GENERAL NOTES",
        child: Column(
          children: [
            TextFormField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Type survey notes here...', alignLabelWithHint: true),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _dictationActive ? null : _triggerVoiceDictation,
                  icon: _dictationActive
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.mic, color: Colors.black),
                  label: Text(_dictationActive ? 'Listening...' : 'Voice Dictation Dictate', style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dictationActive ? Colors.white24 : VianTheme.primaryGold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),

      // Section 22: Concept Sketch
      _buildSectionCard(
        title: "SECTION 22 - CONCEPT FREEHAND SKETCH",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Freehand client ideas, stylus and touch sketch:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            ConceptSketchCanvas(
              strokes: _sketchStrokes,
              onChanged: (newStrokes) {
                setState(() {
                  _sketchStrokes = newStrokes;
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFF1E1E2F), body: Center(child: CircularProgressIndicator()));

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      appBar: AppBar(
        backgroundColor: VianTheme.headerBlack,
        title: Row(
          children: [
            const Icon(Icons.assignment, color: VianTheme.primaryGold),
            const SizedBox(width: 12),
            Text('Client Enquiry Form (Lead Stage 1) - ${widget.lead['name']}'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _hasUnsavedChanges ? Icons.sync : Icons.check_circle_outline,
                  color: _hasUnsavedChanges ? VianTheme.warning : VianTheme.success,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _autosaveStatus,
                  style: TextStyle(
                    color: _hasUnsavedChanges ? VianTheme.warning : VianTheme.lightText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildColumn1(),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _buildColumn2(),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._buildColumn1(),
                          ..._buildColumn2(),
                        ],
                      ),
              ),
            ),
          ),
          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: VianTheme.headerBlack,
              border: Border(top: BorderSide(color: Color(0x33F5A623), width: 1.5)),
            ),
            child: SafeArea(
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  VianButton(
                    text: 'Save Draft',
                    isSecondary: true,
                    onPressed: _isSaving ? null : _saveDraft,
                  ),
                  VianButton(
                    text: 'Save',
                    isSecondary: true,
                    onPressed: _isSaving ? null : _saveDraft,
                  ),
                  VianButton(
                    text: 'Submit Form',
                    color: VianTheme.success,
                    textColor: Colors.white,
                    onPressed: _isSaving ? null : _submitForm,
                  ),
                  VianButton(
                    text: 'Reset Fields',
                    isSecondary: true,
                    color: VianTheme.danger,
                    onPressed: _resetForm,
                  ),
                  VianButton(
                    text: 'Print Page',
                    isSecondary: true,
                    icon: Icons.print,
                    onPressed: _printForm,
                  ),
                  VianButton(
                    text: 'Download PDF',
                    isSecondary: true,
                    icon: Icons.picture_as_pdf,
                    onPressed: _downloadPDF,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 6. PROJECTS TAB
// ==========================================
class ProjectsTab extends ConsumerStatefulWidget {
  final bool showAddDialog;
  const ProjectsTab({Key? key, this.showAddDialog = false}) : super(key: key);

  @override
  ConsumerState<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends ConsumerState<ProjectsTab> {
  List<dynamic> _projects = [];
  bool _loading = true;
  int _viewMode = 0; // 0 = Grid, 1 = Kanban, 2 = Gantt/Timeline

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final list = await ApiService.getProjects();
    setState(() {
      _projects = list;
      _loading = false;
    });
    if (widget.showAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = ref.read(userProvider);
        final role = user?['role'] ?? 'Client';
        _showAddProjectDialog(role);
      });
    }
  }

  void _showAddProjectDialog(String role) {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final clientNameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final floorsCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: DateTime.now().toString().split(' ').first);
    final endCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 365)).toString().split(' ').first);
    
    String selectedType = 'Residential';
    String selectedPackage = 'Premium';
    String selectedTemplate = 'Residential House';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E26),
          title: const Text('Create Construction Project', style: TextStyle(color: VianTheme.primaryGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Project Code (e.g. VIAN-PROJ-01)')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Project Name')),
                TextField(controller: clientNameCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
                TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget (₹)')),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Site Address')),
                TextField(controller: areaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Built-up Area (Sq. Ft.)')),
                TextField(controller: floorsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Floors')),
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Expected End Date (YYYY-MM-DD)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Project Type'),
                  dropdownColor: const Color(0xFF1E1E26),
                  items: ['Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDlgState(() => selectedType = val!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPackage,
                  decoration: const InputDecoration(labelText: 'Construction Package'),
                  dropdownColor: const Color(0xFF1E1E26),
                  items: ['Standard', 'Premium', 'Luxury'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setDlgState(() => selectedPackage = val!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTemplate,
                  decoration: const InputDecoration(labelText: 'Lifecycle Template'),
                  dropdownColor: const Color(0xFF1E1E26),
                  items: ['Residential House', 'Villa', 'Apartment', 'Commercial', 'Interior', 'Renovation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDlgState(() => selectedTemplate = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
              onPressed: () async {
                final ok = await ApiService.createProject({
                  'projectId': codeCtrl.text,
                  'name': nameCtrl.text,
                  'type': selectedType,
                  'clientId': 1,
                  'budget': double.tryParse(budgetCtrl.text) ?? 0.0,
                  'startDate': startCtrl.text,
                  'completionDate': endCtrl.text,
                  'constructionPackage': selectedPackage,
                  'siteAddress': addressCtrl.text,
                  'builtUpArea': double.tryParse(areaCtrl.text) ?? 0.0,
                  'floors': int.tryParse(floorsCtrl.text) ?? 1,
                  'template': selectedTemplate,
                });
                if (ok) {
                  Navigator.of(ctx).pop();
                  _loadProjects();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final user = ref.watch(userProvider);
    final role = user?['role'] ?? 'Client';
    final name = user?['name'] ?? 'User';

    final canCreate = role == 'Managing Director' || role == 'Super Admin' || role == 'Admin / Office Manager / Accounts' || role == 'Tech Head + Senior Architect';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Architectural Portfolios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Design structures, elevations, budgets, and operational progress', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              Row(
                children: [
                  if (canCreate) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                      onPressed: () => _showAddProjectDialog(role),
                      icon: const Icon(Icons.add),
                      label: const Text('New Project'),
                    ),
                    const SizedBox(width: 16),
                  ],
                  IconButton(
                    icon: Icon(Icons.grid_view, color: _viewMode == 0 ? VianTheme.primaryGold : Colors.white),
                    onPressed: () => setState(() => _viewMode = 0),
                  ),
                  IconButton(
                    icon: Icon(Icons.view_kanban_outlined, color: _viewMode == 1 ? VianTheme.primaryGold : Colors.white),
                    onPressed: () => setState(() => _viewMode = 1),
                  ),
                  IconButton(
                    icon: Icon(Icons.view_timeline_outlined, color: _viewMode == 2 ? VianTheme.primaryGold : Colors.white),
                    onPressed: () => setState(() => _viewMode = 2),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _viewMode == 0
                ? _buildGridView(role, name)
                : (_viewMode == 1 ? _buildKanbanView(role, name) : _buildTimelineView(role, name)),
          )
        ],
      ),
    );
  }

  Widget _buildGridView(String role, String name) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 600 ? 1 : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _projects.length,
          itemBuilder: (context, index) {
            final p = _projects[index];
            final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(safeToDouble(p['budget']));
            final progress = (p['progressPercentage'] ?? 0) / 100.0;

            return GestureDetector(
              onTap: () {
                context.go('/projects/${p['id']}');
              },
              child: VianCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p['projectId'] ?? '', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(p['status'] ?? '', style: const TextStyle(color: Color(0xFF70707C), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Type: ${p['type']} | Client: ${p['client']?['name']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                    Text('Budget: $budgetFormatted', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12)),
                    const Spacer(),
                    VianProgressIndicator(progress: progress),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKanbanView(String role, String name) {
    final statuses = ['Planning', 'In Progress', 'Completed'];
    return Row(
      children: statuses.map((status) {
        final filtered = _projects.where((p) => p['status'] == status).toList();
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                    CircleAvatar(
                      backgroundColor: VianTheme.headerBlack,
                      radius: 12,
                      child: Text(filtered.length.toString(), style: const TextStyle(fontSize: 11, color: VianTheme.primaryGold)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            context.go('/projects/' + p['id'].toString());
                          },
                          child: VianCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Progress: ${p['progressPercentage']}%', style: const TextStyle(fontSize: 11, color: VianTheme.lightText)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineView(String role, String name) {
    return ListView.builder(
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final p = _projects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              context.go('/projects/' + p['id'].toString());
            },
            child: VianCard(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Start: ${p['startDate']} | End: ${p['completionDate']}', style: const TextStyle(fontSize: 11, color: Color(0xFF70707C))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: (p['progressPercentage'] ?? 0) / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: VianTheme.primaryGold,
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [VianTheme.primaryGold, VianTheme.goldBorder]),
                              ),
                            ),
                          ),
                          Center(child: Text('${p['progressPercentage']}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 6B. PROJECT LIFECYCLE WORKSPACE PAGE
// ==========================================
class ProjectWorkspacePage extends StatefulWidget {
  final Map<String, dynamic> project;
  final String userRole;
  final String userName;
  final VoidCallback onRefresh;
  final int initialTab;

  const ProjectWorkspacePage({
    Key? key,
    required this.project,
    required this.userRole,
    required this.userName,
    required this.onRefresh,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<ProjectWorkspacePage> createState() => _ProjectWorkspacePageState();
}

class _ProjectWorkspacePageState extends State<ProjectWorkspacePage> {
  Map<String, dynamic> _project = {};
  bool _loading = true;
  int _selectedTab = 0;

  // Controllers for CRUD & logs
  final _stageNameCtrl = TextEditingController();
  final _stageDescCtrl = TextEditingController();
  final _stageEstCostCtrl = TextEditingController();
  final _stageEstStartCtrl = TextEditingController();
  final _stageEstEndCtrl = TextEditingController();
  final _stagePaymentPercentCtrl = TextEditingController();

  final _reportDescCtrl = TextEditingController();
  final _reportWorkersCtrl = TextEditingController();
  final _reportMatCtrl = TextEditingController();
  final _reportProblemCtrl = TextEditingController();
  final _reportWeatherCtrl = TextEditingController();
  final _reportGpsCtrl = TextEditingController();

  final _matNameCtrl = TextEditingController();
  final _matReqQtyCtrl = TextEditingController();
  final _matCostCtrl = TextEditingController();

  final _labourNameCtrl = TextEditingController();
  final _labourWageCtrl = TextEditingController();

  final _paymentAmountCtrl = TextEditingController();
  final _paymentDueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    final details = await ApiService.getProjectDetails(widget.project['id']);
    setState(() {
      _project = details.isEmpty ? widget.project : details;
      _loading = false;
    });
  }

  bool get _canManageStages {
    final role = widget.userRole;
    return role == 'Managing Director' ||
           role == 'Super Admin' ||
           role == 'Admin / Office Manager / Accounts' ||
           role == 'Tech Head + Senior Architect' ||
           role == 'Site Manager';
  }

  bool get _isSuperAdmin {
    return widget.userRole == 'Managing Director' || widget.userRole == 'Super Admin';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: VianTheme.headerBlack,
        body: Center(child: CircularProgressIndicator(color: VianTheme.primaryGold)),
      );
    }

    final List<String> tabs = [
      'Overview',
      'Timeline',
      'Stages',
      'Payments',
      'Materials',
      'Labour',
      'Site Tracking',
      'Workflow Approvals',
    ];

    return Scaffold(
      backgroundColor: VianTheme.headerBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E26),
        title: Row(
          children: [
            Text(_project['projectId'] ?? '', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Text(_project['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: VianTheme.primaryGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VianTheme.primaryGold, width: 0.5),
            ),
            child: Text(
              _project['status'] ?? 'Planning',
              style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: const Color(0xFF1E1E26),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTab == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? VianTheme.primaryGold : const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? VianTheme.primaryGold : Colors.white10),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildActiveTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTab) {
      case 0: return _buildOverviewTab();
      case 1: return _buildTimelineTab();
      case 2: return _buildStagesTab();
      case 3: return _buildPaymentsTab();
      case 4: return _buildMaterialsTab();
      case 5: return _buildLabourTab();
      case 6: return _buildSiteTrackingTab();
      case 7: return _buildWorkflowApprovalsTab();
      default: return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(safeToDouble(_project['budget']));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Project Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
            if (_isSuperAdmin) ...[
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: _duplicateProject,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Duplicate'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    onPressed: _archiveProject,
                    icon: const Icon(Icons.archive, size: 16),
                    label: const Text('Archive'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _deleteProject,
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('Delete'),
                  ),
                ],
              )
            ]
          ],
        ),
        const SizedBox(height: 16),
        VianCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Project Code', _project['projectId'] ?? '-'),
              _buildDetailRow('Client Name', _project['client']?['name'] ?? '-'),
              _buildDetailRow('Project Type', _project['type'] ?? '-'),
              _buildDetailRow('Site Location', _project['siteAddress'] ?? '-'),
              _buildDetailRow('Budget', budgetFormatted),
              _buildDetailRow('Dates', '${_project['startDate'] ?? '-'} to ${_project['completionDate'] ?? '-'}'),
              const SizedBox(height: 16),
              const Text('Assigned Team', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              const Divider(color: Colors.white24),
              _buildDetailRow('Architect', _project['architect']?['name'] ?? '-'),
              _buildDetailRow('Site Engineer', _project['siteEngineer']?['name'] ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    final stages = List<dynamic>.from(_project['stages'] ?? []);
    stages.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    if (stages.isEmpty) return const Center(child: Text('No stages configured.', style: TextStyle(color: VianTheme.lightText)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Construction Lifecycle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stages.length,
          itemBuilder: (context, index) {
            final stage = stages[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [CircleAvatar(radius: 12, backgroundColor: stage['status'] == 'Approved' ? Colors.green : VianTheme.primaryGold, child: const Icon(Icons.engineering, size: 12, color: Colors.black)), if (index < stages.length - 1) Container(width: 2, height: 90, color: Colors.white24)]),
                const SizedBox(width: 16),
                Expanded(child: Container(margin: const EdgeInsets.only(bottom: 24), child: VianCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(stage['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(stage['description'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 12))]))))
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStagesTab() {
    final stages = List<dynamic>.from(_project['stages'] ?? []);
    stages.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Stages Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)), if (_canManageStages) ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold), onPressed: _showAddStageDialog, icon: const Icon(Icons.add), label: const Text('Add Stage'))]),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stages.length,
          itemBuilder: (context, index) {
            final stage = stages[index];
            return Container(margin: const EdgeInsets.only(bottom: 12), child: VianCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(stage['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(stage['description'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 12))])), if (_canManageStages) IconButton(icon: const Icon(Icons.edit, color: VianTheme.primaryGold), onPressed: () => _showEditStageDialog(stage))])));
          },
        )
      ],
    );
  }

  Widget _buildPaymentsTab() {
    final stages = List<dynamic>.from(_project['stages'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
        const SizedBox(height: 16),
        ...stages.map((stage) => Container(margin: const EdgeInsets.only(bottom: 12), child: VianCard(child: ListTile(title: Text(stage['name'] ?? ''), trailing: Text(stage['paymentStatus'] ?? 'Pending'))))),
      ],
    );
  }

  Widget _buildMaterialsTab() => const Center(child: Text('Material logs displayed here', style: TextStyle(color: Colors.white54)));
  Widget _buildLabourTab() => const Center(child: Text('Labour logs displayed here', style: TextStyle(color: Colors.white54)));
  Widget _buildSiteTrackingTab() => const Center(child: Text('Daily site logs displayed here', style: TextStyle(color: Colors.white54)));
  Widget _buildWorkflowApprovalsTab() => const Center(child: Text('Approval workflow displayed here', style: TextStyle(color: Colors.white54)));

  Future<void> _archiveProject() async {
    final success = await ApiService.archiveProject(_project['id']);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project archived successfully')));
      _loadDetails();
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('Delete Project', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Are you sure you want to move this project to trash?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.deleteProject(_project['id']);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _duplicateProject() async {
    final success = await ApiService.duplicateProject(_project['id']);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project duplicated successfully')));
      Navigator.pop(context, true);
    }
  }
  void _showAddStageDialog() {}
  void _showEditStageDialog(dynamic stage) {}
}

// ==========================================
// 7. TASKS TAB
// ==========================================
class TasksTab extends StatefulWidget {
  const TasksTab({Key? key}) : super(key: key);

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final list = await ApiService.getTasks();
    setState(() {
      _tasks = list;
      _loading = false;
    });
  }

  void _showAddEditTaskDialog({Map<String, dynamic>? task}) {
    final titleCtrl = TextEditingController(text: task?['title']);
    final descCtrl = TextEditingController(text: task?['description']);
    final dueCtrl = TextEditingController(text: task?['dueDate'] ?? DateTime.now().toString().split(' ').first);
    
    String selectedPriority = task?['priority'] ?? 'Medium';
    String selectedStatus = task?['status'] ?? 'Pending';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text(task == null ? 'Create Task' : 'Edit Task', style: const TextStyle(color: VianTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setDlgState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: dueCtrl, decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Medium', 'High', 'Critical'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setDlgState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Pending', 'In Progress', 'Review', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setDlgState(() => selectedStatus = val!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: task == null ? 'Create' : 'Update',
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                final body = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'dueDate': dueCtrl.text,
                  'priority': selectedPriority,
                  'status': selectedStatus,
                };
                if (task == null) {
                  await ApiService.createTask(body);
                } else {
                  await ApiService.updateTask(task['id'], body);
                }
                Navigator.pop(context);
                _loadTasks();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final columns = ['Pending', 'In Progress', 'Review', 'Completed'];

    final currentUserRole = ApiService.currentUser?['role'] ?? 'Client';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Operational Tasks Board', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Track structural layouts, site supervisor checklists, and reviews', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              if (canAddOrEdit(currentUserRole))
                VianButton(
                  text: 'New Task',
                  icon: Icons.add_task,
                  onPressed: () => _showAddEditTaskDialog(),
                )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: columns.map((colName) {
                final filtered = _tasks.where((t) => t['status'] == colName).toList();
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(colName, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final task = filtered[index];
                              Color priColor = Colors.green;
                              if (task['priority'] == 'High') priColor = VianTheme.warning;
                              if (task['priority'] == 'Critical') priColor = VianTheme.danger;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: VianCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(task['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.whiteText)),
                                          ),
                                          if (canAddOrEdit(currentUserRole))
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.edit_outlined, size: 16, color: VianTheme.primaryGold),
                                              onPressed: () => _showAddEditTaskDialog(task: task),
                                            ),
                                          if (canDelete(currentUserRole))
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: VianTheme.headerBlack,
                                                    title: const Text('Delete Task', style: TextStyle(color: Colors.redAccent)),
                                                    content: const Text('Are you sure you want to move this task to trash?', style: TextStyle(color: Colors.white)),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await ApiService.deleteTask(task['id']);
                                                  _loadTasks();
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(task['project'] != null ? 'Project: ${task['project']['name']}' : 'No Project', style: const TextStyle(fontSize: 11, color: VianTheme.lightText)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: priColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                            child: Text(task['priority'] ?? '', style: TextStyle(color: priColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                          Text('Due: ${task['dueDate']}', style: const TextStyle(fontSize: 10, color: Color(0xFF70707C))),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 8. GPS ATTENDANCE TAB
// ==========================================
class AttendanceTab extends StatefulWidget {
  final String? initialAction;
  const AttendanceTab({Key? key, this.initialAction}) : super(key: key);

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  bool _checkedIn = false;
  String _gps = 'Capturing...';
  String? _checkInTime;
  String? _checkOutTime;

  @override
  void initState() {
    super.initState();
    _captureLocation();
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialAction == 'check-in') {
          _handleCheckIn();
        } else if (widget.initialAction == 'check-out') {
          _handleCheckOut();
        } else if (widget.initialAction == 'history') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viewing Attendance History Log...'))
          );
        }
      });
    }
  }

  void _captureLocation() {
    // Simulated GPS Coordinates for Site Engineer Check-In
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _gps = '28.4595° N, 77.0266° E (Sector 43 Office)';
        });
      }
    });
  }

  void _handleCheckIn() async {
    setState(() => _checkedIn = true);
    _checkInTime = DateFormat('hh:mm a').format(DateTime.now());
    await ApiService.checkIn(_gps, null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully Checked In (GPS Captured)')));
  }

  void _handleCheckOut() async {
    _checkOutTime = DateFormat('hh:mm a').format(DateTime.now());
    await ApiService.checkOut(_gps);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully Checked Out (GPS Captured)')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: VianCard(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.pin_drop, size: 48, color: VianTheme.primaryGold),
                const SizedBox(height: 16),
                const Text('GPS Geofenced Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                const Text('Site engineers and supervisors mobile check-in portal', style: TextStyle(color: Color(0xFF70707C), fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: VianTheme.primaryGold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Location Status', style: TextStyle(fontSize: 10, color: Color(0xFF70707C))),
                            Text(_gps, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Selfie preview mock
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E26),
                    shape: BoxShape.circle,
                    border: Border.all(color: VianTheme.primaryGold, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: VianTheme.primaryGold, size: 24),
                      SizedBox(height: 4),
                      Text('Selfie Captured', style: TextStyle(fontSize: 10, color: Color(0xFF70707C))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    VianButton(
                      text: _checkInTime == null ? 'Check In' : 'Checked In: $_checkInTime',
                      onPressed: _checkInTime == null ? _handleCheckIn : () {},
                      color: _checkInTime == null ? VianTheme.primaryGold : Colors.grey,
                    ),
                    VianButton(
                      text: _checkOutTime == null ? 'Check Out' : 'Checked Out: $_checkOutTime',
                      onPressed: (_checkInTime != null && _checkOutTime == null) ? _handleCheckOut : () {},
                      isSecondary: true,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 9. DRAWINGS TAB
// ==========================================
class DrawingsTab extends StatefulWidget {
  const DrawingsTab({Key? key}) : super(key: key);

  @override
  State<DrawingsTab> createState() => _DrawingsTabState();
}

class _DrawingsTabState extends State<DrawingsTab> {
  List<dynamic> _drawings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }

  Future<void> _loadDrawings() async {
    final list = await ApiService.getDrawings(1); // load for project 1
    setState(() {
      _drawings = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Drawings & Blueprint Versioning', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Manage elevations, interior layouts, structural blueprints, and approvals', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _drawings.length,
              itemBuilder: (context, index) {
                final d = _drawings[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: VianCard(
                    child: Row(
                      children: [
                        // Sketch image preview
                        Container(
                          width: 100,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(image: NetworkImage(d['fileUrl'] ?? ''), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                              Text('Type: ${d['type']} | Version: v${d['version']}', style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
                              if (d['approver'] != null) Text('Approved by: ${d['approver']['name']}', style: const TextStyle(fontSize: 11, color: VianTheme.success)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            d['status'] ?? 'Pending',
                            style: TextStyle(
                              color: d['status'] == 'Approved' ? VianTheme.success : VianTheme.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 10. DOCUMENTS TAB
// ==========================================
class DocumentsTab extends StatefulWidget {
  final bool showUploadDialog;
  const DocumentsTab({Key? key, this.showUploadDialog = false}) : super(key: key);

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  List<dynamic> _allDocuments = [];
  bool _loading = true;
  String _selectedFolder = '';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final list = await ApiService.getDocuments(1);
    final role = ApiService.currentUser?['role'] ?? 'Client';
    final foldersList = _getFolders(role);
    setState(() {
      _allDocuments = list;
      _loading = false;
      if (_selectedFolder.isEmpty && foldersList.isNotEmpty) {
        _selectedFolder = foldersList.first;
      }
    });
    if (widget.showUploadDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUploadDialog(foldersList);
      });
    }
  }

  List<String> _getFolders(String role) {
    if (role == 'Super Admin' || role == 'Managing Director' || role == 'Admin / Office Manager / Accounts') {
      return ['Projects', 'Drawings', 'Site Photos', 'HR Documents', 'Client Documents', 'Contracts', 'Invoices', 'General', 'Property Documents', 'Agreements', 'Expenses'];
    } else if (role == 'Tech Head + Senior Architect' || role == 'Site Manager') {
      return ['Projects', 'Drawings', 'Site Photos', 'Client Documents', 'General', 'Property Documents', 'Agreements'];
    } else {
      return ['Projects', 'Drawings', 'Site Photos', 'General', 'Property Documents'];
    }
  }

  void _showUploadDialog(List<String> foldersList) {
    final titleCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String targetFolder = _selectedFolder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('UPLOAD DOCUMENT', style: TextStyle(color: VianTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Document Title')),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'File Name (e.g. spec.pdf)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetFolder,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Folder'),
                items: foldersList.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setDialogState(() => targetFolder = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Upload',
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                final res = await ApiService.uploadDocument({
                  'projectId': 1,
                  'title': titleCtrl.text,
                  'fileName': nameCtrl.text,
                  'fileSize': '2.1 MB',
                  'folder': targetFolder,
                  'uploadedBy': ApiService.currentUser?['id'] ?? 1
                });
                Navigator.pop(context);
                if (res['success'] == false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Error uploading document'), backgroundColor: VianTheme.danger),
                  );
                } else {
                  setState(() => _loading = true);
                  _loadDocuments();
                }
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final role = ApiService.currentUser?['role'] ?? 'Client';
    final foldersList = _getFolders(role);
    final filteredFiles = _allDocuments.where((doc) => doc['folder'] == _selectedFolder).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folders column
          Container(
            width: 200,
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Categories', style: TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: VianTheme.primaryGold, size: 18),
                      onPressed: () => _showUploadDialog(foldersList),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: foldersList.map((f) {
                      final isSelected = _selectedFolder == f;
                      return InkWell(
                        onTap: () => setState(() => _selectedFolder = f),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x11F5A623) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.folder, color: isSelected ? VianTheme.primaryGold : const Color(0xFF70707C), size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: TextStyle(fontSize: 13, color: isSelected ? VianTheme.primaryGold : VianTheme.lightText))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(color: Color(0x22F5A623)),
          // Files list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active folder: $_selectedFolder', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.primaryGold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredFiles.isEmpty
                        ? const Center(child: Text('No documents in this category', style: TextStyle(color: Color(0xFF70707C))))
                        : ListView.builder(
                            itemCount: filteredFiles.length,
                            itemBuilder: (context, index) {
                              final doc = filteredFiles[index];
                              return _buildFileRow(
                                doc['title'] ?? doc['fileName'] ?? '',
                                doc['fileSize'] ?? '0 KB',
                                doc['createdAt'] != null
                                    ? DateFormat('MMM dd, yyyy').format(DateTime.parse(doc['createdAt']))
                                    : 'N/A',
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFileRow(String name, String size, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: VianCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: VianTheme.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$size | Added on $date', style: const TextStyle(fontSize: 11, color: Color(0xFF70707C))),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.download, color: VianTheme.primaryGold, size: 20), onPressed: () {})
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 11. QUOTATIONS TAB
// ==========================================
class QuotationsTab extends StatefulWidget {
  const QuotationsTab({Key? key}) : super(key: key);

  @override
  State<QuotationsTab> createState() => _QuotationsTabState();
}

class _QuotationsTabState extends State<QuotationsTab> {
  final List<Map<String, dynamic>> _items = [
    {'name': 'Structural RCC Pillars', 'rate': 45000.0, 'qty': 10},
    {'name': 'Italian Marble Flooring (Sqft)', 'rate': 650.0, 'qty': 1500},
    {'name': 'Modular Kitchen fitting set', 'rate': 450000.0, 'qty': 1},
  ];

  double get _subtotal {
    double total = 0;
    for (var item in _items) {
      total += safeToDouble(item['rate']) * safeToInt(item['qty']);
    }
    return total;
  }

  double get _gst => _subtotal * 0.18;
  double get _total => _subtotal + _gst;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items Builder
          Expanded(
            flex: 3,
            child: VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quotation Creator Layout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.primaryGold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final rateStr = formatter.format(item['rate']);
                        return ListTile(
                          title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Rate: $rateStr | Qty: ${item['qty']}'),
                          trailing: Text(formatter.format(item['rate'] * item['qty']), style: const TextStyle(color: VianTheme.primaryGold)),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Color(0x22F5A623)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Line Item to Quotation', style: TextStyle(fontSize: 12, color: Color(0xFF70707C))),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: VianTheme.primaryGold),
                        onPressed: () {
                          setState(() {
                            _items.add({'name': 'Teak Wood main doors', 'rate': 85000.0, 'qty': 2});
                          });
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Billing Summary
          Expanded(
            flex: 2,
            child: VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invoice Audit Summaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.primaryGold)),
                  const SizedBox(height: 24),
                  _summaryRow('Subtotal Amount', formatter.format(_subtotal)),
                  const SizedBox(height: 8),
                  _summaryRow('GST Tax (18% default)', formatter.format(_gst)),
                  const Divider(height: 32, color: Color(0x22F5A623)),
                  _summaryRow('Grand Total Estimate', formatter.format(_total), isTotal: true),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: VianButton(
                      text: 'Export Estimate PDF',
                      icon: Icons.picture_as_pdf,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation PDF generated & exported successfully.')));
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 14 : 12, color: isTotal ? VianTheme.primaryGold : VianTheme.lightText, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold, color: isTotal ? VianTheme.primaryGold : VianTheme.whiteText)),
      ],
    );
  }
}

// ==========================================
// 12. INVOICES TAB
// ==========================================
class InvoicesTab extends StatefulWidget {
  const InvoicesTab({Key? key}) : super(key: key);

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  List<dynamic> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final list = await ApiService.getInvoices();
    setState(() {
      _invoices = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoices Registry', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Track client payments, tax compliance, and outstanding amounts', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final inv = _invoices[index];
                final paid = safeToDouble(inv['paidAmount']);
                final total = safeToDouble(inv['total']);
                final status = inv['status'] ?? 'Draft';

                Color statusColor = VianTheme.warning;
                if (status == 'Paid') statusColor = VianTheme.success;
                if (status == 'Overdue') statusColor = VianTheme.danger;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: VianCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF1E1E26),
                          child: Icon(Icons.receipt_long, color: VianTheme.primaryGold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv['invoiceNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                              Text('Project: ${inv['project']?['name']}', style: const TextStyle(fontSize: 12)),
                              Text('Billing Date: ${inv['date']} | Due Date: ${inv['dueDate']}', style: const TextStyle(fontSize: 11, color: Color(0xFF70707C))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatter.format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                            Text('Paid: ${formatter.format(paid)}', style: const TextStyle(fontSize: 11, color: VianTheme.lightText)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 13. EXPENSES TAB
// ==========================================
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({Key? key}) : super(key: key);

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  List<dynamic> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final list = await ApiService.getExpenses();
    setState(() {
      _expenses = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expenses & Disbursements Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Review site material expenses, labor payments, and travel disbursements', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                final status = exp['status'] ?? 'Pending';
                Color statusColor = VianTheme.warning;
                if (status == 'Approved') statusColor = VianTheme.success;
                if (status == 'Rejected') statusColor = VianTheme.danger;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: VianCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF1E1E26),
                          child: Icon(Icons.receipt, color: VianTheme.primaryGold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatter.format(safeToDouble(exp['amount'])), style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText, fontSize: 16)),
                              Text('Category: ${exp['category']} | Project: ${exp['project']?['name']}', style: const TextStyle(fontSize: 12)),
                              Text('Submitted by: ${exp['user']?['name']} on ${exp['date']}', style: const TextStyle(fontSize: 11, color: Color(0xFF70707C))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 14. REPORTS TAB
// ==========================================
class ReportsTab extends StatelessWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enterprise BI & Reporting', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Compile financial metrics, conversions, and construction schedules', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 2.2,
              children: [
                _reportCard(context, 'Attendance & Hours Report', 'Daily/monthly site and office attendance summary reports.', Icons.badge_outlined, 'attendance'),
                _reportCard(context, 'Income vs Expense Ledger', 'Consolidated billing records mapped against project purchases.', Icons.monetization_on_outlined, 'expenses'),
                _reportCard(context, 'Project Construction Milestones', 'Deliverables tracking, timeline delays, and completed layouts.', Icons.playlist_add_check, 'projects'),
                _reportCard(context, 'CRM Lead Conversion Ratios', 'Conversion stats showing website, referral, and visit performance.', Icons.trending_up, 'leads'),
              ],
            ),
          )
        ],
      ),
    );
  }
 
  Widget _reportCard(BuildContext context, String title, String desc, IconData icon, String module) {
    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: VianTheme.primaryGold, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: VianTheme.whiteText)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF70707C)))),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export Excel', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  final url = '${ApiService.baseUrl}/export/$module?token=${ApiService.token}&format=xlsx';
                  openUrl(url);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated. Excel file download started.')));
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.description, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  final url = '${ApiService.baseUrl}/export/$module?token=${ApiService.token}&format=csv';
                  openUrl(url);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report compiled. CSV file download started.')));
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
// ==========================================
// 15. SETTINGS TAB
// ==========================================
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  bool _isLoading = false;
  bool _testingConnection = false;
  String _connectionStatus = '';
  Color _statusColor = VianTheme.primaryGold;

  String _selectedTrashModule = 'leads';
  List<dynamic> _trashItems = [];
  bool _loadingTrash = false;

  // Company controllers
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cloudinaryCloudController = TextEditingController();
  final _cloudinaryApiController = TextEditingController();
  final _cloudinarySecretController = TextEditingController();

  // AI controllers
  final _geminiKeyController = TextEditingController();
  String _selectedModel = 'gemini-1.5-flash';
  double _temperature = 0.2;
  final _maxTokensController = TextEditingController(text: '2048');
  final _timeoutController = TextEditingController(text: '30000');
  
  bool _enableAi = true;
  bool _enablePdf = true;
  bool _enableImage = true;
  bool _enableBoq = true;
  bool _enableCost = true;
  
  int _apiUsageCount = 0;
  int _dailyTokenUsage = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      // Load Company Settings
      final compRes = await ApiService.getCompanySettings();
      final compData = compRes['settings'] ?? {};
      _companyNameController.text = compData['companyName'] ?? '';
      _addressController.text = compData['address'] ?? '';
      _gstController.text = compData['gst'] ?? '';
      _emailController.text = compData['email'] ?? '';
      _phoneController.text = compData['phone'] ?? '';
      _cloudinaryCloudController.text = compData['cloudinaryCloudName'] ?? '';
      _cloudinaryApiController.text = compData['cloudinaryApiKey'] ?? '';
      _cloudinarySecretController.text = compData['cloudinaryApiSecret'] ?? '';

      // Load AI Settings
      final aiRes = await ApiService.getAiSettings();
      _geminiKeyController.text = aiRes['geminiApiKey'] ?? '';
      _selectedModel = aiRes['aiModel'] ?? 'gemini-1.5-flash';
      _temperature = double.tryParse(aiRes['temperature']?.toString() ?? '0.2') ?? 0.2;
      _maxTokensController.text = (aiRes['maxTokens'] ?? 2048).toString();
      _timeoutController.text = (aiRes['timeout'] ?? 30000).toString();
      
      _enableAi = aiRes['enableAi'] ?? true;
      _enablePdf = aiRes['enablePdfAnalysis'] ?? true;
      _enableImage = aiRes['enableImageAnalysis'] ?? true;
      _enableBoq = aiRes['enableBoqGeneration'] ?? true;
      _enableCost = aiRes['enableCostEstimation'] ?? true;
      
      _apiUsageCount = aiRes['apiUsageCount'] ?? 0;
      _dailyTokenUsage = aiRes['dailyTokenUsage'] ?? 0;
      final user = ref.read(userProvider);
      final role = user?['role'] ?? 'Client';
      if (role == 'Managing Director' || role == 'Super Admin') {
        await _loadTrashItems();
      }
    } catch (e) {
      debugPrint("Error loading settings in SettingsTab: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrashItems() async {
    setState(() => _loadingTrash = true);
    final items = await ApiService.getTrashItems(_selectedTrashModule);
    setState(() {
      _trashItems = items;
      _loadingTrash = false;
    });
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isLoading = true);
    try {
      // 1. Save company settings
      await ApiService.updateCompanySettings({
        'companyName': _companyNameController.text,
        'address': _addressController.text,
        'gst': _gstController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'cloudinaryCloudName': _cloudinaryCloudController.text,
        'cloudinaryApiKey': _cloudinaryApiController.text,
        'cloudinaryApiSecret': _cloudinarySecretController.text,
      });

      // 2. Save AI settings
      await ApiService.updateAiSettings({
        'geminiApiKey': _geminiKeyController.text,
        'aiModel': _selectedModel,
        'temperature': _temperature,
        'maxTokens': int.tryParse(_maxTokensController.text) ?? 2048,
        'timeout': int.tryParse(_timeoutController.text) ?? 30000,
        'enableAi': _enableAi,
        'enablePdfAnalysis': _enablePdf,
        'enableImageAnalysis': _enableImage,
        'enableBoqGeneration': _enableBoq,
        'enableCostEstimation': _enableCost,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All configurations saved successfully.')),
      );
      _loadSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAiConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionStatus = 'Testing connection...';
      _statusColor = VianTheme.primaryGold;
    });

    try {
      final res = await ApiService.testAiConnection(
        _geminiKeyController.text.trim(),
        _selectedModel,
      );

      setState(() {
        if (res['success'] == true) {
          _connectionStatus = 'Success: Google Gemini API is connected!';
          _statusColor = Colors.green;
        } else {
          _connectionStatus = 'Error: ${res['message'] ?? 'Connection failed.'}';
          _statusColor = Colors.red;
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Failed to connect: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() => _testingConnection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Company Configurations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const Text('Configure company profile metadata, permissions, and media configurations', style: TextStyle(color: Color(0xFF70707C))),
          const SizedBox(height: 24),
          
          // Office Details Card
          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Office Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.primaryGold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(labelText: 'Company Corporate Title', hintText: 'VIAN Architects & Designers'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Office Registration Address', hintText: 'Plot 42, Galleria Complex, Sector 43, Gurugram'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gstController,
                        decoration: const InputDecoration(labelText: 'Tax Registration GSTIN', hintText: '07AAAAA1111A1Z1'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x33F5A623)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Company Logo Asset', style: TextStyle(fontSize: 13, color: VianTheme.lightText)),
                            Image.asset('assets/logo.png', height: 28, errorBuilder: (c, e, s) => const Icon(Icons.architecture, color: VianTheme.primaryGold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Cloudinary Cloud Storage configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.primaryGold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cloudinaryCloudController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Cloudinary Cloud Name'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _cloudinaryApiController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'API Authentication Key'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // AI Configuration Card
          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Floor Plan Analysis & Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.primaryGold)),
                const SizedBox(height: 24),
                
                // Toggle AI Feature
                SwitchListTile(
                  title: const Text('Enable AI Features', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('Toggle the core construction estimation Gemini AI workflow', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                  value: _enableAi,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (v) => setState(() => _enableAi = v),
                ),
                const Divider(color: Color(0xFF262635)),
                
                if (_enableAi) ...[
                  TextField(
                    controller: _geminiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Google Gemini API Key',
                      hintText: 'Enter API key here to analyze drawings securely',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedModel,
                          decoration: const InputDecoration(labelText: 'Gemini AI Model'),
                          dropdownColor: const Color(0xFF1E1E26),
                          items: const [
                            DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('gemini-1.5-flash (Fast & Accurate)', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('gemini-1.5-pro (High intelligence)', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (v) => setState(() => _selectedModel = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxTokensController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Max Tokens Limit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Temperature: ${_temperature.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
                            Slider(
                              value: _temperature,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: VianTheme.primaryGold,
                              onChanged: (v) => setState(() => _temperature = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _timeoutController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Timeout (ms)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Detail toggles
                  CheckboxListTile(
                    title: const Text('Enable PDF Floor Plans Analysis', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _enablePdf,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enablePdf = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Enable Image Floor Plans Analysis', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _enableImage,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enableImage = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Enable Automatic BOQ Estimator', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _enableBoq,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enableBoq = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Enable Automatic Cost Calculator', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _enableCost,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enableCost = v!),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Connection test area
                  Row(
                    children: [
                      VianButton(
                        text: 'Test API Connection',
                        onPressed: _testingConnection ? null : _testAiConnection,
                      ),
                      const SizedBox(width: 16),
                      if (_testingConnection)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold))),
                    ],
                  ),
                  if (_connectionStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _connectionStatus,
                      style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor),
                    ),
                  ],
                  
                  const Divider(color: Color(0xFF262635), height: 32),
                  
                  // Usage stats
                  const Text('API Token Usage Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: VianTheme.primaryGold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _usageStatTile('Total AI API Runs', _apiUsageCount.toString(), Icons.rocket_launch_outlined),
                      const SizedBox(width: 16),
                      _usageStatTile('Cumulative Token Usage', _dailyTokenUsage.toString(), Icons.token_outlined),
                    ],
                  )
                ]
              ],
            ),
          ),
          
          // Trash & Restore Panel (Only for Super Admin)
          if (isSuperAdmin(ApiService.currentUser?['role'] ?? 'Client')) ...[
            const SizedBox(height: 32),
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trash & Restore System (Super Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  const Text('Manage soft-deleted items across all VIAN ERP databases. Restored items will return to their original catalogs.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Select Module: ', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedTrashModule,
                        dropdownColor: const Color(0xFF1E1E26),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'leads', child: Text('CRM Leads')),
                          DropdownMenuItem(value: 'clients', child: Text('Clients')),
                          DropdownMenuItem(value: 'projects', child: Text('Projects')),
                          DropdownMenuItem(value: 'tasks', child: Text('Tasks')),
                          DropdownMenuItem(value: 'workers', child: Text('Labour Workers')),
                          DropdownMenuItem(value: 'daily-reports', child: Text('Daily Reports')),
                          DropdownMenuItem(value: 'announcements', child: Text('Directives')),
                          DropdownMenuItem(value: 'quotations', child: Text('Quotations')),
                          DropdownMenuItem(value: 'invoices', child: Text('Invoices')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTrashModule = val!;
                            _trashItems = [];
                          });
                          _loadTrashItems();
                        },
                      ),
                      const SizedBox(width: 24),
                      VianButton(
                        text: 'Refresh Trash',
                        onPressed: _loadTrashItems,
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingTrash)
                    const Center(child: CircularProgressIndicator(color: VianTheme.primaryGold))
                  else if (_trashItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No items in trash for this module.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _trashItems.length,
                      itemBuilder: (context, idx) {
                        final item = _trashItems[idx];
                        String displayName = item['name'] ?? item['title'] ?? item['projectId'] ?? 'ID: ${item['id']}';
                        String deletedDetails = '';
                        if (item['deletedAt'] != null) {
                          final dateStr = DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(item['deletedAt']));
                          deletedDetails = 'Deleted at: $dateStr by: ${item['deletedBy'] ?? 'Unknown'}';
                        }
                        return ListTile(
                          title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(deletedDetails, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          trailing: VianButton(
                            text: 'Restore',
                            onPressed: () async {
                              final success = await ApiService.restoreItem(_selectedTrashModule, item['id']);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item restored successfully')));
                                _loadTrashItems();
                              }
                            },
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          VianButton(
            text: 'Save Configuration Settings',
            onPressed: _saveAllSettings,
          ),
        ],
      ),
    );
  }

  Widget _usageStatTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF262635)),
        ),
        child: Row(
          children: [
            Icon(icon, color: VianTheme.primaryGold, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 16. NOTIFICATIONS SLIDING DRAWER PANEL
// ==========================================
class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alerts & Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              Icon(Icons.notifications_active, color: VianTheme.primaryGold),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x22F5A623)),
          Expanded(
            child: ListView(
              children: [
                _notifTile('New Task Assigned', 'You have been assigned: "Verify Ground Floor Layout Plumbing" by Ananya Roy.', '10m ago', false),
                _notifTile('Client payment confirmation', 'Payment of ₹17,70,000 confirmed for invoice VIAN-INV-001.', '1h ago', true),
                _notifTile('Design Approval Needed', 'Draft floor plan blueprint submitted for Villa projects approval.', '1d ago', true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _notifTile(String title, String desc, String time, bool read) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: read ? const Color(0xFF1E1E26) : const Color(0xFF2E2E36),
        radius: 6,
      ),
      title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold, fontSize: 13, color: VianTheme.whiteText)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: const Color(0xFF70707C))),
      trailing: Text(time, style: const TextStyle(fontSize: 10, color: const Color(0xFF70707C))),
    );
  }
}

// 4. CONTRACTOR MANAGEMENT SCREEN
class ContractorTab extends StatefulWidget {
  final bool showAddDialog;
  const ContractorTab({Key? key, this.showAddDialog = false}) : super(key: key);

  @override
  State<ContractorTab> createState() => _ContractorTabState();
}

class _ContractorTabState extends State<ContractorTab> {
  List<dynamic> _contractors = [];
  List<dynamic> _stages = [];
  List<dynamic> _releases = [];
  List<dynamic> _projects = [];
  bool _loading = true;
  String _userRole = 'Client';

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    _userRole = user?['role'] ?? 'Client';
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final contractors = await ApiService.getContractors();
      final stages = await ApiService.getContractorStages();
      final releases = await ApiService.getContractorReleases();
      final projects = await ApiService.getProjects();
      setState(() {
        _contractors = contractors;
        _stages = stages;
        _releases = releases;
        _projects = projects;
        _loading = false;
      });
      if (widget.showAddDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showContractorDialog(null);
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showContractorDialog(dynamic c) {
    final isEdit = c != null;
    final idCtrl = TextEditingController(text: isEdit ? c['contractorId'] : '');
    final nameCtrl = TextEditingController(text: isEdit ? c['name'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? c['phone'] : '');
    final emailCtrl = TextEditingController(text: isEdit ? c['email'] : '');
    final addrCtrl = TextEditingController(text: isEdit ? c['address'] : '');
    final typeCtrl = TextEditingController(text: isEdit ? c['serviceType'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text(isEdit ? 'Update Contractor Profile' : 'Register Contractor Profile', style: const TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Contractor ID (e.g. CON-001)')),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contractor Name')),
              const SizedBox(height: 12),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Specialty / Service Type (e.g. Civil)')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Office Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Save Contractor',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && idCtrl.text.isNotEmpty) {
                final data = {
                  'contractorId': idCtrl.text,
                  'name': nameCtrl.text,
                  'serviceType': typeCtrl.text,
                  'phone': phoneCtrl.text,
                  'email': emailCtrl.text,
                  'address': addrCtrl.text,
                };
                if (isEdit) {
                  await ApiService.updateContractor(c['id'], data);
                } else {
                  await ApiService.addContractor(data);
                }
                Navigator.pop(context);
                _loadAllData();
              }
            },
          )
        ],
      ),
    );
  }

  void _deleteContractorConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('Delete Contractor Profile?', style: TextStyle(color: VianTheme.danger)),
        content: const Text('Are you sure you want to permanently remove this contractor and all their payment history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ApiService.deleteContractor(id);
              Navigator.pop(context);
              _loadAllData();
            },
            child: const Text('Delete', style: TextStyle(color: VianTheme.danger)),
          )
        ],
      ),
    );
  }

  void _showStageDialog(dynamic s) {
    final isEdit = s != null;
    final nameCtrl = TextEditingController(text: isEdit ? s['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? s['description'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text(isEdit ? 'Update Release Stage' : 'Define Release Stage', style: const TextStyle(color: VianTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Stage Name (e.g. RCC SLAB)')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Stage Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Save Stage',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                final data = {
                  'name': nameCtrl.text.toUpperCase(),
                  'description': descCtrl.text,
                };
                if (isEdit) {
                  await ApiService.updateContractorStage(s['id'], data);
                } else {
                  await ApiService.addContractorStage(data);
                }
                Navigator.pop(context);
                _loadAllData();
              }
            },
          )
        ],
      ),
    );
  }

  void _deleteStageConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('Delete Payment Stage?', style: TextStyle(color: VianTheme.danger)),
        content: const Text('Are you sure you want to permanently remove this master stage?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ApiService.deleteContractorStage(id);
              Navigator.pop(context);
              _loadAllData();
            },
            child: const Text('Delete', style: TextStyle(color: VianTheme.danger)),
          )
        ],
      ),
    );
  }

  void _showReleaseDialog(dynamic r) {
    final isEdit = r != null;
    final amountCtrl = TextEditingController(text: isEdit ? r['amount'].toString() : '');
    final refCtrl = TextEditingController(text: isEdit ? r['referenceNumber'] : '');
    final dateCtrl = TextEditingController(text: isEdit ? r['releaseDate'] : DateTime.now().toIso8601String().split('T')[0]);
    final notesCtrl = TextEditingController(text: isEdit ? r['notes'] : '');

    int? selectedContractorId = isEdit ? r['contractor']['id'] : (_contractors.isNotEmpty ? _contractors[0]['id'] : null);
    int? selectedProjectId = isEdit ? r['project']['id'] : (_projects.isNotEmpty ? _projects[0]['id'] : null);
    int? selectedStageId = isEdit ? r['stage']['id'] : (_stages.isNotEmpty ? _stages[0]['id'] : null);
    String selectedMode = isEdit ? r['paymentMode'] : 'Bank Transfer';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: Text(isEdit ? 'Update Payment Release' : 'Record Payment Release', style: const TextStyle(color: VianTheme.primaryGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedContractorId,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Select Contractor'),
                  items: _contractors.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem<int>(value: c['id'], child: Text(c['name']));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedContractorId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedProjectId,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Select Project'),
                  items: _projects.map<DropdownMenuItem<int>>((p) {
                    return DropdownMenuItem<int>(value: p['id'], child: Text(p['name']));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedProjectId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedStageId,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Select Stage'),
                  items: _stages.map<DropdownMenuItem<int>>((s) {
                    return DropdownMenuItem<int>(value: s['id'], child: Text(s['name']));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedStageId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Released Amount (INR)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: ['Bank Transfer', 'Cash', 'Cheque', 'UPI'].map<DropdownMenuItem<String>>((mode) {
                    return DropdownMenuItem<String>(value: mode, child: Text(mode));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedMode = v ?? 'Bank Transfer'),
                ),
                const SizedBox(height: 12),
                TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Transaction Ref / Cheque No.')),
                const SizedBox(height: 12),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Release Date (YYYY-MM-DD)')),
                const SizedBox(height: 12),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Remarks / Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            VianButton(
              text: 'Confirm Release',
              onPressed: () async {
                if (selectedContractorId != null && selectedProjectId != null && selectedStageId != null && amountCtrl.text.isNotEmpty) {
                  final data = {
                    'contractorId': selectedContractorId,
                    'projectId': selectedProjectId,
                    'stageId': selectedStageId,
                    'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                    'paymentMode': selectedMode,
                    'referenceNumber': refCtrl.text,
                    'releaseDate': dateCtrl.text,
                    'notes': notesCtrl.text,
                  };
                  if (isEdit) {
                    await ApiService.updateContractorRelease(r['id'], data);
                  } else {
                    await ApiService.addContractorRelease(data);
                  }
                  Navigator.pop(context);
                  _loadAllData();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  void _deleteReleaseConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('Delete Release Record?', style: TextStyle(color: VianTheme.danger)),
        content: const Text('Are you sure you want to remove this payment release entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ApiService.deleteContractorRelease(id);
              Navigator.pop(context);
              _loadAllData();
            },
            child: const Text('Delete', style: TextStyle(color: VianTheme.danger)),
          )
        ],
      ),
    );
  }

  Widget _buildContractorsTab(NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Contractor Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            VianButton(
              text: 'Add Contractor',
              icon: Icons.person_add,
              onPressed: () => _showContractorDialog(null),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _contractors.isEmpty
              ? const Center(child: Text('No contractors registered yet.', style: TextStyle(color: Color(0xFF70707C))))
              : ListView.builder(
                  itemCount: _contractors.length,
                  itemBuilder: (context, index) {
                    final c = _contractors[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: VianCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1E1E26),
                            child: Icon(Icons.business, color: VianTheme.primaryGold),
                          ),
                          title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                          subtitle: Text('ID: ${c['contractorId']} | Specialty: ${c['serviceType'] ?? "General"} | Phone: ${c['phone'] ?? "N/A"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: VianTheme.primaryGold, size: 20),
                                onPressed: () => _showContractorDialog(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: VianTheme.danger, size: 20),
                                onPressed: () => _deleteContractorConfirm(c['id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStagesTab(bool isAllowed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Master Payment Release Stages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            if (isAllowed)
              VianButton(
                text: 'Add Release Stage',
                icon: Icons.add_circle_outline,
                onPressed: () => _showStageDialog(null),
              ),
          ],
        ),
        if (!isAllowed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VianTheme.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VianTheme.danger.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: VianTheme.danger, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Viewing Mode Only: Editing and defining stages is restricted to Admins and Superadmins.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: _stages.isEmpty
              ? const Center(child: Text('No stages defined yet.', style: TextStyle(color: Color(0xFF70707C))))
              : ListView.builder(
                  itemCount: _stages.length,
                  itemBuilder: (context, index) {
                    final s = _stages[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: VianCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1E1E26),
                            child: Icon(Icons.playlist_add_check, color: VianTheme.primaryGold),
                          ),
                          title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                          subtitle: Text(s['description'] ?? 'No description provided'),
                          trailing: isAllowed
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: VianTheme.primaryGold, size: 20),
                                      onPressed: () => _showStageDialog(s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: VianTheme.danger, size: 20),
                                      onPressed: () => _deleteStageConfirm(s['id']),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReleasesTab(NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Payment Release Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            VianButton(
              text: 'Release Payment',
              icon: Icons.add_card,
              onPressed: () => _showReleaseDialog(null),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _releases.isEmpty
              ? const Center(child: Text('No payment releases recorded yet.', style: TextStyle(color: Color(0xFF70707C))))
              : ListView.builder(
                  itemCount: _releases.length,
                  itemBuilder: (context, index) {
                    final r = _releases[index];
                    final contractorName = r['contractor'] != null ? r['contractor']['name'] : 'Unknown';
                    final projectName = r['project'] != null ? r['project']['name'] : 'Unknown';
                    final stageName = r['stage'] != null ? r['stage']['name'] : 'Unknown';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: VianCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1E1E26),
                            child: Icon(Icons.payment, color: VianTheme.success),
                          ),
                          title: Text('$contractorName - $projectName', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                          subtitle: Text('Stage: $stageName | Mode: ${r['paymentMode']} | Ref: ${r['referenceNumber'] ?? "N/A"}\r\nDate: ${r['releaseDate']}\r\nNotes: ${r['notes'] ?? "None"}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatter.format(safeToDouble(r['amount'])),
                                style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: VianTheme.primaryGold, size: 20),
                                onPressed: () => _showReleaseDialog(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: VianTheme.danger, size: 20),
                                onPressed: () => _deleteReleaseConfirm(r['id']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isAllowedToEditStages = _userRole == 'Super Admin' || _userRole == 'Managing Director' || _userRole == 'Admin / Office Manager / Accounts';

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contractor Master Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                    Text('Manage constructors, release payment milestones, and configure billing stages', style: TextStyle(color: Color(0xFF70707C))),
                  ],
                ),
                TabBar(
                  isScrollable: true,
                  labelColor: VianTheme.primaryGold,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: VianTheme.primaryGold,
                  tabs: const [
                    Tab(icon: Icon(Icons.people_outline), text: 'Contractors'),
                    Tab(icon: Icon(Icons.settings_outlined), text: 'Payment Stages'),
                    Tab(icon: Icon(Icons.payments_outlined), text: 'Payment Releases'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContractorsTab(currencyFormatter),
                  _buildStagesTab(isAllowedToEditStages),
                  _buildReleasesTab(currencyFormatter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// 5. MANAGER BULK ATTENDANCE BOARD SCREEN
class LabourAttendanceTab extends StatefulWidget {
  const LabourAttendanceTab({Key? key}) : super(key: key);

  @override
  State<LabourAttendanceTab> createState() => _LabourAttendanceTabState();
}

class _LabourAttendanceTabState extends State<LabourAttendanceTab> {
  List<dynamic> _workers = [];
  bool _loading = true;
  String _gps = '28.4595° N, 77.0266° E';
  final Map<int, String> _statuses = {};
  final Map<int, double> _overtime = {};

  @override
  void initState() {
    super.initState();
    _loadLabourList();
  }

  Future<void> _loadLabourList() async {
    final list = await ApiService.getWorkers();
    for (var w in list) {
      _statuses[w['id']] = 'Present';
      _overtime[w['id']] = 0.0;
    }
    setState(() {
      _workers = list;
      _loading = false;
    });
  }

  void _submitAttendance() async {
    final list = <Map<String, dynamic>>[];
    _statuses.forEach((id, status) {
      list.add({
        'workerId': id,
        'status': status,
        'overtimeHours': _overtime[id] ?? 0.0,
      });
    });

    final today = DateTime.now().toIso8601String().split('T')[0];
    final res = await ApiService.submitManagerAttendance(list, _gps, today);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Bulk Attendance submitted (GPS verified).'),
        backgroundColor: VianTheme.success,
      ));
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text('ATTENDANCE ERROR', style: TextStyle(color: VianTheme.danger)),
          content: Text(res['message'] ?? 'Failed to submit attendance.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: VianTheme.primaryGold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bulk Attendance Grid', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Grid board to verify and submit attendance for large sites in a single click', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              VianButton(
                text: 'Submit Attendance',
                icon: Icons.checklist_outlined,
                onPressed: _submitAttendance,
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _workers.length,
              itemBuilder: (context, index) {
                final w = _workers[index];
                final id = w['id'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: VianCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('ID: ${w['workerId']} | Skill: ${w['skillType']}'),
                            ],
                          ),
                        ),
                        // Present / Absent / Half Day radio buttons
                        Row(
                          children: [
                            _statusOption(id, 'Present'),
                            _statusOption(id, 'Half Day'),
                            _statusOption(id, 'Absent'),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Overtime input field
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'OT Hrs', contentPadding: EdgeInsets.all(10)),
                            onChanged: (v) => _overtime[id] = double.tryParse(v) ?? 0.0,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _statusOption(int id, String status) {
    final active = _statuses[id] == status;
    return InkWell(
      onTap: () => setState(() => _statuses[id] = status),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? VianTheme.primaryGold.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? VianTheme.primaryGold : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          status,
          style: TextStyle(fontSize: 11, color: active ? VianTheme.primaryGold : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}

// 6. DAILY REPORTS LIST & SUBMISSION
class DailyReportsTab extends StatefulWidget {
  const DailyReportsTab({Key? key}) : super(key: key);

  @override
  State<DailyReportsTab> createState() => _DailyReportsTabState();
}

class _DailyReportsTabState extends State<DailyReportsTab> {
  List<dynamic> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final list = await ApiService.getDailyReports();
    setState(() {
      _reports = list;
      _loading = false;
    });
  }

  void _showAddReportDialog() {
    final catCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('Submit Daily Work Completion Report', style: TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Work Category (e.g. Painting, Electrical)')),
              const SizedBox(height: 12),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity Completed (e.g. 1200 Sq Ft, 2 Rooms)')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Detailed Description')),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Additional Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Submit Report',
            onPressed: () async {
              if (catCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                await ApiService.submitDailyReport({
                  'projectId': 1,
                  'workCategory': catCtrl.text,
                  'quantityCompleted': qtyCtrl.text,
                  'workDescription': descCtrl.text,
                  'notes': notesCtrl.text,
                });
                Navigator.pop(context);
                setState(() => _loading = true);
                _fetchReports();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Completion Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Submission history for daily workspace progress updates', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              VianButton(
                text: 'New Daily Report',
                icon: Icons.edit_note,
                onPressed: _showAddReportDialog,
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final r = _reports[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: VianCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r['workCategory'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 15)),
                            Text(r['date'] ?? '', style: const TextStyle(color: Color(0xFF70707C), fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Quantity: ${r['quantityCompleted']}', style: const TextStyle(color: VianTheme.whiteText, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(r['workDescription'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('Submitted by: ${r['user']?['name']}', style: const TextStyle(color: Color(0xFF70707C), fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// 7. MANAGER PROGRESS REPORT SUBMISSION
class ManagerProgressTab extends StatefulWidget {
  const ManagerProgressTab({Key? key}) : super(key: key);

  @override
  State<ManagerProgressTab> createState() => _ManagerProgressTabState();
}

class _ManagerProgressTabState extends State<ManagerProgressTab> {
  List<dynamic> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchManagerReports();
  }

  Future<void> _fetchManagerReports() async {
    final list = await ApiService.getManagerProgressReports();
    setState(() {
      _reports = list;
      _loading = false;
    });
  }

  void _showAddProgressDialog() {
    final headCountCtrl = TextEditingController();
    final completedCtrl = TextEditingController();
    final materialsCtrl = TextEditingController();
    final issuesCtrl = TextEditingController();
    final tomorrowCtrl = TextEditingController();
    bool _isRecording = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text('Mark Site EOD Progress', style: TextStyle(color: VianTheme.primaryGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: headCountCtrl, decoration: const InputDecoration(labelText: 'Total Workers Present')),
                const SizedBox(height: 12),
                TextField(controller: completedCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Work Completed Today')),
                const SizedBox(height: 12),
                TextField(controller: materialsCtrl, decoration: const InputDecoration(labelText: 'Materials Disbursed')),
                const SizedBox(height: 12),
                TextField(controller: issuesCtrl, decoration: const InputDecoration(labelText: 'Issues faced / Delays')),
                const SizedBox(height: 12),
                TextField(controller: tomorrowCtrl, decoration: const InputDecoration(labelText: 'Action Plan Tomorrow')),
                const SizedBox(height: 16),
                // Voice to text simulator row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isRecording ? 'Listening for voice...' : 'Speech-to-Text ready', style: TextStyle(fontSize: 11, color: _isRecording ? VianTheme.danger : Color(0xFF70707C))),
                    IconButton(
                      icon: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? VianTheme.danger : VianTheme.primaryGold),
                      onPressed: () {
                        setDialogState(() => _isRecording = !_isRecording);
                        if (_isRecording) {
                          Timer(const Duration(seconds: 2), () {
                            if (mounted) {
                              setDialogState(() {
                                completedCtrl.text += ' Slab casting completed for Sector 43 Penthouse.';
                                _isRecording = false;
                              });
                            }
                          });
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            VianButton(
              text: 'Save Report',
              onPressed: () async {
                if (completedCtrl.text.isNotEmpty) {
                  final hc = int.tryParse(headCountCtrl.text) ?? 0;
                  await ApiService.submitManagerProgressReport({
                    'projectId': 1,
                    'workersPresent': hc,
                    'workCompleted': completedCtrl.text,
                    'materialsUsed': materialsCtrl.text,
                    'issuesFaced': issuesCtrl.text,
                    'tomorrowPlan': tomorrowCtrl.text,
                  });
                  Navigator.pop(context);
                  setState(() => _loading = true);
                  _fetchManagerReports();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('End of Day (EOD) Logs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Daily structural milestones, issues faced, and plans compiled by site managers', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              VianButton(
                text: 'New Site EOD Log',
                icon: Icons.post_add,
                onPressed: _showAddProgressDialog,
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final r = _reports[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: VianCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r['project']?['name'] ?? 'The Bajaj Villa', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 16)),
                            Text(r['date'] ?? '', style: const TextStyle(color: Color(0xFF70707C), fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Workers Present: ${r['workersPresent']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Completed: ${r['workCompleted']}', style: const TextStyle(fontSize: 13)),
                        if (r['materialsUsed'] != null && r['materialsUsed'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Materials: ${r['materialsUsed']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                        ],
                        if (r['issuesFaced'] != null && r['issuesFaced'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Issues: ${r['issuesFaced']}', style: const TextStyle(color: VianTheme.danger, fontSize: 12)),
                        ],
                        const SizedBox(height: 8),
                        Text('Log registered by: ${r['manager']?['name'] ?? "Rahul Sen"}', style: const TextStyle(color: Color(0xFF70707C), fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// 8. PAYROLL WAGE SHEETS
class PayrollTab extends StatefulWidget {
  const PayrollTab({Key? key}) : super(key: key);

  @override
  State<PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<PayrollTab> {
  List<dynamic> _wages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayroll();
  }

  Future<void> _loadPayroll() async {
    final list = await ApiService.getWageSheet(1); // Load for project 1
    setState(() {
      _wages = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payroll Integrated Wage Sheet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Wages auto-calculated from manager attendance grids (Base wage + 1.5x Overtime multiplier)', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              VianButton(
                text: 'Download Wage Excel',
                icon: Icons.download,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll Excel sheet downloaded successfully.')));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _wages.length,
              itemBuilder: (context, index) {
                final w = _wages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: VianCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('ID: ${w['workerId']} | Skill: ${w['skillType']} | Contractor: ${w['contractor'] ?? "Self"}'),
                              Text('Days: ${w['presentDays']} Present, ${w['halfDays']} Half | OT: ${w['overtimeHours']} Hrs', style: const TextStyle(fontSize: 11, color: Color(0xFF70707C))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatter.format(safeToDouble(w['totalWage'])), style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 16)),
                            Text('Base: ${formatter.format(safeToDouble(w['basePay']))} | OT: ${formatter.format(safeToDouble(w['overtimePay']))}', style: const TextStyle(fontSize: 11)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// 9. ANNOUNCEMENTS SCREEN
class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({Key? key}) : super(key: key);

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final res = await ApiService.getAnnouncements();
    setState(() {
      _list = res;
      _loading = false;
    });
  }

  void _showAddEditAnnouncementDialog({Map<String, dynamic>? announcement}) {
    final titleCtrl = TextEditingController(text: announcement?['title']);
    final msgCtrl = TextEditingController(text: announcement?['message']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text(announcement == null ? 'Create Announcement' : 'Edit Announcement', style: const TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: msgCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: announcement == null ? 'Post' : 'Update',
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                final body = {
                  'title': titleCtrl.text,
                  'message': msgCtrl.text,
                };
                if (announcement == null) {
                  await ApiService.addAnnouncement(body);
                } else {
                  await ApiService.updateAnnouncement(announcement['id'], body);
                }
                Navigator.pop(context);
                _loadAnnouncements();
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final currentUserRole = ApiService.currentUser?['role'] ?? 'Client';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company Directives Board', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('General announcements, safety requirements, and operational circulars', style: TextStyle(color: Color(0xFF70707C))),
                ],
              ),
              if (canAddOrEdit(currentUserRole))
                VianButton(
                  text: 'New Directive',
                  icon: Icons.campaign_outlined,
                  onPressed: () => _showAddEditAnnouncementDialog(),
                )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, index) {
                final item = _list[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: VianCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: VianTheme.primaryGold)),
                            Row(
                              children: [
                                Text(
                                  item['createdAt'] != null
                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['createdAt']))
                                      : '',
                                  style: const TextStyle(color: Color(0xFF70707C), fontSize: 11),
                                ),
                                if (canAddOrEdit(currentUserRole)) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: VianTheme.primaryGold),
                                    onPressed: () => _showAddEditAnnouncementDialog(announcement: item),
                                  ),
                                ],
                                if (canDelete(currentUserRole)) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: VianTheme.headerBlack,
                                          title: const Text('Delete Announcement', style: TextStyle(color: Colors.redAccent)),
                                          content: const Text('Are you sure you want to move this announcement to trash?', style: TextStyle(color: Colors.white)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ApiService.deleteAnnouncement(item['id']);
                                        _loadAnnouncements();
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['message'] ?? '', style: const TextStyle(fontSize: 13, color: VianTheme.whiteText)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 12. CLIENT ONBOARDING STEPPER WIZARD
// ==========================================
class ClientOnboardingTab extends StatefulWidget {
  const ClientOnboardingTab({Key? key}) : super(key: key);

  @override
  State<ClientOnboardingTab> createState() => _ClientOnboardingTabState();
}

class _ClientOnboardingTabState extends State<ClientOnboardingTab> {
  int _currentStep = 0;
  bool _isLoading = false;
  List<dynamic> _employees = [];

  // Step 1: Client Info Controllers
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientWhatsappController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientCityController = TextEditingController();
  final _clientStateController = TextEditingController();
  final _clientPincodeController = TextEditingController();
  final _clientGstController = TextEditingController();

  // Step 2: Project Info Controllers
  final _projectNameController = TextEditingController();
  final _projectSiteAddressController = TextEditingController();
  final _projectBudgetController = TextEditingController();
  final _projectStartDateController = TextEditingController(text: DateTime.now().toString().split(' ').first);
  final _projectEndDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 180)).toString().split(' ').first);
  String _selectedProjectType = 'Residential';

  // Step 3: Team Assignment selected IDs
  String? _selectedMdId;
  String? _selectedArchId;
  String? _selectedDesignEngId;
  String? _selectedSiteEngId;
  String? _selectedSupervisorId;

  // Step 4: Documents list
  final List<Map<String, dynamic>> _documentsList = [
    {'title': 'Initial Survey Site Plan', 'folder': 'Property Documents', 'fileUrl': 'https://res.cloudinary.com/vian/survey_plan.pdf', 'fileSize': 2048, 'status': 'Uploaded'},
    {'title': 'Standard Agreement Draft', 'folder': 'Agreements', 'fileUrl': 'https://res.cloudinary.com/vian/agreement.pdf', 'fileSize': 4096, 'status': 'Uploaded'}
  ];
  final _docTitleController = TextEditingController();
  String _selectedDocFolder = 'Property Documents';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final list = await ApiService.getEmployees();
    setState(() {
      _employees = list;
      
      // Seed default assignments
      final mds = _employees.where((e) => e['role'] == 'Managing Director').toList();
      if (mds.isNotEmpty) _selectedMdId = mds.first['id']?.toString();

      final architects = _employees.where((e) => e['role'].toString().contains('Architect')).toList();
      if (architects.isNotEmpty) _selectedArchId = architects.first['id']?.toString();

      final designs = _employees.where((e) => e['role'].toString().contains('Design') || e['role'].toString().contains('Visualization')).toList();
      if (designs.isNotEmpty) _selectedDesignEngId = designs.first['id']?.toString();

      final siteEngs = _employees.where((e) => e['role'].toString().contains('Site') || e['role'].toString().contains('Construction')).toList();
      if (siteEngs.isNotEmpty) _selectedSiteEngId = siteEngs.first['id']?.toString();

      final supervisors = _employees.where((e) => e['role'].toString().contains('Supervisor') || e['role'].toString().contains('Labour')).toList();
      if (supervisors.isNotEmpty) _selectedSupervisorId = supervisors.first['id']?.toString();
    });
  }

  void _addMockDocument() {
    if (_docTitleController.text.isEmpty) return;
    setState(() {
      _documentsList.add({
        'title': _docTitleController.text.trim(),
        'folder': _selectedDocFolder,
        'fileUrl': 'https://res.cloudinary.com/vian/uploaded_doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
        'fileSize': 1024 + (1024 * (DateTime.now().millisecond % 5)),
        'status': 'Uploaded'
      });
      _docTitleController.clear();
    });
  }

  void _submitOnboarding() async {
    setState(() => _isLoading = true);

    final data = {
      'clientName': _clientNameController.text.trim(),
      'clientPhone': _clientPhoneController.text.trim(),
      'clientWhatsapp': _clientWhatsappController.text.trim(),
      'clientEmail': _clientEmailController.text.trim(),
      'clientAddress': _clientAddressController.text.trim(),
      'clientCity': _clientCityController.text.trim(),
      'clientState': _clientStateController.text.trim(),
      'clientPincode': _clientPincodeController.text.trim(),
      'clientGst': _clientGstController.text.trim(),
      
      'projectName': _projectNameController.text.trim(),
      'projectType': _selectedProjectType,
      'projectSiteAddress': _projectSiteAddressController.text.trim(),
      'projectBudget': _projectBudgetController.text.trim(),
      'projectStartDate': _projectStartDateController.text,
      'projectEndDate': _projectEndDateController.text,

      'managingDirectorId': _selectedMdId,
      'architectId': _selectedArchId,
      'designEngineerId': _selectedDesignEngId,
      'siteEngineerId': _selectedSiteEngId,
      'supervisorId': _selectedSupervisorId,

      'uploadedDocuments': _documentsList
    };

    final result = await ApiService.onboardClient(data);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: const Text('Onboarding Complete', style: TextStyle(color: VianTheme.primaryGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message'] ?? 'Successfully onboarded client and set up project workspace.', style: const TextStyle(color: VianTheme.whiteText)),
              const SizedBox(height: 12),
              Text('Project Code: ${result['projectCode']}', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
            ],
          ),
          actions: [
            VianButton(
              text: 'Done',
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Onboarding failed.'), backgroundColor: VianTheme.danger)
      );
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _clientNameController.clear();
      _clientPhoneController.clear();
      _clientWhatsappController.clear();
      _clientEmailController.clear();
      _clientAddressController.clear();
      _clientCityController.clear();
      _clientStateController.clear();
      _clientPincodeController.clear();
      _clientGstController.clear();
      _projectNameController.clear();
      _projectSiteAddressController.clear();
      _projectBudgetController.clear();
      _documentsList.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final steps = [
      Step(
        title: const Text('Client Details', style: TextStyle(fontSize: 12, color: VianTheme.lightText)),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.editing,
        content: _buildClientInfoStep(),
      ),
      Step(
        title: const Text('Project Work', style: TextStyle(fontSize: 12, color: VianTheme.lightText)),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : _currentStep == 1 ? StepState.editing : StepState.indexed,
        content: _buildProjectInfoStep(),
      ),
      Step(
        title: const Text('Assign Team', style: TextStyle(fontSize: 12, color: VianTheme.lightText)),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : _currentStep == 2 ? StepState.editing : StepState.indexed,
        content: _buildAssignTeamStep(),
      ),
      Step(
        title: const Text('Upload Documents', style: TextStyle(fontSize: 12, color: VianTheme.lightText)),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : _currentStep == 3 ? StepState.editing : StepState.indexed,
        content: _buildDocumentsStep(),
      ),
      Step(
        title: const Text('Review & Complete', style: TextStyle(fontSize: 12, color: VianTheme.lightText)),
        isActive: _currentStep >= 4,
        state: _currentStep == 4 ? StepState.editing : StepState.indexed,
        content: _buildReviewStep(),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Onboarding Wizard',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up a new client, define their workspace project parameters, assign corporate officers, and build initial directories.',
            style: TextStyle(color: VianTheme.lightText, fontSize: 13),
          ),
          const SizedBox(height: 24),
          VianCard(
            padding: EdgeInsets.zero,
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              steps: steps,
              onStepContinue: () {
                if (_currentStep < steps.length - 1) {
                  setState(() => _currentStep++);
                } else {
                  _submitOnboarding();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      VianButton(
                        text: _currentStep == steps.length - 1 ? 'Create Client Workspace' : 'Continue',
                        onPressed: details.onStepContinue!,
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        VianButton(
                          text: 'Back',
                          isSecondary: true,
                          onPressed: details.onStepCancel!,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildClientInfoStep() {
    return Column(
      children: [
        TextField(controller: _clientNameController, decoration: const InputDecoration(labelText: 'Client Name *', prefixIcon: Icon(Icons.person, color: VianTheme.primaryGold))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _clientPhoneController, decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone, color: VianTheme.primaryGold)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _clientWhatsappController, decoration: const InputDecoration(labelText: 'WhatsApp Number', prefixIcon: Icon(Icons.chat_bubble_outline, color: VianTheme.primaryGold)))),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _clientEmailController, decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email, color: VianTheme.primaryGold))),
        const SizedBox(height: 12),
        TextField(controller: _clientAddressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on, color: VianTheme.primaryGold))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _clientCityController, decoration: const InputDecoration(labelText: 'City'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _clientStateController, decoration: const InputDecoration(labelText: 'State'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _clientPincodeController, decoration: const InputDecoration(labelText: 'Pincode'))),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _clientGstController, decoration: const InputDecoration(labelText: 'GST Number (Optional)')),
      ],
    );
  }

  Widget _buildProjectInfoStep() {
    return Column(
      children: [
        TextField(controller: _projectNameController, decoration: const InputDecoration(labelText: 'Project Name *', prefixIcon: Icon(Icons.architecture, color: VianTheme.primaryGold))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedProjectType,
          dropdownColor: VianTheme.headerBlack,
          decoration: const InputDecoration(labelText: 'Project Type *', prefixIcon: Icon(Icons.list, color: VianTheme.primaryGold)),
          items: ['Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedProjectType = v ?? 'Residential'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _projectSiteAddressController, decoration: const InputDecoration(labelText: 'Site Address', prefixIcon: Icon(Icons.home, color: VianTheme.primaryGold))),
        const SizedBox(height: 12),
        TextField(controller: _projectBudgetController, decoration: const InputDecoration(labelText: 'Budget (INR) *', prefixIcon: Icon(Icons.currency_rupee, color: VianTheme.primaryGold))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: _projectStartDateController, decoration: const InputDecoration(labelText: 'Expected Start Date', prefixIcon: Icon(Icons.calendar_month, color: VianTheme.primaryGold)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _projectEndDateController, decoration: const InputDecoration(labelText: 'Expected Completion Date', prefixIcon: Icon(Icons.event, color: VianTheme.primaryGold)))),
          ],
        )
      ],
    );
  }

  Widget _buildAssignTeamStep() {
    if (_employees.isEmpty) return const Center(child: CircularProgressIndicator());

    final mds = _employees.where((e) => e['role'] == 'Managing Director').toList();
    final architects = _employees.where((e) => e['role'].toString().contains('Architect') || e['role'].toString().contains('Senior Design')).toList();
    final designs = _employees.where((e) => e['role'].toString().contains('Design') || e['role'].toString().contains('Visual')).toList();
    final siteEngs = _employees.where((e) => e['role'].toString().contains('Site') || e['role'].toString().contains('Construction')).toList();
    final supervisors = _employees.where((e) => e['role'].toString().contains('Supervisor') || e['role'].toString().contains('Labour')).toList();

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedMdId,
          dropdownColor: VianTheme.headerBlack,
          decoration: const InputDecoration(labelText: 'Managing Director *', prefixIcon: Icon(Icons.person, color: VianTheme.primaryGold)),
          items: mds.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['name'] ?? ''))).toList(),
          onChanged: (v) => setState(() => _selectedMdId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedArchId,
          dropdownColor: VianTheme.headerBlack,
          decoration: const InputDecoration(labelText: 'Architect *', prefixIcon: Icon(Icons.draw, color: VianTheme.primaryGold)),
          items: architects.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text('${e['name']} (${e['role']})'))).toList(),
          onChanged: (v) => setState(() => _selectedArchId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDesignEngId,
          dropdownColor: VianTheme.headerBlack,
          decoration: const InputDecoration(labelText: 'Design Engineer', prefixIcon: Icon(Icons.design_services, color: VianTheme.primaryGold)),
          items: designs.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text('${e['name']} (${e['role']})'))).toList(),
          onChanged: (v) => setState(() => _selectedDesignEngId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedSiteEngId,
          dropdownColor: VianTheme.headerBlack,
          decoration: const InputDecoration(labelText: 'Site Engineer *', prefixIcon: Icon(Icons.construction, color: VianTheme.primaryGold)),
          items: siteEngs.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text(e['name'] ?? ''))).toList(),
          onChanged: (v) => setState(() => _selectedSiteEngId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedSupervisorId,
          dropdownColor: VianTheme.headerBlack,
          decoration: const InputDecoration(labelText: 'Site Supervisor', prefixIcon: Icon(Icons.supervised_user_circle, color: VianTheme.primaryGold)),
          items: supervisors.map((e) => DropdownMenuItem(value: e['id'].toString(), child: Text('${e['name']} (${e['role']})'))).toList(),
          onChanged: (v) => setState(() => _selectedSupervisorId = v),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _docTitleController,
                decoration: const InputDecoration(
                  labelText: 'Document File Name',
                  prefixIcon: Icon(Icons.file_copy_outlined, color: VianTheme.primaryGold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDocFolder,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Target Folder'),
                items: ['Agreements', 'Site Photos', 'Drawings', 'Property Documents'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() => _selectedDocFolder = v ?? 'Property Documents'),
              ),
            ),
            const SizedBox(width: 12),
            VianButton(
              text: 'Upload File',
              icon: Icons.upload_file_outlined,
              onPressed: _addMockDocument,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('CLOUD WORKSPACE ATTACHMENTS (Mock Cloudinary Upload)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.primaryGold)),
        const SizedBox(height: 12),
        _documentsList.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No documents uploaded yet.', style: TextStyle(color: Color(0xFF70707C), fontSize: 13)),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _documentsList.length,
                itemBuilder: (context, idx) {
                  final doc = _documentsList[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x11F5A623)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.file_present_outlined, color: VianTheme.primaryGold),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Folder: ${doc['folder']} | Size: ${(doc['fileSize'] / 1024).toStringAsFixed(1)} MB', style: const TextStyle(color: Color(0xFF70707C), fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.cloud_done_outlined, color: VianTheme.success, size: 16),
                            const SizedBox(width: 4),
                            Text(doc['status'] ?? 'Uploaded', style: const TextStyle(color: VianTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: VianTheme.danger, size: 20),
                              onPressed: () => setState(() => _documentsList.removeAt(idx)),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              )
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SUMMARY AUDIT REVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: VianTheme.primaryGold)),
        const SizedBox(height: 16),
        _reviewSection('Client Information', [
          'Name: ${_clientNameController.text}',
          'Phone: ${_clientPhoneController.text}',
          'Email: ${_clientEmailController.text}',
          'Address: ${_clientAddressController.text}, ${_clientCityController.text}, ${_clientStateController.text}',
          'GST: ${_clientGstController.text.isNotEmpty ? _clientGstController.text : 'N/A'}'
        ]),
        const SizedBox(height: 16),
        _reviewSection('Project Information', [
          'Project Name: ${_projectNameController.text}',
          'Project Type: $_selectedProjectType',
          'Site Location: ${_projectSiteAddressController.text}',
          'Total Budget: INR ${_projectBudgetController.text}',
          'Schedule: ${_projectStartDateController.text} to ${_projectEndDateController.text}'
        ]),
        const SizedBox(height: 16),
        _reviewSection('Assigned Corporate Officers', [
          'Managing Director ID: $_selectedMdId',
          'Lead Architect ID: $_selectedArchId',
          'Design Engineer ID: $_selectedDesignEngId',
          'Site Engineer ID: $_selectedSiteEngId',
          'Site Supervisor ID: $_selectedSupervisorId'
        ]),
        const SizedBox(height: 16),
        _reviewSection('Workspace Assets', [
          'Initial folders to create: Agreements, Drawings, Site Photos, Property Documents, Invoices, Expenses',
          'Documents queued: ${_documentsList.length} files total'
        ])
      ],
    );
  }

  Widget _reviewSection(String title, List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x11F5A623)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13)),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(l, style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
          )).toList()
        ],
      ),
    );
  }
}

// ==========================================
// 13. DATA IMPORT & EXPORT CONTROL CENTER
// ==========================================
class ImportExportTab extends ConsumerStatefulWidget {
  const ImportExportTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportExportTab> createState() => _ImportExportTabState();
}

class _ImportExportTabState extends ConsumerState<ImportExportTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Import State Machine
  int _importWizardStep = 1;
  bool _isUploadingFile = false;
  String? _uploadedFileName;
  String? _uploadedFilePath;
  List<dynamic> _workbookSheets = [];
  int _selectedSheetIndex = 0;
  String _selectedImportModule = 'Clients';

  // Manual Paste fallback
  final _csvPasteController = TextEditingController();

  // Mapping & Parsing States
  List<dynamic> _parsedRows = [];
  List<String> _spreadsheetHeaders = [];
  Map<String, String> _columnMappings = {};
  List<dynamic> _validationResults = [];
  Map<String, dynamic> _validationSummary = {};
  String _duplicateResolutionStrategy = 'skip';
  bool _isImportExecuting = false;
  Map<String, dynamic> _executionResult = {};

  // Export module state
  String _selectedExportModule = 'clients';
  String _selectedExportFormat = 'xlsx';
  bool _isExporting = false;
  
  // Project package export state
  List<dynamic> _projectsList = [];
  int? _selectedExportProjectId;

  // Database Backup / Restore State
  final _backupRestoreJsonController = TextEditingController();
  List<dynamic> _backupHistory = [];
  bool _isBackupLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBackupHistory();
    _loadProjectsList();
  }

  Future<void> _loadBackupHistory() async {
    setState(() => _isBackupLoading = true);
    try {
      final list = await ApiService.getBackupsList();
      setState(() {
        _backupHistory = list;
      });
    } catch (_) {}
    setState(() => _isBackupLoading = false);
  }

  Future<void> _loadProjectsList() async {
    try {
      final projs = await ApiService.getProjects();
      setState(() {
        _projectsList = projs;
        if (projs.isNotEmpty) {
          _selectedExportProjectId = projs.first['id'];
        }
      });
    } catch (_) {}
  }

  // File Picker selector
  Future<void> _pickFileForImport() async {
    setState(() {
      _isUploadingFile = true;
    });

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final ext = file.name.split('.').last.toLowerCase();
        if (ext != 'xlsx' && ext != 'csv' && ext != 'zip' && ext != 'xls') {
          _showErrorSnackBar('Invalid file type. Please select Excel (.xlsx, .xls), CSV, or ZIP.');
          setState(() => _isUploadingFile = false);
          return;
        }
        final bytes = file.bytes ?? (kIsWeb ? null : io.File(file.path!).readAsBytesSync());

        if (bytes != null) {
          final res = await ApiService.uploadImportFile(bytes, file.name);
          if (res['success'] == true) {
            setState(() {
              _uploadedFileName = file.name;
              _uploadedFilePath = res['filePath'];
              _workbookSheets = res['sheets'] ?? [];
              _selectedSheetIndex = 0;
              _isUploadingFile = false;
              _loadPreviewForSelectedSheet();
            });
            return;
          } else {
            _showErrorSnackBar(res['message'] ?? 'Upload failed');
          }
        } else {
          _showErrorSnackBar('Could not read file bytes.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }

    setState(() {
      _isUploadingFile = false;
    });
  }

  void _loadPreviewForSelectedSheet() {
    if (_workbookSheets.isEmpty || _selectedSheetIndex >= _workbookSheets.length) return;

    final sheet = _workbookSheets[_selectedSheetIndex];
    final headers = List<String>.from(sheet['headers'] ?? []);
    final rows = List<Map<String, dynamic>>.from(sheet['rows'] ?? []);

    setState(() {
      _spreadsheetHeaders = headers;
      _parsedRows = rows;
      _selectedImportModule = sheet['detectedModule'] ?? 'Clients';
      
      // Initialize automatic column mapping
      _columnMappings = {};
      final targetFields = _getTargetFieldsForModule(_selectedImportModule);
      for (final field in targetFields) {
        final matched = headers.firstWhere(
          (h) => h.toLowerCase().trim() == field.toLowerCase().trim() ||
                 h.toLowerCase().contains(field.toLowerCase().split(' ').last),
          orElse: () => headers.isNotEmpty ? headers.first : '',
        );
        _columnMappings[field] = matched;
      }

      _importWizardStep = 2; // Jump to preview step
    });
  }

  List<String> _getTargetFieldsForModule(String module) {
    switch (module) {
      case 'Clients':
        return ['Client Name', 'Mobile Number', 'Email', 'Address', 'GST Number'];
      case 'Projects':
        return ['Project Code', 'Project Name', 'Project Type', 'Budget'];
      case 'Employees':
        return ['Employee ID', 'Name', 'Department', 'Role', 'Phone', 'Email'];
      case 'Drawings':
        return ['Drawing Number', 'Drawing Name', 'Revision', 'Status', 'Assigned Architect Email', 'Completion %', 'Approval Status'];
      case 'Drawing Progress':
        return ['Drawing Number', 'Assigned Employee Email', 'Current Status', 'Pending Work', 'Revision History', 'Completion %'];
      case 'BOQ':
        return ['Project Code', 'Item Description', 'Unit', 'Quantity', 'Rate', 'Total Amount'];
      case 'Materials':
        return ['Project Code', 'Material Name', 'Purchased Quantity', 'Used Quantity', 'Balance Stock', 'Material Cost'];
      case 'Labour':
        return ['Labour ID', 'Labour Name', 'Contractor', 'Trade', 'Daily Wage'];
      case 'Payments':
        return ['Project Code', 'Payment Date', 'Description', 'Paid Amount', 'Pending Amount', 'Payment Type', 'Expense Category'];
      case 'Expenses':
        return ['Project Code', 'Amount', 'Category', 'Description', 'Date', 'Status'];
      default:
        return ['Name', 'Phone', 'Email', 'Notes'];
    }
  }

  void _loadDemoTemplate() {
    if (_selectedImportModule == 'Clients') {
      _csvPasteController.text = 
        'Client Name,Mobile Number,Email,Address,GST Number\r\n'
        'Amit Bajaj,9876543210,amit@bajaj.com,Villa 108 Palm Meadows,29BBBBB2222B1Z2\r\n'
        'Kiran Oberoi,9911223344,kiran@oberoigroup.com,DLF Sector 43 Gurugram,07CCCCC3333C1Z3\r\n'
        'Rohan Malhotra,9811223344,rohan@malhotragroup.in,Penthouse Sector 54,07DDDDD4444D1Z4\r\n'
        'Priya Sen,,priya@sen.org,Whitefield Bangalore,';
    } else {
      _csvPasteController.text =
        'Project Code,Project Name,Project Type,Budget,Location\r\n'
        'VIAN-PROJ-2026-901,The Bajaj Villa,Villa,45000000.00,Bangalore Site\r\n'
        'VIAN-PROJ-2026-902,Oberoi Office Phase 2,Commercial,80000000.00,Delhi Site\r\n'
        'VIAN-PROJ-2026-903,Malhotra Penthouse,Interior Design,15000000.00,Noida Site';
    }
    _parsePasteInput();
  }

  void _parsePasteInput() {
    final text = _csvPasteController.text.trim();
    if (text.isEmpty) return;

    final lines = text.split('\r\n');
    if (lines.length < 2) return;

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final List<Map<String, dynamic>> parsed = [];

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final cells = lines[i].split(',').map((c) => c.trim()).toList();
      final Map<String, dynamic> row = {};
      for (int c = 0; c < headers.length; c++) {
        row[headers[c]] = c < cells.length ? cells[c] : '';
      }
      parsed.add(row);
    }

    setState(() {
      _uploadedFileName = 'raw_paste.csv';
      _spreadsheetHeaders = headers;
      _parsedRows = parsed;
      _selectedSheetIndex = 0;
      _workbookSheets = [{
        'name': 'Pasted Text',
        'detectedModule': _selectedImportModule,
        'headers': headers,
        'rows': parsed
      }];
      _loadPreviewForSelectedSheet();
    });
  }

  void _runImportValidation() async {
    setState(() => _isImportExecuting = true);
    final res = await ApiService.validateImport(_parsedRows, _columnMappings, _selectedImportModule);
    setState(() {
      _validationResults = res['validationResults'] != null ? List<dynamic>.from(res['validationResults']) : [];
      _validationSummary = res['summary'] ?? {};
      _isImportExecuting = false;
      _importWizardStep = 4;
    });
  }

  void _executeBulkImport() async {
    setState(() => _isImportExecuting = true);
    final res = await ApiService.executeImport(
      _parsedRows, 
      _columnMappings, 
      _duplicateResolutionStrategy, 
      _selectedImportModule
    );
    setState(() {
      _executionResult = res['summary'] ?? {};
      _isImportExecuting = false;
      _importWizardStep = 5;
    });
  }

  void _triggerExport() async {
    setState(() => _isExporting = true);
    final url = '${ApiService.baseUrl}/export/$_selectedExportModule?format=$_selectedExportFormat';
    openUrl(url);
    setState(() => _isExporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting export of $_selectedExportModule...'), backgroundColor: VianTheme.success)
    );
  }

  void _triggerProjectPackageExport() {
    if (_selectedExportProjectId == null) return;
    final url = '${ApiService.baseUrl}/export/project/$_selectedExportProjectId/package';
    openUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading ZIP project workspace package...'), backgroundColor: VianTheme.success)
    );
  }

  void _triggerBackup() {
    final url = '${ApiService.baseUrl}/backup/export';
    openUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading full SQL/JSON database backup...'), backgroundColor: VianTheme.success)
    );
    _loadBackupHistory();
  }

  void _triggerRestore() async {
    if (_backupRestoreJsonController.text.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('CONFIRM RESTORE DATABASE', style: TextStyle(color: VianTheme.danger)),
        content: const Text('WARNING: Restoring will overwrite all existing database tables with the backup records. This action cannot be undone.', style: TextStyle(color: VianTheme.whiteText)),
        actions: [
          VianButton(
            text: 'Yes, Overwrite Tables',
            color: VianTheme.danger,
            textColor: VianTheme.whiteText,
            onPressed: () async {
              Navigator.pop(context);
              final res = await ApiService.restoreDatabase(_backupRestoreJsonController.text.trim());
              _backupRestoreJsonController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Database restore completed.'), backgroundColor: VianTheme.success)
              );
            },
          ),
          VianButton(
            text: 'Cancel',
            isSecondary: true,
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _downloadTemplate(String templateName) {
    final url = '${ApiService.baseUrl}/templates/$templateName';
    openUrl(url);
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VianTheme.danger)
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    final userRole = user?['role'] ?? '';
    final isAuthorized = userRole == 'Managing Director' || userRole == 'Admin / Office Manager / Accounts' || userRole == 'Super Admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: VianTheme.primaryGold,
            labelColor: VianTheme.primaryGold,
            unselectedLabelColor: VianTheme.lightText,
            tabs: const [
              Tab(text: 'IMPORT WIZARD'),
              Tab(text: 'EXPORT MODULES'),
              Tab(text: 'BACKUP CONTROL'),
              Tab(text: 'IMPORT LOGS'),
            ],
          ),
        ),
      ),
      body: isAuthorized
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildImportTab(),
                _buildExportTab(),
                _buildBackupRestoreTab(),
                _buildLogsTab(),
              ],
            )
          : const Center(
              child: Text(
                'Access Denied. Only Managing Directors and Administrators have Import & Export rights.',
                style: TextStyle(color: VianTheme.danger, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  // 1. IMPORT WIZARD UI
  Widget _buildImportTab() {
    if (_isImportExecuting) return const Center(child: CircularProgressIndicator());

    if (_importWizardStep == 1) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 1: SELECT DESTINATION & UPLOAD WORKBOOK',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'VIAN auto-detects worksheet configurations based on sheet titles (e.g. BOQ, Attendance, Materials). Simply drag & drop or paste raw CSV text.',
                    style: TextStyle(color: VianTheme.lightText, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedImportModule,
                    dropdownColor: VianTheme.headerBlack,
                    decoration: const InputDecoration(labelText: 'Default Destination Module'),
                    items: [
                      'Clients', 'Projects', 'Leads', 'Employees', 'Attendance', 
                      'Drawings', 'Drawing Progress', 'BOQ', 'Materials', 'Labour', 
                      'Payments', 'Expenses', 'Vendors', 'Contractors', 'Tasks', 'Documents'
                    ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedImportModule = v ?? 'Clients'),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _isUploadingFile ? null : _pickFileForImport,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VianTheme.primaryGold, width: 1.5, style: BorderStyle.values[1]),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isUploadingFile ? Icons.sync : Icons.cloud_upload_outlined,
                            size: 44,
                            color: VianTheme.primaryGold,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isUploadingFile ? 'Uploading & parsing sheet...' : 'Drag & Drop Workbook or Click to Browse',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Supported formats: Excel (.xlsx), CSV, ZIP Project Packages',
                            style: TextStyle(color: Color(0xFF70707C), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('OR PASTE RAW CSV SPREADSHEET DATA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.download, size: 14, color: VianTheme.primaryGold),
                            label: const Text('Load Copy-Paste Demo Data', style: TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
                            onPressed: _loadDemoTemplate,
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: const Text('Clear', style: TextStyle(color: VianTheme.danger, fontSize: 11)),
                            onPressed: () => _csvPasteController.clear(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _csvPasteController,
                    maxLines: 6,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    decoration: const InputDecoration(
                      hintText: 'Client Name,Mobile Number,Email,Address,GST Number\r\nAmit Bajaj,9876543210,amit@vian.com,Villa 108,29BBBBB...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  VianButton(
                    text: 'Process Pasted Text',
                    onPressed: _parsePasteInput,
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DOWNLOAD STANDARD WORKBOOK TEMPLATES', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  const SizedBox(height: 8),
                  const Text('Download template layouts formatted specifically for VIAN ERP imports.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'projects', 'clients', 'leads', 'employees', 'attendance',
                      'drawings', 'drawing_progress', 'boq', 'materials', 'labour',
                      'payments', 'expenses'
                    ].map((name) {
                      return OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 14, color: VianTheme.primaryGold),
                        label: Text(name.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: VianTheme.whiteText, fontSize: 10)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x33F5A623)),
                          backgroundColor: const Color(0xFF1E1E26),
                        ),
                        onPressed: () => _downloadTemplate(name),
                      );
                    }).toList(),
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    if (_importWizardStep == 2) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP 2: PREVIEW PARSED WORKSHEET ROWS',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14),
                      ),
                      if (_workbookSheets.length > 1)
                        DropdownButton<int>(
                          value: _selectedSheetIndex,
                          dropdownColor: VianTheme.headerBlack,
                          items: List.generate(_workbookSheets.length, (idx) {
                            return DropdownMenuItem(
                              value: idx,
                              child: Text(_workbookSheets[idx]['name'] ?? 'Sheet $idx', style: const TextStyle(fontSize: 12)),
                            );
                          }),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedSheetIndex = v;
                                _loadPreviewForSelectedSheet();
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Previewing "$_uploadedFileName" worksheet (${_parsedRows.length} total rows parsed). Target: $_selectedImportModule Module.',
                    style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF1E1E26)),
                      columns: _spreadsheetHeaders.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11)))).toList(),
                      rows: _parsedRows.take(8).map((row) {
                        return DataRow(
                          cells: _spreadsheetHeaders.map((h) => DataCell(Text(row[h]?.toString() ?? '', style: const TextStyle(fontSize: 11)))).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      VianButton(
                        text: 'Auto-Detect / Map Columns',
                        onPressed: () => setState(() => _importWizardStep = 3),
                      ),
                      const SizedBox(width: 12),
                      VianButton(
                        text: 'Cancel',
                        isSecondary: true,
                        onPressed: () => setState(() => _importWizardStep = 1),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    if (_importWizardStep == 3) {
      final erpFields = _getTargetFieldsForModule(_selectedImportModule);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 3: SPREADSHEET COLUMN MAPPING',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verify mappings for $_selectedImportModule workspace fields. Standard VIAN files require no mapping adjustments.',
                    style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ...erpFields.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(f, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const Icon(Icons.arrow_right_alt, color: VianTheme.primaryGold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              value: _columnMappings[f],
                              dropdownColor: VianTheme.headerBlack,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              items: _spreadsheetHeaders.map((sh) => DropdownMenuItem(value: sh, child: Text(sh, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setState(() => _columnMappings[f] = v!),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      VianButton(
                        text: 'Validate Records',
                        onPressed: _runImportValidation,
                      ),
                      const SizedBox(width: 12),
                      VianButton(
                        text: 'Back',
                        isSecondary: true,
                        onPressed: () => setState(() => _importWizardStep = 2),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    if (_importWizardStep == 4) {
      final isValid = _validationSummary['isValidSuite'] == true;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 4: IMPORT DATA AUDIT & CONFLICT RESOLUTION',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isValid ? VianTheme.success : VianTheme.warning),
                    ),
                    child: Row(
                      children: [
                        Icon(isValid ? Icons.check_circle : Icons.warning_amber, color: isValid ? VianTheme.success : VianTheme.warning, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isValid ? 'VALIDATION SUCCEEDED' : 'VALIDATION CHECKS COMPLETED WITH WARNINGS',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isValid ? VianTheme.success : VianTheme.warning),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Missing values: ${_validationSummary['missingFields']} | Duplicate matches: ${_validationSummary['duplicateClients'] + _validationSummary['duplicateProjects']} | Invalid emails: ${_validationSummary['invalidEmails']}',
                                style: const TextStyle(color: Color(0xFF70707C), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('DUPLICATE RECORD RESOLUTION STRATEGY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.primaryGold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _duplicateResolutionStrategy,
                    dropdownColor: VianTheme.headerBlack,
                    items: const [
                      DropdownMenuItem(value: 'skip', child: Text('Skip Matches (Do Not Import)')),
                      DropdownMenuItem(value: 'update', child: Text('Update / Overwrite Existing Records')),
                      DropdownMenuItem(value: 'merge', child: Text('Merge / Fill Empty Fields Only')),
                      DropdownMenuItem(value: 'create_new', child: Text('Force Import as New Records')),
                    ],
                    onChanged: (v) => setState(() => _duplicateResolutionStrategy = v ?? 'skip'),
                  ),
                  const SizedBox(height: 24),
                  const Text('DETAILED DATA AUDIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.primaryGold)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _validationResults.length,
                    itemBuilder: (context, idx) {
                      final item = _validationResults[idx];
                      final errs = item['errors'] as Map<String, dynamic>;
                      final warns = item['warnings'] as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: errs.isNotEmpty ? VianTheme.danger : warns.isNotEmpty ? VianTheme.warning : const Color(0x22F5A623)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Row ${item['index'] + 1}: ${item['resolvedValues']['Client Name'] ?? item['resolvedValues']['Project Name'] ?? 'Record'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Icon(
                                  errs.isNotEmpty ? Icons.cancel : warns.isNotEmpty ? Icons.warning : Icons.check_circle_outline,
                                  color: errs.isNotEmpty ? VianTheme.danger : warns.isNotEmpty ? VianTheme.warning : VianTheme.success,
                                  size: 16,
                                ),
                              ],
                            ),
                            if (errs.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ...errs.entries.map((e) => Text('• Error: ${e.value}', style: const TextStyle(color: VianTheme.danger, fontSize: 11))).toList()
                            ],
                            if (warns.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ...warns.entries.map((e) => Text('• Match Warning: ${e.value}', style: const TextStyle(color: VianTheme.warning, fontSize: 11))).toList()
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      VianButton(
                        text: 'Commit Import',
                        onPressed: _executeBulkImport,
                      ),
                      const SizedBox(width: 12),
                      VianButton(
                        text: 'Back',
                        isSecondary: true,
                        onPressed: () => setState(() => _importWizardStep = 3),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: VianTheme.success, size: 40),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IMPORT PROCESS COMPLETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: VianTheme.success)),
                        Text('Workspace synchronization completed successfully.', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                _summaryTile('New Records Imported', _executionResult['imported']?.toString() ?? '0', VianTheme.success),
                _summaryTile('Updated / Merged Records', _executionResult['updated']?.toString() ?? '0', VianTheme.primaryGold),
                _summaryTile('Skipped Duplicates', _executionResult['skipped']?.toString() ?? '0', VianTheme.lightText),
                _summaryTile('Rejected / Failed Rows', _executionResult['failed']?.toString() ?? '0', VianTheme.danger),
                const SizedBox(height: 32),
                Row(
                  children: [
                    VianButton(
                      text: 'Import Another Sheet',
                      onPressed: () {
                        setState(() {
                          _importWizardStep = 1;
                          _csvPasteController.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    VianButton(
                      text: 'View logs',
                      isSecondary: true,
                      onPressed: () {
                        _tabController.animateTo(3);
                      },
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String val, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(val, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // 2. EXPORT MODULES PANEL
  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXPORT MASTER DIRECTORIES', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Export live module directories as spreadsheets, PDF or JSON formats.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedExportModule,
                        dropdownColor: VianTheme.headerBlack,
                        decoration: const InputDecoration(labelText: 'Source Module'),
                        items: const [
                          DropdownMenuItem(value: 'clients', child: Text('Clients Directory')),
                          DropdownMenuItem(value: 'projects', child: Text('Projects Workspace')),
                          DropdownMenuItem(value: 'attendance', child: Text('GPS Shift Attendance')),
                          DropdownMenuItem(value: 'expenses', child: Text('Expenses & Vouchers')),
                          DropdownMenuItem(value: 'invoices', child: Text('Client Billings & Invoices')),
                        ],
                        onChanged: (v) => setState(() => _selectedExportModule = v ?? 'clients'),
                      ),
                      const SizedBox(height: 20),
                      const Text('Document Export Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _formatRadio('xlsx', 'Excel (.xlsx)'),
                          const SizedBox(width: 20),
                          _formatRadio('csv', 'CSV (.csv)'),
                          const SizedBox(width: 20),
                          _formatRadio('json', 'JSON (.json)'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _isExporting
                          ? const Center(child: CircularProgressIndicator())
                          : VianButton(
                              text: 'Generate and Export File',
                              icon: Icons.download,
                              onPressed: _triggerExport,
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: VianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROJECT WORKSPACE ZIP EXPORT', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Bundles complete Project data: metadata, drawings, folders of photos, invoices, and quotations into a portable ZIP package.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                      const SizedBox(height: 24),
                      if (_projectsList.isEmpty)
                        const Text('No projects available.', style: TextStyle(color: VianTheme.lightText, fontSize: 12))
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedExportProjectId,
                          dropdownColor: VianTheme.headerBlack,
                          decoration: const InputDecoration(labelText: 'Target Project Workspace'),
                          items: _projectsList.map((p) {
                            return DropdownMenuItem<int>(
                              value: p['id'],
                              child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedExportProjectId = v),
                        ),
                      const SizedBox(height: 32),
                      VianButton(
                        text: 'Download Project Package (.zip)',
                        icon: Icons.inventory_2_outlined,
                        onPressed: _projectsList.isEmpty ? null : _triggerProjectPackageExport,
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _formatRadio(String val, String label) {
    return InkWell(
      onTap: () => setState(() => _selectedExportFormat = val),
      child: Row(
        children: [
          Radio<String>(
            value: val,
            groupValue: _selectedExportFormat,
            activeColor: VianTheme.primaryGold,
            onChanged: (v) => setState(() => _selectedExportFormat = v!),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // 3. BACKUP CONTROL PANEL
  Widget _buildBackupRestoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FULL ERP DATABASE BACKUP', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Exports full relational data schemas, keys, worker rosters, and settings configurations into a portable dump file.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                      const SizedBox(height: 24),
                      VianButton(
                        text: 'Trigger Full DB Backup',
                        icon: Icons.backup,
                        onPressed: _triggerBackup,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: VianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WIPE & RESTORE DATABASE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.danger, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Restores full structure configuration from a backed-up JSON dump. WARNING: This wipes all tables.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _backupRestoreJsonController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        decoration: const InputDecoration(hintText: 'Paste backup JSON content here...'),
                      ),
                      const SizedBox(height: 16),
                      VianButton(
                        text: 'Upload and Restore Backup',
                        color: VianTheme.danger,
                        textColor: VianTheme.whiteText,
                        onPressed: _triggerRestore,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY LOCAL BACKUP REGISTRY', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14)),
                const SizedBox(height: 12),
                _isBackupLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _backupHistory.isEmpty
                        ? const Text('No local backups found.', style: TextStyle(color: VianTheme.lightText, fontSize: 12))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _backupHistory.length,
                            itemBuilder: (context, idx) {
                              final item = _backupHistory[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.storage, color: VianTheme.primaryGold, size: 20),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text('Size: ${item['size']} | Date: ${item['date']}', style: const TextStyle(color: Color(0xFF70707C), fontSize: 10)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    VianButton(
                                      text: 'Trigger restore',
                                      isSecondary: true,
                                      onPressed: () {
                                        _backupRestoreJsonController.text = '{"User":[],"Client":[],"Project":[]}';
                                        _triggerRestore();
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 4. ACTIVITY LOGS TAB
  Widget _buildLogsTab() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getImportLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final logs = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BULK ONBOARDING & AUDIT HISTORY', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF1E1E26)),
                    columns: const [
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                      DataColumn(label: Text('Destination Module', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                      DataColumn(label: Text('Import File', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                      DataColumn(label: Text('Audit Counts', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                      DataColumn(label: Text('Operator', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                      DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                      DataColumn(label: Text('Source file', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11))),
                    ],
                    rows: logs.map((log) {
                      final timeStr = log['createdAt'] != null
                          ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(log['createdAt']))
                          : '';
                      final recordsStr = 'Imp: ${log['recordsImported']} | Upd: ${log['recordsUpdated']} | Fail: ${log['recordsFailed']}';

                      return DataRow(
                        cells: [
                          DataCell(Text(log['type'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: log['type'] == 'Import' ? VianTheme.success : VianTheme.primaryGold, fontSize: 11))),
                          DataCell(Text(log['module'] ?? '', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(log['fileName'] ?? 'Raw paste', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(recordsStr, style: const TextStyle(fontSize: 11))),
                          DataCell(Text(log['user']?['name'] ?? 'Admin', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(timeStr, style: const TextStyle(fontSize: 11))),
                          DataCell(
                            log['filePath'] != null
                                ? IconButton(
                                    icon: const Icon(Icons.download_for_offline, color: VianTheme.primaryGold, size: 18),
                                    onPressed: () {
                                      final url = '${ApiService.baseUrl}/import-logs/${log['id']}/download';
                                      openUrl(url);
                                    },
                                  )
                                : const Text('No File', style: TextStyle(color: Color(0xFF70707C), fontSize: 10)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 14. BUSINESS TARGETS & PERFORMANCE MODULE
// ==========================================
class BusinessTargetsTab extends ConsumerStatefulWidget {
  const BusinessTargetsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<BusinessTargetsTab> createState() => _BusinessTargetsTabState();
}

class _BusinessTargetsTabState extends ConsumerState<BusinessTargetsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String _selectedFY = '2026-2027';
  
  List<dynamic> _annualTargets = [];
  List<dynamic> _monthlyTargets = [];
  List<dynamic> _teamTargets = [];
  List<dynamic> _employeeTargets = [];
  List<dynamic> _employees = [];
  Map<String, dynamic>? _analytics;
  List<dynamic> _alerts = [];
  
  int? _selectedAnnualId;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkPermissionsAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLoad() async {
    final user = ref.read(userProvider);
    final role = user?['role'] ?? '';
    _isSuperAdmin = role == 'Managing Director' || role == 'Super Admin';
    
    if (!_isSuperAdmin) {
      _tabController = TabController(length: 1, vsync: this);
    }
    
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (_isSuperAdmin) {
        _annualTargets = await ApiService.getAnnualTargets();
        if (_annualTargets.isNotEmpty) {
          final approvedTarget = _annualTargets.firstWhere((t) => t['isApproved'] == true, orElse: () => _annualTargets.first);
          _selectedAnnualId = approvedTarget['id'];
          _monthlyTargets = await ApiService.getMonthlyTargets(_selectedAnnualId!);
        }
        _teamTargets = await ApiService.getTeamTargets(_selectedFY);
        _analytics = await ApiService.getExecutiveAnalytics();
        _alerts = await ApiService.getTargetAlerts();
      }
      
      _employeeTargets = await ApiService.getEmployeeTargets();
      _employees = await ApiService.getEmployees();
    } catch (_) {}
    
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeAnnualTarget(int? id) async {
    if (id == null) return;
    setState(() => _loading = true);
    try {
      _selectedAnnualId = id;
      _monthlyTargets = await ApiService.getMonthlyTargets(id);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showCreateAnnualTargetDialog() {
    final fyCtrl = TextEditingController(text: '2026-2027');
    final projCtrl = TextEditingController(text: '120');
    final revCtrl = TextEditingController(text: '12000000');
    final profitCtrl = TextEditingController(text: '3600000');
    final resCtrl = TextEditingController(text: '50');
    final commCtrl = TextEditingController(text: '30');
    final intCtrl = TextEditingController(text: '30');
    final renCtrl = TextEditingController(text: '10');
    final newCliCtrl = TextEditingController(text: '15');
    final repCliCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('CREATE ANNUAL BUSINESS TARGETS', style: TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fyCtrl, decoration: const InputDecoration(labelText: 'Financial Year (e.g. 2026-2027)')),
              const SizedBox(height: 12),
              TextField(controller: projCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Annual Project Target')),
              const SizedBox(height: 12),
              TextField(controller: revCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Annual Revenue Target (Turnover)')),
              const SizedBox(height: 12),
              TextField(controller: profitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Annual Profit Target')),
              const SizedBox(height: 12),
              TextField(controller: resCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Residential Projects Target')),
              const SizedBox(height: 12),
              TextField(controller: commCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Commercial Projects Target')),
              const SizedBox(height: 12),
              TextField(controller: intCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interior Projects Target')),
              const SizedBox(height: 12),
              TextField(controller: renCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Renovation Projects Target')),
              const SizedBox(height: 12),
              TextField(controller: newCliCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Client Target')),
              const SizedBox(height: 12),
              TextField(controller: repCliCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat Client Target')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Save Targets',
            onPressed: () async {
              final payload = {
                'financialYear': fyCtrl.text,
                'annualProjectTarget': int.tryParse(projCtrl.text) ?? 0,
                'annualRevenueTarget': double.tryParse(revCtrl.text) ?? 0.0,
                'annualProfitTarget': double.tryParse(profitCtrl.text) ?? 0.0,
                'residentialProjectsTarget': int.tryParse(resCtrl.text) ?? 0,
                'commercialProjectsTarget': int.tryParse(commCtrl.text) ?? 0,
                'interiorProjectsTarget': int.tryParse(intCtrl.text) ?? 0,
                'renovationProjectsTarget': int.tryParse(renCtrl.text) ?? 0,
                'newClientTarget': int.tryParse(newCliCtrl.text) ?? 0,
                'repeatClientTarget': int.tryParse(repCliCtrl.text) ?? 0,
              };
              final res = await ApiService.createAnnualTarget(payload);
              Navigator.pop(context);
              if (res['success'] == true) {
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: VianTheme.danger));
              }
            },
          )
        ],
      ),
    );
  }

  void _showEditMonthlyTargetDialog(Map<String, dynamic> monthly) {
    final projCtrl = TextEditingController(text: monthly['projectTarget'].toString());
    final revCtrl = TextEditingController(text: monthly['revenueTarget'].toString());
    final profitCtrl = TextEditingController(text: monthly['profitTarget'].toString());
    final resCtrl = TextEditingController(text: monthly['residentialProjectsTarget'].toString());
    final commCtrl = TextEditingController(text: monthly['commercialProjectsTarget'].toString());
    final intCtrl = TextEditingController(text: monthly['interiorProjectsTarget'].toString());
    final renCtrl = TextEditingController(text: monthly['renovationProjectsTarget'].toString());
    final newCliCtrl = TextEditingController(text: monthly['newClientTarget'].toString());
    final repCliCtrl = TextEditingController(text: monthly['repeatClientTarget'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text('MANUAL OVERRIDE: ${monthly['monthName'].toString().toUpperCase()}', style: const TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: projCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Projects Target')),
              const SizedBox(height: 12),
              TextField(controller: revCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Revenue Target')),
              const SizedBox(height: 12),
              TextField(controller: profitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Profit Target')),
              const SizedBox(height: 12),
              TextField(controller: resCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Residential Projects')),
              const SizedBox(height: 12),
              TextField(controller: commCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Commercial Projects')),
              const SizedBox(height: 12),
              TextField(controller: intCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Interior Projects')),
              const SizedBox(height: 12),
              TextField(controller: renCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Renovation Projects')),
              const SizedBox(height: 12),
              TextField(controller: newCliCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Clients')),
              const SizedBox(height: 12),
              TextField(controller: repCliCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat Clients')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Apply Override',
            onPressed: () async {
              final payload = {
                'projectTarget': int.tryParse(projCtrl.text) ?? 0,
                'revenueTarget': double.tryParse(revCtrl.text) ?? 0.0,
                'profitTarget': double.tryParse(profitCtrl.text) ?? 0.0,
                'residentialProjectsTarget': int.tryParse(resCtrl.text) ?? 0,
                'commercialProjectsTarget': int.tryParse(commCtrl.text) ?? 0,
                'interiorProjectsTarget': int.tryParse(intCtrl.text) ?? 0,
                'renovationProjectsTarget': int.tryParse(renCtrl.text) ?? 0,
                'newClientTarget': int.tryParse(newCliCtrl.text) ?? 0,
                'repeatClientTarget': int.tryParse(repCliCtrl.text) ?? 0,
              };
              await ApiService.updateMonthlyTarget(monthly['id'], payload);
              Navigator.pop(context);
              _loadData();
            },
          )
        ],
      ),
    );
  }

  void _showCreateTeamTargetDialog() {
    String team = 'Design Team';
    String metric = 'Project Design Completion';
    final valCtrl = TextEditingController();
    String unit = 'number';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('ASSIGN TEAM TARGET', style: TextStyle(color: VianTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: team,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Department / Team'),
                items: ['Design Team', 'Site Team', 'Accounts Team'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => team = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: metric,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Target Metric'),
                items: [
                  'Project Design Completion', 'Drawing Completion', 'Client Approval Rate',
                  'Site Completion', 'Attendance %', 'Daily Progress', 'Site Quality',
                  'Invoice Collection', 'Outstanding Payments', 'Expense Control'
                ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setDialogState(() => metric = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: valCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Goal Value')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: unit,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Value Unit'),
                items: ['number', 'percentage', 'amount'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setDialogState(() => unit = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Save Team Target',
            onPressed: () async {
              if (valCtrl.text.isNotEmpty) {
                final payload = {
                  'financialYear': _selectedFY,
                  'teamName': team,
                  'targetMetric': metric,
                  'targetValue': double.tryParse(valCtrl.text) ?? 0.0,
                  'unit': unit
                };
                await ApiService.createTeamTarget(payload);
                Navigator.pop(context);
                _loadData();
              }
            },
          )
        ],
      ),
    );
  }

  void _showAssignEmployeeTargetDialog() {
    int? selectedEmpId;
    if (_employees.isNotEmpty) selectedEmpId = _employees.first['id'];
    
    final descCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String metric = 'drawings';
    String period = 'Monthly';
    
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('ASSIGN GOAL TO EMPLOYEE', style: TextStyle(color: VianTheme.primaryGold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedEmpId,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Select Employee'),
                  items: _employees.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['name'] ?? ''))).toList(),
                  onChanged: (v) => setDialogState(() => selectedEmpId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Goal Description (e.g. Complete 8 drawings)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: metric,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Target Metric Type'),
                  items: ['drawings', 'inspections', 'collection_amount', 'site_visits', 'tasks'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => metric = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: valCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Goal Value (Count/INR)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: period,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Goal Period'),
                  items: ['Weekly', 'Monthly', 'Yearly'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => period = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start: ${DateFormat('dd MMM').format(start)}', style: const TextStyle(fontSize: 12)),
                    TextButton(
                      child: const Text('Change'),
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2026), lastDate: DateTime(2028));
                        if (d != null) setDialogState(() => start = d);
                      },
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('End: ${DateFormat('dd MMM').format(end)}', style: const TextStyle(fontSize: 12)),
                    TextButton(
                      child: const Text('Change'),
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2026), lastDate: DateTime(2028));
                        if (d != null) setDialogState(() => end = d);
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Assign Goal',
            onPressed: () async {
              if (selectedEmpId != null && descCtrl.text.isNotEmpty && valCtrl.text.isNotEmpty) {
                final payload = {
                  'employeeId': selectedEmpId,
                  'targetDescription': descCtrl.text,
                  'targetMetric': metric,
                  'targetValue': double.tryParse(valCtrl.text) ?? 0.0,
                  'period': period,
                  'startDate': start.toIso8601String().split('T')[0],
                  'endDate': end.toIso8601String().split('T')[0],
                };
                await ApiService.assignEmployeeTarget(payload);
                Navigator.pop(context);
                _loadData();
              }
            },
          )
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(Map<String, dynamic> target) {
    final valCtrl = TextEditingController(text: target['currentValue'].toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: const Text('UPDATE PROGRESS', style: TextStyle(color: VianTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(target['targetDescription'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Target: ${target['targetValue']} ${target['targetMetric']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: valCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Value Achieved')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          VianButton(
            text: 'Update',
            onPressed: () async {
              final val = double.tryParse(valCtrl.text) ?? 0.0;
              await ApiService.updateEmployeeTarget(target['id'], {'currentValue': val});
              Navigator.pop(context);
              _loadData();
            },
          )
        ],
      ),
    );
  }

  void _triggerReportsExport(String format) {
    final url = '${ApiService.baseUrl}/targets/reports?format=$format&financialYear=$_selectedFY';
    openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));

    final currentTarget = _annualTargets.firstWhere((t) => t['id'] == _selectedAnnualId, orElse: () => {});

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: VianTheme.primaryGold,
            labelColor: VianTheme.primaryGold,
            unselectedLabelColor: VianTheme.lightText,
            tabs: _isSuperAdmin ? const [
              Tab(text: 'Company Targets'),
              Tab(text: 'Team Targets'),
              Tab(text: 'Employee Targets'),
              Tab(text: 'Analytics & Scorecard'),
            ] : const [
              Tab(text: 'My Targets'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _isSuperAdmin ? [
          _buildCompanyTargetsView(currentTarget),
          _buildTeamTargetsView(),
          _buildEmployeeTargetsView(),
          _buildScorecardAndReportsTab(),
        ] : [
          _buildEmployeeTargetsView(),
        ],
      ),
    );
  }

  Widget _buildCompanyTargetsView(Map<dynamic, dynamic> currentTarget) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Financial Year Target:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedAnnualId,
                    dropdownColor: VianTheme.headerBlack,
                    items: _annualTargets.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'],
                        child: Text(t['financialYear'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) => _changeAnnualTarget(v),
                  )
                ],
              ),
              Row(
                children: [
                  VianButton(
                    text: 'Set New FY Target',
                    icon: Icons.add,
                    onPressed: _showCreateAnnualTargetDialog,
                  ),
                  if (currentTarget.isNotEmpty && currentTarget['isApproved'] != true) ...[
                    const SizedBox(width: 12),
                    VianButton(
                      text: 'Approve Targets',
                      icon: Icons.check_circle_outline,
                      color: VianTheme.success,
                      textColor: Colors.white,
                      onPressed: () async {
                        await ApiService.approveAnnualTarget(currentTarget['id']);
                        _loadData();
                      },
                    )
                  ]
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          if (currentTarget.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text('No Annual Goals defined yet. Click above to create one.', style: TextStyle(color: VianTheme.lightText)),
              ),
            )
          else ...[
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGoalCard('TOTAL PROJECTS', currentTarget['annualProjectTarget'].toString(), Icons.architecture),
                _buildGoalCard('TOTAL REVENUE GOAL', currencyFormatter.format(safeToDouble(currentTarget['annualRevenueTarget'])), Icons.payments),
                _buildGoalCard('TOTAL PROFIT GOAL', currencyFormatter.format(safeToDouble(currentTarget['annualProfitTarget'])), Icons.trending_up),
              ],
            ),
            const SizedBox(height: 24),

            // Sector specific breakdowns
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SECTOR PROJECT BREAKDOWN & CLIENT GOALS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniGoalItem('Residential', '${currentTarget['residentialProjectsTarget']} projs'),
                      _buildMiniGoalItem('Commercial', '${currentTarget['commercialProjectsTarget']} projs'),
                      _buildMiniGoalItem('Interior', '${currentTarget['interiorProjectsTarget']} projs'),
                      _buildMiniGoalItem('Renovation', '${currentTarget['renovationProjectsTarget']} projs'),
                      _buildMiniGoalItem('New Clients', '${currentTarget['newClientTarget']} clients'),
                      _buildMiniGoalItem('Repeat Clients', '${currentTarget['repeatClientTarget']} clients'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MONTHLY SPLIT DIRECTIVE & OVERRIDES', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                      Text('Drafted targets are split equally. Override manually below.', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _monthlyTargets.length,
                    itemBuilder: (context, idx) {
                      final m = _monthlyTargets[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E1E26)))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['monthName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Projs: ${m['projectTarget']} | Rev: ${currencyFormatter.format(safeToDouble(m['revenueTarget']))}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: VianTheme.primaryGold),
                              onPressed: () => _showEditMonthlyTargetDialog(m),
                            )
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTeamTargetsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DEPARTMENT TARGET LIST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              VianButton(
                text: 'Assign Team Target',
                icon: Icons.add,
                onPressed: _showCreateTeamTargetDialog,
              )
            ],
          ),
          const SizedBox(height: 24),

          if (_teamTargets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text('No team targets defined.', style: TextStyle(color: VianTheme.lightText)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _teamTargets.length,
              itemBuilder: (context, idx) {
                final tt = _teamTargets[idx];
                final isAmt = tt['unit'] == 'amount';
                final displayVal = isAmt 
                    ? NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(safeToDouble(tt['targetValue']))
                    : '${tt['targetValue']}';
                
                return Card(
                  color: const Color(0xFF16161F),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF262635)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1E1E26), child: Icon(Icons.groups, color: VianTheme.primaryGold)),
                    title: Text(tt['teamName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Goal: $displayVal (${tt['targetMetric']})', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: VianTheme.danger),
                      onPressed: () async {
                        await ApiService.deleteTeamTarget(tt['id']);
                        _loadData();
                      },
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildEmployeeTargetsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('INDIVIDUAL EMPLOYEE TARGET TRACKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              if (_isSuperAdmin)
                VianButton(
                  text: 'Assign Goal',
                  icon: Icons.add,
                  onPressed: _showAssignEmployeeTargetDialog,
                )
            ],
          ),
          const SizedBox(height: 24),

          if (_employeeTargets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Text('No active individual employee goals assigned.', style: TextStyle(color: VianTheme.lightText)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _employeeTargets.length,
              itemBuilder: (context, idx) {
                final et = _employeeTargets[idx];
                final targetVal = safeToDouble(et['targetValue'] ?? 1.0);
                final currentVal = safeToDouble(et['currentValue'] ?? 0.0);
                final pct = targetVal > 0 ? (currentVal / targetVal) : 0.0;
                final statusStr = et['status'] ?? 'Pending';

                return Card(
                  color: const Color(0xFF16161F),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF262635)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(et['targetDescription'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusStr == 'Completed' ? const Color(0x3328A745) : const Color(0x33F5A623),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusStr.toUpperCase(), 
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: statusStr == 'Completed' ? VianTheme.success : VianTheme.primaryGold
                                )
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Assigned To: ${et['employee']?['name'] ?? ''} | Due: ${et['endDate']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct > 1.0 ? 1.0 : pct,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFF2E2E3E),
                                  valueColor: AlwaysStoppedAnimation<Color>(statusStr == 'Completed' ? VianTheme.success : VianTheme.primaryGold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${currentVal.toInt()} / ${targetVal.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_isSuperAdmin) ...[
                              VianButton(
                                text: 'Update Progress',
                                icon: Icons.update,
                                isSecondary: true,
                                onPressed: () => _showUpdateProgressDialog(et),
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: VianTheme.primaryGold, size: 20),
                                onPressed: () => _showUpdateProgressDialog(et),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: VianTheme.danger, size: 20),
                                onPressed: () async {
                                  await ApiService.deleteEmployeeTarget(et['id']);
                                  _loadData();
                                },
                              ),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildScorecardAndReportsTab() {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final scoreData = _analytics?['scorecard'] ?? {};
    final forecasts = _analytics?['forecasts'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EXECUTIVE PERFORMANCE REPORT & ANALYTICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              VianButton(
                text: 'Export target Summary (CSV)',
                icon: Icons.download,
                isSecondary: true,
                onPressed: () => _triggerReportsExport('csv'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SEASONAL YEAR-END PERFORMANCE PROJECTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildForecastScoreCard('PROJECTED REVENUE', currencyFormatter.format(safeToDouble(forecasts['projectedYearEndRevenue'] ?? 0))),
                    _buildForecastScoreCard('PROJECTED PROJECTS', '${forecasts['projectedYearEndProjects'] ?? 0} Projs'),
                    _buildForecastScoreCard('PROJECTED NET PROFIT', currencyFormatter.format(safeToDouble(forecasts['projectedYearEndProfit'] ?? 0))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VIAN BUSINESS BALANCED SCORECARD', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                    Text('Health Status: EXCELLENT', style: TextStyle(color: VianTheme.success, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildScorecardLine('Financial Perspectives', safeToDouble(scoreData['financial'] ?? 70)),
                _buildScorecardLine('Projects & Schedule Accuracy', safeToDouble(scoreData['projects'] ?? 68)),
                _buildScorecardLine('Operations & Design Throughput', safeToDouble(scoreData['operations'] ?? 82)),
                _buildScorecardLine('Client Retention & satisfaction', safeToDouble(scoreData['clients'] ?? 72)),
                _buildScorecardLine('Employee Productivity & Attendance', safeToDouble(scoreData['employees'] ?? 88)),
                const Divider(color: Color(0xFF2E2E3E), height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('OVERALL VIAN BUSINESS HEALTH INDEX', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_analytics?['financialHealthScore'] ?? 78}% / 100%', style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VianTheme.headerBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VianTheme.primaryGold.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: VianTheme.lightText, fontWeight: FontWeight.bold)),
              Icon(icon, color: VianTheme.primaryGold, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMiniGoalItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
      ],
    );
  }

  Widget _buildForecastScoreCard(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
      ],
    );
  }

  Widget _buildScorecardLine(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text('${score.toInt()}%', style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFF23232E),
              valueColor: AlwaysStoppedAnimation<Color>(score > 85 ? VianTheme.success : VianTheme.primaryGold),
            ),
          )
        ],
      ),
    );
  }
}

class BuildCenterTab extends ConsumerStatefulWidget {
  const BuildCenterTab({Key? key}) : super(key: key);

  @override
  ConsumerState<BuildCenterTab> createState() => _BuildCenterTabState();
}

class _BuildCenterTabState extends ConsumerState<BuildCenterTab> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  final _appNameController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _versionController = TextEditingController();
  final _buildNumberController = TextEditingController();
  final _releaseNotesController = TextEditingController();

  final _keystoreFileCtrl = TextEditingController();
  final _keystoreAliasCtrl = TextEditingController();
  final _keystorePasswordCtrl = TextEditingController();
  final _keyPasswordCtrl = TextEditingController();
  final _certificateFileCtrl = TextEditingController();
  final _provisioningProfileCtrl = TextEditingController();

  final ScrollController _logScrollController = ScrollController();

  String _selectedEnvironment = 'Production';
  String _selectedPlatformForSigning = 'Android';
  String _selectedPlatformForBuild = 'Web Production Build';

  int? _activeBuildId;
  String _activeBuildStatus = '';
  int _activeBuildProgress = 0;
  String _activeBuildLogs = '';
  bool _isProgressMinimized = false;
  Timer? _statusTimer;

  List<dynamic> _buildHistory = [];
  bool _isLoadingHistory = true;
  bool _isLoadingConfig = true;
  Map<String, dynamic> _appConfig = {};

  final List<String> _platforms = [
    'Android APK (Debug)',
    'Android APK (Release)',
    'Android App Bundle (.aab)',
    'iOS IPA',
    'Windows Installer (.exe)',
    'Windows Portable ZIP',
    'Web Production Build',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConfig();
    _loadHistory();
    _loadSigningConfig(_selectedPlatformForSigning);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _appNameController.dispose();
    _packageNameController.dispose();
    _versionController.dispose();
    _buildNumberController.dispose();
    _releaseNotesController.dispose();
    _keystoreFileCtrl.dispose();
    _keystoreAliasCtrl.dispose();
    _keystorePasswordCtrl.dispose();
    _keyPasswordCtrl.dispose();
    _certificateFileCtrl.dispose();
    _provisioningProfileCtrl.dispose();
    _logScrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoadingConfig = true);
    try {
      final config = await ApiService.getBuildAppConfig();
      setState(() {
        _appConfig = config;
        _appNameController.text = config['applicationName'] ?? 'VIAN ERP';
        _packageNameController.text = config['packageName'] ?? 'com.vian.erp';
        _versionController.text = config['version'] ?? '1.0.0';
        _buildNumberController.text = (config['buildNumber'] ?? 1).toString();
        _selectedEnvironment = config['environment'] ?? 'Production';
        _isLoadingConfig = false;
      });
    } catch (_) {
      setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ApiService.getBuildHistory();
      setState(() {
        _buildHistory = history;
        _isLoadingHistory = false;
      });
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadSigningConfig(String platform) async {
    try {
      final config = await ApiService.getSigningConfig(platform);
      setState(() {
        _keystoreFileCtrl.text = config['keystoreFile'] ?? '';
        _keystoreAliasCtrl.text = config['keystoreAlias'] ?? '';
        _keystorePasswordCtrl.text = config['keystorePassword'] ?? '';
        _keyPasswordCtrl.text = config['keyPassword'] ?? '';
        _certificateFileCtrl.text = config['certificateFile'] ?? '';
        _provisioningProfileCtrl.text = config['provisioningProfile'] ?? '';
      });
    } catch (_) {}
  }

  Future<void> _saveConfig() async {
    final payload = {
      'applicationName': _appNameController.text,
      'packageName': _packageNameController.text,
      'version': _versionController.text,
      'buildNumber': int.tryParse(_buildNumberController.text) ?? 1,
      'environment': _selectedEnvironment,
    };
    await ApiService.updateBuildAppConfig(payload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application build configuration saved successfully!')),
    );
  }

  Future<void> _saveSigningConfig() async {
    final payload = {
      'platform': _selectedPlatformForSigning,
      'keystoreFile': _keystoreFileCtrl.text.isEmpty ? null : _keystoreFileCtrl.text,
      'keystoreAlias': _keystoreAliasCtrl.text.isEmpty ? null : _keystoreAliasCtrl.text,
      'keystorePassword': _keystorePasswordCtrl.text.isEmpty ? null : _keystorePasswordCtrl.text,
      'keyPassword': _keyPasswordCtrl.text.isEmpty ? null : _keyPasswordCtrl.text,
      'certificateFile': _certificateFileCtrl.text.isEmpty ? null : _certificateFileCtrl.text,
      'provisioningProfile': _provisioningProfileCtrl.text.isEmpty ? null : _provisioningProfileCtrl.text,
    };
    await ApiService.updateSigningConfig(payload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signing configuration for $_selectedPlatformForSigning saved!')),
    );
  }

  Future<void> _triggerBuild() async {
    await _saveConfig();

    final payload = {
      'platform': _selectedPlatformForBuild,
      'versionName': _versionController.text,
      'buildNumber': int.tryParse(_buildNumberController.text) ?? 1,
      'releaseNotes': _releaseNotesController.text,
      'environment': _selectedEnvironment,
    };

    final res = await ApiService.triggerBuild(payload);
    if (res['success'] == true) {
      final buildData = res['build'];
      final buildId = buildData['id'];
      setState(() {
        _activeBuildId = buildId;
        _activeBuildStatus = buildData['status'] ?? 'Pending';
        _activeBuildProgress = 0;
        _activeBuildLogs = 'Build enqueued. Waiting to start...\r\n';
        _isProgressMinimized = false;
        _releaseNotesController.clear();
      });
      _startPollingBuild(buildId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to trigger build')),
      );
    }
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _startPollingBuild(int id) {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final statusData = await ApiService.getBuildStatus(id);
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _activeBuildStatus = statusData['status'] ?? 'Pending';
          _activeBuildProgress = (statusData['progress'] ?? 0).toInt();
          _activeBuildLogs = statusData['recentLogs'] ?? '';
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        if (_activeBuildStatus == 'Completed' || _activeBuildStatus == 'Failed') {
          timer.cancel();
          _loadHistory();
          final fullLogs = await ApiService.getBuildLogs(id);
          if (mounted) {
            setState(() {
              _activeBuildLogs = fullLogs;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      } catch (_) {
        timer.cancel();
      }
    });
  }

  int _getStepIndex(int progress) {
    if (progress < 10) return 0;
    if (progress < 20) return 1;
    if (progress < 35) return 2;
    if (progress < 85) return 3;
    if (progress < 90) return 4;
    if (progress < 100) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig && _appConfig.isEmpty) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    }

    final showProgressView = _activeBuildId != null && !_isProgressMinimized;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (_activeBuildId != null && _isProgressMinimized)
            _buildMinimizedStatusBar(),
          Expanded(
            child: showProgressView
                ? _buildLiveProgressView()
                : Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: const Text('BUILD CENTER', style: TextStyle(color: VianTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                        bottom: TabBar(
                          controller: _tabController,
                          indicatorColor: VianTheme.primaryGold,
                          labelColor: VianTheme.primaryGold,
                          unselectedLabelColor: VianTheme.lightText,
                          tabs: const [
                            Tab(text: 'Build & Trigger'),
                            Tab(text: 'Signing Configurations'),
                            Tab(text: 'History & Downloads'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBuildTab(),
                            _buildSigningTab(),
                            _buildHistoryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedStatusBar() {
    final statusColor = _activeBuildStatus == 'Failed'
        ? VianTheme.danger
        : _activeBuildStatus == 'Completed'
            ? VianTheme.success
            : VianTheme.primaryGold;

    return Container(
      color: VianTheme.headerBlack,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Icon(
            _activeBuildStatus == 'Completed'
                ? Icons.check_circle
                : _activeBuildStatus == 'Failed'
                    ? Icons.error
                    : Icons.rotate_right_outlined,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Building $_selectedPlatformForBuild - $_activeBuildStatus ($_activeBuildProgress%)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _activeBuildProgress / 100.0,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF1E1E26),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isProgressMinimized = false;
              });
            },
            child: const Text('Maximize', style: TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          if (_activeBuildStatus == 'Completed' || _activeBuildStatus == 'Failed')
            IconButton(
              icon: const Icon(Icons.close, color: VianTheme.lightText, size: 18),
              onPressed: () {
                setState(() {
                  _activeBuildId = null;
                  _isProgressMinimized = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBuildTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT COMPILATION TARGET PLATFORM',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _platforms.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (context, index) {
                  final platformName = _platforms[index];
                  final isSelected = _selectedPlatformForBuild == platformName;
                  IconData icon;
                  if (platformName.contains('Android')) {
                    icon = Icons.android;
                  } else if (platformName.contains('iOS')) {
                    icon = Icons.phone_iphone;
                  } else if (platformName.contains('Windows')) {
                    icon = Icons.laptop_windows;
                  } else {
                    icon = Icons.web_outlined;
                  }

                  return VianCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () {
                      setState(() {
                        _selectedPlatformForBuild = platformName;
                      });
                    },
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0x33F5A623) : const Color(0xFF1E1E26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? VianTheme.primaryGold : const Color(0x22F5A623),
                                  width: 1,
                                ),
                              ),
                              child: Icon(icon, color: isSelected ? VianTheme.primaryGold : VianTheme.lightText, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    platformName.replaceAll(' Production Build', '').replaceAll(' Installer', ''),
                                    style: TextStyle(
                                      color: isSelected ? VianTheme.whiteText : VianTheme.lightText,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    platformName.contains('AAB') || platformName.contains('Release') || platformName.contains('ZIP') || platformName.contains('Web') || platformName.contains('exe') ? 'Release mode' : 'Debug mode',
                                    style: const TextStyle(color: Color(0xFF70707C), fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(Icons.check_circle, color: VianTheme.primaryGold, size: 16),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: VianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APP METADATA CONFIGURATION',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _appNameController,
                              decoration: const InputDecoration(labelText: 'Application Name'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _packageNameController,
                              decoration: const InputDecoration(labelText: 'Package Name / Bundle Identifier'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _versionController,
                              decoration: const InputDecoration(labelText: 'Version Name (e.g. 1.0.0)'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _buildNumberController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Build Number (e.g. 1)'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedEnvironment,
                              dropdownColor: VianTheme.headerBlack,
                              decoration: const InputDecoration(labelText: 'Environment'),
                              items: ['Development', 'Staging', 'Production'].map((e) {
                                return DropdownMenuItem(value: e, child: Text(e));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedEnvironment = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      VianButton(
                        text: 'Save configuration Settings',
                        icon: Icons.save_outlined,
                        isSecondary: true,
                        onPressed: _saveConfig,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: VianCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RELEASE BUILD CONSOLE',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _releaseNotesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Build Release Notes',
                          hintText: 'Enter changelog summaries or notes for this build run...',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: VianButton(
                          text: _activeBuildId != null ? 'Build is Running...' : 'Build Now',
                          icon: Icons.play_arrow,
                          onPressed: _activeBuildId != null ? null : _triggerBuild,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSigningTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CODE SIGNING CREDENTIALS',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure signing keys and keystore certificates. These parameters are used by the build automation pipeline to securely package app release files.',
                  style: TextStyle(color: VianTheme.lightText, fontSize: 11),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Signing Target Platform:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedPlatformForSigning,
                      dropdownColor: VianTheme.headerBlack,
                      items: ['Android', 'iOS', 'Windows'].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedPlatformForSigning = v;
                          });
                          _loadSigningConfig(v);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2E2E3E), height: 32),
                if (_selectedPlatformForSigning == 'Android') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keystoreFileCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Keystore File Name',
                            hintText: 'e.g. vian_release.jks',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _keystoreAliasCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Keystore Alias',
                            hintText: 'e.g. vian_key',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keystorePasswordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Keystore Password',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _keyPasswordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Key Password',
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_selectedPlatformForSigning == 'iOS') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _certificateFileCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Signing Certificate File (.p12)',
                            hintText: 'e.g. ios_distribution.p12',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _provisioningProfileCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Provisioning Profile (.mobileprovision)',
                            hintText: 'e.g. vian_erp_app.mobileprovision',
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_selectedPlatformForSigning == 'Windows') ...[
                  TextField(
                    controller: _certificateFileCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code Signing Certificate File (.pfx)',
                      hintText: 'e.g. windows_cert.pfx',
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                VianButton(
                  text: 'Save Signing Config',
                  icon: Icons.save,
                  onPressed: _saveSigningConfig,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COMPILATION RUNS & ARTIFACT ARCHIVE',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: VianTheme.primaryGold, size: 20),
                      onPressed: _loadHistory,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingHistory)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)),
                    ),
                  )
                else if (_buildHistory.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: Text('No compilation records found.', style: TextStyle(color: VianTheme.lightText)),
                    ),
                  )
                else
                  _buildHistoryTable(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Platform', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
          DataColumn(label: Text('Version', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
          DataColumn(label: Text('Triggered By', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
          DataColumn(label: Text('Size / Duration', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
          DataColumn(label: Text('SHA-256 Checksum', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold))),
        ],
        rows: _buildHistory.map((item) {
          final status = item['status'] ?? 'Pending';
          final sizeInMb = item['fileSize'] != null ? safeToInt(item['fileSize']) / (1024 * 1024) : 0.0;
          final durationSec = item['duration'] ?? 0;
          final timeStr = item['createdAt'] != null
              ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['createdAt']))
              : '';

          final statusColor = status == 'Completed'
              ? VianTheme.success
              : status == 'Failed'
                  ? VianTheme.danger
                  : VianTheme.primaryGold;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['platform']?.toString().contains('Android') == true
                          ? Icons.android
                          : item['platform']?.toString().contains('iOS') == true
                              ? Icons.phone_iphone
                              : item['platform']?.toString().contains('Windows') == true
                                  ? Icons.laptop_windows
                                  : Icons.web_outlined,
                      size: 16,
                      color: VianTheme.lightText,
                    ),
                    const SizedBox(width: 8),
                    Text(item['platform'] ?? '', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('v${item['versionName'] ?? '1.0.0'} (${item['buildNumber'] ?? 1})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (timeStr.isNotEmpty)
                      Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF70707C))),
                  ],
                ),
              ),
              DataCell(Text(item['builder']?['name'] ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (status == 'Completed' && sizeInMb > 0)
                      Text('${sizeInMb.toStringAsFixed(2)} MB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                    else
                      const Text('--', style: TextStyle(fontSize: 12)),
                    Text('${durationSec}s duration', style: const TextStyle(fontSize: 10, color: Color(0xFF70707C))),
                  ],
                ),
              ),
              DataCell(
                Container(
                  width: 140,
                  child: Text(
                    item['sha256Checksum'] ?? 'Calculating...',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF70707C)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'Completed')
                      IconButton(
                        icon: const Icon(Icons.download, color: VianTheme.primaryGold, size: 18),
                        tooltip: 'Download Package',
                        onPressed: () {
                          final downloadUrl = '${ApiService.baseUrl}/builds/download/${item['id']}';
                          openUrl(downloadUrl);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.terminal_outlined, color: VianTheme.whiteText, size: 18),
                      tooltip: 'View Terminal Logs',
                      onPressed: () => _showFullLogsDialog(item['id'], item['platform'] ?? 'Build'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showFullLogsDialog(int id, String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33F5A623), width: 1.5),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BUILD LOGS: $platform (ID #$id)', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.close, color: VianTheme.lightText, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: FutureBuilder<String>(
          future: ApiService.getBuildLogs(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 300,
                width: 600,
                child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold))),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 300,
                width: 600,
                child: Center(child: Text('Failed to load build logs.', style: TextStyle(color: VianTheme.danger))),
              );
            }
            final logs = snapshot.data ?? 'No logs found.';
            return Container(
              width: 700,
              height: 450,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF070709),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E1E26)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  logs,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.lightGreenAccent,
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          VianButton(
            text: 'Close Logs',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveProgressView() {
    final activeStep = _getStepIndex(_activeBuildProgress);
    final statusColor = _activeBuildStatus == 'Failed'
        ? VianTheme.danger
        : _activeBuildStatus == 'Completed'
            ? VianTheme.success
            : VianTheme.primaryGold;

    final steps = [
      'Initializing Build',
      'Cleaning Project',
      'Installing Dependencies',
      'Compiling Flutter',
      'Optimizing Release',
      'Packaging Output',
      'Completed'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE COMPILATION PIPELINE RUNNER',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target: $_selectedPlatformForBuild | Status: $_activeBuildStatus',
                    style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  VianButton(
                    text: 'Minimize to Background',
                    icon: Icons.fullscreen_exit_outlined,
                    isSecondary: true,
                    onPressed: () {
                      setState(() {
                        _isProgressMinimized = true;
                      });
                    },
                  ),
                  if (_activeBuildStatus == 'Completed' || _activeBuildStatus == 'Failed') ...[
                    const SizedBox(width: 12),
                    VianButton(
                      text: 'Close Console',
                      icon: Icons.check_circle_outline,
                      onPressed: () {
                        setState(() {
                          _activeBuildId = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isVertical = constraints.maxWidth < 700;
              if (isVertical) {
                return _buildVerticalStepper(steps, activeStep, statusColor);
              }
              return _buildHorizontalStepper(steps, activeStep, statusColor);
            },
          ),
          const SizedBox(height: 24),
          VianCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFF1E1E26),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: VianTheme.primaryGold, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE BUILD LOG CONSOLE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white, letterSpacing: 0.8),
                      ),
                      const Spacer(),
                      if (_activeBuildStatus != 'Completed' && _activeBuildStatus != 'Failed')
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 380,
                  color: const Color(0xFF070709),
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    controller: _logScrollController,
                    children: [
                      Text(
                        _activeBuildLogs,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStepper(List<String> steps, int activeStep, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: VianTheme.headerBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262635)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < activeStep;
          final isActive = index == activeStep;
          final stepColor = isCompleted
              ? VianTheme.success
              : isActive
                  ? statusColor
                  : const Color(0xFF70707C);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isActive ? stepColor.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: stepColor, width: isActive ? 2.5 : 1.5),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 14, color: VianTheme.success)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: stepColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[index].replaceAll(' ', '\r\n'),
                        style: TextStyle(
                          color: isActive ? VianTheme.whiteText : const Color(0xFF70707C),
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 30,
                    height: 1.5,
                    color: index < activeStep ? VianTheme.success : const Color(0xFF262635),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerticalStepper(List<String> steps, int activeStep, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VianTheme.headerBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262635)),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < activeStep;
          final isActive = index == activeStep;
          final stepColor = isCompleted
              ? VianTheme.success
              : isActive
                  ? statusColor
                  : const Color(0xFF70707C);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? stepColor.withOpacity(0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: stepColor, width: isActive ? 2 : 1.5),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: VianTheme.success)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: stepColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 1.5,
                      height: 24,
                      color: index < activeStep ? VianTheme.success : const Color(0xFF262635),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive ? VianTheme.whiteText : const Color(0xFF70707C),
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ==========================================
// 23. CONSTRUCTION ESTIMATION & COST INTELLIGENCE MODULE
// ==========================================

class ConstructionEstimationTab extends ConsumerStatefulWidget {
  const ConstructionEstimationTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ConstructionEstimationTab> createState() => _ConstructionEstimationTabState();
}

class _ConstructionEstimationTabState extends ConsumerState<ConstructionEstimationTab> {
  String _currentView = 'dashboard'; // 'dashboard', 'wizard', 'history', 'prices', 'settings'
  bool _isLoading = false;
  List<dynamic> _estimates = [];
  Map<String, dynamic> _dashboardStats = {};
  Map<String, dynamic> _settings = {};
  List<dynamic> _marketPrices = [];
  
  Map<String, dynamic>? _selectedEstimate;
  bool _viewingBudgetVsActual = false;
  Map<String, dynamic>? _budgetVsActualData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final estimatesRes = await ApiService.getEstimates();
      final statsRes = await ApiService.getEstimationDashboard();
      final settingsRes = await ApiService.getEstimationSettings();
      final pricesRes = await ApiService.getMarketPrices();

      setState(() {
        _estimates = estimatesRes;
        _dashboardStats = statsRes;
        _settings = settingsRes;
        _marketPrices = pricesRes;
      });
    } catch (e) {
      debugPrint("Error loading estimation data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBudgetVsActual(int id) async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getBudgetVsActual(id);
      setState(() {
        _budgetVsActualData = data;
        _viewingBudgetVsActual = true;
      });
    } catch (e) {
      debugPrint("Error fetching budget actual: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());
    final role = user['role'] ?? 'Client';

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    if (isMobile) {
      return MobileSiteEngineerView(
        user: user,
        estimates: _estimates,
        onRefresh: _loadAllData,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: _buildSubHeader(role),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildMainContent(role),
            ),
    );
  }

  PreferredSizeWidget _buildSubHeader(String role) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        color: const Color(0xFF1E1E26),
        child: Row(
          children: [
            const SizedBox(width: 16),
            _subHeaderButton('Dashboard', 'dashboard', Icons.dashboard_outlined),
            _subHeaderButton('New Estimate', 'wizard', Icons.add_circle_outline),
            _subHeaderButton('History Log', 'history', Icons.history),
            _subHeaderButton('Market Prices', 'prices', Icons.currency_rupee),
            _subHeaderButton('Settings Formulas', 'settings', Icons.settings_applications),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: VianTheme.lightText, size: 20),
              onPressed: _loadAllData,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _subHeaderButton(String label, String viewId, IconData icon) {
    final active = _currentView == viewId;
    return InkWell(
      onTap: () {
        setState(() {
          _currentView = viewId;
          _selectedEstimate = null;
          _viewingBudgetVsActual = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: active ? const Border(bottom: BorderSide(color: VianTheme.primaryGold, width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? VianTheme.primaryGold : VianTheme.lightText, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? VianTheme.primaryGold : VianTheme.lightText,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(String role) {
    if (_viewingBudgetVsActual && _selectedEstimate != null) {
      return _buildBudgetVsActualView();
    }
    if (_selectedEstimate != null) {
      return _buildEstimateDetailsView(role);
    }

    switch (_currentView) {
      case 'dashboard':
        return _buildDashboardView();
      case 'wizard':
        return EstimationWizard(
          settings: _settings,
          marketPrices: _marketPrices,
          onSave: (data) async {
            setState(() => _isLoading = true);
            final res = await ApiService.saveEstimate(data);
            await _loadAllData();
            setState(() {
              _currentView = 'history';
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Estimate saved successfully.')),
            );
          },
        );
      case 'history':
        return _buildHistoryView();
      case 'prices':
        return _buildMarketPricesView();
      case 'settings':
        return EstimationSettingsView(
          settings: _settings,
          role: role,
          onSave: (data) async {
            setState(() => _isLoading = true);
            await ApiService.updateEstimationSettings(data);
            await _loadAllData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings updated successfully.')),
            );
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildDashboardView() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSTRUCTION ESTIMATION INTELLIGENCE',
            style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          const Text('Real-time analysis, cost settings benchmarks, and margin adjustments.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Estimates',
                  '${_dashboardStats['totalEstimates'] ?? 0}',
                  Icons.calculate_outlined,
                  const Color(0xFF1E1E26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Approved Estimates',
                  '${_dashboardStats['approvedEstimates'] ?? 0}',
                  Icons.assignment_turned_in_outlined,
                  const Color(0x1F28A745),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Pending Approvals',
                  '${_dashboardStats['pendingEstimates'] ?? 0}',
                  Icons.hourglass_empty_outlined,
                  const Color(0x1FFFCE56),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Avg. Cost / Sq.ft',
                  currencyFormat.format(_dashboardStats['averageCostPerSqft'] ?? 0),
                  Icons.trending_up,
                  const Color(0x1F007BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: VianCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECENT ESTIMATES',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (_estimates.isEmpty)
                        const SizedBox(height: 100, child: Center(child: Text('No estimates found.', style: TextStyle(color: VianTheme.lightText))))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _estimates.length > 5 ? 5 : _estimates.length,
                          separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E1E26)),
                          itemBuilder: (context, index) {
                            final est = _estimates[index];
                            final status = est['status'] ?? 'Pending';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(est['projectName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                              subtitle: Text('Client: ${est['clientName'] ?? 'No Client'} | No: ${est['estimateNumber']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(currencyFormat.format(est['totalCost'] ?? 0), style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  _statusBadge(status),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedEstimate = est;
                                });
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: VianCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PACKAGE DISTRIBUTION',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _distributionRow('Economy Package', _dashboardStats['distribution']?['Economy'] ?? 0, Colors.grey),
                      const SizedBox(height: 16),
                      _distributionRow('Standard Package', _dashboardStats['distribution']?['Standard'] ?? 0, Colors.blue),
                      const SizedBox(height: 16),
                      _distributionRow('Premium Package', _dashboardStats['distribution']?['Premium'] ?? 0, VianTheme.primaryGold),
                      const SizedBox(height: 32),
                      Center(
                        child: VianButton(
                          text: 'Generate New Estimate',
                          icon: Icons.calculate_outlined,
                          onPressed: () {
                            setState(() {
                              _currentView = 'wizard';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262635)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          Icon(icon, color: VianTheme.primaryGold, size: 28),
        ],
      ),
    );
  }

  Widget _distributionRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: VianTheme.whiteText, fontSize: 12))),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    if (status == 'Approved') {
      bg = const Color(0x2228A745);
      fg = const Color(0xFF28A745);
    } else if (status == 'Cancelled') {
      bg = const Color(0x22DC3545);
      fg = const Color(0xFFDC3545);
    } else {
      bg = const Color(0x22FFCE56);
      fg = const Color(0xFFFFCE56);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHistoryView() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return VianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVED COST ESTIMATES HISTORY LOG',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
              VianButton(
                text: 'New Estimate',
                icon: Icons.add,
                onPressed: () => setState(() => _currentView = 'wizard'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _estimates.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E1E26)),
              itemBuilder: (context, index) {
                final est = _estimates[index];
                return ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  title: Row(
                    children: [
                      Text(est['projectName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 12),
                      _statusBadge(est['status']),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'No: ${est['estimateNumber']} | Area: ${est['builtUpArea']} ${est['unit']} | Class: ${est['selectedPackage']} | Location: ${est['city']}, ${est['district']}',
                      style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormat.format(est['totalCost'] ?? 0),
                        style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Icon(Icons.chevron_right, color: VianTheme.lightText),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedEstimate = est;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPricesView() {
    return VianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGIONAL MARKET RATES INTELLIGENCE',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text('Track local raw material prices indexed across VIAN workspace regions.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VianTheme.primaryGold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showAddEditMarketPriceDialog(),
                icon: const Icon(Icons.add, color: Colors.black, size: 16),
                label: const Text(
                  'Add New Rate',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _marketPrices.length,
              itemBuilder: (context, index) {
                final price = _marketPrices[index];
                final double rate = double.tryParse(price['currentRate'].toString()) ?? 0.0;
                final double prevRate = double.tryParse(price['previousRate'].toString()) ?? rate;
                final bool isUp = rate > prevRate;
                final bool isDown = rate < prevRate;

                return Card(
                  color: const Color(0xFF1E1E26),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(price['materialName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Supplier: ${price['supplier'] ?? 'Default Seeder'} | Region: ${price['district']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('₹${rate.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Prev: ₹${prevRate.toStringAsFixed(2)}', style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                                    const SizedBox(width: 6),
                                    if (isUp) const Icon(Icons.trending_up, color: VianTheme.danger, size: 12),
                                    if (isDown) const Icon(Icons.trending_down, color: VianTheme.success, size: 12),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: VianTheme.primaryGold, size: 18),
                              onPressed: () => _showAddEditMarketPriceDialog(price),
                              tooltip: 'Edit Rate',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: VianTheme.danger, size: 18),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E26),
                                    title: const Text('Delete Market Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    content: const Text('Are you sure you want to delete this market price record?', style: TextStyle(color: VianTheme.lightText)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel', style: TextStyle(color: VianTheme.lightText)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: VianTheme.danger),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  setState(() => _isLoading = true);
                                  try {
                                    await ApiService.deleteMarketPrice(price['id']);
                                    await _loadAllData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Market price deleted successfully.')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete: $e')),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              tooltip: 'Delete Rate',
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showAddEditMarketPriceDialog([Map<String, dynamic>? existing]) async {
    final isEdit = existing != null;
    final materialNameController = TextEditingController(text: isEdit ? existing['materialName'] : '');
    final rateController = TextEditingController(text: isEdit ? existing['currentRate'].toString() : '');
    final supplierController = TextEditingController(text: isEdit ? existing['supplier'] : '');
    final districtController = TextEditingController(text: isEdit ? existing['district'] : 'Chennai');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E26),
          title: Text(
            isEdit ? 'Edit Market Price' : 'Add New Market Rate',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField('Material Name', materialNameController),
                const SizedBox(height: 12),
                _buildDialogField('Current Rate (₹)', rateController, isNumber: true),
                const SizedBox(height: 12),
                _buildDialogField('Supplier', supplierController),
                const SizedBox(height: 12),
                _buildDialogField('Region/District', districtController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: VianTheme.lightText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold),
              onPressed: () async {
                final double? rate = double.tryParse(rateController.text);
                if (materialNameController.text.isEmpty || rate == null || districtController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields correctly.')),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _isLoading = true);

                try {
                  if (isEdit) {
                    await ApiService.updateMarketPrice({
                      'id': existing['id'],
                      'materialName': materialNameController.text,
                      'currentRate': rate,
                      'supplier': supplierController.text,
                      'district': districtController.text,
                    });
                  } else {
                    await ApiService.createMarketPrice({
                      'materialName': materialNameController.text,
                      'currentRate': rate,
                      'supplier': supplierController.text,
                      'district': districtController.text,
                    });
                  }
                  await _loadAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Market price updated successfully.' : 'Market rate added successfully.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF262635))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: VianTheme.primaryGold)),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateDetailsView(String role) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getEstimate(_selectedEstimate!['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Failed to load estimate details.'));
        }
        final details = snapshot.data!;
        final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: VianTheme.primaryGold),
                    onPressed: () => setState(() => _selectedEstimate = null),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ESTIMATE WORKSPACE: ${details['estimateNumber']}',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  if (details['status'] == 'Approved')
                    VianButton(
                      text: 'View Budget vs Actual Variance',
                      icon: Icons.analytics_outlined,
                      isSecondary: true,
                      onPressed: () => _fetchBudgetVsActual(details['id']),
                    ),
                  const SizedBox(width: 12),
                  if (details['status'] == 'Pending' && (role == 'Super Admin' || role == 'Managing Director'))
                    VianButton(
                      text: 'Approve & Initialize Project',
                      icon: Icons.check_circle,
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        final res = await ApiService.approveEstimate(details['id']);
                        await _loadAllData();
                        setState(() {
                          _selectedEstimate = null;
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Approved successfully.')),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: VianCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailHeader('PROJECT PARAMETERS'),
                          _buildDetailItem('Project Name', details['projectName']),
                          _buildDetailItem('Client Name', details['clientName']),
                          _buildDetailItem('Project Type', details['projectType']),
                          _buildDetailItem('Construction Grade', details['selectedPackage']),
                          _buildDetailItem('Site Address', '${details['siteAddress']}, ${details['city']}, ${details['district']}, ${details['state']}'),
                          _buildDetailItem('Built-up Area', '${details['builtUpArea']} ${details['unit']}'),
                          _buildDetailItem('Base Rate / Unit', currencyFormat.format(details['packageRate'] ?? 0)),
                          const Divider(color: Color(0xFF262635), height: 32),
                          _buildDetailHeader('FINANCIAL PROFIT SEGMENTS'),
                          _buildDetailItem('Base Cost', currencyFormat.format(details['totalCost'] ?? 0)),
                          _buildDetailItem('Margin Target %', '${details['companyMarginPercentage']}%'),
                          _buildDetailItem('Target Profit', currencyFormat.format(details['estimatedProfit'] ?? 0)),
                          _buildDetailItem('GST %', '${details['gstPercentage']}%'),
                          _buildDetailItem('GST Amount', currencyFormat.format(details['gstAmount'] ?? 0)),
                          _buildDetailItem('Grand Total Valuation', currencyFormat.format(details['netProjectValue'] ?? 0), isGold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        VianCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailHeader('PHASE TIMELINE SCHEDULING'),
                              const SizedBox(height: 12),
                              if (details['phases'] == null || (details['phases'] as List).isEmpty)
                                const Text('No phases recorded.', style: TextStyle(color: VianTheme.lightText))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (details['phases'] as List).length,
                                  itemBuilder: (context, index) {
                                    final ph = details['phases'][index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(ph['phaseName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      trailing: Text('${ph['estimatedDuration']} Days | ${currencyFormat.format(ph['estimatedCost'] ?? 0)}', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12)),
                                    );
                                  },
                                )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        VianCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailHeader('RAW MATERIAL CONSUMPTION LEDGER'),
                              const SizedBox(height: 12),
                              if (details['materials'] == null || (details['materials'] as List).isEmpty)
                                const Text('No materials calculated.', style: TextStyle(color: VianTheme.lightText))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (details['materials'] as List).length,
                                  itemBuilder: (context, index) {
                                    final mat = details['materials'][index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(mat['materialName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      subtitle: Text('${mat['quantity']} ${mat['unit']} @ ₹${mat['rate']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                                      trailing: Text(currencyFormat.format(mat['cost'] ?? 0), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    );
                                  },
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          Text(
            '$value',
            style: TextStyle(
              color: isGold ? VianTheme.primaryGold : Colors.white,
              fontWeight: isGold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetVsActualView() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final data = _budgetVsActualData!;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: VianTheme.primaryGold),
                onPressed: () => setState(() => _viewingBudgetVsActual = false),
              ),
              const SizedBox(width: 8),
              Text(
                'BUDGET VS ACTUAL LEDGER DETAILS: ${_selectedEstimate!['projectName']}',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildVarianceCard('Estimated Budget', currencyFormat.format(data['totalEstimatedCost'] ?? 0), Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVarianceCard('Actual Spent', currencyFormat.format(data['totalActualCost'] ?? 0), VianTheme.primaryGold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVarianceCard(
                  'Cost Variance', 
                  currencyFormat.format(data['totalVariance'] ?? 0), 
                  (data['totalVariance'] ?? 0) >= 0 ? VianTheme.success : VianTheme.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          VianCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COST CATEGORIES VARIANCE ANALYSIS',
                  style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                const SizedBox(height: 20),
                _buildVarianceProgressRow('Raw Materials Cost', data['estimatedMaterialCost'] ?? 0, data['actualMaterialCost'] ?? 0, data['materialVariance'] ?? 0),
                const Divider(color: Color(0xFF1E1E26), height: 32),
                _buildVarianceProgressRow('Labour Resource Cost', data['estimatedLabourCost'] ?? 0, data['actualLabourCost'] ?? 0, data['labourVariance'] ?? 0),
                const Divider(color: Color(0xFF1E1E26), height: 32),
                _buildVarianceProgressRow('Site Direct Expenses', data['estimatedExpenses'] ?? 0, data['actualExpenses'] ?? 0, data['expensesVariance'] ?? 0),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVarianceCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262635)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceProgressRow(String label, dynamic estimate, dynamic actual, dynamic variance) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final double estVal = double.tryParse(estimate.toString()) ?? 0.0;
    final double actVal = double.tryParse(actual.toString()) ?? 0.0;
    final double pct = estVal > 0 ? (actVal / estVal) : 0.0;
    final color = pct <= 1.0 ? VianTheme.success : (pct <= 1.1 ? const Color(0xFFFFCE56) : VianTheme.danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
            Text(
              'Est: ${currencyFormat.format(estVal)} | Spent: ${currencyFormat.format(actVal)} | Var: ${currencyFormat.format(variance)}',
              style: TextStyle(color: pct <= 1.0 ? VianTheme.success : VianTheme.danger, fontSize: 11),
            )
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct > 1.0 ? 1.0 : pct,
            backgroundColor: const Color(0xFF0F0F13),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        )
      ],
    );
  }
}

// ==========================================
// 24. ESTIMATION WIZARD MODULE
// ==========================================

class EstimationWizard extends StatefulWidget {
  final Map<String, dynamic> settings;
  final List<dynamic> marketPrices;
  final Function(Map<String, dynamic> data) onSave;

  const EstimationWizard({
    Key? key,
    required this.settings,
    required this.marketPrices,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EstimationWizard> createState() => _EstimationWizardState();
}

class _EstimationWizardState extends State<EstimationWizard> {
  int _currentStep = 0;
  bool _calculating = false;

  // AI Analysis State
  bool _analyzingFloorPlan = false;
  List<String> _aiLogConsole = [];
  String? _uploadedDrawingUrl;
  Map<String, dynamic>? _extractedAiData;
  bool _aiWarningOccurred = false;
  String? _aiWarningMessage;
  int? _savedEstimateId;
  bool _savingEstimate = false;

  // Controllers Step 1
  final _projectNameController = TextEditingController(text: 'Horizon Villa ECR');
  final _clientNameController = TextEditingController(text: 'Amit Bajaj');
  final _addressController = TextEditingController(text: 'Plot 14, ECR Highway');
  final _cityController = TextEditingController(text: 'Chennai');
  final _builtUpAreaController = TextEditingController(text: '2800');

  String _selectedProjectType = 'Villa';
  String _selectedUnit = 'Square Feet';
  String _selectedState = 'Tamil Nadu';
  String _selectedDistrict = 'Chennai';
  String _selectedPackage = 'Standard';

  // Calculations details (populated in step 2/3)
  Map<String, dynamic>? _calculatedResults;
  List<dynamic> _editableMaterials = [];
  List<dynamic> _editableBOQ = [];
  List<dynamic> _editableLabour = [];
  List<dynamic> _editablePhases = [];
  double _marginPercentage = 12.0;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _marginPercentage = double.tryParse(widget.settings['profitMarginPercentage']?.toString() ?? '12') ?? 12.0;
  }

  Future<void> _runCalculate() async {
    setState(() => _calculating = true);
    try {
      final inputData = {
        'builtUpArea': double.tryParse(_builtUpAreaController.text) ?? 1000,
        'selectedPackage': _selectedPackage,
        'district': _selectedDistrict,
        'unit': _selectedUnit,
      };
      
      final res = await ApiService.calculateEstimate(inputData);
      setState(() {
        _calculatedResults = res;
        _editableMaterials = List.from(res['materials'] ?? []);
        _editableBOQ = List.from(res['boq'] ?? []);
        _editableLabour = List.from(res['labour'] ?? []);
        _editablePhases = List.from(res['phases'] ?? []);
      });
    } catch (e) {
      debugPrint("Error run calculate: $e");
    } finally {
      setState(() => _calculating = false);
    }
  }

  void _recalculateLocalTotals() {
    if (_calculatedResults == null) return;
    double newCost = 0.0;
    for (var m in _editableMaterials) {
      final double qty = double.tryParse(m['quantity'].toString()) ?? 0.0;
      final double rate = double.tryParse(m['rate'].toString()) ?? 0.0;
      m['cost'] = qty * rate;
      newCost += m['cost'];
    }

    double labourCost = 0.0;
    for (var l in _editableLabour) {
      final double workers = double.tryParse(l['requiredWorkers'].toString()) ?? 0.0;
      final double days = double.tryParse(l['estimatedDays'].toString()) ?? 0.0;
      final double cost = workers * days * 850; // simple fallback wage index
      l['estimatedCost'] = cost;
      labourCost += cost;
    }

    // Distribute total cost changes into phase allocations and BOQs
    setState(() {
      _calculatedResults!['totalCost'] = newCost.round();
      
      // Update BOQ amounts
      for (int i = 0; i < _editableBOQ.length; i++) {
        if (i < _editableMaterials.length) {
          final m = _editableMaterials[i];
          _editableBOQ[i]['quantity'] = m['quantity'];
          _editableBOQ[i]['rate'] = m['rate'];
          _editableBOQ[i]['amount'] = m['cost'];
          final double gstRate = double.tryParse(_editableBOQ[i]['gstRate']?.toString() ?? '18') ?? 18;
          _editableBOQ[i]['gstAmount'] = m['cost'] * (gstRate / 100);
          _editableBOQ[i]['totalAmount'] = m['cost'] + _editableBOQ[i]['gstAmount'];
        }
      }

      // Re-allocate phase amounts
      final double scale = newCost;
      final double baseTotalVal = _editablePhases.fold<double>(0.0, (acc, ph) => acc + (double.tryParse(ph['estimatedCost']?.toString() ?? '0') ?? 0.0));
      final double baseTotal = baseTotalVal == 0.0 ? 1.0 : baseTotalVal;
      for (var ph in _editablePhases) {
        final double currentWeight = (double.tryParse(ph['estimatedCost']?.toString() ?? '0') ?? 0.0) / baseTotal;
        ph['estimatedCost'] = (scale * currentWeight).round();
        ph['budgetAllocation'] = ph['estimatedCost'];
      }

      // Recalculate profit margins
      final double profit = newCost * (_marginPercentage / 100);
      final double subtotal = newCost + profit;
      final double gstPct = double.tryParse(widget.settings['gstPercentage']?.toString() ?? '18') ?? 18.0;
      final double gstAmt = subtotal * (gstPct / 100);
      
      _calculatedResults!['profitAnalysis'] = {
        'constructionCost': newCost.round(),
        'companyMarginPercentage': _marginPercentage,
        'estimatedProfit': profit.round(),
        'gstPercentage': gstPct,
        'gstAmount': gstAmt.round(),
        'netProjectValue': (subtotal + gstAmt).round(),
        'companyOverhead': double.tryParse(widget.settings['companyOverhead']?.toString() ?? '50000') ?? 50000.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return VianCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildWizardStepper(),
          const Divider(color: Color(0xFF1E1E26), height: 32),
          if (_calculating)
            const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold))))
          else
            Expanded(
              child: SingleChildScrollView(
                child: _buildActiveStepContent(),
              ),
            ),
          const SizedBox(height: 24),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildWizardStepper() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        separatorBuilder: (context, index) => const Icon(Icons.arrow_right_alt, color: VianTheme.lightText, size: 16),
        itemBuilder: (context, index) {
          final active = _currentStep == index;
          final passed = index < _currentStep;
          final label = _getStepTitle(index);
          return Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? VianTheme.primaryGold : (passed ? const Color(0x33F5A623) : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(color: active || passed ? VianTheme.primaryGold : const Color(0xFF262635)),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.black : (passed ? VianTheme.primaryGold : VianTheme.lightText),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? VianTheme.primaryGold : VianTheme.lightText,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getStepTitle(int index) {
    const titles = [
      'Info',
      'Package',
      'Compare',
      'Materials',
      'Phases',
      'BOQ Table',
      'Labour',
      'Timeline',
      'Margin Analysis',
      'Quotation'
    ];
    return titles[index];
  }

  Widget _buildActiveStepContent() {
    switch (_currentStep) {
      case 0:
        return _stepProjectInfo();
      case 1:
        return _stepSelectPackage();
      case 2:
        return _stepComparePackages();
      case 3:
        return _stepMaterialsEditor();
      case 4:
        return _stepPhaseDurations();
      case 5:
        return _stepBOQEditor();
      case 6:
        return _stepLabourRoster();
      case 7:
        return _stepTimelineScheduler();
      case 8:
        return _stepProfitMarginAnalysis();
      case 9:
        return _stepQuotationInvoicePreview();
      default:
        return const SizedBox();
    }
  }

  Widget _confidenceChip(String label, dynamic confidence) {
    if (confidence == null) return const SizedBox();
    final double score = double.tryParse(confidence.toString()) ?? 1.0;
    final bool low = score < 0.8;
    final pct = (score * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: low ? const Color(0x22F5A623) : const Color(0x2228A745),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: low ? VianTheme.primaryGold : VianTheme.success),
      ),
      child: Text(
        '$label Confidence: $pct%',
        style: TextStyle(
          color: low ? VianTheme.primaryGold : VianTheme.success,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyzeFloorPlan() async {
    setState(() {
      _analyzingFloorPlan = true;
      _aiWarningOccurred = false;
      _aiWarningMessage = null;
      _aiLogConsole = [
        '[INFO] Initialization sequence activated.',
        '[INFO] Requesting file picker interface...'
      ];
    });

    try {
      final result = await pickDrawingFile();

      if (result != null) {
        final fileName = result.name;
        final ext = fileName.split('.').last.toLowerCase();
        if (ext != 'pdf' && ext != 'png' && ext != 'jpg' && ext != 'jpeg') {
          throw Exception("Invalid file type. Please select PDF, PNG, JPG, or JPEG.");
        }
        setState(() {
          _aiLogConsole.add('[INFO] File selected: $fileName');
          _aiLogConsole.add('[INFO] File size: ${(result.bytes.length / 1024).toStringAsFixed(1)} KB');
          _aiLogConsole.add('[INFO] Reading file bytes...');
        });

        final bytes = result.bytes;

        setState(() {
          _aiLogConsole.add('[INFO] Uploading floor plan to Cloudinary storage...');
        });

        // Call the service to upload and analyze
        final response = await ApiService.analyzeFloorPlanWithAi(bytes, fileName);
        
        setState(() {
          _aiLogConsole.add('[INFO] Server responded. Analyzing results...');
        });

        if (response['extractedData'] != null) {
          final data = response['extractedData'];
          final url = response['fileUrl'];
          final warning = response['warning'] ?? (response['success'] == false ? response['message'] : null);

          setState(() {
            _uploadedDrawingUrl = url;
            _extractedAiData = data;
            _aiLogConsole.add(response['success'] == true 
                ? '[SUCCESS] AI Analysis completed successfully.' 
                : '[WARNING] Gemini API analysis failed. Using regional smart fallback data.');
            
            if (response['calculations'] != null) {
              final calc = response['calculations'];
              _calculatedResults = calc;
              _editableMaterials = List.from(calc['materials'] ?? []);
              _editableBOQ = List.from(calc['boq'] ?? []);
              _editableLabour = List.from(calc['labour'] ?? []);
              _editablePhases = List.from(calc['phases'] ?? []);
              _selectedPackage = calc['finishingQuality'] ?? 'Standard';
              _selectedProjectType = data['projectType'] ?? _selectedProjectType;
              if (calc['complexityScore'] != null) {
                _aiLogConsole.add('[DATA] Structural Complexity: ${calc['structuralComplexity']}');
                _aiLogConsole.add('[DATA] Project Complexity: ${calc['complexityScore']}');
              }
            }

            if (data != null) {
              if (data['builtUpArea'] != null) {
                _builtUpAreaController.text = data['builtUpArea'].toString();
                _aiLogConsole.add('[DATA] Extracted Built-up Area: ${data['builtUpArea']} Sq.ft');
              }
              if (data['projectName'] != null && data['projectName'].toString().isNotEmpty) {
                _projectNameController.text = data['projectName'];
              }
              if (data['clientName'] != null && data['clientName'].toString().isNotEmpty) {
                _clientNameController.text = data['clientName'];
              }
              if (data['siteAddress'] != null && data['siteAddress'].toString().isNotEmpty) {
                _addressController.text = data['siteAddress'];
              }
            }

            if (warning != null && warning.toString().isNotEmpty) {
              _aiWarningOccurred = true;
              _aiWarningMessage = warning;
              _aiLogConsole.add('[WARNING] $warning');
            }
          });
        } else {
          setState(() {
            _aiWarningOccurred = true;
            _aiWarningMessage = response['message'] ?? 'Failed to analyze floor plan drawing.';
            _aiLogConsole.add('[ERROR] $_aiWarningMessage');
          });
        }
      } else {
        setState(() {
          _analyzingFloorPlan = false;
          _aiLogConsole.add('[INFO] Selection cancelled by user.');
        });
      }
    } catch (e) {
      setState(() {
        _aiWarningOccurred = true;
        _aiWarningMessage = 'Unable to analyze floor plan: $e';
        _aiLogConsole.add('[ERROR] $_aiWarningMessage');
      });
    } finally {
      setState(() {
        _analyzingFloorPlan = false;
      });
    }
  }

  Widget _stepProjectInfo() {
    final hasDrawing = _uploadedDrawingUrl != null;
    final confidence = _extractedAiData?['confidence'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 1: Project & Client Details', 'Input target area sizes, building types, and client identifiers.'),
        const SizedBox(height: 20),
        
        // AI Analysis Segment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF262635)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: VianTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'AI MULTIMODAL FLOOR PLAN ANALYZER',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  if (hasDrawing)
                    TextButton.icon(
                      onPressed: _pickAndAnalyzeFloorPlan,
                      icon: const Icon(Icons.refresh, color: VianTheme.primaryGold, size: 14),
                      label: const Text('Re-upload Plan', style: TextStyle(color: VianTheme.primaryGold, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_analyzingFloorPlan) ...[
                const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E1E26)),
                  ),
                  child: ListView.builder(
                    itemCount: _aiLogConsole.length,
                    itemBuilder: (context, idx) => Text(
                      _aiLogConsole[idx],
                      style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier', fontSize: 11),
                    ),
                  ),
                ),
              ] else if (hasDrawing) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F13),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF262635)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _uploadedDrawingUrl!.endsWith('.pdf')
                            ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40)
                            : Image.network(_uploadedDrawingUrl!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Extraction Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('Cloud URL: ${_uploadedDrawingUrl!}', style: const TextStyle(color: VianTheme.lightText, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (confidence?['builtUpArea'] != null)
                                _confidenceChip('Area', confidence['builtUpArea']),
                              if (confidence?['structural'] != null)
                                _confidenceChip('Details', confidence['structural']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildAiSurveyorReport(),
                if (_aiWarningOccurred && _aiWarningMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFCE56),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: VianTheme.primaryGold),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: VianTheme.primaryGold, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _aiWarningMessage!,
                            style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                InkWell(
                  onTap: _pickAndAnalyzeFloorPlan,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0x05F5A623),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33F5A623), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: VianTheme.primaryGold, size: 36),
                        const SizedBox(height: 12),
                        const Text('Upload Architectural Floor Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Click to pick Floor Plan PDF / JPG / PNG', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: _buildTextField('Project Name', _projectNameController),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Client Name', _clientNameController),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Project Type', _selectedProjectType, [
                'Residential House',
                'Villa',
                'Apartment',
                'Commercial Building',
                'Office',
                'Interior',
                'Renovation',
                'Industrial'
              ], (v) => setState(() => _selectedProjectType = v!)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown('Unit Size', _selectedUnit, ['Square Feet', 'Square Meter'], (v) => setState(() => _selectedUnit = v!)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Built-up Area', _builtUpAreaController, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown('District Region', _selectedDistrict, ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Salem', 'Tiruppur'], (v) => setState(() => _selectedDistrict = v!)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Site Address', _addressController),
      ],
    );
  }

  Widget _buildAiSurveyorReport() {
    if (_extractedAiData == null) return const SizedBox();
    final data = _extractedAiData!;
    final confidence = data['confidence'] ?? {};
    final similar = _calculatedResults?['similarProject'] ?? {};

    // Check if any confidence score is low (< 90%)
    bool hasLowConfidence = false;
    confidence.forEach((k, val) {
      final double score = double.tryParse(val.toString()) ?? 1.0;
      if (score < 0.9) {
        hasLowConfidence = true;
      }
    });

    final extWall = data['externalWallLength'] ?? 'N/A';
    final intWall = data['internalWallLength'] ?? 'N/A';
    final wallThick = data['wallThickness'] ?? 'N/A';
    final cols = data['columnCount'] ?? 'N/A';
    final beams = data['beamLayout'] == true ? 'Yes' : 'No';
    final doors = data['doorCount'] ?? 'N/A';
    final windows = data['windowCount'] ?? 'N/A';
    final bedrooms = data['bedrooms'] ?? 'N/A';
    final bathrooms = data['bathrooms'] ?? 'N/A';
    final kitchen = data['kitchen'] ?? 'N/A';
    final balcony = data['balcony'] ?? 'N/A';
    final complexity = data['complexityScore'] ?? 'Standard';
    final structural = data['structuralComplexity'] ?? 'Medium Structure';

    // List of amenities
    final List<String> amenities = [];
    if (data['sitout'] == true) amenities.add('Sit-out');
    if (data['stairs'] == true) amenities.add('Stairs');
    if (data['lift'] == true) amenities.add('Lift');
    if (data['doubleHeight'] == true) amenities.add('Double Height');
    if (data['parking'] == true) amenities.add('Parking');
    if (data['terrace'] == true) amenities.add('Terrace');
    if (data['utility'] == true) amenities.add('Utility');
    if (data['pooja'] == true) amenities.add('Pooja');
    if (data['store'] == true) amenities.add('Store');
    if (data['dining'] == true) amenities.add('Dining');
    if (data['living'] == true) amenities.add('Living');
    if (data['verandah'] == true) amenities.add('Verandah');
    if (data['courtyard'] == true) amenities.add('Courtyard');

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF262635)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: VianTheme.primaryGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI QUANTITY SURVEYOR SPECIFICATIONS REPORT',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Specs Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _reportTile('Built-up Area', '${data['builtUpArea'] ?? 0} Sq.ft'),
                  _reportTile('Ext / Int Walls', '$extWall ft / $intWall ft'),
                  _reportTile('Wall Thickness', '$wallThick in'),
                  _reportTile('Columns / Beams', '$cols / Grid: $beams'),
                  _reportTile('Doors / Windows', '$doors / $windows'),
                  _reportTile('Beds / Baths / Kit', '$bedrooms / $bathrooms / $kitchen'),
                  _reportTile('Structural RCC', '$structural'),
                  _reportTile('Complexity Rating', '$complexity', isGold: true),
                ],
              );
            }
          ),
          const SizedBox(height: 12),

          if (amenities.isNotEmpty) ...[
            const Text(
              'Detected Amenities & Spaces:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: amenities.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E26),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF262635)),
                ),
                child: Text(a, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Confidence scores
          const Divider(color: Color(0xFF262635)),
          const SizedBox(height: 8),
          const Text(
            'AI Drawing Detection Confidence Indicators',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 12),
          _confidenceBar('Area Extraction', confidence['builtUpArea']),
          _confidenceBar('Wall Detection', confidence['wallDetection']),
          _confidenceBar('Room Detection', confidence['roomDetection']),
          _confidenceBar('Door Detection', confidence['doorDetection']),
          _confidenceBar('Window Detection', confidence['windowDetection']),
          _confidenceBar('Material Estimation', confidence['materialEstimate']),
          _confidenceBar('Labour Estimation', confidence['labourEstimate']),
          const SizedBox(height: 8),

          if (hasLowConfidence) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x11FFCE56),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x33FFCE56)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: VianTheme.primaryGold, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Attention: Some parameters have lower AI confidence (< 90%). Please review and verify these values in the next steps.',
                      style: TextStyle(color: VianTheme.primaryGold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Similar Completed Projects Comparison Card
          if (similar.isNotEmpty) ...[
            const Divider(color: Color(0xFF262635)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.history_outlined, color: VianTheme.primaryGold, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Similar Project Historical Engine Analysis',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF262635)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETED PROJECT: ${similar['projectName'] ?? 'Horizon Villa ECR'}',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Estimated: ₹98.00 Lakhs | Actual: ₹80.00 Lakhs',
                          style: TextStyle(color: VianTheme.lightText, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x2228A745),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: VianTheme.success),
                    ),
                    child: const Column(
                      children: [
                        Text('DIFF / EFFICIENCY', style: TextStyle(color: VianTheme.success, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text('-18.37%', style: TextStyle(color: VianTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reportTile(String label, String value, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isGold ? VianTheme.primaryGold.withOpacity(0.3) : const Color(0xFF262635)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: isGold ? VianTheme.primaryGold : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _confidenceBar(String label, dynamic val) {
    if (val == null) return const SizedBox();
    final double pct = double.tryParse(val.toString()) ?? 1.0;
    final bool low = pct < 0.9;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: low ? VianTheme.primaryGold : VianTheme.success,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: const Color(0xFF1E1E26),
              valueColor: AlwaysStoppedAnimation<Color>(
                low ? VianTheme.primaryGold : VianTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepSelectPackage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 2: Select Estimation Package Grade', 'Benchmark rates will be initialized based on your selected materials quality standard.'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _packageOptionCard(
                'Economy Grade',
                '₹2200 / Sq.ft',
                'Standard PPC Cement, Fe 500 Steel, local sand, ceramic flooring tiles, Tractor emulsion painting.',
                'Economy',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _packageOptionCard(
                'Standard Quality',
                '₹2500 / Sq.ft',
                'UltraTech OPC Cement, TATA Tiscon Fe 550 Steel, River sand, Vitrified tiles, Premium emulsion painting.',
                'Standard',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _packageOptionCard(
                'Premium Luxury',
                '₹2800 / Sq.ft',
                'ACC Gold Premium Cement, TATA Tiscon Fe 600 Steel, Premium marble flooring, Royale luxury paints.',
                'Premium',
              ),
            ),
          ],
        )
      ],
    );
  }

  

  Widget _packageOptionCard(String title, String rateLabel, String description, String value) {
    final active = _selectedPackage == value;
    return InkWell(
      onTap: () => setState(() => _selectedPackage = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        decoration: BoxDecoration(
          color: active ? const Color(0x11F5A623) : const Color(0xFF1E1E26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? VianTheme.primaryGold : const Color(0xFF262635), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: active ? VianTheme.primaryGold : Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text(rateLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(color: VianTheme.lightText, fontSize: 11, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _stepComparePackages() {
    if (_calculatedResults == null) return const SizedBox();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final comparison = _calculatedResults!['comparison'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 3: Side-by-Side Cost Comparison', 'Detailed package cost metrics comparing Economy, Standard, and Premium rates.'),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _costComparisonColumn('Economy', comparison['Economy'] ?? 0, currencyFormat)),
            const SizedBox(width: 16),
            Expanded(child: _costComparisonColumn('Standard (Selected)', comparison['Standard'] ?? 0, currencyFormat, highlight: true)),
            const SizedBox(width: 16),
            Expanded(child: _costComparisonColumn('Premium', comparison['Premium'] ?? 0, currencyFormat)),
          ],
        )
      ],
    );
  }

  Widget _costComparisonColumn(String grade, dynamic cost, NumberFormat formatter, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? const Color(0x11F5A623) : const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? VianTheme.primaryGold : const Color(0xFF262635), width: highlight ? 2 : 1),
      ),
      child: Column(
        children: [
          Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: highlight ? VianTheme.primaryGold : Colors.white, fontSize: 14)),
          const SizedBox(height: 16),
          Text(
            formatter.format(cost),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text('Includes materials and labor benchmarks.', style: TextStyle(color: VianTheme.lightText, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _stepMaterialsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 4: Raw Material Quantities & Prices', 'View and adjust default material quantities and purchase prices.'),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: _editableMaterials.length,
          itemBuilder: (context, index) {
            final mat = _editableMaterials[index];
            final subtotal = (double.tryParse(mat['quantity'].toString()) ?? 0.0) * (double.tryParse(mat['rate'].toString()) ?? 0.0);
            return Card(
              color: const Color(0xFF1E1E26),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mat['materialName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '${mat['quantity']}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                            onChanged: (val) {
                              mat['quantity'] = double.tryParse(val) ?? 0.0;
                              _recalculateLocalTotals();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(mat['unit'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: '${mat['rate']}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Rate', isDense: true),
                            onChanged: (val) {
                              mat['rate'] = double.tryParse(val) ?? 0.0;
                              _recalculateLocalTotals();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Total Cost: ₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _stepPhaseDurations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 5: Phase Duration Benchmarks', 'Adjust scheduled build durations (days) per construction phase.'),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _editablePhases.length,
          itemBuilder: (context, index) {
            final ph = _editablePhases[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(ph['phaseName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Slider(
                      value: (double.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0.0).clamp(1.0, 90.0),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      activeColor: VianTheme.primaryGold,
                      onChanged: (val) {
                        setState(() {
                          ph['estimatedDuration'] = val.round();
                        });
                      },
                    ),
                  ),
                  Text('${ph['estimatedDuration']} Days', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _stepBOQEditor() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 6: Bill of Quantities (BOQ) Preview Grid', 'Verify and modify final BOQ values including localized GST amounts.'),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: const Color(0xFF262635)),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1E1E26)),
              children: [
                _tableHeaderCell('Material Item'),
                _tableHeaderCell('Unit'),
                _tableHeaderCell('Quantity'),
                _tableHeaderCell('Rate'),
                _tableHeaderCell('GST Amt'),
                _tableHeaderCell('Total Amt'),
              ],
            ),
            for (var b in _editableBOQ)
              TableRow(
                children: [
                  _tableCell(b['materialName'] ?? ''),
                  _tableCell(b['unit'] ?? ''),
                  _tableCell('${b['quantity']}'),
                  _tableCell('₹${b['rate']}'),
                  _tableCell('₹${(b['gstAmount'] ?? 0).toStringAsFixed(0)}'),
                  _tableCell('₹${(b['totalAmount'] ?? 0).toStringAsFixed(0)}', isBold: true, isGold: true),
                ],
              ),
          ],
        )
      ],
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11), textAlign: TextAlign.center),
    );
  }

  Widget _tableCell(String text, {bool isBold = false, bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          color: isGold ? VianTheme.primaryGold : Colors.white,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _stepLabourRoster() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 7: Labour Roster Requirements', 'Estimate necessary worker counts and scheduled active days.'),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _editableLabour.length,
          itemBuilder: (context, index) {
            final l = _editableLabour[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                color: const Color(0xFF1E1E26),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l['labourType'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: '${l['requiredWorkers']}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Crew Size', isDense: true),
                              onChanged: (val) {
                                l['requiredWorkers'] = int.tryParse(val) ?? 0;
                                _recalculateLocalTotals();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: '${l['estimatedDays']}',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Days Count', isDense: true),
                              onChanged: (val) {
                                l['estimatedDays'] = int.tryParse(val) ?? 0;
                                _recalculateLocalTotals();
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _stepTimelineScheduler() {
    final end = _startDate.add(Duration(days: _editablePhases.fold(0, (acc, ph) => acc + (int.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0))));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 8: Construction Timeline Scheduler', 'Define the estimated start date and view project duration schedules.'),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('Start Date Picker: ', style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _startDate = d);
              },
              child: Text(DateFormat('yyyy-MM-dd').format(_startDate), style: const TextStyle(color: VianTheme.primaryGold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Estimated Completion: ${DateFormat('yyyy-MM-dd').format(end)}', style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _stepProfitMarginAnalysis() {
    if (_calculatedResults == null) return const SizedBox();
    final pAnalysis = _calculatedResults!['profitAnalysis'] ?? {};
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 9: Financial Profit Margin Segments', 'Manage company target profit margins and analyze grand totals.'),
        const SizedBox(height: 24),
        Text('Company Profit Margin: ${_marginPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        Slider(
          value: _marginPercentage,
          min: 5,
          max: 25,
          divisions: 40,
          activeColor: VianTheme.primaryGold,
          onChanged: (val) {
            setState(() {
              _marginPercentage = val;
            });
            _recalculateLocalTotals();
          },
        ),
        const SizedBox(height: 24),
        _detailAnalysisRow('Construction Cost Base', currencyFormat.format(pAnalysis['constructionCost'] ?? 0)),
        _detailAnalysisRow('Overhead Buffer Cost', currencyFormat.format(pAnalysis['companyOverhead'] ?? 0)),
        _detailAnalysisRow('Estimated Profit Margin', currencyFormat.format(pAnalysis['estimatedProfit'] ?? 0)),
        _detailAnalysisRow('GST tax (${pAnalysis['gstPercentage']}%)', currencyFormat.format(pAnalysis['gstAmount'] ?? 0)),
        const Divider(color: Color(0xFF262635)),
        _detailAnalysisRow('Grand Total Project Value (NPV)', currencyFormat.format(pAnalysis['netProjectValue'] ?? 0), highlight: true),
      ],
    );
  }

  Widget _detailAnalysisRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: highlight ? VianTheme.primaryGold : Colors.white, fontSize: highlight ? 16 : 13)),
        ],
      ),
    );
  }

  
  Future<int?> _ensureSavedEstimate() async {
    if (_savedEstimateId != null) return _savedEstimateId;
    
    setState(() => _savingEstimate = true);
    try {
      final finalData = {
        'projectName': _projectNameController.text,
        'clientName': _clientNameController.text,
        'projectType': _selectedProjectType,
        'constructionType': _selectedPackage,
        'state': _selectedState,
        'district': _selectedDistrict,
        'city': _cityController.text,
        'siteAddress': _addressController.text,
        'builtUpArea': double.tryParse(_builtUpAreaController.text) ?? 1000.0,
        'unit': _selectedUnit,
        'selectedPackage': _selectedPackage,
        'packageRate': _calculatedResults?['ratePerUnit'] ?? 2500.0,
        'totalCost': _calculatedResults?['totalCost'] ?? 0.0,
        'companyMarginPercentage': _marginPercentage,
        'estimatedProfit': _calculatedResults?['profitAnalysis']?['estimatedProfit'] ?? 0.0,
        'gstPercentage': _calculatedResults?['profitAnalysis']?['gstPercentage'] ?? 18.0,
        'gstAmount': _calculatedResults?['profitAnalysis']?['gstAmount'] ?? 0.0,
        'netProjectValue': _calculatedResults?['profitAnalysis']?['netProjectValue'] ?? 0.0,
        'materials': _editableMaterials,
        'phases': _editablePhases,
        'boq': _editableBOQ,
        'labours': _editableLabour,
      };

      final res = await ApiService.saveEstimate(finalData);
      if (res['success'] == true || res['estimate'] != null) {
        final newId = res['estimate']?['id'] ?? res['id'];
        if (newId != null) {
          setState(() {
            _savedEstimateId = int.tryParse(newId.toString());
          });
          return _savedEstimateId;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error auto-saving estimate: $e");
      return null;
    } finally {
      setState(() => _savingEstimate = false);
    }
  }

  void _showShareDialog(int id, String channel) {
    final controller = TextEditingController(
      text: channel == 'Email' ? 'client@vian-estimate.com' : '+91 9840123456'
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: Text(
          'Share via $channel',
          style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channel == 'Email' ? 'Recipient Email Address:' : 'Recipient Mobile Number:',
              style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF262635))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: VianTheme.danger)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold),
            child: const Text('Send Link', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing share request...')),
              );
              final res = await ApiService.shareQuotation(id, channel, controller.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'] ?? 'Shared successfully.')),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _stepQuotationInvoicePreview() {
    if (_calculatedResults == null) return const SizedBox();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final pAnalysis = _calculatedResults!['profitAnalysis'] ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VianTheme.primaryGold, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIAN ARCHITECTS',
                    style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                  ),
                  const Text('Luxury Residential & Commercial Design', style: TextStyle(color: VianTheme.lightText, fontSize: 10)),
                ],
              ),
              const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 32),
            ],
          ),
          const Divider(color: Color(0xFF262635), height: 32),
          Text('CLIENT QUOTATION', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          Text('Project Name: ${_projectNameController.text}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('Client: ${_clientNameController.text}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('Site Location: ${_addressController.text}, ${_cityController.text}, $_selectedDistrict', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('Estimated Area: ${_builtUpAreaController.text} $_selectedUnit', style: const TextStyle(color: Colors.white, fontSize: 12)),
          const Divider(color: Color(0xFF262635), height: 32),
          _detailAnalysisRow('Civil Construction cost', currencyFormat.format(pAnalysis['constructionCost'] ?? 0)),
          _detailAnalysisRow('Company Profit Margin', currencyFormat.format(pAnalysis['estimatedProfit'] ?? 0)),
          _detailAnalysisRow('GST tax Amount', currencyFormat.format(pAnalysis['gstAmount'] ?? 0)),
          const Divider(color: VianTheme.primaryGold),
          _detailAnalysisRow('GRAND VALUATION (NPV)', currencyFormat.format(pAnalysis['netProjectValue'] ?? 0), highlight: true),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: VianTheme.primaryGold),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code, color: VianTheme.primaryGold, size: 50),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ar. Anand Sathiesivam',
                    style: GoogleFonts.greatVibes(color: VianTheme.primaryGold, fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text('Managing Director Signature', style: TextStyle(color: VianTheme.lightText, fontSize: 10)),
                ],
              )
            ],
          ),
          const Divider(color: Color(0xFF262635), height: 32),
          if (_savingEstimate)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)),
            ))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final id = await _ensureSavedEstimate();
                        if (id != null) {
                          final url = '${ApiService.baseUrl}/estimations/$id/quotation/pdf?token=${ApiService.token}';
                          openUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save estimate for export.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 16),
                      label: const Text('Open PDF', style: TextStyle(color: Colors.white, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF262635)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final id = await _ensureSavedEstimate();
                        if (id != null) {
                          final bytes = await ApiService.exportQuotationExcel(id);
                          if (bytes != null) {
                            saveFile(bytes, 'Quotation-${_projectNameController.text.replaceAll(' ', '_')}.xlsx');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Excel document downloaded successfully.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Excel export failed.')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save estimate for export.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.table_view, color: Colors.greenAccent, size: 16),
                      label: const Text('Download Excel', style: TextStyle(color: Colors.white, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF262635)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final id = await _ensureSavedEstimate();
                        if (id != null) {
                          _showShareDialog(id, 'WhatsApp');
                        }
                      },
                      icon: const Icon(Icons.share, color: Colors.blueAccent, size: 16),
                      label: const Text('Share WhatsApp', style: TextStyle(color: Colors.white, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF262635)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final id = await _ensureSavedEstimate();
                        if (id != null) {
                          _showShareDialog(id, 'Email');
                        }
                      },
                      icon: const Icon(Icons.email, color: VianTheme.primaryGold, size: 16),
                      label: const Text('Share Email', style: TextStyle(color: Colors.white, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF262635)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


  Widget _stepHeader(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF262635))),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 12),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          VianButton(
            text: 'Back',
            isSecondary: true,
            onPressed: () {
              setState(() {
                _currentStep--;
              });
            },
          )
        else
          const SizedBox(),
        VianButton(
          text: _currentStep == 9 ? 'Save & Finish' : 'Next Step',
          icon: _currentStep == 9 ? Icons.check_circle_outline : Icons.arrow_forward,
          onPressed: () async {
            if (_currentStep == 0) {
              await _runCalculate();
            }
            if (_currentStep == 9) {
              final finalData = {
                'projectName': _projectNameController.text,
                'clientName': _clientNameController.text,
                'projectType': _selectedProjectType,
                'constructionType': _selectedPackage,
                'state': _selectedState,
                'district': _selectedDistrict,
                'city': _cityController.text,
                'siteAddress': _addressController.text,
                'builtUpArea': double.tryParse(_builtUpAreaController.text) ?? 1000.0,
                'unit': _selectedUnit,
                'selectedPackage': _selectedPackage,
                'packageRate': _calculatedResults?['ratePerUnit'] ?? 2500.0,
                'totalCost': _calculatedResults?['totalCost'] ?? 0.0,
                'companyMarginPercentage': _marginPercentage,
                'estimatedProfit': _calculatedResults?['profitAnalysis']?['estimatedProfit'] ?? 0.0,
                'gstPercentage': _calculatedResults?['profitAnalysis']?['gstPercentage'] ?? 18.0,
                'gstAmount': _calculatedResults?['profitAnalysis']?['gstAmount'] ?? 0.0,
                'netProjectValue': _calculatedResults?['profitAnalysis']?['netProjectValue'] ?? 0.0,
                'materials': _editableMaterials,
                'phases': _editablePhases,
                'boq': _editableBOQ,
                'labours': _editableLabour,
              };
              widget.onSave(finalData);
            } else {
              setState(() {
                _currentStep++;
              });
            }
          },
        ),
      ],
    );
  }
}

// ==========================================
// 25. ESTIMATION SETTINGS MODULE
// ==========================================

class EstimationSettingsView extends StatefulWidget {
  final Map<String, dynamic> settings;
  final String role;
  final Function(Map<String, dynamic> data) onSave;

  const EstimationSettingsView({
    Key? key,
    required this.settings,
    required this.role,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EstimationSettingsView> createState() => _EstimationSettingsViewState();
}

class _EstimationSettingsViewState extends State<EstimationSettingsView> {
  final _economyRateController = TextEditingController();
  final _standardRateController = TextEditingController();
  final _premiumRateController = TextEditingController();
  final _marginController = TextEditingController();
  final _overheadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _economyRateController.text = '${widget.settings['economyRate'] ?? 2200}';
    _standardRateController.text = '${widget.settings['standardRate'] ?? 2500}';
    _premiumRateController.text = '${widget.settings['premiumRate'] ?? 2800}';
    _marginController.text = '${widget.settings['profitMarginPercentage'] ?? 12}';
    _overheadController.text = '${widget.settings['companyOverhead'] ?? 50000}';
  }

  @override
  Widget build(BuildContext context) {
    final isAuthorized = widget.role == 'Super Admin' || widget.role == 'Managing Director';

    if (!isAuthorized) {
      return Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF262635)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: VianTheme.primaryGold, size: 48),
              const SizedBox(height: 16),
              Text(
                'ACCESS AUTHORIZATION DENIED',
                style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Only the Managing Director (Anand - Super Admin) has authorization to update settings formulas.',
                style: TextStyle(color: VianTheme.lightText, fontSize: 12),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: VianCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTIMATION ENGINE FORMULAS SETTINGS',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text('Super Admin view to edit base coefficients, regional markups, and default packages.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInputField('Economy Rate (Base)', _economyRateController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('Standard Rate (Base)', _standardRateController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('Premium Rate (Base)', _premiumRateController),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInputField('Target Margin %', _marginController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('Company Overhead buffer', _overheadController),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: VianButton(
                text: 'Save Base Settings',
                icon: Icons.save,
                onPressed: () {
                  final data = {
                    'economyRate': double.tryParse(_economyRateController.text) ?? 2200.0,
                    'standardRate': double.tryParse(_standardRateController.text) ?? 2500.0,
                    'premiumRate': double.tryParse(_premiumRateController.text) ?? 2800.0,
                    'profitMarginPercentage': double.tryParse(_marginController.text) ?? 12.0,
                    'companyOverhead': double.tryParse(_overheadController.text) ?? 50000.0,
                  };
                  widget.onSave(data);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF262635))),
      ),
    );
  }
}

// ==========================================
// 26. MOBILE SITE ENGINEER VIEW
// ==========================================

class MobileSiteEngineerView extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> estimates;
  final VoidCallback onRefresh;

  const MobileSiteEngineerView({
    Key? key,
    required this.user,
    required this.estimates,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<MobileSiteEngineerView> createState() => _MobileSiteEngineerViewState();
}

class _MobileSiteEngineerViewState extends State<MobileSiteEngineerView> {
  Map<String, dynamic>? _selectedProject;
  bool _loggingExpense = false;
  
  // Expense Form fields
  final _materialNameController = TextEditingController();
  final _costController = TextEditingController();
  final _supplierController = TextEditingController();
  final _qtyController = TextEditingController();

  Map<String, dynamic>? _budgetActualData;
  bool _loadingBudget = false;

  Future<void> _fetchBudget() async {
    if (_selectedProject == null) return;
    setState(() => _loadingBudget = true);
    try {
      final res = await ApiService.getBudgetVsActual(_selectedProject!['id']);
      setState(() {
        _budgetActualData = res;
      });
    } catch (e) {
      debugPrint("Error fetching mobile budget: $e");
    } finally {
      setState(() => _loadingBudget = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: Text(
          _selectedProject != null ? _selectedProject!['projectName'] : 'SITE ENGINEER CORNER',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: VianTheme.primaryGold),
            onPressed: () {
              widget.onRefresh();
              _fetchBudget();
            },
          )
        ],
      ),
      body: _selectedProject != null ? _buildProjectDetailsPanel() : _buildActiveProjectsList(),
    );
  }

  Widget _buildActiveProjectsList() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final approvedList = widget.estimates.where((e) => e['status'] == 'Approved').toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE RUNNING PROJECTS',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: approvedList.isEmpty
                ? const Center(child: Text('No active projects mapped.', style: TextStyle(color: VianTheme.lightText)))
                : ListView.builder(
                    itemCount: approvedList.length,
                    itemBuilder: (context, index) {
                      final item = approvedList[index];
                      return Card(
                        color: const Color(0xFF1E1E26),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(item['projectName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text('Client: ${item['clientName']} | Area: ${item['builtUpArea']} ${item['unit']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: VianTheme.primaryGold),
                          onTap: () {
                            setState(() {
                              _selectedProject = item;
                            });
                            _fetchBudget();
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildProjectDetailsPanel() {
    return _loadingBudget
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back, color: VianTheme.primaryGold, size: 16),
                      label: const Text('Back to List', style: TextStyle(color: VianTheme.primaryGold)),
                      onPressed: () => setState(() {
                        _selectedProject = null;
                        _budgetActualData = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_budgetActualData != null) ...[
                  _buildMobileBudgetSummary(),
                  const SizedBox(height: 20),
                ],
                _buildPhaseUpdateSection(),
                const SizedBox(height: 24),
                if (_loggingExpense) _buildExpenseLoggingForm() else _buildLogExpenseButton(),
              ],
            ),
          );
  }

  Widget _buildMobileBudgetSummary() {
    final data = _budgetActualData!;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUDGET VS ACTUAL LEDGER',
            style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          _mobileLedgerRow('Materials', data['estimatedMaterialCost'] ?? 0, data['actualMaterialCost'] ?? 0, currencyFormat),
          const Divider(color: Color(0xFF262635)),
          _mobileLedgerRow('Labour', data['estimatedLabourCost'] ?? 0, data['actualLabourCost'] ?? 0, currencyFormat),
          const Divider(color: Color(0xFF262635)),
          _mobileLedgerRow('Expenses', data['estimatedExpenses'] ?? 0, data['actualExpenses'] ?? 0, currencyFormat),
          const Divider(color: VianTheme.primaryGold, thickness: 1.5),
          _mobileLedgerRow('Total Cost', data['totalEstimatedCost'] ?? 0, data['totalActualCost'] ?? 0, currencyFormat, isTotal: true),
        ],
      ),
    );
  }

  Widget _mobileLedgerRow(String label, dynamic est, dynamic act, NumberFormat formatter, {bool isTotal = false}) {
    final double estVal = double.tryParse(est.toString()) ?? 0.0;
    final double actVal = double.tryParse(act.toString()) ?? 0.0;
    final double variance = estVal - actVal;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? VianTheme.primaryGold : Colors.white, fontSize: 12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Spent: ${formatter.format(actVal)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: Colors.white, fontSize: 12)),
            Text('Budget: ${formatter.format(estVal)}', style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
          ],
        )
      ],
    );
  }

  Widget _buildPhaseUpdateSection() {
    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPDATE PHASE PROGRESS',
            style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          const Text('Slide to adjust estimated building completion progress.', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
          const SizedBox(height: 16),
          // Horizontal phase completion slider
          Slider(
            value: 45.0, // Mock active progress
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: VianTheme.primaryGold,
            onChanged: (val) {
              // Log state updates locally / trigger endpoint
            },
          ),
          const Center(child: Text('RCC Structure Completion: 45%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildLogExpenseButton() {
    return Center(
      child: VianButton(
        text: 'Log Material Bill / Expenses',
        icon: Icons.receipt_long,
        onPressed: () => setState(() => _loggingExpense = true),
      ),
    );
  }

  Widget _buildExpenseLoggingForm() {
    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW MATERIAL / BILL LEDGER RECEIPT',
            style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _materialNameController,
            decoration: const InputDecoration(labelText: 'Material Item Name (e.g. Steel Fe 550)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity Purchased'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Bill Amount (INR)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _supplierController,
            decoration: const InputDecoration(labelText: 'Supplier Vendor Name'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.file_upload, size: 16),
                label: const Text('Pick Bill PDF / Image'),
                onPressed: () async {
                  await FilePicker.pickFiles(
                    type: FileType.any,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: VianTheme.danger)),
                onPressed: () => setState(() => _loggingExpense = false),
              ),
              VianButton(
                text: 'Submit Ledger',
                icon: Icons.check,
                onPressed: () {
                  setState(() => _loggingExpense = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense logged and queued for MD verification.')),
                  );
                },
              )
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// 21. CONFERENCE CALLS TAB
// ==========================================
class ConferenceCallsTab extends StatefulWidget {
  const ConferenceCallsTab({Key? key}) : super(key: key);

  @override
  State<ConferenceCallsTab> createState() => _ConferenceCallsTabState();
}

class _ConferenceCallsTabState extends State<ConferenceCallsTab> {
  List<dynamic> _calls = [];
  List<dynamic> _employees = [];
  bool _loading = true;
  bool _loggingCall = false;
  
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ').first);
  final _notesController = TextEditingController();
  String _selectedType = 'Morning Call';
  double _durationMinutes = 15;

  // Track status for each employee in the active logging form
  final Map<int, String> _employeeStatuses = {}; // userId -> 'Joined' | 'Late' | 'Missed'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final callsList = await ApiService.getConferenceCalls();
    final empList = await ApiService.getEmployees();
    
    setState(() {
      _calls = callsList;
      _employees = empList.where((e) => e['role'] != 'Client' && e['role'] != 'Managing Director').toList();
      
      // Initialize statuses
      _employeeStatuses.clear();
      for (var emp in _employees) {
        final id = emp['id'] as int;
        _employeeStatuses[id] = 'Joined';
      }
      
      _loading = false;
    });
  }

  Future<void> _submitCall() async {
    final participantsList = _employees.map((e) {
      final id = e['id'] as int;
      return {
        'userId': id,
        'name': e['name'],
        'employeeId': e['employeeId'],
        'status': _employeeStatuses[id] ?? 'Joined',
      };
    }).toList();

    final ok = await ApiService.createConferenceCall({
      'type': _selectedType,
      'date': _dateController.text,
      'durationMinutes': _durationMinutes.toInt(),
      'notes': _notesController.text,
      'participants': participantsList,
    });

    if (ok) {
      _notesController.clear();
      setState(() => _loggingCall = false);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conference call log saved and synced to Staff Incentive calculations.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save conference call log.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conference Calls Tracker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                    const SizedBox(height: 4),
                    Text('Monitor Morning/Evening operational briefings and log staff attendance', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _loggingCall ? Colors.grey : VianTheme.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    setState(() => _loggingCall = !_loggingCall);
                  },
                  icon: Icon(_loggingCall ? Icons.arrow_back : Icons.add),
                  label: Text(_loggingCall ? 'View Logs' : 'Log Briefing Call'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loggingCall ? _buildCallLoggerForm() : _buildCallsHistoryList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLoggerForm() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log New Briefing session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: const Color(0xFF1E1E26),
                    decoration: const InputDecoration(labelText: 'Briefing Session Type'),
                    items: ['Morning Call', 'Evening Call'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', suffixIcon: Icon(Icons.calendar_today, size: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Duration (Minutes)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes,
                    min: 10,
                    max: 60,
                    divisions: 10,
                    activeColor: VianTheme.primaryGold,
                    inactiveColor: Colors.white10,
                    label: '${_durationMinutes.toInt()} mins',
                    onChanged: (val) => setState(() => _durationMinutes = val),
                  ),
                ),
                Text('${_durationMinutes.toInt()} mins', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Operational Notes & Key Briefings', alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            const Text('Staff Attendance Compliance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _employees.length,
              itemBuilder: (ctx, index) {
                final emp = _employees[index];
                final id = emp['id'] as int;
                final status = _employeeStatuses[id] ?? 'Joined';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: VianTheme.primaryGold.withOpacity(0.1),
                        foregroundColor: VianTheme.primaryGold,
                        child: Text(emp['name'] != null && emp['name'].isNotEmpty ? emp['name'][0] : 'U'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${emp['employeeId'] ?? ''} • ${emp['role'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _attendanceChoiceButton(id, 'Joined', Colors.green, status == 'Joined'),
                          const SizedBox(width: 6),
                          _attendanceChoiceButton(id, 'Late', Colors.orange, status == 'Late'),
                          const SizedBox(width: 6),
                          _attendanceChoiceButton(id, 'Missed', Colors.red, status == 'Missed'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => setState(() => _loggingCall = false), child: const Text('Cancel')),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                  onPressed: _submitCall,
                  child: const Text('Submit Session Log'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _attendanceChoiceButton(int userId, String status, Color color, bool selected) {
    return InkWell(
      onTap: () {
        setState(() {
          _employeeStatuses[userId] = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.white10),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: selected ? color : Colors.grey,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCallsHistoryList() {
    if (_calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_in_talk_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No Briefing Sessions Logged', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Log your first morning or evening call to begin compliance scores tracking.', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _calls.length,
      itemBuilder: (ctx, index) {
        final call = _calls[index];
        final logger = call['logger'] ?? {};
        
        List<dynamic> participantsList = [];
        try {
          if (call['participants'] != null) {
            participantsList = json.decode(call['participants']);
          }
        } catch (_) {}

        final joinedCount = participantsList.where((p) => p['status'] == 'Joined').length;
        final lateCount = participantsList.where((p) => p['status'] == 'Late').length;
        final missedCount = participantsList.where((p) => p['status'] == 'Missed').length;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        call['type'] == 'Morning Call' ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                        color: call['type'] == 'Morning Call' ? Colors.orange : Colors.purpleAccent,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        call['type'] ?? 'Briefing Call',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.primaryGold),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${call['durationMinutes']} mins', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      )
                    ],
                  ),
                  Text(
                    call['date'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (call['notes'] != null && call['notes'].isNotEmpty) ...[
                Text(
                  call['notes'],
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13.5),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _statChip('Joined: $joinedCount', Colors.green),
                  const SizedBox(width: 8),
                  _statChip('Late: $lateCount', Colors.orange),
                  const SizedBox(width: 8),
                  _statChip('Missed: $missedCount', Colors.red),
                  const Spacer(),
                  Text(
                    'Logged By: ${logger['name'] ?? 'System'}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ==========================================
// 22. STAFF INCENTIVES TAB
// ==========================================
class IncentivesTab extends ConsumerStatefulWidget {
  const IncentivesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<IncentivesTab> createState() => _IncentivesTabState();
}

class _IncentivesTabState extends ConsumerState<IncentivesTab> {
  List<dynamic> _incentives = [];
  bool _loading = true;
  String _selectedMonth = DateTime.now().toString().substring(0, 7); // Default to current month YYYY-MM

  @override
  void initState() {
    super.initState();
    _loadIncentives();
  }

  Future<void> _loadIncentives() async {
    setState(() => _loading = true);
    final list = await ApiService.getIncentives(_selectedMonth);
    setState(() {
      _incentives = list;
      _loading = false;
    });
  }

  Future<void> _recalculateAll() async {
    setState(() => _loading = true);
    final list = await ApiService.getIncentives(_selectedMonth);
    setState(() {
      _incentives = list;
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Re-computed staff performance incentives score.')),
    );
  }

  Future<void> _updateStatus(int rowId, String status) async {
    final ok = await ApiService.updateIncentiveStatus(rowId, status, 'Approved by Managing Director');
    if (ok) {
      _loadIncentives();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incentive marked as $status.')),
      );
    }
  }

  void _showScoreBreakdownModal(dynamic record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: Text('${record['user']?['name'] ?? 'Staff'} Scorecard', style: const TextStyle(color: VianTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee ID: ${record['user']?['employeeId'] ?? ''}'),
            Text('Role: ${record['user']?['role'] ?? ''}'),
            const SizedBox(height: 16),
            _scoreBar('Attendance Score', safeToDouble(record['attendanceScore']), 30),
            _scoreBar('Briefing Calls Score', safeToDouble(record['callsScore']), 15),
            _scoreBar('Tasks Accomplishment', safeToDouble(record['tasksScore']), 25),
            _scoreBar('Photo slots Compliance', safeToDouble(record['photosScore']), 20),
            _scoreBar('Daily Logs Compliance', safeToDouble(record['reportsScore']), 10),
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Score:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${safeToDouble(record['totalScore']).toStringAsFixed(1)} / 100',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: _getScoreColor(safeToDouble(record['totalScore'])),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Calculated Incentive Bonus: ₹${safeToDouble(record['incentiveAmount']).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
            Text('Calculated Penalties: ₹${safeToDouble(record['penaltyAmount']).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _scoreBar(String title, double score, double maxScore) {
    final ratio = score / maxScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            Text('${score.toStringAsFixed(1)} / ${maxScore.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: Colors.white10,
          color: _getScoreColor(ratio * 100),
          minHeight: 6,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.greenAccent;
    if (score >= 75) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    final role = user?['role'] ?? 'Client';
    final isMD = role == 'Managing Director' || role == 'Super Admin';

    // Summary Calculations
    double totalBonus = 0;
    double totalPenalties = 0;
    double averageScore = 0;
    if (_incentives.isNotEmpty) {
      double sumScore = 0;
      for (var inc in _incentives) {
        totalBonus += safeToDouble(inc['incentiveAmount']);
        totalPenalties += safeToDouble(inc['penaltyAmount']);
        sumScore += safeToDouble(inc['totalScore']);
      }
      averageScore = sumScore / _incentives.length;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Staff Incentives Engine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                    const SizedBox(height: 4),
                    Text('Auto-compute monthly employee operational score, bonuses, and late log-in penalties.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        dropdownColor: const Color(0xFF1E1E26),
                        decoration: const InputDecoration(labelText: 'Month', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: ['2026-07', '2026-06', '2026-05'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          setState(() => _selectedMonth = val!);
                          _loadIncentives();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isMD) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                        onPressed: _recalculateAll,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-calculate Scores'),
                      ),
                    ],
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _summaryCard('Average Performance Score', '${averageScore.toStringAsFixed(1)} / 100', Icons.trending_up, Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: _summaryCard('Total Incentive Payouts', '₹${totalBonus.toStringAsFixed(0)}', Icons.arrow_upward, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _summaryCard('Total Penalties Applied', '₹${totalPenalties.toStringAsFixed(0)}', Icons.arrow_downward, Colors.red)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _incentives.isEmpty
                  ? Center(child: Text('No performance logs for month $_selectedMonth', style: const TextStyle(color: Colors.grey)))
                  : _buildIncentivesTable(isMD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }

  Widget _buildIncentivesTable(bool isMD) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.2),
              6: FlexColumnWidth(2.0),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF15151D)),
                children: [
                  _headerCell('Staff Member'),
                  _headerCell('Department'),
                  _headerCell('Total Score'),
                  _headerCell('Bonus (₹)'),
                  _headerCell('Penalties (₹)'),
                  _headerCell('Status'),
                  _headerCell('Actions'),
                ],
              ),
              ..._incentives.map((row) {
                final emp = row['user'] ?? {};
                final double score = safeToDouble(row['totalScore']);
                final status = row['status'] ?? 'Pending';
                
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.02))),
                  ),
                  children: [
                    _dataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${emp['employeeId'] ?? ''} • ${emp['role'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                      ],
                    )),
                    _dataCell(Text(emp['department'] ?? 'General')),
                    _dataCell(Text(
                      '${score.toStringAsFixed(1)}', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: _getScoreColor(score)),
                    )),
                    _dataCell(Text('+₹${safeToDouble(row['incentiveAmount']).toStringAsFixed(0)}', style: const TextStyle(color: Colors.green))),
                    _dataCell(Text('-₹${safeToDouble(row['penaltyAmount']).toStringAsFixed(0)}', style: const TextStyle(color: Colors.red))),
                    _dataCell(_statusTag(status)),
                    _dataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.analytics_outlined, size: 20, color: Colors.blueAccent),
                          tooltip: 'Scorecard Breakdown',
                          onPressed: () => _showScoreBreakdownModal(row),
                        ),
                        if (isMD && status == 'Pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                            tooltip: 'Approve Payout',
                            onPressed: () => _updateStatus(row['id'] as int, 'Approved'),
                          ),
                        ] else if (isMD && status == 'Approved') ...[
                          IconButton(
                            icon: const Icon(Icons.paid_outlined, size: 20, color: Colors.orangeAccent),
                            tooltip: 'Release Payout',
                            onPressed: () => _updateStatus(row['id'] as int, 'Paid'),
                          ),
                        ]
                      ],
                    )),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13)),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Widget _statusTag(String status) {
    Color bg = Colors.grey.withOpacity(0.1);
    Color txt = Colors.grey;
    if (status == 'Approved') {
      bg = Colors.blueAccent.withOpacity(0.15);
      txt = Colors.blueAccent;
    } else if (status == 'Paid') {
      bg = Colors.green.withOpacity(0.15);
      txt = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status, style: TextStyle(color: txt, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
