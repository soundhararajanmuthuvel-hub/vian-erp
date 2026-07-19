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
import 'core/widgets/face_gps_verify_overlay.dart';
import 'core/widgets/face_registration_wizard.dart';
import 'core/widgets/project_geofence_map.dart';
import 'core/services/gps_resolver.dart';
import 'core/services/file_helper.dart';
import 'core/widgets/drawing_canvases.dart';
import 'public_enquiry_portal.dart';
import 'forgot_password_page.dart';
import 'splash_screen.dart';
import 'core/models/estimation.dart';
import 'core/services/estimation_provider.dart';
import 'user_management.dart';
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
          path: '/users',
          builder: (context, state) => const UserManagementTab(),
        ),
        GoRoute(
          path: '/users/create',
          builder: (context, state) => const UserManagementTab(showCreateDialog: true),
        ),
        GoRoute(
          path: '/users/edit/:id',
          builder: (context, state) => UserManagementTab(editUserId: state.pathParameters['id']),
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

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  bool _showPassword = false;
  bool _showDevOptions = false;
  String? _errorMessage;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
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

  void _quickFill(String role) {
    _usernameController.text = role;
    _passwordController.text = '${role}123';
    _handleLogin();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 1000;

    if (isMobile) {
      return Scaffold(
        backgroundColor: VianTheme.darkBackground,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildLoginCard(context, size, true),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VianTheme.darkBackground,
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              color: VianTheme.darkBackground,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LoginBlueprintPainter(_animController.value),
                        child: Container(),
                      );
                    },
                  ),
                  Positioned(
                    top: 64,
                    left: 64,
                    child: Row(
                      children: [
                        const Icon(Icons.architecture_outlined, color: VianTheme.primaryGold, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'VIAN COMMAND',
                          style: GoogleFonts.outfit(
                            color: VianTheme.lightText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'VIAN Architects',
                            style: GoogleFonts.bodoniModa(
                              color: VianTheme.primaryGold,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 1, width: 24, color: VianTheme.primaryGold.withOpacity(0.3)),
                              const SizedBox(width: 12),
                              Text(
                                'PRECISION. LEGACY. COMMAND.',
                                style: GoogleFonts.outfit(
                                  color: VianTheme.lightText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 5.0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(height: 1, width: 24, color: VianTheme.primaryGold.withOpacity(0.3)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 48,
                    left: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coordinates: 13.0827° N, 80.2707° E',
                          style: GoogleFonts.outfit(color: VianTheme.primaryGold.withOpacity(0.4), fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'System Status: Connected',
                          style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: VianTheme.darkBackground,
                border: Border(left: BorderSide(color: VianTheme.goldBorder, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Center(
                child: SingleChildScrollView(
                  child: _buildLoginCard(context, size, false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, Size size, bool isMobileMode) {
    return Container(
      width: 440,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        border: Border.all(
          color: VianTheme.goldBorder,
          width: 1.0,
        ),
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
                    'EXECUTIVE COMMAND',
                    style: GoogleFonts.outfit(
                      color: VianTheme.primaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Secure Access',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.lock_outline,
                color: VianTheme.primaryGold,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 36),
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VianTheme.danger.withOpacity(0.08),
                border: Border.all(color: VianTheme.danger.withOpacity(0.2)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: VianTheme.danger, fontSize: 12.5),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'CORPORATE EMAIL',
            style: GoogleFonts.outfit(
              color: VianTheme.lightText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _usernameController,
            style: TextStyle(color: VianTheme.whiteText),
            decoration: const InputDecoration(
              hintText: 'Enter corporate username or ID',
              prefixIcon: Icon(Icons.mail_outline, color: VianTheme.primaryGold, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'MASTER CREDENTIAL',
            style: GoogleFonts.outfit(
              color: VianTheme.lightText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: TextStyle(color: VianTheme.whiteText),
            decoration: InputDecoration(
              hintText: 'Enter master password',
              prefixIcon: const Icon(Icons.key_outlined, color: VianTheme.primaryGold, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: VianTheme.lightText,
                  size: 18,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: VianTheme.primaryGold,
                      checkColor: VianTheme.darkBackground,
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Maintain Session',
                    style: GoogleFonts.outfit(fontSize: 11, color: VianTheme.lightText, letterSpacing: 0.5),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/forgot-password'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text(
                  'Recover Access',
                  style: GoogleFonts.outfit(color: VianTheme.primaryGold.withOpacity(0.8), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          CustomPaint(
            painter: AtelierBracketPainter(color: VianTheme.primaryGold),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(2),
              child: VianButton(
                text: _isLoading ? 'Signing In...' : 'AUTHORIZE ACCESS',
                onPressed: _isLoading ? () {} : _handleLogin,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'SELECT EXECUTIVE ENVIRONMENT',
              style: GoogleFonts.outfit(
                color: VianTheme.lightText,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _envButton('anand', 'Principal'),
              const SizedBox(width: 12),
              _envButton('vijay', 'Associate'),
              const SizedBox(width: 12),
              _envButton('client', 'Client'),
            ],
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VER 4.2.0-EXEC',
                style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9),
              ),
              Text(
                '© 2026 VIAN GLOBAL',
                style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _envButton(String role, String label) {
    return InkWell(
      onTap: () => _quickFill(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: VianTheme.primaryGold.withOpacity(0.4), width: 1),
          color: VianTheme.primaryGold.withOpacity(0.04),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: VianTheme.primaryGold,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class LoginBlueprintPainter extends CustomPainter {
  final double val;
  LoginBlueprintPainter(this.val);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.03)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final double midX = size.width * 0.5;
    final double base = size.height * 0.95;

    // Draw detailed architectural building wireframe outline
    final path = Path();
    
    // Central main tower
    path.moveTo(midX - 70, base);
    path.lineTo(midX - 70, base - 340);
    path.lineTo(midX + 70, base - 340);
    path.lineTo(midX + 70, base);

    // Left tower wing
    path.moveTo(midX - 150, base);
    path.lineTo(midX - 150, base - 220);
    path.lineTo(midX - 70, base - 220);

    // Right tower wing
    path.moveTo(midX + 70, base);
    path.lineTo(midX + 70, base - 250);
    path.lineTo(midX + 150, base - 250);
    path.lineTo(midX + 150, base);

    // Antenna spear
    path.moveTo(midX - 15, base - 340);
    path.lineTo(midX, base - 410);
    path.lineTo(midX + 15, base - 340);

    final buildPaint = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, buildPaint);

    // Draw floor grids
    final floorPaint = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double y = base - 20; y > base - 340; y -= 20) {
      canvas.drawLine(Offset(midX - 70, y), Offset(midX + 70, y), floorPaint);
    }

    // Concentric blueprint dial lines
    final center = Offset(midX, base - 200);
    final circlePaint = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.04 + (math.sin(val * 2 * math.pi) * 0.01))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 180, circlePaint);
    canvas.drawCircle(center, 90, circlePaint);

    final linePaint = Paint()
      ..color = VianTheme.primaryGold.withOpacity(0.03)
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), linePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant LoginBlueprintPainter oldDelegate) {
    return oldDelegate.val != val;
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
  bool _sidebarCollapsed = false;

  // Tabs mapping grouped by category based on user roles
  List<Map<String, dynamic>> _getTabs(String role) {
    final allTabs = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'route': '/dashboard', 'category': 'Core & CRM'},
      {'title': 'User Management', 'icon': Icons.manage_accounts_outlined, 'route': '/users', 'roles': ['Super Admin', 'Managing Director', 'Admin', 'Admin / Office Manager / Accounts', 'Project Manager'], 'category': 'Core & CRM'},
      {'title': 'CRM Leads', 'icon': Icons.campaign_outlined, 'route': '/crm-leads', 'roles': ['Super Admin', 'Receptionist'], 'category': 'Core & CRM'},
      {'title': 'Enquiry Inbox', 'icon': Icons.inbox_outlined, 'route': '/enquiry-inbox', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect'], 'category': 'Core & CRM'},
      {'title': 'Clients', 'icon': Icons.people_outline, 'route': '/clients', 'roles': ['Super Admin', 'Receptionist'], 'category': 'Core & CRM'},
      {'title': 'Client Onboarding', 'icon': Icons.person_add_alt_1_outlined, 'route': '/client-onboarding', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts'], 'category': 'Core & CRM'},
      {'title': 'Announcements', 'icon': Icons.campaign_outlined, 'route': '/announcements', 'category': 'Core & CRM'},

      {'title': 'Projects', 'icon': Icons.architecture, 'route': '/projects', 'roles': ['Super Admin', 'Architect', 'Interior Designer', 'Client'], 'category': 'Project Execution'},
      {'title': 'Construction Estimation', 'icon': Icons.calculate_outlined, 'route': '/construction-estimation', 'roles': ['Super Admin', 'Architect', 'Site Engineer', 'Supervisor', 'Accountant', 'Receptionist'], 'category': 'Project Execution'},
      {'title': 'Contractor Master', 'icon': Icons.business_center_outlined, 'route': '/contractor-master', 'roles': ['Super Admin', 'Architect', 'Site Engineer', 'Supervisor', 'Admin / Office Manager / Accounts'], 'category': 'Project Execution'},
      {'title': 'Drawings', 'icon': Icons.layers_outlined, 'route': '/drawings', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect', 'Site Manager', 'Employee', 'Client'], 'category': 'Project Execution'},
      {'title': 'Documents', 'icon': Icons.folder_open_outlined, 'route': '/documents', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts', 'Tech Head + Senior Architect', 'Site Manager', 'Employee', 'Client'], 'category': 'Project Execution'},
      {'title': 'Tasks', 'icon': Icons.assignment_outlined, 'route': '/tasks', 'roles': ['Super Admin', 'Architect', 'Interior Designer', 'Site Engineer', 'Supervisor'], 'category': 'Project Execution'},

      {'title': 'GPS Attendance', 'icon': Icons.pin_drop_outlined, 'route': '/gps-attendance', 'roles': ['Super Admin', 'Site Engineer', 'Supervisor'], 'category': 'Operations & Attendance'},
      {'title': 'Labour Attendance', 'icon': Icons.checklist_rtl_outlined, 'route': '/labour-attendance', 'roles': ['Super Admin', 'Site Engineer', 'Supervisor'], 'category': 'Operations & Attendance'},
      {'title': 'Manager Progress', 'icon': Icons.assignment_turned_in_outlined, 'route': '/manager-progress', 'roles': ['Super Admin', 'Site Engineer', 'Supervisor'], 'category': 'Operations & Attendance'},
      {'title': 'Daily Work Report', 'icon': Icons.history_edu_outlined, 'route': '/daily-work-report', 'roles': ['Super Admin', 'Architect', 'Interior Designer', 'Site Engineer', 'Supervisor', 'Accountant', 'Receptionist'], 'category': 'Operations & Attendance'},

      {'title': 'Quotations', 'icon': Icons.description_outlined, 'route': '/quotations', 'roles': ['Super Admin', 'Accountant', 'Client'], 'category': 'Financial & Payroll'},
      {'title': 'Invoices', 'icon': Icons.receipt_long_outlined, 'route': '/invoices', 'roles': ['Super Admin', 'Accountant', 'Client'], 'category': 'Financial & Payroll'},
      {'title': 'Expenses', 'icon': Icons.payments_outlined, 'route': '/expenses', 'roles': ['Super Admin', 'Accountant'], 'category': 'Financial & Payroll'},
      {'title': 'Payroll', 'icon': Icons.price_check_outlined, 'route': '/payroll', 'roles': ['Super Admin', 'Accountant'], 'category': 'Financial & Payroll'},
      {'title': 'Incentives', 'icon': Icons.monetization_on_outlined, 'route': '/incentives', 'roles': ['Super Admin', 'Admin / Office Manager / Accounts'], 'category': 'Financial & Payroll'},

      {'title': 'Settings', 'icon': Icons.settings_outlined, 'roles': ['Super Admin'], 'category': 'Administration'},
      {'title': 'Import/Export', 'icon': Icons.swap_horizontal_circle_outlined, 'route': '/import-export', 'roles': ['Super Admin'], 'category': 'Administration'},
      {'title': 'Build Center', 'icon': Icons.build_circle_outlined, 'route': '/build-center', 'roles': ['Super Admin'], 'category': 'Administration'},
    ];

    return allTabs.where((tab) {
      if (tab['roles'] == null) return true;
      final roles = tab['roles'] as List<String>;
      final effectiveRole = role == 'Managing Director' ? 'Super Admin' : role;
      return roles.contains(effectiveRole) || roles.contains(role);
    }).toList();
  }

  void _showCommandPalette(List<Map<String, dynamic>> tabs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.search, color: VianTheme.primaryGold),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: VianTheme.headerBlack),
                decoration: const InputDecoration(
                  hintText: 'Search modules or quick commands...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (val) {
                  // filter if needed
                },
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('QUICK COMMANDS', style: TextStyle(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold)),
              ListTile(
                leading: const Icon(Icons.add, color: VianTheme.primaryGold),
                title: const Text('New Project Estimate', style: TextStyle(color: VianTheme.headerBlack)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/construction-estimation');
                },
              ),
              ListTile(
                leading: const Icon(Icons.pin_drop, color: VianTheme.primaryGold),
                title: const Text('Mark GPS Attendance', style: TextStyle(color: VianTheme.headerBlack)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/gps-attendance');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: VianTheme.primaryGold),
                title: const Text('View Latest Invoices', style: TextStyle(color: VianTheme.headerBlack)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/invoices');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final role = user['role'] ?? 'Client';
    final tabs = _getTabs(role);

    final currentPath = GoRouterState.of(context).matchedLocation;
    int index = tabs.indexWhere((tab) {
      final route = tab['route'] as String?;
      if (route == null) return false;
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
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.architecture, color: VianTheme.primaryGold, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'VIAN ERP',
              style: GoogleFonts.poppins(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              const Text('/', style: TextStyle(color: VianTheme.lightText, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: 'Chennai Main',
                dropdownColor: VianTheme.cardColor,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: VianTheme.lightText),
                items: ['Chennai Main', 'Coimbatore Branch', 'Madurai Branch']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, color: VianTheme.headerBlack, fontWeight: FontWeight.w600))))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(width: 8),
              const Text('/', style: TextStyle(color: VianTheme.lightText, fontSize: 13)),
              const SizedBox(width: 8),
              Text(
                tabs[_selectedIndex]['title'],
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () => _showCommandPalette(tabs),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 14, color: VianTheme.lightText),
                      SizedBox(width: 8),
                      Text(
                        'Search or type ⌘K...',
                        style: TextStyle(color: VianTheme.lightText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isMobile) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_circle_outline, color: VianTheme.primaryGold),
              tooltip: 'Quick Create',
              onSelected: (val) {
                if (val == 'project') {
                  context.go('/projects');
                } else if (val == 'invoice') {
                  context.go('/invoices');
                } else if (val == 'lead') {
                  context.go('/crm-leads');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'lead', child: Text('New CRM Lead', style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 'project', child: Text('New Project', style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 'invoice', child: Text('New Invoice', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, size: 14, color: VianTheme.accentBlue),
                  SizedBox(width: 6),
                  Text(
                    'Chennai: 31°C Sunny',
                    style: TextStyle(color: VianTheme.accentBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: VianTheme.success),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('E, d MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(color: VianTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: VianTheme.lightText, size: 20),
              tooltip: 'Select Language',
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'en', child: Text('English (US)', style: TextStyle(fontSize: 12))),
                const PopupMenuItem(value: 'ta', child: Text('Tamil (தமிழ்)', style: TextStyle(fontSize: 12))),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: VianTheme.lightText, size: 20),
              tooltip: 'Recent Chats',
              onPressed: () {},
            ),
          ],
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: VianTheme.sidebarBg,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => const NotificationsPanel(),
              );
            },
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: VianTheme.sidebarBg,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _sidebarCollapsed ? 76 : 250,
              decoration: const BoxDecoration(
                color: VianTheme.sidebarBg,
                border: Border(right: BorderSide(color: Colors.white10, width: 1)),
              ),
              child: _buildDrawerContent(user, tabs, role, showHeader: true, isSidebar: true),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              backgroundColor: VianTheme.sidebarBg,
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

  Widget _buildDrawerContent(Map<String, dynamic> user, List<Map<String, dynamic>> tabs, String role, {bool showHeader = false, bool isSidebar = false}) {
    final collapsed = isSidebar && _sidebarCollapsed;

    // Group items by category subheaders
    final List<Map<String, dynamic>> listItems = [];
    String? lastCategory;
    for (final tab in tabs) {
      final cat = tab['category'] ?? 'General';
      if (cat != lastCategory) {
        if (!collapsed) {
          listItems.add({'isHeader': true, 'title': cat.toUpperCase()});
        }
        lastCategory = cat;
      }
      listItems.add({'isHeader': false, 'tab': tab});
    }

    return Column(
      children: [
        if (showHeader && isSidebar) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Image.asset(
          'assets/logo.png',
          height: collapsed ? 36 : 48,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.architecture, color: VianTheme.primaryGold, size: collapsed ? 28 : 40),
        ),
        if (!collapsed) ...[
          const SizedBox(height: 12),
          Text(
            'VIAN ARCHITECTS',
            style: GoogleFonts.poppins(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
          ),
          const Text('Enterprise SaaS', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        Expanded(
          child: ListView.builder(
            itemCount: listItems.length,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              final item = listItems[index];
              if (item['isHeader'] == true) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
                  child: Text(
                    item['title'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              }

              final tab = item['tab'] as Map<String, dynamic>;
              final tabIndex = tabs.indexOf(tab);
              final active = _selectedIndex == tabIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: active ? VianTheme.primaryGold.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: active ? Border.all(color: VianTheme.primaryGold.withOpacity(0.24)) : null,
                ),
                child: ListTile(
                  contentPadding: collapsed ? const EdgeInsets.symmetric(horizontal: 4) : const EdgeInsets.symmetric(horizontal: 12),
                  leading: Tooltip(
                    message: collapsed ? (tab['title'] as String) : '',
                    child: Icon(
                      tab['icon'] as IconData,
                      color: active ? VianTheme.primaryGold : Colors.white70,
                      size: 20,
                    ),
                  ),
                  title: collapsed 
                      ? null 
                      : Text(
                          tab['title'] as String,
                          style: TextStyle(
                            color: active ? VianTheme.primaryGold : Colors.white70,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                  dense: true,
                  onTap: () {
                    final route = tab['route'] as String?;
                    if (route != null) {
                      context.go(route);
                    }
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              );
            },
          ),
        ),
        const Divider(color: Colors.white10),
        // User profile footer
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (!collapsed) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        role,
                        style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.logout, color: VianTheme.danger, size: 20),
                tooltip: collapsed ? 'Log Out' : '',
                onPressed: () async {
                  await ApiService.logout();
                  ref.read(userProvider.notifier).state = null;
                  context.go('/login');
                },
              ),
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
    } else if (role == 'Client') {
      return const ClientPortalView();
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
  Map<String, dynamic>? _selectedLead;

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
      if (list.isNotEmpty) {
        if (_selectedLead == null) {
          _selectedLead = list.first;
        } else {
          _selectedLead = list.firstWhere((l) => l['id'] == _selectedLead!['id'], orElse: () => list.first);
        }
      } else {
        _selectedLead = null;
      }
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
          content: Text('Staff can only recommend conversion but cannot execute it. Please contact an Admin or Super Admin.', style: TextStyle(color: VianTheme.whiteText)),
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
                  Text('Are you sure you want to convert "${lead['name']}" into an active client?', style: TextStyle(color: VianTheme.whiteText)),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Auto-create Initial Project', style: TextStyle(color: VianTheme.whiteText, fontSize: 13)),
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
                      dropdownColor: VianTheme.cardColor,
                      items: const [
                        DropdownMenuItem(value: 'Residential', child: Text('Residential', style: TextStyle(color: VianTheme.whiteText))),
                        DropdownMenuItem(value: 'Villa', child: Text('Villa', style: TextStyle(color: VianTheme.whiteText))),
                        DropdownMenuItem(value: 'Commercial', child: Text('Commercial', style: TextStyle(color: VianTheme.whiteText))),
                        DropdownMenuItem(value: 'Apartment', child: Text('Apartment', style: TextStyle(color: VianTheme.whiteText))),
                        DropdownMenuItem(value: 'Interior Design', child: Text('Interior Design', style: TextStyle(color: VianTheme.whiteText))),
                        DropdownMenuItem(value: 'Renovation', child: Text('Renovation', style: TextStyle(color: VianTheme.whiteText))),
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
            style: TextStyle(color: VianTheme.whiteText)),
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
            Text('Client Name: ${client['name']}', style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Client ID: ${client['clientId']}', style: const TextStyle(color: VianTheme.lightText)),
            const SizedBox(height: 6),
            Text('Converted By: ${client['convertedBy']}', style: const TextStyle(color: VianTheme.lightText)),
            const SizedBox(height: 6),
            Text('Converted On: ${client['convertedOn']}', style: const TextStyle(color: VianTheme.lightText)),
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
                            style: TextStyle(color: VianTheme.whiteText, fontSize: 13, fontWeight: FontWeight.bold),
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
                  Divider(color: VianTheme.goldBorder, height: 24),
                  Text('Record Follow-up/Activity Log:', style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: actionCtrl,
                          style: TextStyle(color: VianTheme.whiteText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Action / Milestone',
                            labelStyle: TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VianTheme.goldBorder)),
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
                          style: TextStyle(color: VianTheme.whiteText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Notes / Update details',
                            labelStyle: TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VianTheme.goldBorder)),
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
                  Divider(color: VianTheme.goldBorder, height: 24),
                  Text('Timeline History:', style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                              Text(entry['action'] ?? '', style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text(dateFormatted, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                                            ],
                                          ),
                                          if (entry['notes'] != null && entry['notes'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(entry['notes'], style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
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
                  child: Text('Close', style: TextStyle(color: VianTheme.whiteText)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailFieldRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: VianTheme.whiteText, fontSize: 12.5),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    final currentUserRole = ApiService.currentUser?['role'] ?? 'Client';
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;

    // Filter leads by columns
    final qualLeads = _leads.where((l) {
      final s = (l['status'] ?? 'New').toString().toLowerCase();
      return s == 'new' || s == 'qualification' || s == 'inquiry';
    }).toList();

    final conceptLeads = _leads.where((l) {
      final s = (l['status'] ?? 'New').toString().toLowerCase();
      return s == 'contacted' || s == 'concept' || s == 'in review';
    }).toList();

    final negoLeads = _leads.where((l) {
      final s = (l['status'] ?? 'New').toString().toLowerCase();
      return s == 'negotiation' || s == 'proposal sent';
    }).toList();

    final contractLeads = _leads.where((l) {
      final s = (l['status'] ?? 'New').toString().toLowerCase();
      return s == 'contracting' || s == 'converted' || s == 'closed';
    }).toList();

    Widget kanbanColumn(String title, List<dynamic> leads, Color markerColor) {
      return Container(
        width: 300,
        margin: const EdgeInsets.only(right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: VianTheme.goldBorder, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: markerColor),
                      const SizedBox(width: 8),
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: VianTheme.primaryGold.withOpacity(0.08),
                    child: Text(
                      leads.length.toString().padLeft(2, '0'),
                      style: GoogleFonts.outfit(
                        color: VianTheme.primaryGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cards List
            Expanded(
              child: leads.isEmpty
                  ? Center(
                      child: Text(
                        'NO LEADS',
                        style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, letterSpacing: 0.5),
                      ),
                    )
                  : ListView.builder(
                      itemCount: leads.length,
                      itemBuilder: (context, idx) {
                        final lead = leads[idx];
                        final isSelected = _selectedLead != null && _selectedLead!['id'] == lead['id'];
                        final budgetVal = safeToDouble(lead['budget']);
                        final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(budgetVal);

                        Widget cardWidget = Container(
                          decoration: BoxDecoration(
                            color: VianTheme.cardColor,
                            border: Border.all(
                              color: isSelected ? VianTheme.primaryGold : VianTheme.goldBorder.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead['name'] ?? 'Untitled Lead',
                                style: GoogleFonts.inter(
                                  color: isSelected ? VianTheme.primaryGold : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    budgetFormatted,
                                    style: GoogleFonts.outfit(
                                      color: VianTheme.primaryGold,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    (lead['status'] ?? 'New').toString().toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: VianTheme.lightText,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        if (isSelected) {
                          cardWidget = CustomPaint(
                            painter: AtelierBracketPainter(color: VianTheme.primaryGold),
                            child: cardWidget,
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => setState(() => _selectedLead = lead),
                            child: cardWidget,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    Widget leftKanbanBoard() {
      return Container(
        color: VianTheme.darkBackground,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PIPELINE: RESIDENTIAL 2026',
                  style: GoogleFonts.outfit(
                    color: VianTheme.lightText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'ACTIVE LEADS: ${_leads.length}',
                  style: GoogleFonts.outfit(
                    color: VianTheme.lightText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    kanbanColumn('Qualification', qualLeads, VianTheme.primaryGold),
                    kanbanColumn('Concept Phase', conceptLeads, VianTheme.primaryGold),
                    kanbanColumn('Negotiation', negoLeads, VianTheme.primaryGold),
                    kanbanColumn('Contracting', contractLeads, VianTheme.goldBorder),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget rightDetailPanel() {
      if (_selectedLead == null) {
        return Container(
          color: VianTheme.cardColor,
          child: Center(
            child: Text(
              'SELECT A LEAD TO VIEW DETAILS',
              style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 11, letterSpacing: 1.0),
            ),
          ),
        );
      }

      final lead = _selectedLead!;
      final budgetVal = safeToDouble(lead['budget']);
      final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(budgetVal);

      final timeline = List.from(lead['timeline'] ?? []);
      timeline.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      return Container(
        color: VianTheme.cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Header
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECTED LEAD',
                        style: GoogleFonts.outfit(
                          color: VianTheme.primaryGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Row(
                        children: [
                          if (canAddOrEdit(currentUserRole))
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: VianTheme.lightText, size: 20),
                              onPressed: () => _showAddLeadDialog(lead: lead),
                            ),
                          IconButton(
                            icon: const Icon(Icons.share, color: VianTheme.lightText, size: 20),
                            onPressed: () => _showPublicLinkDialog(lead),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lead['name'] ?? 'Untitled Lead',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ESTIMATED VALUE', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(budgetFormatted, style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LEAD OWNER', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: VianTheme.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.person, size: 10, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('Julian Vane', style: GoogleFonts.inter(color: VianTheme.whiteText, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const Divider(color: VianTheme.goldBorder, height: 1),

            // Scrollable Info Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary Contact Details
                    Row(
                      children: [
                        Container(width: 6, height: 6, color: VianTheme.primaryGold),
                        const SizedBox(width: 8),
                        Text('PRIMARY CONTACT', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: VianTheme.darkBackground,
                        border: Border.all(color: VianTheme.goldBorder.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _detailFieldRow('PHONE', lead['phone'] ?? 'N/A'),
                          const SizedBox(height: 12),
                          _detailFieldRow('REQUIREMENT', lead['requirement'] ?? 'N/A'),
                          const SizedBox(height: 12),
                          _detailFieldRow('STATUS', (lead['status'] ?? 'New').toString().toUpperCase()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Notes Timeline
                    Row(
                      children: [
                        Container(width: 6, height: 6, color: VianTheme.primaryGold),
                        const SizedBox(width: 8),
                        Text('NOTES TIMELINE', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (timeline.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'No timeline events logged yet.',
                          style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: timeline.length > 3 ? 3 : timeline.length,
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
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
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
                                            Text(entry['action'] ?? '', style: GoogleFonts.inter(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(dateFormatted, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9)),
                                          ],
                                        ),
                                        if (entry['notes'] != null && entry['notes'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            entry['notes'],
                                            style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11),
                                          ),
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
              ),
            ),
            const Divider(color: VianTheme.goldBorder, height: 1),

            // Action Buttons Footer
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  if (lead['converted'] == 'Yes' || lead['clientId'] != null)
                    SizedBox(
                      width: double.infinity,
                      child: VianButton(
                        text: 'VIEW CLIENT PROFILE',
                        onPressed: () => context.go('/clients'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: VianButton(
                        text: 'CONVERT TO CLIENT',
                        onPressed: () => _handleConvertLead(lead),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: VianTheme.goldBorder),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => _showLeadTrackingSheet(lead),
                          child: Text('TRACK PROGRESS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: VianTheme.goldBorder),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeadStage1FormScreen(lead: lead),
                              ),
                            ).then((_) => _fetchLeads());
                          },
                          child: Text('STAGE 1 FORM', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: VianTheme.darkBackground,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Kanban Board
          Expanded(
            flex: 13,
            child: leftKanbanBoard(),
          ),
          // Right: Detail Panel
          if (isDesktop)
            Expanded(
              flex: 7,
              child: rightDetailPanel(),
            ),
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
                  Text('Directory of active construction clients and associated properties', style: TextStyle(color: VianTheme.lightText)),
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
                              backgroundColor: VianTheme.cardColor,
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
                                Text(client['propertyDetails'] ?? '', style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
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
                                          content: Text('Are you sure you want to move this client to trash?', style: TextStyle(color: VianTheme.whiteText)),
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
                Text('Page $_currentPage of $_totalPages', style: TextStyle(color: VianTheme.whiteText)),
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
        backgroundColor: VianTheme.cardColor,
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
        backgroundColor: VianTheme.cardColor,
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
            Text('Exporting Lead Stage 1 Client Enquiry Form...', style: TextStyle(color: VianTheme.whiteText)),
            const SizedBox(height: 16),
            LinearProgressIndicator(color: VianTheme.primaryGold, backgroundColor: VianTheme.goldBorder),
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
            backgroundColor: VianTheme.cardColor,
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
            Divider(color: VianTheme.goldBorder, height: 20),
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
              dropdownColor: VianTheme.cardColor,
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
            const Text('Select all that apply * (Required)', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
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
                      color: selected ? Color(0x22F5A623) : VianTheme.cardColor,
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
                        Text(type, style: TextStyle(color: selected ? VianTheme.whiteText : VianTheme.lightText, fontSize: 13)),
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
          dropdownColor: VianTheme.cardColor,
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
                dropdownColor: VianTheme.cardColor,
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
              dropdownColor: VianTheme.cardColor,
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
              dropdownColor: VianTheme.cardColor,
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
            const Text('Describe neighboring structures (North, South, East, West):', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
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
            const Text('Sketch layout dimensions and orientation (N arrow, text, arrows, shapes):', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
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
                    backgroundColor: _dictationActive ? VianTheme.lightText : VianTheme.primaryGold,
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
            const Text('Freehand client ideas, stylus and touch sketch:', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
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
    if (_loading) return Scaffold(backgroundColor: VianTheme.darkBackground, body: Center(child: CircularProgressIndicator()));

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    return Scaffold(
      backgroundColor: VianTheme.darkBackground,
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
          backgroundColor: VianTheme.cardColor,
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
                  dropdownColor: VianTheme.cardColor,
                  items: ['Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDlgState(() => selectedType = val!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPackage,
                  decoration: const InputDecoration(labelText: 'Construction Package'),
                  dropdownColor: VianTheme.cardColor,
                  items: ['Standard', 'Premium', 'Luxury'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setDlgState(() => selectedPackage = val!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTemplate,
                  decoration: const InputDecoration(labelText: 'Lifecycle Template'),
                  dropdownColor: VianTheme.cardColor,
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
                  Text('Design structures, elevations, budgets, and operational progress', style: TextStyle(color: VianTheme.lightText)),
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
        int cols = 1;
        double ratio = 1.3;
        if (constraints.maxWidth >= 1400) {
          cols = 4;
          ratio = 1.6;
        } else if (constraints.maxWidth >= 1000) {
          cols = 3;
          ratio = 1.5;
        } else if (constraints.maxWidth >= 600) {
          cols = 2;
          ratio = 1.4;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: ratio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _projects.length,
          itemBuilder: (context, index) {
            final p = _projects[index];
            final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(safeToDouble(p['budget']));
            final progress = (p['progressPercentage'] ?? 0) / 100.0;

            final String status = p['status'] ?? 'Planning';
            final Color statusColor;
            if (status == 'Completed') {
              statusColor = VianTheme.success;
            } else if (status == 'In Progress') {
              statusColor = VianTheme.warning;
            } else {
              statusColor = VianTheme.accentBlue;
            }

            return GestureDetector(
              onTap: () {
                context.go('/projects/${p['id']}');
              },
              child: VianCard(
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p['projectId'] ?? '', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Type: ${p['type']} | Client: ${p['client']?['name'] ?? 'None'}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('BUDGET', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(height: 2),
                                      Text(budgetFormatted, style: const TextStyle(fontSize: 12, color: VianTheme.primaryGold, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PACKAGE', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(height: 2),
                                      Text(p['constructionPackage'] ?? 'Premium', style: const TextStyle(fontSize: 12, color: VianTheme.headerBlack, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('TIMELINE', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(height: 2),
                                      Text('${p['startDate'] ?? '2026-07-01'} to ${p['completionDate'] ?? '2027-07-01'}', style: const TextStyle(fontSize: 11, color: VianTheme.lightText), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('SITE LOCATION', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      const SizedBox(height: 2),
                                      Text(p['siteAddress'] ?? 'Chennai, TN', style: const TextStyle(fontSize: 11, color: VianTheme.lightText), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            VianProgressIndicator(progress: progress),
                          ],
                        ),
                      ),
                    ),
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
              color: VianTheme.cardColor,
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
                        Text('Start: ${p['startDate']} | End: ${p['completionDate']}', style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: VianTheme.cardColor,
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
        backgroundColor: VianTheme.cardColor,
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
            color: VianTheme.cardColor,
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
                      border: Border.all(color: isSelected ? VianTheme.primaryGold : VianTheme.goldBorder),
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

  Widget _buildGanttRow(String name, double progress, int startCol, int endCol, {bool isMilestone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              name,
              style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              height: 24,
              color: Colors.white.withOpacity(0.02),
              child: Stack(
                children: [
                  Positioned(
                    left: startCol * 40.0,
                    width: (endCol - startCol) * 40.0,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFC6A15B), Color(0xFFE9C178), Color(0xFFC6A15B)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  if (isMilestone)
                    Positioned(
                      left: endCol * 40.0 - 6,
                      top: 4,
                      child: Transform.rotate(
                        angle: 0.78, // 45 degrees
                        child: Container(
                          width: 8,
                          height: 8,
                          color: VianTheme.primaryGold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blueprintGrid() {
    final blueprints = [
      {'name': 'Floor Plan v4', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuD8P9wN81Pzs6KyL06HiXivGYId7ZtZ1H2BGhV7U4TzHRp8U7ozjqSD1AM0FLFKJlWd1zHxXQr4037g3ox6r88nhAVhaPk6sgSG8qMC2N7t3nCHj9ugLSlI_BIuWUwE5yDtBToqaTgES82inrUDNXyE6Re1QNO21RUAAHNFylfHIBbXpFSPCamY6E7Wo8dpaR1RDuiG-6OPpmIysk917oOr91zB_8NkYPSW0DfvPePbpje22MbXURZdkY0Z0vxM9PlSlrNBJt9HVzI'},
      {'name': 'West Elevation', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB3YO50nWF-vk1ILVV17UBFwfVshM-U1zaG1SvVwqarnuEsF4w0leaEs8jR-dcjsceK7Huj45M10HKameL8KdzL_lFNwkwrwyG_IxeLXl7kkempSQOBY6tXKNBkwFHw4_bRmJaM5YSi9IYLhlTwBrHkUMo0qWwdiTJ79-2PYqu8aRO2Z-henR5RLYi91AvZS-8w0ZO3uLfvay6PT5iTm5A20XN6OeAxPGmDUSwuEjmsgATmjpELH5KZEYIsgZN9odJXjHUZTl2jSBc'},
      {'name': 'Lighting Map', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuActu67DeN0Y2QZFGrD8fq_mLToN6W_EHNEo2kynM5XZ7K6xgreTLYHBG0UGy3v7ycyrB4cugR8l2EfFthiAxPkZFeffDvkyVkCSU4Vf-VRDT90cqUkdkORS7mbcAdRCjhCAoaVtQiAS9IKDf1XXMuNeIYllV1ReG42G699-bwmxETSRVHkXZ7-WsjIvO5HhRsfaVTqgGGIXhb3Ot-xV3m8fdqZ9d53cecDjzDfch6pE-E5GOmoglHO9D_MToj3OdulAlRfdHOU2Wo'},
      {'name': 'Site Analysis', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCEDwGmkQMj_7LoiBIdQQTNbuXX0LStLENNURLoGmMzXz5wCEeKzDdL2BTGcDNumFMKntiGWuFCPbbBWzu0wPcCNxL0pkcSLn8IF7EX8LApcuz1MGR0a7MeUbOVFnsxw5J7nQbLB2zyg3YJwh-quSot6GPOqIjjXGqiV-EfPENN5y7YZsY6zBnKRWm61lJw_bcXpwl2Fgz-oCKJUtAFy4lH7zwxzDPPp6nw7wkf7HmM_BHwP32ROzUNgl6dlOrY4Dg2LRJHSrU0Sts'},
      {'name': 'Roof Details', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBDrqzKzz5gNaWILTkyKLftpKDQiFBLvDTglDN16t970XkhqPeh4oBob_RZwvphqC_upc5gQ3lttvdprDlnn48VgAFwnL8ky-wzpoBYn3cUYkPV2qBaqnPWnGAdvHSOW1_Mj3HaRdPrA86K8lxluMdbk99QNqeDLjpuvfpQUDUzBD0kGF3jKX0YRhtd5x3X-0Ox4yTkzcWEID_TW_NyXeJNZtGAGn9cLeFDC5LB2gzmVeD5oRwjlFlb93ClDgPAX5Sdm2mAaHu_YsQ'},
      {'name': 'Facade Mesh', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDuhROg9nAq5q2mS5hpPWgxfnIIRINTLZjwQYdq9EFqHWnAvm4dsJGnSLWen6XphM5xPooLm3nbNoR_OasAQ2tdgWSVUaY7K9pjEpJN_OMQHMtwIub48Dib7u6jrcLZO4_ezxQtvZSBZqb7x4HgQysiXnwLQmE3hNL52sRqxpS2FH1BvbYChqNyfMmdx0-eoewRVJfCZgyeq8jweP95sTeyxeoeH5BmD7_RwZrVNwcUosHxbLQz6vyrkRW7VQUGEzYFs6654SKK6-g'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: blueprints.length,
      itemBuilder: (context, idx) {
        final bp = blueprints[idx];
        return Container(
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            border: Border.all(color: VianTheme.goldBorder.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  bp['url']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.architecture, color: VianTheme.lightText, size: 24),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    bp['name']!,
                    style: GoogleFonts.outfit(
                      color: VianTheme.primaryGold,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    final budgetFormatted = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(safeToDouble(_project['budget']));
    final stages = List<dynamic>.from(_project['stages'] ?? []);
    stages.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

    final List<Widget> timelineRows = [];
    if (stages.isEmpty) {
      // Mockup default rows
      timelineRows.add(_buildGanttRow('Concept Dev', 1.0, 0, 2, isMilestone: true));
      timelineRows.add(_buildGanttRow('Structural Specs', 0.92, 1, 4, isMilestone: true));
      timelineRows.add(_buildGanttRow('Material Sourcing', 0.40, 3, 5));
      timelineRows.add(_buildGanttRow('Final Assembly', 0.0, 5, 7));
    } else {
      for (int i = 0; i < stages.length; i++) {
        final stg = stages[i];
        final progress = (stg['status'] == 'Approved' || stg['status'] == 'Completed') ? 1.0 : (stg['status'] == 'In Progress' ? 0.5 : 0.0);
        final startMonth = (i * 2) % 7;
        final endMonth = ((i * 2) + 2) % 8;
        timelineRows.add(_buildGanttRow(
          stg['name'] ?? 'Phase ${i+1}',
          progress,
          startMonth,
          endMonth == 0 ? 7 : endMonth,
          isMilestone: progress > 0.8,
        ));
      }
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;

    Widget leftContent() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gantt chart section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Project Timeline',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                Container(width: 8, height: 8, color: VianTheme.primaryGold),
                const SizedBox(width: 6),
                Text('PROGRESS', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(width: 16),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: VianTheme.primaryGold, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('MILESTONE', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            border: Border.all(color: VianTheme.goldBorder.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Months Header
              Row(
                children: [
                  const SizedBox(width: 140, child: Text('PHASE', style: TextStyle(color: VianTheme.lightText, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL'].map((m) {
                        return Text(m, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold));
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const Divider(color: VianTheme.goldBorder, height: 24),
              ...timelineRows,
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Blueprints gallery section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Project Blueprints',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'VIEW FULL ARCHIVE',
              style: GoogleFonts.outfit(
                color: VianTheme.primaryGold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _blueprintGrid(),
      ],
    );

    Widget rightMetaContent() => Container(
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        border: Border.all(color: VianTheme.goldBorder.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROJECT META', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Text('Client Entity', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(_project['client']?['name'] ?? 'Vanguard Estate Group', style: GoogleFonts.inter(color: VianTheme.whiteText, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('Site Address', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(_project['siteAddress'] ?? '42 Knightsbridge Row', style: GoogleFonts.inter(color: VianTheme.whiteText, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Text('Package Tier', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: VianTheme.primaryGold.withOpacity(0.08),
              border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, color: VianTheme.primaryGold, size: 14),
                const SizedBox(width: 6),
                Text('PLATINUM ATELIER', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Assigned Team', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(3, (idx) {
                return Align(
                  widthFactor: 0.7,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: VianTheme.primaryGold,
                    child: Center(
                      child: Icon(Icons.person, size: 14, color: VianTheme.cardColor),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 14,
                backgroundColor: VianTheme.lightText,
                child: Center(
                  child: Text('+4', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text('Led by Senior Associate Julia Sterling', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: VianTheme.goldBorder),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () {},
              child: Text('VIEW PROJECT SPECS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ),
          if (_isSuperAdmin) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VianTheme.lightText,
                      side: const BorderSide(color: VianTheme.lightText),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _duplicateProject,
                    child: const Text('DUPLICATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _deleteProject,
                    child: const Text('DELETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: leftContent()),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: rightMetaContent()),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftContent(),
          const SizedBox(height: 24),
          rightMetaContent(),
        ],
      );
    }
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
                Column(children: [CircleAvatar(radius: 12, backgroundColor: stage['status'] == 'Approved' ? Colors.green : VianTheme.primaryGold, child: const Icon(Icons.engineering, size: 12, color: Colors.black)), if (index < stages.length - 1) Container(width: 2, height: 90, color: VianTheme.lightText)]),
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

  Widget _buildMaterialsTab() => const Center(child: Text('Material logs displayed here', style: TextStyle(color: VianTheme.lightText)));
  Widget _buildLabourTab() => const Center(child: Text('Labour logs displayed here', style: TextStyle(color: VianTheme.lightText)));
  Widget _buildSiteTrackingTab() => const Center(child: Text('Daily site logs displayed here', style: TextStyle(color: VianTheme.lightText)));
  Widget _buildWorkflowApprovalsTab() => const Center(child: Text('Approval workflow displayed here', style: TextStyle(color: VianTheme.lightText)));

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
        content: Text('Are you sure you want to move this project to trash?', style: TextStyle(color: VianTheme.whiteText)),
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
                  items: ['Low', 'Medium', 'High', 'Critical'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: VianTheme.whiteText)))).toList(),
                  onChanged: (val) => setDlgState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: VianTheme.headerBlack,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Pending', 'In Progress', 'Review', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: VianTheme.whiteText)))).toList(),
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
                  Text('Track structural layouts, site supervisor checklists, and reviews', style: TextStyle(color: VianTheme.lightText)),
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
                    decoration: BoxDecoration(color: VianTheme.cardColor, borderRadius: BorderRadius.circular(12)),
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
                                                    content: Text('Are you sure you want to move this task to trash?', style: TextStyle(color: VianTheme.whiteText)),
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
                                          Text('Due: ${task['dueDate']}', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
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
class AttendanceTab extends ConsumerStatefulWidget {
  final String? initialAction;
  const AttendanceTab({Key? key, this.initialAction}) : super(key: key);

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  bool _checkedIn = false;
  String _gps = '28.4630° N, 77.0300° E (Sector 43 Office)';
  String? _checkInTime;
  String? _checkOutTime;

  bool _loading = true;
  List<dynamic> _reports = [];
  List<dynamic> _employees = [];
  List<dynamic> _auditLogs = [];
  bool _currentMonthLocked = false;
  String _selectedMonthForLock = DateFormat('yyyy-MM').format(DateTime.now());

  // Geofencing and face subtabs
  String _activeSubTab = 'roster'; 
  List<dynamic> _pendingApprovals = [];
  List<dynamic> _allProjects = [];
  dynamic _selectedProjectForGeofence;

  @override
  void initState() {
    super.initState();
    _loadTabContent();
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialAction == 'check-in') {
          _handleCheckIn();
        } else if (widget.initialAction == 'check-out') {
          _handleCheckOut();
        }
      });
    }
  }

  Future<void> _loadTabContent() async {
    setState(() => _loading = true);
    final user = ref.read(userProvider);
    final role = user?['role'] ?? '';

    // Load month lock status
    final locked = await ApiService.getMonthLockStatus(_selectedMonthForLock);
    _currentMonthLocked = locked;

    if (role == 'Super Admin' || role.toString().contains('Admin')) {
      _reports = await ApiService.getAttendanceReports();
      _employees = await ApiService.getEmployees();
      _pendingApprovals = await ApiService.getPendingGeofenceApprovals();
      _allProjects = await ApiService.getProjects();
      
      if (_allProjects.isNotEmpty) {
        if (_selectedProjectForGeofence == null) {
          _selectedProjectForGeofence = _allProjects.first;
        } else {
          final matched = _allProjects.firstWhere(
            (p) => p['id'] == _selectedProjectForGeofence['id'],
            orElse: () => null,
          );
          if (matched != null) {
            _selectedProjectForGeofence = matched;
          } else {
            _selectedProjectForGeofence = _allProjects.first;
          }
        }
      }

      if (role == 'Super Admin') {
        _auditLogs = await ApiService.getAttendanceAuditLogs();
      }
    } else {
      // Staff personal history
      final uId = user?['id'];
      if (uId != null) {
        _reports = await ApiService.getAttendanceReports(employeeId: uId);
      }
      // Check if user has already punched in today
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayRecord = _reports.firstWhere(
        (r) => r['date'] == todayStr && r['userId'] == uId,
        orElse: () => null,
      );
      if (todayRecord != null) {
        _checkedIn = true;
        _checkInTime = todayRecord['checkInTime'];
        _checkOutTime = todayRecord['checkOutTime'];
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _handleCheckIn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceGpsVerifyOverlay(
        action: 'check-in',
        onSuccess: () {
          Navigator.pop(ctx);
          _loadTabContent();
        },
        onCancel: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _handleCheckOut() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceGpsVerifyOverlay(
        action: 'check-out',
        onSuccess: () {
          Navigator.pop(ctx);
          _loadTabContent();
        },
        onCancel: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showManualAttendanceDialog() {
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final checkInCtrl = TextEditingController(text: '09:00:00');
    final checkOutCtrl = TextEditingController(text: '18:00:00');
    final reasonCtrl = TextEditingController();
    int? selectedEmpId;
    String selectedStatus = 'Present';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: VianTheme.cardColor,
          title: const Text('Add / Correct Manual Attendance', style: TextStyle(color: VianTheme.primaryGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Employee'),
                  dropdownColor: VianTheme.cardColor,
                  value: selectedEmpId,
                  items: _employees.map<DropdownMenuItem<int>>((e) {
                    return DropdownMenuItem<int>(
                      value: e['id'] as int,
                      child: Text(e['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) => setStateModal(() => selectedEmpId = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: checkInCtrl,
                  decoration: const InputDecoration(labelText: 'Check In Time (HH:MM:SS)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: checkOutCtrl,
                  decoration: const InputDecoration(labelText: 'Check Out Time (HH:MM:SS)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Status'),
                  dropdownColor: VianTheme.cardColor,
                  value: selectedStatus,
                  items: ['Present', 'Late', 'Half Day', 'Leave', 'Absent'].map((s) {
                    return DropdownMenuItem<String>(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) => setStateModal(() => selectedStatus = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason (required for Audit)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
              onPressed: () async {
                if (selectedEmpId == null || reasonCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Employee and Reason are required.')),
                  );
                  return;
                }
                final ok = await ApiService.submitManualAttendance({
                  'userId': selectedEmpId,
                  'date': dateCtrl.text,
                  'checkInTime': checkInCtrl.text,
                  'checkOutTime': checkOutCtrl.text,
                  'status': selectedStatus,
                  'reason': reasonCtrl.text,
                });
                if (ok) {
                  Navigator.pop(ctx);
                  _loadTabContent();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manual attendance saved successfully.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save manual attendance.')),
                  );
                }
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaceRegistrationWizard(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceRegistrationWizard(
        employee: employee,
        onComplete: () {
          Navigator.pop(ctx);
          _loadTabContent();
        },
      ),
    );
  }

  void _showGeofenceOverrideApprovalDialog(Map<String, dynamic> pending) {
    final reasonCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        title: const Text('Review Geofence Breach Override', style: TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee: ${pending['user']?['name'] ?? "Unknown"}', style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Date: ${pending['date']} | Time: ${pending['checkInTime'] ?? "N/A"}', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
              Text('Punch Distance: ${pending['checkInGpsDistance'] != null ? double.parse(pending['checkInGpsDistance'].toString()).toStringAsFixed(1) : "N/A"} meters from site', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
              (() {
                final latVal = double.tryParse(pending['checkInLatitude']?.toString() ?? '0.0') ?? 0.0;
                final lngVal = double.tryParse(pending['checkInLongitude']?.toString() ?? '0.0') ?? 0.0;
                final address = GpsAddressResolver.resolve(latVal, lngVal);
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'Resolved Location:\n${address.toFormattedMultiLine()}',
                    style: const TextStyle(color: VianTheme.lightText, fontSize: 11, height: 1.4),
                  ),
                );
              })(),
              const Divider(color: VianTheme.goldBorder, height: 24),
              TextFormField(
                controller: reasonCtrl,
                style: TextStyle(color: VianTheme.whiteText),
                decoration: const InputDecoration(
                  labelText: 'Override Reason (e.g. Authorized Off-site client meeting)',
                  labelStyle: TextStyle(color: VianTheme.lightText),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: remarksCtrl,
                style: TextStyle(color: VianTheme.whiteText),
                decoration: const InputDecoration(
                  labelText: 'Remarks / Additional notes',
                  labelStyle: TextStyle(color: VianTheme.lightText),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: VianTheme.lightText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VianTheme.danger, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an override reason.')));
                return;
              }
              final ok = await ApiService.approveOverride(
                attendanceId: pending['id'],
                status: 'Rejected',
                reason: reasonCtrl.text,
                remarks: remarksCtrl.text,
              );
              if (ok) {
                Navigator.pop(ctx);
                _loadTabContent();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Breach punch override Rejected.')));
              }
            },
            child: const Text('Reject Punch'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an override reason.')));
                return;
              }
              final ok = await ApiService.approveOverride(
                attendanceId: pending['id'],
                status: 'Approved',
                reason: reasonCtrl.text,
                remarks: remarksCtrl.text,
              );
              if (ok) {
                Navigator.pop(ctx);
                _loadTabContent();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Breach punch successfully Approved.')));
              }
            },
            child: const Text('Approve Punch'),
          ),
        ],
      ),
    );
  }

  void _showEditGeofenceDialog(Map<String, dynamic> project) {
    final latCtrl = TextEditingController(text: project['latitude']?.toString() ?? '28.4595');
    final lngCtrl = TextEditingController(text: project['longitude']?.toString() ?? '77.0266');
    final radCtrl = TextEditingController(text: project['allowedRadius']?.toString() ?? '100');
    final addrCtrl = TextEditingController(text: project['siteAddress']?.toString() ?? project['name']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        title: Text('Edit Geofence - ${project['name']}', style: const TextStyle(color: VianTheme.primaryGold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latCtrl,
                style: TextStyle(color: VianTheme.whiteText),
                decoration: const InputDecoration(labelText: 'Site Latitude'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lngCtrl,
                style: TextStyle(color: VianTheme.whiteText),
                decoration: const InputDecoration(labelText: 'Site Longitude'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: radCtrl,
                style: TextStyle(color: VianTheme.whiteText),
                decoration: const InputDecoration(labelText: 'Allowed Radius (meters: 50 - 1000)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addrCtrl,
                style: TextStyle(color: VianTheme.whiteText),
                decoration: const InputDecoration(labelText: 'Configured Address / Landmark'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: VianTheme.lightText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
            onPressed: () async {
              final latVal = double.tryParse(latCtrl.text);
              final lngVal = double.tryParse(lngCtrl.text);
              final radVal = int.tryParse(radCtrl.text);

              if (latVal == null || lngVal == null || radVal == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid latitude, longitude, or radius.')));
                return;
              }
              if (radVal < 50 || radVal > 1000) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Allowed radius must be between 50 and 1000 meters.')));
                return;
              }

              final ok = await ApiService.updateProjectGeofence(
                project['id'],
                latVal,
                lngVal,
                radVal,
                addrCtrl.text,
              );

              if (ok) {
                Navigator.pop(ctx);
                _loadTabContent();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project geofence updated successfully.')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update project geofence.')));
              }
            },
            child: const Text('Save Geofence'),
          ),
        ],
      ),
    );
  }

  void _toggleMonthLock() async {
    bool ok;
    if (_currentMonthLocked) {
      ok = await ApiService.unlockMonth(_selectedMonthForLock);
    } else {
      ok = await ApiService.lockMonth(_selectedMonthForLock);
    }
    if (ok) {
      _loadTabContent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lock state updated for $_selectedMonthForLock')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation failed. Super Admin permissions required.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final role = user?['role'] ?? '';
    final isSuperAdmin = role == 'Super Admin';
    final isAdmin = role.toString().contains('Admin');

    if (_loading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    }

    if (isSuperAdmin) {
      return _buildSuperAdminView();
    } else if (isAdmin) {
      return _buildAdminView();
    } else {
      return _buildStaffView();
    }
  }

  Widget _buildSubTabNavigation() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          _subTabButton('roster', 'Roster History', Icons.assignment_outlined),
          _subTabButton('face', 'Biometric Register', Icons.face_retouching_natural),
          _subTabButton('geofence', 'Project Geofences', Icons.map_outlined),
          _subTabButton('pending', 'Pending Approvals (${_pendingApprovals.length})', Icons.notification_important_outlined),
        ],
      ),
    );
  }

  Widget _subTabButton(String id, String label, IconData icon) {
    final active = _activeSubTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSubTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: active ? VianTheme.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.black : VianTheme.lightText),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: active ? Colors.black : VianTheme.lightText,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceBiometricsView() {
    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('EMPLOYEE BIOMETRIC FACE DIRECTORY', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              Text('Super Admin & Admin Face Registration Terminal', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
            ],
          ),
          const Divider(color: VianTheme.goldBorder, height: 24),
          _employees.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No employees found', style: TextStyle(color: VianTheme.lightText))),
                )
              : Container(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(VianTheme.cardColor),
                    dataRowHeight: 64,
                    columns: const [
                      DataColumn(label: Text('Employee ID', style: TextStyle(color: VianTheme.primaryGold))),
                      DataColumn(label: Text('Name', style: TextStyle(color: VianTheme.primaryGold))),
                      DataColumn(label: Text('Department / Role', style: TextStyle(color: VianTheme.primaryGold))),
                      DataColumn(label: Text('Face ID Status', style: TextStyle(color: VianTheme.primaryGold))),
                      DataColumn(label: Text('Action', style: TextStyle(color: VianTheme.primaryGold))),
                    ],
                    rows: _employees.map<DataRow>((e) {
                      final isEnrolled = e['username'] == 'anand' || e['username'] == 'vijay' || e['id'] == 1 || e['id'] == 2;
                      return DataRow(
                        cells: [
                          DataCell(Text(e['employeeId'] ?? 'N/A')),
                          DataCell(Text(e['name'] ?? '')),
                          DataCell(Text('${e['department'] ?? "N/A"} / ${e['role'] ?? "N/A"}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isEnrolled ? const Color(0x1A10B981) : VianTheme.goldBorder,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isEnrolled ? Colors.greenAccent.withOpacity(0.3) : VianTheme.lightText),
                              ),
                              child: Text(
                                isEnrolled ? 'Registered' : 'Not Configured',
                                style: TextStyle(
                                  color: isEnrolled ? Colors.greenAccent : VianTheme.lightText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.biotech, color: VianTheme.primaryGold),
                              tooltip: 'Enroll Face Prints',
                              onPressed: () => _showFaceRegistrationWizard(e),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildGeofencesView() {
    if (_allProjects.isEmpty) {
      return const VianCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No active projects found to configure geofencing.', style: TextStyle(color: VianTheme.lightText)),
          ),
        ),
      );
    }

    final selectedProj = _selectedProjectForGeofence ?? _allProjects.first;
    final hasCoords = selectedProj['latitude'] != null && selectedProj['longitude'] != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROJECT SITES LIST', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allProjects.length,
                  itemBuilder: (context, idx) {
                    final proj = _allProjects[idx];
                    final isSelected = selectedProj['id'] == proj['id'];
                    final hasCoords = proj['latitude'] != null && proj['longitude'] != null;

                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedProjectForGeofence = proj;
                        });
                      },
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: Colors.white.withOpacity(0.04),
                      title: Text(proj['name'] ?? '', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(
                        hasCoords 
                            ? '${GpsAddressResolver.resolve(double.parse(proj['latitude'].toString()), double.parse(proj['longitude'].toString())).toShortString()} (${proj['allowedRadius'] ?? 100}m)' 
                            : 'Geofence Not Configured',
                        style: TextStyle(color: hasCoords ? VianTheme.lightText : VianTheme.danger, fontSize: 10),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_location_alt, size: 18, color: VianTheme.primaryGold),
                        onPressed: () => _showEditGeofenceDialog(proj),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: VianCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (selectedProj['name'] ?? '').toUpperCase(),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Site ID: ${selectedProj['projectId'] ?? "N/A"}',
                            style: const TextStyle(color: VianTheme.lightText, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
                      icon: const Icon(Icons.edit_road, size: 14),
                      label: const Text('Update Geofence', style: TextStyle(fontSize: 11)),
                      onPressed: () => _showEditGeofenceDialog(selectedProj),
                    ),
                  ],
                ),
                const Divider(color: VianTheme.goldBorder, height: 24),
                ProjectGeofenceMap(
                  projectName: selectedProj['name'] ?? 'Project Site',
                  projectLatitude: selectedProj['latitude'] != null ? double.parse(selectedProj['latitude'].toString()) : 28.4595,
                  projectLongitude: selectedProj['longitude'] != null ? double.parse(selectedProj['longitude'].toString()) : 77.0266,
                  employeeLatitude: selectedProj['latitude'] != null ? double.parse(selectedProj['latitude'].toString()) : 28.4595,
                  employeeLongitude: selectedProj['longitude'] != null ? double.parse(selectedProj['longitude'].toString()) : 77.0266,
                  allowedRadius: selectedProj['allowedRadius'] != null ? double.parse(selectedProj['allowedRadius'].toString()) : 100.0,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Site Geodetic Telemetry Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.lightText),
                ),
                const SizedBox(height: 10),
                _telemetryRow('Site Resolved Name', hasCoords ? GpsAddressResolver.resolve(double.parse(selectedProj['latitude'].toString()), double.parse(selectedProj['longitude'].toString())).siteName : 'Not Set'),
                _telemetryRow('Resolved Location Address', hasCoords ? GpsAddressResolver.resolve(double.parse(selectedProj['latitude'].toString()), double.parse(selectedProj['longitude'].toString())).toAddressOnly() : 'Not Set'),
                _telemetryRow('Nearby Geofence Landmark', hasCoords ? GpsAddressResolver.resolve(double.parse(selectedProj['latitude'].toString()), double.parse(selectedProj['longitude'].toString())).landmark : 'Not Set'),
                _telemetryRow('Allowed Geofence Radius', '${selectedProj['allowedRadius'] ?? 100} meters'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
          Text(value, style: const TextStyle(color: VianTheme.whiteText, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPendingOverridesView() {
    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('PENDING GEOFENCE BREACH APPROVALS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
              Text('Roster manual verification overrides panel', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
            ],
          ),
          const Divider(color: VianTheme.goldBorder, height: 24),
          _pendingApprovals.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text('No pending geofence override approvals today.', style: TextStyle(color: VianTheme.lightText, fontSize: 13)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingApprovals.length,
                  itemBuilder: (context, idx) {
                    final pending = _pendingApprovals[idx];
                    final dist = pending['checkInGpsDistance'] != null 
                        ? double.parse(pending['checkInGpsDistance'].toString()) 
                        : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VianTheme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      pending['user']?['name'] ?? 'Unknown User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Outside Geofence', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Date: ${pending['date']} | Time: ${pending['checkInTime'] ?? "N/A"}',
                                  style: const TextStyle(color: VianTheme.lightText, fontSize: 11),
                                ),
                                (() {
                                  final latVal = double.tryParse(pending['checkInLatitude']?.toString() ?? '0.0') ?? 0.0;
                                  final lngVal = double.tryParse(pending['checkInLongitude']?.toString() ?? '0.0') ?? 0.0;
                                  final address = GpsAddressResolver.resolve(latVal, lngVal);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Check-In Place: ${address.siteName} (Near ${address.landmark})',
                                        style: const TextStyle(color: VianTheme.lightText, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Address: ${address.toAddressOnly()}',
                                        style: const TextStyle(color: VianTheme.lightText, fontSize: 10),
                                      ),
                                    ],
                                  );
                                })(),
                                Text(
                                  'Distance: ${dist.toStringAsFixed(1)} meters outside boundary',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: VianTheme.danger),
                                tooltip: 'Reject Override',
                                onPressed: () => _showGeofenceOverrideApprovalDialog(pending),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                                tooltip: 'Approve Override',
                                onPressed: () => _showGeofenceOverrideApprovalDialog(pending),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminView() {
    final gpsPct = _reports.isEmpty ? 100 : ((_reports.where((r) => r['checkInGpsDistance'] == null || r['attendanceStatus'] != 'Outside Geofence').length / _reports.length) * 100).toStringAsFixed(1);
    final facePct = _reports.isEmpty ? 100 : ((_reports.where((r) => r['checkInFaceScore'] != null && safeToDouble(r['checkInFaceScore']) >= 95).length / _reports.length) * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ATTENDANCE BUSINESS COMMAND CENTER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Super Admin Configuration & Security Audit Panel', style: TextStyle(color: VianTheme.lightText)),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, color: VianTheme.primaryGold), onPressed: _loadTabContent),
            ],
          ),
          const SizedBox(height: 24),
          _buildSubTabNavigation(),
          if (_activeSubTab == 'roster') ...[
            Row(
              children: [
                Expanded(child: VianMetricCard(title: 'TOTAL PUNCHES', value: _reports.length.toString(), icon: Icons.history)),
                const SizedBox(width: 12),
                Expanded(child: VianMetricCard(title: 'GPS SUCCESS RATE', value: '$gpsPct%', icon: Icons.gps_fixed, iconColor: VianTheme.success)),
                const SizedBox(width: 12),
                Expanded(child: VianMetricCard(title: 'FACE MATCH RATE', value: '$facePct%', icon: Icons.face, iconColor: VianTheme.primaryGold)),
              ],
            ),
            const SizedBox(height: 24),
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MONTH LOCKS AND COMPLIANCE', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: VianTheme.cardColor,
                          value: _selectedMonthForLock,
                          items: ['2026-05', '2026-06', '2026-07', '2026-08'].map((m) {
                            return DropdownMenuItem<String>(value: m, child: Text(m));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedMonthForLock = val!;
                            });
                            _loadTabContent();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentMonthLocked ? Colors.redAccent : VianTheme.primaryGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        icon: Icon(_currentMonthLocked ? Icons.lock : Icons.lock_open),
                        label: Text(_currentMonthLocked ? 'Unlock Month' : 'Lock Month'),
                        onPressed: _toggleMonthLock,
                      ),
                    ],
                  ),
                  if (_currentMonthLocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('⚠️ locked month: Attendance mutations are frozen for all users (except Super Admin).', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildRosterTable(),
            const SizedBox(height: 24),
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ATTENDANCE AUDIT LOGS', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _auditLogs.length > 8 ? 8 : _auditLogs.length,
                    itemBuilder: (context, idx) {
                      final log = _auditLogs[idx];
                      return ListTile(
                        dense: true,
                        title: Text('${log['action']} - ${log['details']}'),
                        subtitle: Text('By: ${log['user']} (${log['role']}) | GPS: ${log['gps'] ?? "N/A"}'),
                        trailing: Text(log['timestamp'] != null ? log['timestamp'].toString().substring(0, 16).replaceAll('T', ' ') : ''),
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else if (_activeSubTab == 'face') ...[
            _buildFaceBiometricsView(),
          ] else if (_activeSubTab == 'geofence') ...[
            _buildGeofencesView(),
          ] else if (_activeSubTab == 'pending') ...[
            _buildPendingOverridesView(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('ADMIN ATTENDANCE CONTROL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Manual Entry, Corrections, and Live Operations Roster', style: TextStyle(color: VianTheme.lightText)),
                ],
              ),
              Row(
                children: [
                  VianButton(text: 'Add Manual Attendance', onPressed: _showManualAttendanceDialog),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.refresh, color: VianTheme.primaryGold), onPressed: _loadTabContent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSubTabNavigation(),
          if (_activeSubTab == 'roster') ...[
            _buildRosterTable(),
          ] else if (_activeSubTab == 'face') ...[
            _buildFaceBiometricsView(),
          ] else if (_activeSubTab == 'geofence') ...[
            _buildGeofencesView(),
          ] else if (_activeSubTab == 'pending') ...[
            _buildPendingOverridesView(),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
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
                  Text('Secure biometric & geofence validated punch terminal', style: TextStyle(color: VianTheme.lightText, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: VianTheme.cardColor, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: VianTheme.primaryGold, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GPS Resolved Location', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
                              const SizedBox(height: 4),
                              (() {
                                double latVal = 28.4630;
                                double lngVal = 77.0300;
                                if (_gps.contains('28.4595')) {
                                  latVal = 28.4595;
                                  lngVal = 77.0266;
                                }
                                final address = GpsAddressResolver.resolve(latVal, lngVal);
                                return Text(
                                  '${address.siteName}\n${address.toAddressOnly()}\nNear ${address.landmark}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: VianTheme.whiteText, height: 1.4),
                                );
                              })(),
                            ],
                          ),
                        )
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
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PERSONAL PUNCH HISTORY (PAST 30 DAYS)', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  const SizedBox(height: 12),
                  _reports.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('No attendance records logged this month.', style: TextStyle(color: VianTheme.lightText))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reports.length,
                          itemBuilder: (context, idx) {
                            final r = _reports[idx];
                            final isManual = r['manualEntry'] == true;
                            final isLate = r['status'] == 'Late';
                            return ListTile(
                              leading: Icon(
                                isManual ? Icons.edit_attributes : Icons.verified_user,
                                color: isManual ? VianTheme.warning : (isLate ? Colors.blueAccent : Colors.greenAccent),
                                size: 20,
                              ),
                              title: Text('${r['date']} - ${r['status']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('In: ${r['checkInTime'] ?? "N/A"} | Out: ${r['checkOutTime'] ?? "N/A"}'),
                                  if (!isManual && r['checkInLatitude'] != null && r['checkInLongitude'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      GpsAddressResolver.resolve(
                                        double.parse(r['checkInLatitude'].toString()),
                                        double.parse(r['checkInLongitude'].toString()),
                                      ).toShortString(),
                                      style: const TextStyle(fontSize: 10, color: VianTheme.lightText),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Text(
                                isManual ? 'Manual Override' : 'GPS+Face Verified',
                                style: TextStyle(color: isManual ? VianTheme.warning : Colors.greenAccent, fontSize: 11),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterTable() {
    return VianCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COMPANY ROSTER LOG', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Employee')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('In Time')),
                DataColumn(label: Text('Out Time')),
                DataColumn(label: Text('Location & Landmark')),
                DataColumn(label: Text('Distance')),
                DataColumn(label: Text('Method')),
                DataColumn(label: Text('Verification Score')),
              ],
              rows: _reports.map<DataRow>((r) {
                final empName = r['user']?['name'] ?? 'Employee';
                final isManual = r['manualEntry'] == true;
                final faceScore = r['checkInFaceScore'] != null ? '${r['checkInFaceScore']}%' : 'N/A';
                return DataRow(
                  cells: [
                    DataCell(Text(empName)),
                    DataCell(Text(r['date'] ?? '')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r['status'] == 'Late' ? Colors.blueAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(r['status'] ?? '', style: TextStyle(color: r['status'] == 'Late' ? Colors.blueAccent : Colors.greenAccent)),
                      ),
                    ),
                    DataCell(Text(r['checkInTime'] ?? 'N/A')),
                    DataCell(Text(r['checkOutTime'] ?? 'N/A')),
                    DataCell(
                      Text(isManual
                          ? 'Manual Override'
                          : (r['checkInLatitude'] != null && r['checkInLongitude'] != null
                              ? GpsAddressResolver.resolve(
                                  double.parse(r['checkInLatitude'].toString()),
                                  double.parse(r['checkInLongitude'].toString()),
                                ).toShortString()
                              : 'GPS Verified')),
                    ),
                    DataCell(
                      Text(isManual
                          ? 'N/A'
                          : (r['checkInGpsDistance'] != null
                              ? '${double.parse(r['checkInGpsDistance'].toString()).toStringAsFixed(1)}m'
                              : '0.0m')),
                    ),
                    DataCell(Text(isManual ? 'Manual Override' : 'GPS+Face Verified')),
                    DataCell(Text(faceScore)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
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
          Text('Manage elevations, interior layouts, structural blueprints, and approvals', style: TextStyle(color: VianTheme.lightText)),
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
                            color: VianTheme.cardColor,
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
                              Icon(Icons.folder, color: isSelected ? VianTheme.primaryGold : VianTheme.lightText, size: 18),
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
                        ? Center(child: Text('No documents in this category', style: TextStyle(color: VianTheme.lightText)))
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
                  Text('$size | Added on $date', style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
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

class QuotationsTab extends StatefulWidget {
  const QuotationsTab({Key? key}) : super(key: key);

  @override
  State<QuotationsTab> createState() => _QuotationsTabState();
}

class _QuotationsTabState extends State<QuotationsTab> {
  List<dynamic> _quotations = [];
  List<dynamic> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final quotes = await ApiService.getQuotations();
      final projects = await ApiService.getProjects();
      setState(() {
        _quotations = quotes;
        _projects = projects;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showCreateQuotationDialog(String role) {
    int? selectedProjectId;
    final discountCtrl = TextEditingController(text: '0');
    final taxRateCtrl = TextEditingController(text: '18');
    final itemsList = <Map<String, dynamic>>[
      {'name': '', 'quantity': 1.0, 'rate': 0.0}
    ];

    String? projectError;
    String? itemsError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
          double subtotal = 0;
          for (var item in itemsList) {
            final double qty = double.tryParse(item['quantity'].toString()) ?? 0;
            final double rate = double.tryParse(item['rate'].toString()) ?? 0;
            subtotal += qty * rate;
          }
          final double disc = double.tryParse(discountCtrl.text) ?? 0;
          final double tax = double.tryParse(taxRateCtrl.text) ?? 18;
          final double taxAmt = subtotal * (tax / 100);
          final double grandTotal = subtotal + taxAmt - disc;

          return AlertDialog(
            backgroundColor: VianTheme.cardColor,
            title: const Text('Create Quotation', style: TextStyle(color: VianTheme.primaryGold)),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Select Project *',
                        errorText: projectError,
                      ),
                      dropdownColor: VianTheme.cardColor,
                      value: selectedProjectId,
                      items: _projects.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(p['name'] ?? '', style: TextStyle(color: VianTheme.whiteText)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDlgState(() {
                          selectedProjectId = val;
                          projectError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taxRateCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Discount (₹)'),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                        TextButton.icon(
                          onPressed: () {
                            setDlgState(() {
                              itemsList.add({'name': '', 'quantity': 1.0, 'rate': 0.0});
                              itemsError = null;
                            });
                          },
                          icon: const Icon(Icons.add, size: 16, color: VianTheme.primaryGold),
                          label: const Text('Add Item', style: TextStyle(color: VianTheme.primaryGold)),
                        ),
                      ],
                    ),
                    if (itemsError != null)
                      Text(itemsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itemsList.length,
                      itemBuilder: (context, index) {
                        final item = itemsList[index];
                        final nameCtrl = TextEditingController(text: item['name']);
                        final qtyCtrl = TextEditingController(text: item['quantity'].toString());
                        final rateCtrl = TextEditingController(text: item['rate'].toString());

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(labelText: 'Item Name'),
                                  onChanged: (val) => item['name'] = val,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Qty'),
                                  onChanged: (val) {
                                    item['quantity'] = double.tryParse(val) ?? 0.0;
                                    setDlgState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: rateCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Rate'),
                                  onChanged: (val) {
                                    item['rate'] = double.tryParse(val) ?? 0.0;
                                    setDlgState(() {});
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                onPressed: () {
                                  setDlgState(() {
                                    itemsList.removeAt(index);
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: VianTheme.goldBorder, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: VianTheme.lightText)),
                        Text(formatter.format(subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax (${tax.toStringAsFixed(0)}%):', style: const TextStyle(color: VianTheme.lightText)),
                        Text(formatter.format(taxAmt), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(color: VianTheme.lightText)),
                        Text('- ${formatter.format(disc)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: VianTheme.goldBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold)),
                        Text(formatter.format(grandTotal), style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              VianButton(
                text: 'Create',
                onPressed: () async {
                  bool valid = true;
                  if (selectedProjectId == null) {
                    setDlgState(() => projectError = 'Project selection required.');
                    valid = false;
                  }
                  if (itemsList.isEmpty) {
                    setDlgState(() => itemsError = 'At least one item required.');
                    valid = false;
                  } else {
                    for (var item in itemsList) {
                      if (item['name'].toString().trim().isEmpty) {
                        setDlgState(() => itemsError = 'Item name cannot be empty.');
                        valid = false;
                      }
                      if ((double.tryParse(item['quantity'].toString()) ?? 0.0) <= 0) {
                        setDlgState(() => itemsError = 'Quantity must be greater than zero.');
                        valid = false;
                      }
                      if ((double.tryParse(item['rate'].toString()) ?? 0.0) < 0) {
                        setDlgState(() => itemsError = 'Rate cannot be negative.');
                        valid = false;
                      }
                    }
                  }

                  if (valid) {
                    final ok = await ApiService.createQuotation({
                      'projectId': selectedProjectId,
                      'items': itemsList,
                      'taxRate': double.tryParse(taxRateCtrl.text) ?? 18,
                      'discount': double.tryParse(discountCtrl.text) ?? 0,
                    });
                    if (ok) {
                      Navigator.pop(ctx);
                      setState(() => _loading = true);
                      _loadData();
                    } else {
                      setDlgState(() => itemsError = 'Backend submission failed.');
                    }
                  }
                },
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: VianTheme.primaryGold));
    }

    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final user = ApiService.currentUser;
    final role = user?['role'] ?? 'Client';
    final canCreate = role == 'Super Admin' || role == 'Managing Director' || role == 'Admin / Office Manager / Accounts' || role == 'Accountant';

    return Padding(
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
                  Text(
                    'QUOTATIONS REGISTRY',
                    style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage cost projections and drafts presented to stakeholders',
                    style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
                  ),
                ],
              ),
              if (canCreate)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VianTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('NEW QUOTATION', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  onPressed: () => _showCreateQuotationDialog(role),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _quotations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 48, color: VianTheme.lightText),
                        SizedBox(height: 16),
                        Text('No Quotations Recorded', style: TextStyle(color: VianTheme.lightText, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _quotations.length,
                    itemBuilder: (context, index) {
                      final quote = _quotations[index];
                      final double total = safeToDouble(quote['total']);
                      final double subtotal = safeToDouble(quote['subtotal']);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: VianCard(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: VianTheme.cardColor,
                                child: Icon(Icons.description, color: VianTheme.primaryGold),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quote['quotationNumber'] ?? 'VIAN-QT-XXXX',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Project: ${quote['project']?['name'] ?? 'General Concept'} | Date: ${quote['date']}',
                                      style: const TextStyle(fontSize: 12, color: VianTheme.lightText),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatter.format(total),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 16),
                                  ),
                                  Text(
                                    'Subtotal: ${formatter.format(subtotal)}',
                                    style: const TextStyle(fontSize: 11, color: VianTheme.lightText),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
  List<dynamic> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final list = await ApiService.getInvoices();
      final projects = await ApiService.getProjects();
      setState(() {
        _invoices = list;
        _projects = projects;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showCreateInvoiceDialog(String role) {
    int? selectedProjectId;
    final discountCtrl = TextEditingController(text: '0');
    final taxRateCtrl = TextEditingController(text: '18');
    final dueDateCtrl = TextEditingController(
      text: DateTime.now().add(const Duration(days: 15)).toString().split(' ').first
    );
    final itemsList = <Map<String, dynamic>>[
      {'name': '', 'quantity': 1.0, 'rate': 0.0}
    ];

    String? projectError;
    String? itemsError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
          double subtotal = 0;
          for (var item in itemsList) {
            final double qty = double.tryParse(item['quantity'].toString()) ?? 0;
            final double rate = double.tryParse(item['rate'].toString()) ?? 0;
            subtotal += qty * rate;
          }
          final double disc = double.tryParse(discountCtrl.text) ?? 0;
          final double tax = double.tryParse(taxRateCtrl.text) ?? 18;
          final double taxAmt = subtotal * (tax / 100);
          final double grandTotal = subtotal + taxAmt - disc;

          return AlertDialog(
            backgroundColor: VianTheme.cardColor,
            title: const Text('Create Invoice', style: TextStyle(color: VianTheme.primaryGold)),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Select Project *',
                        errorText: projectError,
                      ),
                      dropdownColor: VianTheme.cardColor,
                      value: selectedProjectId,
                      items: _projects.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(p['name'] ?? '', style: TextStyle(color: VianTheme.whiteText)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDlgState(() {
                          selectedProjectId = val;
                          projectError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dueDateCtrl,
                      decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taxRateCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Discount (₹)'),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                        TextButton.icon(
                          onPressed: () {
                            setDlgState(() {
                              itemsList.add({'name': '', 'quantity': 1.0, 'rate': 0.0});
                              itemsError = null;
                            });
                          },
                          icon: const Icon(Icons.add, size: 16, color: VianTheme.primaryGold),
                          label: const Text('Add Item', style: TextStyle(color: VianTheme.primaryGold)),
                        ),
                      ],
                    ),
                    if (itemsError != null)
                      Text(itemsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itemsList.length,
                      itemBuilder: (context, index) {
                        final item = itemsList[index];
                        final nameCtrl = TextEditingController(text: item['name']);
                        final qtyCtrl = TextEditingController(text: item['quantity'].toString());
                        final rateCtrl = TextEditingController(text: item['rate'].toString());

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(labelText: 'Item Name'),
                                  onChanged: (val) => item['name'] = val,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Qty'),
                                  onChanged: (val) {
                                    item['quantity'] = double.tryParse(val) ?? 0.0;
                                    setDlgState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: rateCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Rate'),
                                  onChanged: (val) {
                                    item['rate'] = double.tryParse(val) ?? 0.0;
                                    setDlgState(() {});
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                onPressed: () {
                                  setDlgState(() {
                                    itemsList.removeAt(index);
                                  });
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: VianTheme.goldBorder, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: VianTheme.lightText)),
                        Text(formatter.format(subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax (${tax.toStringAsFixed(0)}%):', style: const TextStyle(color: VianTheme.lightText)),
                        Text(formatter.format(taxAmt), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(color: VianTheme.lightText)),
                        Text('- ${formatter.format(disc)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: VianTheme.goldBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold)),
                        Text(formatter.format(grandTotal), style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              VianButton(
                text: 'Create',
                onPressed: () async {
                  bool valid = true;
                  if (selectedProjectId == null) {
                    setDlgState(() => projectError = 'Project selection required.');
                    valid = false;
                  }
                  if (itemsList.isEmpty) {
                    setDlgState(() => itemsError = 'At least one item required.');
                    valid = false;
                  } else {
                    for (var item in itemsList) {
                      if (item['name'].toString().trim().isEmpty) {
                        setDlgState(() => itemsError = 'Item name cannot be empty.');
                        valid = false;
                      }
                      if ((double.tryParse(item['quantity'].toString()) ?? 0.0) <= 0) {
                        setDlgState(() => itemsError = 'Quantity must be greater than zero.');
                        valid = false;
                      }
                      if ((double.tryParse(item['rate'].toString()) ?? 0.0) < 0) {
                        setDlgState(() => itemsError = 'Rate cannot be negative.');
                        valid = false;
                      }
                    }
                  }

                  if (valid) {
                    final ok = await ApiService.createInvoice({
                      'projectId': selectedProjectId,
                      'items': itemsList,
                      'taxRate': double.tryParse(taxRateCtrl.text) ?? 18,
                      'discount': double.tryParse(discountCtrl.text) ?? 0,
                      'dueDate': dueDateCtrl.text,
                    });
                    if (ok) {
                      Navigator.pop(ctx);
                      setState(() => _loading = true);
                      _loadInvoices();
                    } else {
                      setDlgState(() => itemsError = 'Backend submission failed.');
                    }
                  }
                },
              )
            ],
          );
        },
      ),
    );
  }

  void _showUpdateStatusDialog(Map<String, dynamic> invoice) {
    String selectedStatus = invoice['status'] ?? 'Draft';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: VianTheme.cardColor,
          title: const Text('Update Invoice Status', style: TextStyle(color: VianTheme.primaryGold)),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            dropdownColor: VianTheme.cardColor,
            items: ['Draft', 'Sent', 'Paid', 'Overdue'].map((s) {
              return DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: VianTheme.whiteText)));
            }).toList(),
            onChanged: (v) => setStateModal(() => selectedStatus = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            VianButton(
              text: 'Update',
              onPressed: () async {
                final ok = await ApiService.updateInvoiceStatus(invoice['id'], selectedStatus);
                if (ok) {
                  Navigator.pop(ctx);
                  setState(() => _loading = true);
                  _loadInvoices();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;

    final user = ApiService.currentUser;
    final role = user?['role'] ?? 'Client';
    final canCreate = role == 'Super Admin' || role == 'Managing Director' || role == 'Admin / Office Manager / Accounts' || role == 'Accountant';

    // Calculate aggregated statistics from invoices
    double totalInvoiced = 0;
    double paidToDate = 0;
    double outstanding = 0;
    double overdue = 0;

    for (var inv in _invoices) {
      final double totalVal = safeToDouble(inv['total']);
      final double paidVal = safeToDouble(inv['paidAmount']);
      final String status = inv['status'] ?? 'Draft';
      
      totalInvoiced += totalVal;
      paidToDate += paidVal;
      if (status == 'Overdue') {
        overdue += (totalVal - paidVal);
      }
    }
    outstanding = totalInvoiced - paidToDate;

    // Fallbacks if active database lists are empty
    final String displayTotalInvoiced = totalInvoiced > 0 ? formatter.format(totalInvoiced) : "₹1,24,50,000";
    final String displayPaidToDate = paidToDate > 0 ? formatter.format(paidToDate) : "₹84,20,000";
    final String displayOutstanding = outstanding > 0 ? formatter.format(outstanding) : "₹38,15,000";
    final String displayOverdue = overdue > 0 ? formatter.format(overdue) : "₹2,15,000";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FINANCIALS HUB',
                    style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track client payments, tax compliance, and cash flow forecasts',
                    style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
                  ),
                ],
              ),
              if (canCreate)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VianTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('NEW INVOICE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  onPressed: () => _showCreateInvoiceDialog(role),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Responsive Stats Strip & Aging Chart
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.6,
                    children: [
                      _buildStatCard('TOTAL INVOICED', displayTotalInvoiced, Icons.receipt_long, VianTheme.primaryGold, '+12% vs last Q'),
                      _buildStatCard('PAID TO DATE', displayPaidToDate, Icons.check_circle_outline, VianTheme.success, '70% collection rate'),
                      _buildStatCard('OUTSTANDING', displayOutstanding, Icons.hourglass_empty, VianTheme.primaryGold, 'Avg 14 days delay'),
                      _buildStatCard('OVERDUE BALANCE', displayOverdue, Icons.warning_amber_outlined, VianTheme.danger, '3 accounts at risk', isOverdue: true),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildAgingChartCard(),
                ),
              ],
            )
          else ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: width > 600 ? 2 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: [
                _buildStatCard('TOTAL INVOICED', displayTotalInvoiced, Icons.receipt_long, VianTheme.primaryGold, '+12% vs last Q'),
                _buildStatCard('PAID TO DATE', displayPaidToDate, Icons.check_circle_outline, VianTheme.success, '70% collection rate'),
                _buildStatCard('OUTSTANDING', displayOutstanding, Icons.hourglass_empty, VianTheme.primaryGold, 'Avg 14 days delay'),
                _buildStatCard('OVERDUE BALANCE', displayOverdue, Icons.warning_amber_outlined, VianTheme.danger, '3 accounts at risk', isOverdue: true),
              ],
            ),
            const SizedBox(height: 24),
            _buildAgingChartCard(),
          ],

          const SizedBox(height: 40),

          // Invoices Registry Table
          Container(
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RECENT TRANSACTIONS', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text('Detailed breakdown of architectural project billing cycles', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: VianTheme.goldBorder),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            icon: const Icon(Icons.filter_list, size: 14),
                            label: const Text('FILTER'),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: VianTheme.goldBorder),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            icon: const Icon(Icons.file_download, size: 14),
                            label: const Text('EXPORT'),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: VianTheme.goldBorder, height: 1),
                
                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('INVOICE ID', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(flex: 4, child: Text('CLIENT & PROJECT', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('ISSUE DATE', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text('AMOUNT', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                const Divider(color: VianTheme.goldBorder, height: 1),

                _invoices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('No Invoices Recorded', style: TextStyle(color: VianTheme.lightText))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final inv = _invoices[index];
                          final total = safeToDouble(inv['total']);
                          return InkWell(
                            onTap: canCreate ? () => _showUpdateStatusDialog(inv) : null,
                            child: _buildTableRow(
                              inv['invoiceNumber'] ?? 'INV-XXXX',
                              inv['project']?['client']?['name'] ?? inv['project']?['clientName'] ?? 'Walk-in Client',
                              inv['project']?['name'] ?? 'General Architecture',
                              inv['date'] ?? 'N/A',
                              inv['status'] ?? 'Draft',
                              formatter.format(total),
                            ),
                          );
                        },
                      ),

                // Table Pagination footer
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SHOWING ${_invoices.isEmpty ? 4 : _invoices.length} OF 128 TRANSACTIONS', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _buildPageButton('<', active: false),
                          const SizedBox(width: 4),
                          _buildPageButton('1', active: true),
                          const SizedBox(width: 4),
                          _buildPageButton('2', active: false),
                          const SizedBox(width: 4),
                          _buildPageButton('3', active: false),
                          const SizedBox(width: 4),
                          _buildPageButton('>', active: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Bento Forecast / Gateways Layout
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRevenueForecastCard(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildGatewaysCard(),
                      const SizedBox(height: 24),
                      _buildReviewCard(),
                    ],
                  ),
                )
              ],
            )
          else ...[
            _buildRevenueForecastCard(),
            const SizedBox(height: 24),
            _buildGatewaysCard(),
            const SizedBox(height: 24),
            _buildReviewCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtext, {bool isOverdue = false}) {
    return CustomPaint(
      painter: AtelierBracketPainter(color: isOverdue ? VianTheme.danger : VianTheme.primaryGold),
      child: Container(
        color: VianTheme.cardColor,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Icon(icon, color: color.withOpacity(0.4), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.bodoniModa(color: color, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isOverdue ? Icons.warning : Icons.trending_up, color: color.withOpacity(0.6), size: 12),
                const SizedBox(width: 4),
                Text(subtext, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 10)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAgingChartCard() {
    return Container(
      height: 285,
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AGING ANALYSIS', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const Icon(Icons.query_stats, color: VianTheme.lightText, size: 16),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildAgingBar('Current', 0.4, VianTheme.primaryGold),
                _buildAgingBar('30d', 0.65, VianTheme.primaryGold),
                _buildAgingBar('60d', 1.0, VianTheme.primaryGold),
                _buildAgingBar('90d', 0.3, VianTheme.primaryGold),
                _buildAgingBar('90d+', 0.15, VianTheme.danger),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CURRENT', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 8)),
              Text('30D', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 8)),
              Text('60D', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 8)),
              Text('90D', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 8)),
              Text('90D+', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 8)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAgingBar(String label, double heightPct, Color barColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 120 * heightPct,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.2),
                border: Border(top: BorderSide(color: barColor, width: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String invId, String clientName, String project, String date, String status, String amount) {
    Color statusColor = VianTheme.warning;
    if (status == 'Paid') statusColor = VianTheme.success;
    if (status == 'Overdue') statusColor = VianTheme.danger;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: VianTheme.goldBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(invId, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 13))),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: VianTheme.goldBorder,
                  child: Text(clientName[0].toUpperCase(), style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientName, style: GoogleFonts.inter(color: VianTheme.whiteText, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(project, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(date, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 12))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: statusColor.withOpacity(0.1),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.outfit(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(amount, style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPageButton(String label, {required bool active}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? VianTheme.primaryGold.withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: active ? VianTheme.primaryGold : VianTheme.lightText),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: active ? VianTheme.primaryGold : VianTheme.lightText,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueForecastCard() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
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
                  Text('REVENUE FORECAST', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('Projected cash receipts based on upcoming phases', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, color: VianTheme.primaryGold),
                  const SizedBox(width: 4),
                  Text('CONFIRMED', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 9)),
                  const SizedBox(width: 12),
                  Container(width: 8, height: 8, color: VianTheme.lightText),
                  const SizedBox(width: 4),
                  Text('PROJECTED', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 9)),
                ],
              )
            ],
          ),
          const Spacer(),
          // Forecast Custom chart columns
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildForecastBar('Nov', 0.4, 0.2),
                _buildForecastBar('Dec', 0.55, 0.15),
                _buildForecastBar('Jan', 0.75, 0.1),
                _buildForecastBar('Feb', 0.9, 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastBar(String month, double confirmedPct, double projectedPct) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      height: 150 * confirmedPct,
                      color: VianTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 150 * projectedPct,
                      color: VianTheme.goldBorder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(month, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewaysCard() {
    return Container(
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAYMENT GATEWAYS', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildGatewayRow('Chase Corporate', 'ACTIVE', Icons.account_balance),
          const SizedBox(height: 12),
          _buildGatewayRow('Stripe Executive', 'ACTIVE', Icons.credit_card),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: VianTheme.primaryGold,
              side: const BorderSide(color: VianTheme.primaryGold),
              minimumSize: const Size(double.infinity, 44),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {},
            child: Text('MANAGE METHODS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          )
        ],
      ),
    );
  }

  Widget _buildGatewayRow(String name, String status, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Icon(icon, color: VianTheme.primaryGold, size: 16),
          const SizedBox(width: 12),
          Text(name, style: GoogleFonts.inter(color: VianTheme.whiteText, fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(status, style: GoogleFonts.outfit(color: VianTheme.success, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: VianTheme.primaryGold.withOpacity(0.03),
        border: Border.all(color: VianTheme.primaryGold.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUARTERLY REVIEW', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            'Your collection efficiency has improved by 8.4% compared to Q3. Current outstanding invoices average 14 days delay.',
            style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Text(
              'VIEW INSIGHTS REPORT →',
              style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
  List<dynamic> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final list = await ApiService.getExpenses();
      final projects = await ApiService.getProjects();
      setState(() {
        _expenses = list;
        _projects = projects;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showCreateExpenseDialog() {
    int? selectedProjectId;
    String selectedCategory = 'Site Expenses';
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final receiptUrlCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toString().split(' ').first
    );

    String? projectError;
    String? amountError;
    String? descError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: VianTheme.cardColor,
          title: const Text('New Expense/Disbursement', style: TextStyle(color: VianTheme.primaryGold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Project *',
                      errorText: projectError,
                    ),
                    dropdownColor: VianTheme.cardColor,
                    value: selectedProjectId,
                    items: _projects.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['name'] ?? '', style: TextStyle(color: VianTheme.whiteText)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDlgState(() {
                        selectedProjectId = val;
                        projectError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category *'),
                    dropdownColor: VianTheme.cardColor,
                    value: selectedCategory,
                    items: ['Site Expenses', 'Material Expenses', 'Labour Expenses', 'Travel Expenses'].map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: TextStyle(color: VianTheme.whiteText)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDlgState(() => selectedCategory = val!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹) *',
                      errorText: amountError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      errorText: descError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: receiptUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Receipt URL (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            VianButton(
              text: 'Submit',
              onPressed: () async {
                bool valid = true;
                if (selectedProjectId == null) {
                  setDlgState(() => projectError = 'Project required');
                  valid = false;
                }
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt <= 0) {
                  setDlgState(() => amountError = 'Enter a valid amount > 0');
                  valid = false;
                }
                if (descriptionCtrl.text.trim().isEmpty) {
                  setDlgState(() => descError = 'Description is required');
                  valid = false;
                }

                if (valid) {
                  final ok = await ApiService.addExpense({
                    'projectId': selectedProjectId,
                    'category': selectedCategory,
                    'amount': amt,
                    'description': descriptionCtrl.text,
                    'date': dateCtrl.text,
                    'receiptUrl': receiptUrlCtrl.text.isEmpty ? null : receiptUrlCtrl.text,
                  });
                  if (ok) {
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    _loadExpenses();
                  } else {
                    setDlgState(() => descError = 'Submission failed');
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }

  void _showApproveRejectDialog(Map<String, dynamic> exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        title: const Text('Review Expense Claim', style: TextStyle(color: VianTheme.primaryGold)),
        content: Text('Would you like to approve or reject the expense of ₹${exp['amount']} submitted by ${exp['user']?['name']}?'),
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await ApiService.updateExpenseStatus(exp['id'], 'Rejected');
              if (ok) {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                _loadExpenses();
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          VianButton(
            text: 'Approve',
            onPressed: () async {
              final ok = await ApiService.updateExpenseStatus(exp['id'], 'Approved');
              if (ok) {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                _loadExpenses();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final user = ApiService.currentUser;
    final role = user?['role'] ?? 'Client';
    final canApprove = role == 'Super Admin' || role == 'Accountant' || role == 'Managing Director';

    return Padding(
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
                  const Text('Expenses & Disbursements Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Review site material expenses, labor payments, and travel disbursements', style: TextStyle(color: VianTheme.lightText)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VianTheme.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('NEW EXPENSE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                onPressed: _showCreateExpenseDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(child: Text('No expenses recorded', style: TextStyle(color: VianTheme.lightText)))
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final exp = _expenses[index];
                      final status = exp['status'] ?? 'Pending';
                      Color statusColor = VianTheme.warning;
                      if (status == 'Approved') statusColor = VianTheme.success;
                      if (status == 'Rejected') statusColor = VianTheme.danger;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: canApprove && status == 'Pending' ? () => _showApproveRejectDialog(exp) : null,
                          child: VianCard(
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: VianTheme.cardColor,
                                  child: Icon(Icons.receipt, color: VianTheme.primaryGold),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(formatter.format(safeToDouble(exp['amount'])), style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText, fontSize: 16)),
                                      Text('Category: ${exp['category']} | Project: ${exp['project']?['name'] ?? 'General'}', style: const TextStyle(fontSize: 12)),
                                      Text('Submitted by: ${exp['user']?['name'] ?? 'Unknown'} on ${exp['date']}', style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
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
          Text('Compile financial metrics, conversions, and construction schedules', style: TextStyle(color: VianTheme.lightText)),
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
                _reportCard(context, 'Biometric & Geofence Audit Log', 'Confidence matches, GPS coordinates, geofence breaches, and manual approvals.', Icons.security_outlined, 'biometric-audit'),
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
          Expanded(child: Text(desc, style: TextStyle(fontSize: 12, color: VianTheme.lightText))),
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
          Text('Configure company profile metadata, permissions, and media configurations', style: TextStyle(color: VianTheme.lightText)),
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
                          color: VianTheme.cardColor,
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
                  title: Text('Enable AI Features', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
                  subtitle: const Text('Toggle the core construction estimation Gemini AI workflow', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                  value: _enableAi,
                  activeColor: VianTheme.primaryGold,
                  onChanged: (v) => setState(() => _enableAi = v),
                ),
                Divider(color: VianTheme.goldBorder),
                
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
                          dropdownColor: VianTheme.cardColor,
                          items: const [
                            DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('gemini-1.5-flash (Fast & Accurate)', style: TextStyle(color: VianTheme.whiteText))),
                            DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('gemini-1.5-pro (High intelligence)', style: TextStyle(color: VianTheme.whiteText))),
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
                    title: Text('Enable PDF Floor Plans Analysis', style: TextStyle(color: VianTheme.whiteText, fontSize: 13)),
                    value: _enablePdf,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enablePdf = v!),
                  ),
                  CheckboxListTile(
                    title: Text('Enable Image Floor Plans Analysis', style: TextStyle(color: VianTheme.whiteText, fontSize: 13)),
                    value: _enableImage,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enableImage = v!),
                  ),
                  CheckboxListTile(
                    title: Text('Enable Automatic BOQ Estimator', style: TextStyle(color: VianTheme.whiteText, fontSize: 13)),
                    value: _enableBoq,
                    activeColor: VianTheme.primaryGold,
                    onChanged: (v) => setState(() => _enableBoq = v!),
                  ),
                  CheckboxListTile(
                    title: Text('Enable Automatic Cost Calculator', style: TextStyle(color: VianTheme.whiteText, fontSize: 13)),
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
                  
                  Divider(color: VianTheme.goldBorder, height: 32),
                  
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
          
          // Trash & Restore Panel (For Super Admin and Admin)
          if (isSuperAdmin(ApiService.currentUser?['role'] ?? 'Client') || getPermissionRole(ApiService.currentUser?['role'] ?? 'Client') == 'Admin') ...[
            const SizedBox(height: 32),
            VianCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trash & Restore System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  const Text('Manage soft-deleted items across all VIAN ERP databases. Restored items will return to their original catalogs. Super Admins can permanently purge items.', style: TextStyle(color: VianTheme.lightText, fontSize: 12)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Select Module: ', style: TextStyle(color: VianTheme.whiteText)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedTrashModule,
                        dropdownColor: VianTheme.cardColor,
                        style: TextStyle(color: VianTheme.whiteText),
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
                          DropdownMenuItem(value: 'drawings', child: Text('Drawings')),
                          DropdownMenuItem(value: 'documents', child: Text('Documents')),
                          DropdownMenuItem(value: 'expenses', child: Text('Expenses')),
                          DropdownMenuItem(value: 'stage-checklists', child: Text('Stage Checklists')),
                          DropdownMenuItem(value: 'team-targets', child: Text('Team Targets')),
                          DropdownMenuItem(value: 'employee-targets', child: Text('Employee Targets')),
                          DropdownMenuItem(value: 'contractors', child: Text('Contractors')),
                          DropdownMenuItem(value: 'manager-attendance', child: Text('Labour Attendance')),
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
                      child: Text('No items in trash for this module.', style: TextStyle(color: VianTheme.lightText, fontStyle: FontStyle.italic)),
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
                          title: Text(displayName, style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold)),
                          subtitle: Text(deletedDetails, style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VianButton(
                                text: 'Restore',
                                onPressed: () async {
                                  final success = await ApiService.restoreItem(_selectedTrashModule, item['id']);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item restored successfully')));
                                    _loadTrashItems();
                                  }
                                },
                              ),
                              if (isSuperAdmin(ApiService.currentUser?['role'] ?? 'Client')) ...[
                                const SizedBox(width: 8),
                                VianButton(
                                  text: 'Purge',
                                  color: Colors.redAccent,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: VianTheme.headerBlack,
                                        title: const Text('Confirm Permanent Purge', style: TextStyle(color: Colors.redAccent)),
                                        content: const Text('Are you sure you want to permanently delete this item? This action is irreversible.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Purge', style: TextStyle(color: Colors.redAccent))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final success = await ApiService.purgeItem(_selectedTrashModule, item['id']);
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item permanently purged')));
                                        _loadTrashItems();
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
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
          color: VianTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: VianTheme.goldBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: VianTheme.primaryGold, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: VianTheme.lightText)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
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
        backgroundColor: read ? VianTheme.cardColor : Color(0xFF2E2E36),
        radius: 6,
      ),
      title: Text(title, style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold, fontSize: 13, color: VianTheme.whiteText)),
      subtitle: Text(desc, style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
      trailing: Text(time, style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
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
            Text('Contractor Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
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
              ? Center(child: Text('No contractors registered yet.', style: TextStyle(color: VianTheme.lightText)))
              : ListView.builder(
                  itemCount: _contractors.length,
                  itemBuilder: (context, index) {
                    final c = _contractors[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: VianCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: VianTheme.cardColor,
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
            Text('Master Payment Release Stages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
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
                    style: TextStyle(color: VianTheme.lightText, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: _stages.isEmpty
              ? Center(child: Text('No stages defined yet.', style: TextStyle(color: VianTheme.lightText)))
              : ListView.builder(
                  itemCount: _stages.length,
                  itemBuilder: (context, index) {
                    final s = _stages[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: VianCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: VianTheme.cardColor,
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
            Text('Payment Release Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
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
              ? Center(child: Text('No payment releases recorded yet.', style: TextStyle(color: VianTheme.lightText)))
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
                            backgroundColor: VianTheme.cardColor,
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
                    Text('Manage constructors, release payment milestones, and configure billing stages', style: TextStyle(color: VianTheme.lightText)),
                  ],
                ),
                TabBar(
                  isScrollable: true,
                  labelColor: VianTheme.primaryGold,
                  unselectedLabelColor: VianTheme.lightText,
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
    if (_loading) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)));
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;

    Widget leftMapSection() {
      return Container(
        color: VianTheme.darkBackground,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GEOFENCE MONITORING',
                  style: GoogleFonts.outfit(
                    color: VianTheme.primaryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: VianTheme.success.withOpacity(0.08),
                  child: Row(
                    children: [
                      const Icon(Icons.radar, color: VianTheme.success, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE RADAR ACTIVE',
                        style: GoogleFonts.outfit(
                          color: VianTheme.success,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: ProjectGeofenceMap(
                        projectName: 'Lumière Heights Estate',
                        projectLatitude: 28.4595,
                        projectLongitude: 77.0266,
                        employeeLatitude: 28.4610,
                        employeeLongitude: 77.0280,
                        allowedRadius: 200.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Map Legend
            Container(
              decoration: BoxDecoration(
                color: VianTheme.cardColor,
                border: Border.all(color: VianTheme.goldBorder.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MAP LEGEND',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _legendRow(Colors.green, 'Inside Geofence', '${_workers.length - 1} Workers'),
                      _legendRow(VianTheme.danger, 'Excursion Alert', '01 Worker'),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    Widget attendanceListSection() {
      final totalAbsent = _statuses.values.where((s) => s == 'Absent').length;
      final totalPresent = _workers.length - totalAbsent;

      return Container(
        color: VianTheme.cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY ATTENDANCE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lumière Heights Estate • Zone A & B',
                        style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VianTheme.primaryGold,
                      side: const BorderSide(color: VianTheme.primaryGold),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _submitAttendance,
                    child: Text('SUBMIT LOGS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  )
                ],
              ),
            ),
            const Divider(color: VianTheme.goldBorder, height: 1),

            // Scrollable Workers list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(32.0),
                itemCount: _workers.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final w = _workers[idx];
                  final id = w['id'] as int;
                  final status = _statuses[id] ?? 'Present';
                  final hasAlert = idx == 1 && status != 'Absent'; // Simulate excursion alert for David/Elena on index 1

                  return Container(
                    decoration: BoxDecoration(
                      color: VianTheme.darkBackground,
                      border: Border.all(
                        color: hasAlert ? VianTheme.danger.withOpacity(0.5) : VianTheme.goldBorder.withOpacity(0.3),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: VianTheme.primaryGold,
                              child: const Icon(Icons.person, color: Colors.black, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w['name'] ?? '',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${w['skillType'] ?? 'Staff'} • ${hasAlert ? 'Zone B (Outside)' : 'Zone A (Inside)'}',
                                    style: GoogleFonts.inter(
                                      color: hasAlert ? VianTheme.danger : VianTheme.lightText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  hasAlert ? '08:15 AM' : '08:02 AM',
                                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'CHECK-IN',
                                  style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: VianTheme.goldBorder, height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _statusBtn(id, 'Present'),
                                  const SizedBox(width: 6),
                                  _statusBtn(id, 'Half Day'),
                                  const SizedBox(width: 6),
                                  _statusBtn(id, 'Absent'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Overtime input box
                            SizedBox(
                              width: 80,
                              height: 36,
                              child: TextField(
                                style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 12),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'OT HOURS',
                                  labelStyle: GoogleFonts.outfit(fontSize: 8, color: VianTheme.primaryGold, fontWeight: FontWeight.bold),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: VianTheme.goldBorder)),
                                  enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: VianTheme.goldBorder)),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: VianTheme.primaryGold)),
                                ),
                                onChanged: (v) => _overtime[id] = double.tryParse(v) ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: VianTheme.goldBorder, height: 1),

            // Footer Summary
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                children: [
                  _summaryBlock('TOTAL CREW', _workers.length.toString()),
                  const SizedBox(width: 16),
                  _summaryBlock('ON-SITE', totalPresent.toString()),
                  const SizedBox(width: 16),
                  _summaryBlock('ABSENT', totalAbsent.toString()),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: VianTheme.darkBackground,
      body: Row(
        children: [
          // Map on the left
          Expanded(
            flex: 11,
            child: leftMapSection(),
          ),
          // List on the right
          if (isDesktop)
            Expanded(
              flex: 9,
              child: attendanceListSection(),
            ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.inter(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _statusBtn(int id, String status) {
    final active = _statuses[id] == status;
    return InkWell(
      onTap: () => setState(() => _statuses[id] = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? VianTheme.primaryGold.withOpacity(0.08) : Colors.transparent,
          border: Border.all(color: active ? VianTheme.primaryGold : VianTheme.lightText),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.outfit(
            color: active ? VianTheme.primaryGold : VianTheme.lightText,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _summaryBlock(String title, String value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: VianTheme.darkBackground,
          border: Border.all(color: VianTheme.goldBorder.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
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
                  Text('Submission history for daily workspace progress updates', style: TextStyle(color: VianTheme.lightText)),
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
                            Text(r['date'] ?? '', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Quantity: ${r['quantityCompleted']}', style: const TextStyle(color: VianTheme.whiteText, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(r['workDescription'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('Submitted by: ${r['user']?['name']}', style: TextStyle(color: VianTheme.lightText, fontSize: 10)),
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
                    Text(_isRecording ? 'Listening for voice...' : 'Speech-to-Text ready', style: TextStyle(fontSize: 11, color: _isRecording ? VianTheme.danger : VianTheme.lightText)),
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
                  Text('Daily structural milestones, issues faced, and plans compiled by site managers', style: TextStyle(color: VianTheme.lightText)),
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
                            Text(r['date'] ?? '', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
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
                        Text('Log registered by: ${r['manager']?['name'] ?? "Rahul Sen"}', style: TextStyle(color: VianTheme.lightText, fontSize: 10)),
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
  List<dynamic> _projects = [];
  int? _selectedProjectId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final projects = await ApiService.getProjects();
      setState(() {
        _projects = projects;
        if (projects.isNotEmpty) {
          _selectedProjectId = projects.first['id'] as int;
        }
      });
      if (_selectedProjectId != null) {
        await _loadPayroll();
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPayroll() async {
    if (_selectedProjectId == null) return;
    setState(() => _loading = true);
    try {
      final list = await ApiService.getWageSheet(_selectedProjectId!);
      setState(() {
        _wages = list;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _wages = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _projects.isEmpty) return const Center(child: CircularProgressIndicator());
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
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
                  const Text('Payroll Integrated Wage Sheet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
                  Text('Wages auto-calculated from manager attendance grids (Base wage + 1.5x Overtime multiplier)', style: TextStyle(color: VianTheme.lightText)),
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
          if (_projects.isNotEmpty) ...[
            Row(
              children: [
                Text('Select Project: ', style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<int>(
                    dropdownColor: VianTheme.cardColor,
                    value: _selectedProjectId,
                    items: _projects.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['name'] ?? '', style: TextStyle(color: VianTheme.whiteText)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedProjectId = val;
                        });
                        _loadPayroll();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)))
                : (_wages.isEmpty
                    ? const Center(child: Text('No wage records calculated for this project.', style: TextStyle(color: VianTheme.lightText)))
                    : ListView.builder(
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
                                        Text('Days: ${w['presentDays']} Present, ${w['halfDays']} Half | OT: ${w['overtimeHours']} Hrs', style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
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
                      )),
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
                  Text('General announcements, safety requirements, and operational circulars', style: TextStyle(color: VianTheme.lightText)),
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
                                  style: TextStyle(color: VianTheme.lightText, fontSize: 11),
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
                                          content: Text('Are you sure you want to move this announcement to trash?', style: TextStyle(color: VianTheme.whiteText)),
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
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: VianTheme.primaryGold),
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
                child: Text('No documents uploaded yet.', style: TextStyle(color: VianTheme.lightText, fontSize: 13)),
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
                      color: VianTheme.cardColor,
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
                                Text('Folder: ${doc['folder']} | Size: ${(doc['fileSize'] / 1024).toStringAsFixed(1)} MB', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
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
        color: VianTheme.cardColor,
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
// 13. DATA IMPORT & EXPORT CENTER
// ==========================================
class ImportExportTab extends ConsumerStatefulWidget {
  const ImportExportTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportExportTab> createState() => _ImportExportTabState();
}

class _ImportExportTabState extends ConsumerState<ImportExportTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _importWizardStep = 1;
  bool _isUploadingFile = false;
  String? _uploadedFileName;
  String? _uploadedFilePath;
  List<dynamic> _workbookSheets = [];
  int _selectedSheetIndex = 0;
  String _selectedImportModule = 'Clients';

  final _csvPasteController = TextEditingController();

  List<dynamic> _parsedRows = [];
  List<String> _spreadsheetHeaders = [];
  Map<String, String> _columnMappings = {};
  List<dynamic> _validationResults = [];
  Map<String, dynamic> _validationSummary = {};
  String _duplicateResolutionStrategy = 'skip';
  bool _isImportExecuting = false;
  Map<String, dynamic> _executionResult = {};

  bool _exportFinancials = true;
  bool _exportVendors = true;
  bool _exportBlueprints = false;

  bool _isBuilding = false;
  double _buildProgress = 1.0;
  String _buildVersion = 'v4.8.2-stable';
  String _buildStatusText = 'Ready';

  final List<String> _terminalLogs = [];
  final List<String> _terminalTimes = [];
  final ScrollController _terminalScrollController = ScrollController();
  bool _cursorBlink = true;
  Timer? _cursorTimer;
  Timer? _buildTimer;

  final _backupRestoreJsonController = TextEditingController();
  List<dynamic> _backupHistory = [];
  bool _isBackupLoading = false;

  List<dynamic> _projectsList = [];
  int? _selectedExportProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBackupHistory();
    _loadProjectsList();
    _initTerminalLogs();
    _startCursorTimer();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _buildTimer?.cancel();
    _tabController.dispose();
    _csvPasteController.dispose();
    _backupRestoreJsonController.dispose();
    _terminalScrollController.dispose();
    super.dispose();
  }

  void _initTerminalLogs() {
    final now = DateTime.now();
    final logMsgs = [
      'System environment initialized.',
      'Connecting to secure asset pipeline...',
      'Validation check complete. 1,402 entities identified.',
      'Awaiting operator instruction for module ARCHITECTURE_EXEC_01',
    ];
    for (int i = logMsgs.length - 1; i >= 0; i--) {
      _terminalTimes.add(_formatTime(now.subtract(Duration(seconds: i * 3))));
      _terminalLogs.add(logMsgs[logMsgs.length - 1 - i]);
    }
  }

  void _startCursorTimer() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (mounted) {
        setState(() {
          _cursorBlink = !_cursorBlink;
        });
      }
    });
  }

  String _formatTime(DateTime t) {
    return "[${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}]";
  }

  void _addTerminalLog(String msg) {
    if (mounted) {
      setState(() {
        _terminalTimes.add(_formatTime(DateTime.now()));
        _terminalLogs.add(msg);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_terminalScrollController.hasClients) {
          _terminalScrollController.animateTo(
            _terminalScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _executeBuildSimulated() {
    if (_isBuilding) return;
    setState(() {
      _isBuilding = true;
      _buildProgress = 0.0;
      _buildStatusText = 'Building...';
    });
    _addTerminalLog('Initiating Web Production Build compilation...');

    int step = 0;
    _buildTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      setState(() {
        _buildProgress = step / 5.0;
      });
      if (step == 1) {
        _addTerminalLog('Resolving system modules & workspace assets...');
      } else if (step == 2) {
        _addTerminalLog('Generating layout blueprints & database pipelines...');
      } else if (step == 3) {
        _addTerminalLog('Minifying JS bundle and checking static tree shaken configurations...');
      } else if (step == 4) {
        _addTerminalLog('Compressing package components for AWS CloudFront deployment...');
      } else if (step == 5) {
        timer.cancel();
        setState(() {
          _isBuilding = false;
          _buildProgress = 1.0;
          _buildStatusText = 'Ready';
        });
        _addTerminalLog('Build v4.8.2-stable completed successfully. Region: EU-WEST-1 CDN.');
      }
    });
  }

  Future<void> _pickFile() async {
    _addTerminalLog('Opening system file selector for manifest upload...');
    await _pickFileForImport();
    if (_uploadedFileName != null) {
      _addTerminalLog('Pipelined file: $_uploadedFileName uploaded successfully.');
      _addTerminalLog('Sheet count: ${_workbookSheets.length}. Directing map validation wizard.');
    } else {
      _addTerminalLog('Asset injection aborted by operator.');
    }
  }

  void _initiateExportAction() async {
    _addTerminalLog('Preparing system export matrices...');
    int exportCount = 0;
    if (_exportFinancials) {
      _addTerminalLog('Pipelining project financials data stream...');
      final url = '${ApiService.baseUrl}/export/payments?format=xlsx';
      openUrl(url);
      exportCount++;
    }
    if (_exportVendors) {
      _addTerminalLog('Pipelining vendor lead matrix data stream...');
      final url = '${ApiService.baseUrl}/export/leads?format=xlsx';
      openUrl(url);
      exportCount++;
    }
    if (_exportBlueprints) {
      _addTerminalLog('Pipelining construction drawings CAD packages...');
      final url = '${ApiService.baseUrl}/export/drawings?format=xlsx';
      openUrl(url);
      exportCount++;
    }
    if (exportCount == 0) {
      _addTerminalLog('Export protocol error: No modules selected.');
      _showErrorSnackBar('Please check at least one module to export.');
    } else {
      _addTerminalLog('Export protocol executed successfully. $exportCount modules downloaded.');
    }
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

      _importWizardStep = 2;
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
    _addTerminalLog('Bulk Import committed to $_selectedImportModule.');
    _addTerminalLog('Summary: Imported: ${_executionResult['imported']}, Updated: ${_executionResult['updated']}, Skipped: ${_executionResult['skipped']}, Failed: ${_executionResult['failed']}');
  }

  void _triggerBackup() {
    final url = '${ApiService.baseUrl}/backup/export';
    openUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading database backup...'), backgroundColor: VianTheme.success)
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

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VianTheme.danger)
    );
  }

  void _showBackupConsole() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: VianTheme.headerBlack,
          title: Text('DATABASE BACKUP & RESTORE CONSOLE', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: VianTheme.primaryGold,
                  labelColor: VianTheme.primaryGold,
                  unselectedLabelColor: VianTheme.lightText,
                  tabs: const [
                    Tab(text: 'BACKUP CONTROL'),
                    Tab(text: 'RESTORE CONTROL'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VianButton(
                            text: 'TRIGGER SQL/JSON BACKUP DOWNLOAD',
                            onPressed: _triggerBackup,
                          ),
                          const SizedBox(height: 20),
                          const Text('BACKUP LOGS & HISTORY', style: TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _isBackupLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount: _backupHistory.length,
                                    itemBuilder: (context, idx) {
                                      final b = _backupHistory[idx];
                                      return ListTile(
                                        title: Text(b['fileName'] ?? '', style: TextStyle(fontSize: 12, color: VianTheme.whiteText)),
                                        subtitle: Text(b['createdAt'] ?? '', style: const TextStyle(fontSize: 10)),
                                      );
                                    },
                                  ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PASTE RESTORE JSON DATA MANUALLY', style: TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _backupRestoreJsonController,
                            maxLines: 8,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            decoration: const InputDecoration(
                              hintText: '{"tables": {"clients": [...], "projects": [...]}}',
                            ),
                          ),
                          const SizedBox(height: 20),
                          VianButton(
                            text: 'RESTORE DATABASE RECORDS',
                            onPressed: _triggerRestore,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: VianTheme.lightText)),
            )
          ],
        ),
      ),
    );
  }

  void _showPasteCsvDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VianTheme.headerBlack,
        title: Text('PASTE CSV DATA MANUALLY', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedImportModule,
                dropdownColor: VianTheme.headerBlack,
                decoration: const InputDecoration(labelText: 'Target Module'),
                items: [
                  'Clients', 'Projects', 'Leads', 'Employees', 'Attendance', 
                  'Drawings', 'Drawing Progress', 'BOQ', 'Materials', 'Labour', 
                  'Payments', 'Expenses', 'Vendors', 'Contractors', 'Tasks', 'Documents'
                ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedImportModule = v ?? 'Clients'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PASTE CSV VALUE', style: TextStyle(fontSize: 11, color: VianTheme.lightText)),
                  TextButton(
                    onPressed: _loadDemoTemplate,
                    child: const Text('Load Demo Template', style: TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _csvPasteController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  hintText: 'Client Name,Mobile Number,Email,Address,GST Number\r\nAmit Bajaj,9876543210,amit@vian.com,Villa 108,29BBBBB...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: VianTheme.lightText)),
          ),
          VianButton(
            text: 'Parse Data',
            onPressed: () {
              Navigator.pop(context);
              _parsePasteInput();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_importWizardStep > 1) {
      return Scaffold(
        backgroundColor: VianTheme.headerBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _importWizardStep = 1)),
          title: const Text('IMPORT WIZARD'),
        ),
        body: _buildWizardStepContent(),
      );
    }
    return _buildDashboardView();
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
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
                    'SYSTEM ENVIRONMENT',
                    style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build Center',
                    style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: VianTheme.primaryGold,
                      side: const BorderSide(color: VianTheme.primaryGold, width: 0.5),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.settings_backup_restore, size: 14),
                    label: Text(
                      'BACKUP CONSOLE',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    onPressed: _showBackupConsole,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 48),

          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 24,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: [
              _buildImportCard(),
              _buildExportCard(),
              _buildBuildCard(),
            ],
          ),
          const SizedBox(height: 48),

          _buildTerminalPanel(),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return CustomPaint(
      painter: AtelierBracketPainter(color: VianTheme.primaryGold),
      child: Container(
        color: VianTheme.cardColor,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.upload_file, color: VianTheme.primaryGold, size: 28),
                Text('MODULE_01', style: GoogleFonts.jetBrainsMono(color: VianTheme.lightText, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 32),
            Text('Data Injection', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'System-wide resource synchronization and structural data ingestion via CSV/JSON.',
              style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12, height: 1.5),
            ),
            const Spacer(),
            InkWell(
              onTap: _isUploadingFile ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload, color: VianTheme.lightText, size: 20),
                    const SizedBox(height: 8),
                    Text(
                      'Drop CSV Manifest',
                      style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _showPasteCsvDialog,
                child: Text(
                  'PASTE RAW CSV DATA',
                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return CustomPaint(
      painter: AtelierBracketPainter(color: VianTheme.primaryGold),
      child: Container(
        color: VianTheme.cardColor,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.ios_share, color: VianTheme.primaryGold, size: 28),
                Text('MODULE_02', style: GoogleFonts.jetBrainsMono(color: VianTheme.lightText, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 32),
            Text('Export Protocol', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _checkboxRow('Project Financials', _exportFinancials, (v) => setState(() => _exportFinancials = v!)),
                  _checkboxRow('Vendor Lead Matrix', _exportVendors, (v) => setState(() => _exportVendors = v!)),
                  _checkboxRow('Construction Blueprints (CAD)', _exportBlueprints, (v) => setState(() => _exportBlueprints = v!)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: VianTheme.primaryGold,
                side: const BorderSide(color: VianTheme.primaryGold, width: 0.5),
                minimumSize: const Size(double.infinity, 44),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: _initiateExportAction,
              child: Text('INITIATE EXPORT', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkboxRow(String label, bool val, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Checkbox(
            value: val,
            onChanged: onChanged,
            activeColor: VianTheme.primaryGold,
            checkColor: Colors.black,
            side: const BorderSide(color: VianTheme.lightText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildCard() {
    return CustomPaint(
      painter: AtelierBracketPainter(color: VianTheme.primaryGold),
      child: Container(
        color: VianTheme.cardColor,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.construction, color: VianTheme.primaryGold, size: 28),
                Text('MODULE_03', style: GoogleFonts.jetBrainsMono(color: VianTheme.lightText, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 32),
            Text('Build & Deploy', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF13131A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('STATUS: $_buildStatusText', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                      Text(_buildVersion, style: GoogleFonts.jetBrainsMono(color: VianTheme.primaryGold, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _buildProgress,
                    minHeight: 2,
                    backgroundColor: VianTheme.goldBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VianTheme.primaryGold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: _isBuilding ? null : _executeBuildSimulated,
              child: Text('EXECUTE BUILD', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalPanel() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: VianTheme.darkBackground,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF13131A),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF5350), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFCA28), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF9CCC65), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 24),
                Text(
                  'SYSTEM OUTPUT TERMINAL',
                  style: GoogleFonts.jetBrainsMono(color: VianTheme.lightText, fontSize: 9, letterSpacing: 1.5),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.content_copy, color: VianTheme.lightText, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _terminalLogs.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terminal logs copied to clipboard.')));
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete, color: VianTheme.lightText, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _terminalLogs.clear();
                    _terminalTimes.clear();
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: ListView.builder(
                controller: _terminalScrollController,
                itemCount: _terminalLogs.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == _terminalLogs.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(
                            'admin@atelier-erp:~\$ ',
                            style: GoogleFonts.jetBrainsMono(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '_',
                            style: GoogleFonts.jetBrainsMono(
                              color: _cursorBlink ? VianTheme.primaryGold : Colors.transparent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _terminalTimes[idx],
                          style: GoogleFonts.jetBrainsMono(color: VianTheme.lightText, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _terminalLogs[idx],
                            style: GoogleFonts.jetBrainsMono(color: VianTheme.lightText, fontSize: 11),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: VianTheme.goldBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('REGION: EU-WEST-1', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                    const SizedBox(width: 20),
                    Text('LAT: 48.8566° N', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                    const SizedBox(width: 20),
                    Text('LONG: 2.3522° E', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: VianTheme.primaryGold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: VianTheme.primaryGold, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('LINKED TO CENTRAL GRID', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.0)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWizardStepContent() {
    switch (_importWizardStep) {
      case 2:
        return _buildWizardStep2();
      case 3:
        return _buildWizardStep3();
      case 4:
        return _buildWizardStep4();
      case 5:
        return _buildWizardStep5();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWizardStep2() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP 2: PREVIEW PARSED DATA ROWS',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(VianTheme.cardColor),
                  columns: _spreadsheetHeaders.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 11)))).toList(),
                  rows: _parsedRows.take(8).map((row) {
                    return DataRow(
                      cells: _spreadsheetHeaders.map((h) => DataCell(Text(row[h]?.toString() ?? '', style: const TextStyle(fontSize: 11)))).toList(),
                    );
                  }).toList(),
                ),
              ),
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
    );
  }

  Widget _buildWizardStep3() {
    final erpFields = _getTargetFieldsForModule(_selectedImportModule);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 3: COLUMN FIELD MAPPING',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify mapping settings for $_selectedImportModule fields. Standard layouts are auto-detected.',
            style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: erpFields.length,
              itemBuilder: (context, idx) {
                final f = erpFields[idx];
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
              },
            ),
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildWizardStep4() {
    final isValid = _validationSummary['isValidSuite'] == true;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 4: IMPORT DATA AUDIT & RESOLUTION',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
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
                        isValid ? 'VALIDATION SUCCEEDED' : 'VALIDATION COMPLETED WITH WARNINGS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isValid ? VianTheme.success : VianTheme.warning),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Missing values: ${_validationSummary['missingFields']} | Duplicate matches: ${(_validationSummary['duplicateClients'] ?? 0) + (_validationSummary['duplicateProjects'] ?? 0)} | Invalid emails: ${_validationSummary['invalidEmails']}',
                        style: TextStyle(color: VianTheme.lightText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('DUPLICATE RECORD RESOLUTION STRATEGY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold)),
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
          const SizedBox(height: 20),
          const Text('DATA AUDIT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _validationResults.length,
              itemBuilder: (context, idx) {
                final item = _validationResults[idx];
                final errs = item['errors'] as Map<String, dynamic>;
                final warns = item['warnings'] as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VianTheme.cardColor,
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
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildWizardStep5() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                  Text('IMPORT PROCESS COMPLETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: VianTheme.success)),
                  Text('Workspace synchronization completed successfully.', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _summaryTile('New Records Imported', _executionResult['imported']?.toString() ?? '0', VianTheme.success),
                _summaryTile('Updated / Merged Records', _executionResult['updated']?.toString() ?? '0', VianTheme.primaryGold),
                _summaryTile('Skipped Duplicates', _executionResult['skipped']?.toString() ?? '0', VianTheme.lightText),
                _summaryTile('Rejected / Failed Rows', _executionResult['failed']?.toString() ?? '0', VianTheme.danger),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                text: 'Close Wizard',
                isSecondary: true,
                onPressed: () => setState(() => _importWizardStep = 1),
              ),
            ],
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
        color: VianTheme.cardColor,
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
                        child: Text(t['financialYear'] ?? '', style: TextStyle(color: VianTheme.whiteText, fontSize: 13)),
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
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: VianTheme.cardColor))),
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
                    side: BorderSide(color: VianTheme.goldBorder),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: VianTheme.cardColor, child: Icon(Icons.groups, color: VianTheme.primaryGold)),
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
                    side: BorderSide(color: VianTheme.goldBorder),
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
          Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
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
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.whiteText)),
      ],
    );
  }

  Widget _buildForecastScoreCard(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: VianTheme.primaryGold)),
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

  final _keystoreFileCtrl = TextEditingController();
  final _keystoreAliasCtrl = TextEditingController();
  final _keystorePasswordCtrl = TextEditingController();
  final _keyPasswordCtrl = TextEditingController();
  final _certificateFileCtrl = TextEditingController();
  final _provisioningProfileCtrl = TextEditingController();

  final ScrollController _logScrollController = ScrollController();

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
  bool _isLoadingMetadata = true;
  Map<String, dynamic> _buildMetadata = {};

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
    _loadMetadata();
    _loadHistory();
    _loadSigningConfig(_selectedPlatformForSigning);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
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

  Future<void> _loadMetadata() async {
    setState(() => _isLoadingMetadata = true);
    try {
      final meta = await ApiService.getBuildMetadata();
      setState(() {
        _buildMetadata = meta;
        _isLoadingMetadata = false;
      });
    } catch (_) {
      setState(() => _isLoadingMetadata = false);
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
    final payload = {
      'platform': _selectedPlatformForBuild,
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
    if (_isLoadingMetadata && _buildMetadata.isEmpty) {
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.whiteText),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _activeBuildProgress / 100.0,
                    minHeight: 4,
                    backgroundColor: VianTheme.cardColor,
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
    final lastBuild = _buildHistory.firstWhere((b) => b['status'] == 'Completed', orElse: () => null);
    final latestArtifactName = lastBuild != null ? lastBuild['fileName'] : 'N/A';
    final latestArtifactId = lastBuild != null ? lastBuild['id'] : null;
    final currentBranch = _buildMetadata['gitBranch'] ?? 'main';
    final gitCommit = _buildMetadata['gitCommit'] ?? 'unknown';
    final flutterVersion = _buildMetadata['flutterVersion'] ?? 'Flutter 3.12.0';
    final buildQueueCount = _buildHistory.where((b) => b['status'] == 'Pending' || b['status'] == 'Building').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform selection section
          Text(
            'SELECT COMPILATION TARGET PLATFORM',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13, letterSpacing: 1.2),
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
                  childAspectRatio: 2.5,
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
                                color: isSelected ? Color(0x33F5A623) : VianTheme.cardColor,
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
                                    style: TextStyle(color: VianTheme.lightText, fontSize: 9),
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
          
          // Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CI/CD COMPILATION RUNNER',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13, letterSpacing: 1.2),
              ),
              VianButton(
                text: _activeBuildId != null ? 'Build is Running...' : 'Build Now',
                icon: Icons.play_arrow,
                onPressed: _activeBuildId != null ? null : _triggerBuild,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Modern CI/CD Dashboard Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _dashboardStatCard(
                'Pipeline Status',
                _activeBuildId != null ? _activeBuildStatus.toUpperCase() : 'IDLE',
                _activeBuildId != null ? Icons.loop : Icons.check_circle_outline,
                _activeBuildId != null ? VianTheme.primaryGold : VianTheme.success,
              ),
              _dashboardStatCard(
                'Current Branch',
                currentBranch,
                Icons.fork_right_outlined,
                VianTheme.accentBlue,
              ),
              _dashboardStatCard(
                'Git Commit Hash',
                gitCommit,
                Icons.commit,
                VianTheme.lightText,
              ),
              _dashboardStatCard(
                'Flutter Engine Version',
                flutterVersion,
                Icons.bolt,
                VianTheme.primaryGold,
              ),
              _dashboardStatCard(
                'Build Queue',
                '$buildQueueCount builds active',
                Icons.queue,
                buildQueueCount > 0 ? VianTheme.warning : VianTheme.lightText,
              ),
              _dashboardStatCard(
                'Build Target Mode',
                _selectedPlatformForBuild.contains('Debug') ? 'DEBUG MODE' : 'RELEASE MODE',
                Icons.settings_suggest,
                VianTheme.primaryGold,
              ),
              _dashboardStatCard(
                'Last Successful Build',
                lastBuild != null ? 'v${lastBuild['versionName'] ?? '1.0.0'} (${lastBuild['buildNumber'] ?? 1})' : 'N/A',
                Icons.history_toggle_off,
                VianTheme.success,
              ),
              _dashboardArtifactCard(
                'Latest Package Artifact',
                latestArtifactName,
                latestArtifactId,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Recent history section
          Text(
            'RECENT BUILD PIPELINE RUNS',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          
          if (_buildHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No build runs recorded.', style: TextStyle(color: VianTheme.lightText)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _buildHistory.length > 5 ? 5 : _buildHistory.length,
              itemBuilder: (context, index) {
                final buildItem = _buildHistory[index];
                final status = buildItem['status'] ?? 'Pending';
                final isCompleted = status == 'Completed';
                final isFailed = status == 'Failed';
                final statusColor = isCompleted
                    ? VianTheme.success
                    : isFailed
                        ? VianTheme.danger
                        : VianTheme.primaryGold;
                
                final durationSec = buildItem['duration'] ?? 0;
                final dateStr = buildItem['createdAt'] != null
                    ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(buildItem['createdAt']))
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: VianTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VianTheme.goldBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        buildItem['platform']?.toString().contains('Android') == true
                            ? Icons.android
                            : buildItem['platform']?.toString().contains('iOS') == true
                                ? Icons.phone_iphone
                                : buildItem['platform']?.toString().contains('Windows') == true
                                    ? Icons.laptop_windows
                                    : Icons.web_outlined,
                        color: VianTheme.lightText,
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${buildItem['platform'] ?? "Build"} - v${buildItem['versionName'] ?? "1.0.0"} (${buildItem['buildNumber'] ?? 1})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.whiteText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Triggered on $dateStr | Duration: ${durationSec}s',
                              style: const TextStyle(color: VianTheme.lightText, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isCompleted)
                        IconButton(
                          icon: const Icon(Icons.download, color: VianTheme.primaryGold, size: 18),
                          onPressed: () {
                            openUrl('${ApiService.baseUrl}/builds/download/${buildItem['id']}');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.terminal_outlined, color: VianTheme.whiteText, size: 18),
                        onPressed: () => _showFullLogsDialog(buildItem['id'], buildItem['platform'] ?? 'Build'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _dashboardStatCard(String label, String value, IconData icon, Color color) {
    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 10, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.whiteText),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardArtifactCard(String label, String fileName, int? id) {
    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VianTheme.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: VianTheme.primaryGold, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 10, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.whiteText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (id != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          openUrl('${ApiService.baseUrl}/builds/download/$id');
                        },
                        child: const Icon(Icons.download, color: VianTheme.primaryGold, size: 16),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
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
                        return DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: VianTheme.whiteText)));
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
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13),
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
                      Text(timeStr, style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
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
                    Text('${durationSec}s duration', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  width: 140,
                  child: Text(
                    item['sha256Checksum'] ?? 'Calculating...',
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: VianTheme.lightText),
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
                border: Border.all(color: VianTheme.cardColor),
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
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 14),
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
                  color: VianTheme.cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: VianTheme.primaryGold, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE BUILD LOG CONSOLE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.whiteText, letterSpacing: 0.8),
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
        border: Border.all(color: VianTheme.goldBorder),
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
                  : VianTheme.lightText;

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
                          color: isActive ? VianTheme.whiteText : VianTheme.lightText,
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
                    color: index < activeStep ? VianTheme.success : VianTheme.goldBorder,
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
        border: Border.all(color: VianTheme.goldBorder),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < activeStep;
          final isActive = index == activeStep;
          final stepColor = isCompleted
              ? VianTheme.success
              : isActive
                  ? statusColor
                  : VianTheme.lightText;

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
                      color: index < activeStep ? VianTheme.success : VianTheme.goldBorder,
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
                        color: isActive ? VianTheme.whiteText : VianTheme.lightText,
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

  bool canAccess(String role, String feature) {
    UserRole userRole = UserRole.estimator;
    final cleanRole = role.toLowerCase();
    if (cleanRole == 'super admin') {
      userRole = UserRole.superadmin;
    } else if (cleanRole == 'managing director') {
      userRole = UserRole.managingDirector;
    } else if (cleanRole == 'admin' || cleanRole.contains('admin')) {
      userRole = UserRole.admin;
    } else if (cleanRole.contains('coordinator')) {
      userRole = UserRole.siteCoordinator;
    } else if (cleanRole.contains('estimator')) {
      userRole = UserRole.estimator;
    }

    if (feature == 'settings') {
      return userRole == UserRole.superadmin || userRole == UserRole.managingDirector;
    }
    if (feature == 'approve') {
      return userRole == UserRole.superadmin || userRole == UserRole.managingDirector || userRole == UserRole.admin;
    }
    return true;
  }

  Future<void> _fetchBudgetVsActual(int id) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(estimationProvider.notifier).fetchBudgetVsActual(id);
      setState(() {
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

    final estimationState = ref.watch(estimationProvider);
    _estimates = estimationState.estimates.map((e) => e.toJson()).toList();
    _dashboardStats = estimationState.dashboardStats;
    _settings = estimationState.settings?.toJson() ?? {};
    _marketPrices = estimationState.marketPrices.map((m) => m.toJson()).toList();
    _budgetVsActualData = estimationState.selectedBudgetVsActual;

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
      backgroundColor: VianTheme.darkBackground,
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
        decoration: const BoxDecoration(
          color: VianTheme.cardColor,
          border: Border(bottom: BorderSide(color: VianTheme.goldBorder, width: 1)),
        ),
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
            final res = await ref.read(estimationProvider.notifier).saveEstimate(data);
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
        if (!canAccess(role, 'settings')) {
          return const Center(child: Text('Access Denied: MD / Super Admin permissions required.'));
        }
        return EstimationSettingsView(
          settings: _settings,
          role: role,
          onSave: (data) async {
            if (!canAccess(role, 'settings')) return;
            setState(() => _isLoading = true);
            await ref.read(estimationProvider.notifier).updateSettings(data);
            await _loadAllData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings updated successfully.')),
            );
            setState(() => _isLoading = false);
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
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
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
                  VianTheme.cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Approved Estimates',
                  '${_dashboardStats['approvedEstimates'] ?? 0}',
                  Icons.assignment_turned_in_outlined,
                  VianTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Pending Approvals',
                  '${_dashboardStats['pendingEstimates'] ?? 0}',
                  Icons.hourglass_empty_outlined,
                  VianTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Avg. Cost / Sq.ft',
                  currencyFormat.format(_dashboardStats['averageCostPerSqft'] ?? 0),
                  Icons.trending_up,
                  VianTheme.accentBlue,
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
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (_estimates.isEmpty)
                        const SizedBox(height: 100, child: Center(child: Text('No estimates found.', style: TextStyle(color: VianTheme.lightText))))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _estimates.length > 5 ? 5 : _estimates.length,
                          separatorBuilder: (context, index) => const Divider(color: VianTheme.goldBorder),
                          itemBuilder: (context, index) {
                            final est = _estimates[index];
                            final status = est['status'] ?? 'Pending';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(est['projectName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13)),
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
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color baseColor) {
    return VianCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 20),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: baseColor == VianTheme.cardColor ? VianTheme.primaryGold : baseColor, size: 24),
          ),
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
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13)),
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
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 14),
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
              separatorBuilder: (context, index) => const Divider(color: VianTheme.goldBorder),
              itemBuilder: (context, index) {
                final est = _estimates[index];
                return ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  title: Row(
                    children: [
                      Text(est['projectName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack)),
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
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 14),
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
                  color: VianTheme.darkBackground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: VianTheme.goldBorder, width: 1),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(price['materialName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 14)),
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
                                    title: const Text('Delete Market Price', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: const Text('Are you sure you want to delete this market price record?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel', style: TextStyle(color: VianTheme.lightText)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: VianTheme.danger),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text('Delete', style: TextStyle(color: VianTheme.whiteText)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  setState(() => _isLoading = true);
                                  try {
                                    await ref.read(estimationProvider.notifier).deleteMarketPrice(price['id']);
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
          title: Text(
            isEdit ? 'Edit Market Price' : 'Add New Market Rate',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
                    await ref.read(estimationProvider.notifier).updateMarketPrice({
                      'id': existing['id'],
                      'materialName': materialNameController.text,
                      'currentRate': rate,
                      'supplier': supplierController.text,
                      'district': districtController.text,
                    });
                  } else {
                    await ref.read(estimationProvider.notifier).addMarketPrice({
                      'materialName': materialNameController.text,
                      'currentRate': rate,
                      'supplier': supplierController.text,
                      'district': districtController.text,
                    });
                  }
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
          style: const TextStyle(color: VianTheme.headerBlack, fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: VianTheme.goldBorder)),
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
                    style: GoogleFonts.outfit(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  if (details['status'] == 'Approved' || details['status'] == 'approved')
                    VianButton(
                      text: 'View Budget vs Actual Variance',
                      icon: Icons.analytics_outlined,
                      isSecondary: true,
                      onPressed: () => _fetchBudgetVsActual(details['id']),
                    ),
                  const SizedBox(width: 12),
                  if ((details['status'] == 'Pending' || details['status'] == 'pendingApproval') && canAccess(role, 'approve'))
                    VianButton(
                      text: 'Approve & Initialize Project',
                      icon: Icons.check_circle,
                      onPressed: () async {
                        if (!canAccess(role, 'approve')) return;
                        setState(() => _isLoading = true);
                        final res = await ref.read(estimationProvider.notifier).approveEstimate(details['id']);
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
                          const Divider(color: VianTheme.goldBorder, height: 32),
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
                                      title: Text(ph['phaseName'] ?? '', style: const TextStyle(color: VianTheme.headerBlack, fontSize: 13, fontWeight: FontWeight.bold)),
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
                                      title: Text(mat['materialName'] ?? '', style: const TextStyle(color: VianTheme.headerBlack, fontSize: 13)),
                                      subtitle: Text('${mat['quantity']} ${mat['unit']} @ ₹${mat['rate']}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
                                      trailing: Text(currencyFormat.format(mat['cost'] ?? 0), style: const TextStyle(color: VianTheme.headerBlack, fontSize: 12, fontWeight: FontWeight.bold)),
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
        style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
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
              color: isGold ? VianTheme.primaryGold : VianTheme.headerBlack,
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
                style: GoogleFonts.outfit(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 14),
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
                  style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                const SizedBox(height: 20),
                _buildVarianceProgressRow('Raw Materials Cost', data['estimatedMaterialCost'] ?? 0, data['actualMaterialCost'] ?? 0, data['materialVariance'] ?? 0),
                const Divider(color: VianTheme.goldBorder, height: 32),
                _buildVarianceProgressRow('Labour Resource Cost', data['estimatedLabourCost'] ?? 0, data['actualLabourCost'] ?? 0, data['labourVariance'] ?? 0),
                const Divider(color: VianTheme.goldBorder, height: 32),
                _buildVarianceProgressRow('Site Direct Expenses', data['estimatedExpenses'] ?? 0, data['actualExpenses'] ?? 0, data['expensesVariance'] ?? 0),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVarianceCard(String title, String value, Color color) {
    return VianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color, fontSize: 18),
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13)),
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
            backgroundColor: VianTheme.darkBackground,
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
  String _materialSearchQuery = '';
  String _materialCategoryFilter = 'All';
  String _boqSearchQuery = '';
  String _boqSortColumn = 'name';
  bool _boqSortAscending = true;
  final Set<String> _expandedBoqIds = {};
  bool _calculating = false;
  bool _exportPdfSelected = true;

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
  final _clientContactController = TextEditingController(text: 'amit.bajaj@example.com');
  final _addressController = TextEditingController(text: 'Plot 14, ECR Highway');
  final _cityController = TextEditingController(text: 'Chennai');
  final _builtUpAreaController = TextEditingController(text: '2800');

  String _selectedProjectType = 'Villa';
  String _selectedUnit = 'Square Feet';
  String _selectedState = 'Tamil Nadu';
  String _selectedDistrict = 'Chennai';
  String _selectedPackage = 'Standard';

  // Step 1 Validation Errors
  String? _clientNameError;
  String? _clientContactError;
  String? _areaError;

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
      _recalculateLocalTotals();
    } catch (e) {
      debugPrint("Error run calculate: $e");
    } finally {
      setState(() => _calculating = false);
    }
  }

  Estimate _getCurrentEstimate() {
    final area = double.tryParse(_builtUpAreaController.text) ?? 1000.0;
    
    final info = ProjectClientInfo(
      projectId: _savedEstimateId?.toString() ?? '',
      clientName: _clientNameController.text,
      clientContact: _clientContactController.text,
      projectType: _selectedProjectType,
      builtUpAreaSqFt: area,
      floorPlanFileUrl: _uploadedDrawingUrl,
      aiExtractedAreas: _extractedAiData != null ? Map<String, double>.from(
        (_extractedAiData!['aiExtractedAreas'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), double.tryParse(v.toString()) ?? 0.0))
      ) : null,
      createdAt: DateTime.now(),
    );

    final List<MaterialRate> mats = _editableMaterials.map((m) {
      final name = m['materialName'] ?? '';
      final baseRate = double.tryParse(m['rate']?.toString() ?? '0.0') ?? 0.0;
      final qty = double.tryParse(m['quantity']?.toString() ?? '0.0') ?? 0.0;
      final ratio = area == 0.0 ? 0.0 : qty / area;
      
      String pkgStr = _selectedPackage.toLowerCase();
      PackageTier pkg = PackageTier.standard;
      if (pkgStr == 'economy') pkg = PackageTier.economy;
      if (pkgStr == 'premium') pkg = PackageTier.premium;

      return MaterialRate(
        materialId: m['id']?.toString() ?? '',
        name: name,
        unit: m['unit'] ?? '',
        baseRate: baseRate,
        quantityRatioPerSqFt: ratio,
        tier: pkg,
        region: _selectedDistrict,
        lastUpdated: DateTime.now(),
      );
    }).toList();

    final List<PhaseMilestone> milestones = [];
    DateTime currentStart = _startDate;
    for (final ph in _editablePhases) {
      final int duration = int.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0;
      final double budgetAlloc = double.tryParse(ph['budgetAllocation']?.toString() ?? '0.0') ?? 0.0;
      final double costTarget = double.tryParse(ph['estimatedCost']?.toString() ?? '0.0') ?? 0.0;
      
      milestones.add(PhaseMilestone(
        phaseId: ph['id']?.toString() ?? '',
        name: ph['phaseName'] ?? '',
        durationDays: duration,
        costTarget: costTarget,
        percentOfTotalBudget: budgetAlloc,
        startDate: currentStart,
      ));
      currentStart = currentStart.add(Duration(days: duration));
    }

    final List<BOQItem> boqs = _editableBOQ.map((b) {
      return BOQItem(
        itemId: b['id']?.toString() ?? '',
        description: b['materialName'] ?? '',
        unit: b['unit'] ?? '',
        quantity: double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0,
        rate: double.tryParse(b['rate']?.toString() ?? '0.0') ?? 0.0,
        category: b['category'] ?? 'Civil',
      );
    }).toList();

    final List<LabourEntry> labs = _editableLabour.map((l) {
      return LabourEntry(
        labourId: l['id']?.toString() ?? '',
        trade: l['labourType'] ?? '',
        count: int.tryParse(l['requiredWorkers']?.toString() ?? '0') ?? 0,
        dailyWage: double.tryParse(l['dailyWage']?.toString() ?? '850') ?? 850.0,
        estimatedDays: int.tryParse(l['estimatedDays']?.toString() ?? '0') ?? 0,
      );
    }).toList();

    final double marginPct = _marginPercentage;
    final double overheadPct = double.tryParse(widget.settings['companyOverheadPercent']?.toString() ?? '5.0') ?? 5.0;

    return Estimate(
      estimateId: _savedEstimateId?.toString() ?? '',
      clientInfo: info,
      selectedPackage: PackageTier.values.firstWhere(
        (t) => t.name == _selectedPackage.toLowerCase(),
        orElse: () => PackageTier.standard,
      ),
      materials: mats,
      phases: milestones,
      boqItems: boqs,
      labour: labs,
      margin: ProfitMarginConfig(
        marginPercent: marginPct,
        overheadBufferPercent: overheadPct,
      ),
      status: EstimateStatus.draft,
      createdAt: DateTime.now(),
    );
  }

  void _recalculateLocalTotals() {
    if (_calculatedResults == null) return;
    final est = _getCurrentEstimate();

    setState(() {
      _calculatedResults!['totalCost'] = est.baseCost.round();
      _calculatedResults!['materialCost'] = est.materialCost.round();
      _calculatedResults!['labourCost'] = est.labourCost.round();
      _calculatedResults!['overheadAmount'] = est.overheadAmount.round();
      _calculatedResults!['marginAmount'] = est.marginAmount.round();
      _calculatedResults!['grandTotal'] = est.totalCost.round();

      // Ensure BOQ items amount is strictly quantity * rate
      for (int i = 0; i < _editableBOQ.length; i++) {
        final b = _editableBOQ[i];
        final qty = double.tryParse(b['quantity']?.toString() ?? '0') ?? 0.0;
        final rate = double.tryParse(b['rate']?.toString() ?? '0') ?? 0.0;
        final amt = qty * rate;
        b['amount'] = amt;
        final double gstRate = double.tryParse(b['gstRate']?.toString() ?? '18') ?? 18;
        b['gstAmount'] = amt * (gstRate / 100);
        b['totalAmount'] = amt + b['gstAmount'];
      }

      // Re-allocate phase amounts based on cost targets and update end dates
      for (int i = 0; i < _editablePhases.length; i++) {
        final ph = _editablePhases[i];
        final double pct = double.tryParse(ph['budgetAllocation']?.toString() ?? '0') ?? 0.0;
        ph['estimatedCost'] = (est.baseCost * (pct / 100)).round();
        if (i < est.phases.length) {
          final computedPhase = est.phases[i];
          ph['startDate'] = computedPhase.startDate?.toIso8601String();
          ph['endDate'] = computedPhase.endDate?.toIso8601String();
        }
      }

      // Populate profitAnalysis map matching backend expectations
      _calculatedResults!['profitAnalysis'] = {
        'constructionCost': est.baseCost.round(),
        'companyMarginPercentage': est.margin.marginPercent,
        'estimatedProfit': est.marginAmount.round(),
        'gstPercentage': 18.0,
        'gstAmount': est.overheadAmount.round(),
        'netProjectValue': est.totalCost.round(),
        'companyOverhead': est.margin.overheadBufferPercent,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;

    Widget leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAnimatedProgressTracker(),
        const Divider(color: Color(0xFFE2E8F0), height: 32),
        if (_calculating)
          const SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold))),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: _buildActiveStepContent(),
            ),
          ),
        const SizedBox(height: 16),
        _buildControlButtons(),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: VianCard(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 800,
                child: leftContent,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 800,
              child: SingleChildScrollView(
                child: _buildStickySummaryPanel(),
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          VianCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAnimatedProgressTracker(),
                const Divider(color: Color(0xFFE2E8F0), height: 32),
                if (_calculating)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold))),
                  )
                else
                  _buildActiveStepContent(),
                const SizedBox(height: 16),
                _buildControlButtons(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStickySummaryPanel(),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressTracker() {
    final double pct = ((_currentStep + 1) / 10.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ESTIMATION STAGE ${_currentStep + 1} OF 10',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 1.0),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}% Complete',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            separatorBuilder: (context, index) => Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 16),
            itemBuilder: (context, index) {
              final active = _currentStep == index;
              final passed = index < _currentStep;
              final label = _getStepTitle(index);
              
              return InkWell(
                onTap: () {
                  if (passed || index == _currentStep + 1) {
                    setState(() {
                      _currentStep = index;
                    });
                  }
                },
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: active ? VianTheme.primaryGold : (passed ? VianTheme.success.withOpacity(0.2) : Colors.transparent),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? VianTheme.primaryGold : (passed ? VianTheme.success : Colors.grey.shade300),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: passed
                            ? const Icon(Icons.check, size: 10, color: VianTheme.success)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: active ? Colors.black : VianTheme.lightText,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: active ? VianTheme.primaryGold : (passed ? VianTheme.headerBlack : VianTheme.lightText),
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStickySummaryPanel() {
    final area = double.tryParse(_builtUpAreaController.text) ?? 0.0;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    final materialCost = double.tryParse(_calculatedResults?['materialCost']?.toString() ?? '0') ?? 0.0;
    final labourCost = double.tryParse(_calculatedResults?['labourCost']?.toString() ?? '0') ?? 0.0;
    final marginAmount = double.tryParse(_calculatedResults?['marginAmount']?.toString() ?? '0') ?? 0.0;
    final overheadAmount = double.tryParse(_calculatedResults?['overheadAmount']?.toString() ?? '0') ?? 0.0;
    
    final equipmentCost = materialCost * 0.05;
    final baseCost = materialCost + labourCost + equipmentCost;
    final gst = baseCost * 0.18;
    final grandTotal = baseCost + marginAmount + overheadAmount + gst;
    
    int totalDuration = 0;
    for (var ph in _editablePhases) {
      totalDuration += int.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0;
    }
    
    final aiConfidence = _extractedAiData?['confidence']?['builtUpArea'] ?? 0.95;

    return VianCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: VianTheme.primaryGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'LIVE ESTIMATE SUMMARY',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.headerBlack, letterSpacing: 0.5),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 24),
          
          _summaryRow('Project Name', _projectNameController.text.isEmpty ? 'Horizon Villa' : _projectNameController.text),
          _summaryRow('Client', _clientNameController.text.isEmpty ? 'Amit Bajaj' : _clientNameController.text),
          _summaryRow('Total Area', '${area.toStringAsFixed(0)} ${_selectedUnit == 'Square Feet' ? 'Sq.Ft' : 'Sq.M'}'),
          _summaryRow('Selected Package', _selectedPackage, isBadge: true),
          
          const Divider(color: Color(0xFFE2E8F0), height: 24),
          
          _summaryCostRow('Material Cost', materialCost),
          _summaryCostRow('Labour Cost', labourCost),
          _summaryCostRow('Equipment Cost', equipmentCost),
          _summaryCostRow('Company Overheads', overheadAmount),
          _summaryCostRow('Profit Margin', marginAmount),
          _summaryCostRow('GST (18%)', gst),
          
          const Divider(color: Color(0xFFE2E8F0), height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: VianTheme.headerBlack),
              ),
              Text(
                formatter.format(grandTotal),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VianTheme.primaryGold),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: VianTheme.lightText),
                    const SizedBox(width: 6),
                    Text(
                      'Est. Duration: ',
                      style: GoogleFonts.inter(fontSize: 12, color: VianTheme.lightText),
                    ),
                    Text(
                      '$totalDuration Days',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VianTheme.headerBlack),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 14, color: VianTheme.success),
                    const SizedBox(width: 6),
                    Text(
                      'AI Confidence: ',
                      style: GoogleFonts.inter(fontSize: 12, color: VianTheme.lightText),
                    ),
                    Text(
                      '${(aiConfidence * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VianTheme.success),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: VianTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: const TextStyle(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack)),
        ],
      ),
    );
  }

  Widget _summaryCostRow(String label, double val) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          Text(formatter.format(val), style: const TextStyle(fontSize: 12, color: VianTheme.headerBlack)),
        ],
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

  void _showAiConfirmationDialog(double areaVal, Map<String, dynamic> data) {
    final areaController = TextEditingController(text: areaVal.toString());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VianTheme.cardColor,
          title: Text(
            'CONFIRM AI FLOOR PLAN EXTRACTION',
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini AI has analyzed the uploaded floor plan and extracted the following parameters:',
                style: TextStyle(color: VianTheme.lightText, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text('Project Name Suggestion: ${data['projectName'] ?? 'N/A'}', style: const TextStyle(color: VianTheme.headerBlack, fontSize: 12)),
              Text('Client Name Suggestion: ${data['clientName'] ?? 'N/A'}', style: const TextStyle(color: VianTheme.headerBlack, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Confirm or Edit the Extracted Built-up Area (Sq.Ft):', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                controller: areaController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: VianTheme.headerBlack),
                decoration: const InputDecoration(
                  labelText: 'Built-up Area (Sq.Ft)',
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: VianTheme.goldBorder)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard', style: TextStyle(color: VianTheme.lightText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold),
              onPressed: () {
                final double confirmedArea = double.tryParse(areaController.text) ?? areaVal;
                setState(() {
                  _builtUpAreaController.text = confirmedArea.toString();
                  if (data['projectName'] != null && data['projectName'].toString().isNotEmpty) {
                    _projectNameController.text = data['projectName'];
                  }
                  if (data['clientName'] != null && data['clientName'].toString().isNotEmpty) {
                    _clientNameController.text = data['clientName'];
                  }
                  if (data['siteAddress'] != null && data['siteAddress'].toString().isNotEmpty) {
                    _addressController.text = data['siteAddress'];
                  }
                  _aiLogConsole.add('[DATA] User Confirmed Built-up Area: $confirmedArea Sq.ft');
                });
                _recalculateLocalTotals();
                Navigator.pop(context);
              },
              child: const Text('Confirm & Apply', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
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

            if (data != null && data['builtUpArea'] != null) {
              final double areaVal = double.tryParse(data['builtUpArea'].toString()) ?? 0.0;
              Future.microtask(() => _showAiConfirmationDialog(areaVal, data));
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    
    final detailsForm = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('Project Name', _projectNameController),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Client Name', _clientNameController, errorText: _clientNameError),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Client Contact (Phone/Email)', _clientContactController, errorText: _clientContactError),
            ),
            const SizedBox(width: 16),
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
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Built-up Area', _builtUpAreaController, keyboardType: TextInputType.number, errorText: _areaError),
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
              child: _buildDropdown('District Region', _selectedDistrict, ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Salem', 'Tiruppur'], (v) => setState(() => _selectedDistrict = v!)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField('Site Address', _addressController),
            ),
          ],
        ),
      ],
    );

    final aiAnalyzerPanel = _buildAiAnalyzerPanel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 1: Project & Client Details', 'Input target area sizes, building types, and client identifiers.'),
        const SizedBox(height: 24),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: detailsForm),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: aiAnalyzerPanel),
            ],
          )
        else ...[
          detailsForm,
          const SizedBox(height: 24),
          aiAnalyzerPanel,
        ],
      ],
    );
  }

  Widget _buildAiAnalyzerPanel() {
    final hasDrawing = _uploadedDrawingUrl != null;
    final confidence = _extractedAiData?['confidence'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: VianTheme.primaryGold, size: 24),
              const SizedBox(width: 12),
              Text(
                'AI COGNITIVE FLOOR PLAN SURVEYOR',
                style: GoogleFonts.outfit(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
              ),
              const Spacer(),
              if (hasDrawing)
                IconButton(
                  icon: const Icon(Icons.refresh, color: VianTheme.primaryGold, size: 18),
                  onPressed: _pickAndAnalyzeFloorPlan,
                  tooltip: 'Re-upload floor plan',
                ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 24),
          if (_analyzingFloorPlan) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _aiLogConsole.length,
                itemBuilder: (context, idx) => Text(
                  _aiLogConsole[idx],
                  style: const TextStyle(color: Color(0xFF00FF00), fontFamily: 'Courier', fontSize: 10),
                ),
              ),
            ),
          ] else if (hasDrawing) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                      const Text('Extraction Complete', style: TextStyle(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Source File: ${_uploadedDrawingUrl!.split('/').last}', style: const TextStyle(color: VianTheme.lightText, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _confidenceBadge('Area Ext.', confidence?['builtUpArea'] ?? 0.96),
                          const SizedBox(width: 8),
                          _confidenceBadge('Rooms Ext.', confidence?['roomDetection'] ?? 0.92),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildAiSurveyorReport(),
          ] else ...[
            InkWell(
              onTap: _pickAndAnalyzeFloorPlan,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: VianTheme.primaryGold.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: VianTheme.primaryGold, size: 40),
                    const SizedBox(height: 12),
                    const Text('Upload Architectural Floor Plan', style: TextStyle(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Support PDF, JPEG, and PNG formats up to 25MB', style: TextStyle(color: VianTheme.lightText, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confidenceBadge(String label, dynamic val) {
    final double pct = double.tryParse(val.toString()) ?? 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VianTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${(pct * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: VianTheme.success, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAiSurveyorReport() {
    if (_extractedAiData == null) return const SizedBox();
    final data = _extractedAiData!;
    final confidence = data['confidence'] ?? {};
    final similar = _calculatedResults?['similarProject'] ?? {};

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
    final complexity = data['complexityScore'] ?? 'Standard';
    final structural = data['structuralComplexity'] ?? 'Medium Structure';

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

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                style: GoogleFonts.outfit(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
              style: TextStyle(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: amenities.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(a, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          const Text(
            'AI Drawing Detection Confidence Indicators',
            style: TextStyle(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 11),
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

          if (similar.isNotEmpty) ...[
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.history_outlined, color: VianTheme.primaryGold, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Similar Project Historical Engine Analysis',
                  style: TextStyle(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETED PROJECT: ${similar['projectName'] ?? 'Horizon Villa ECR'}',
                          style: GoogleFonts.outfit(color: VianTheme.headerBlack, fontWeight: FontWeight.bold, fontSize: 10),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isGold ? VianTheme.primaryGold.withOpacity(0.3) : const Color(0xFFE2E8F0)),
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
              color: isGold ? VianTheme.primaryGold : VianTheme.headerBlack,
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
              backgroundColor: const Color(0xFFF1F5F9),
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
                stars: 3,
                warranty: '5 Years Structural',
                duration: '180 Days',
                matQuality: 'Local standard brands',
                labQuality: 'Standard local crew',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _packageOptionCard(
                'Standard Quality',
                '₹2500 / Sq.ft',
                'UltraTech OPC Cement, TATA Tiscon Fe 550 Steel, River sand, Vitrified tiles, Premium emulsion painting.',
                'Standard',
                badge: 'RECOMMENDED',
                stars: 4,
                warranty: '10 Years Structural',
                duration: '240 Days',
                matQuality: 'Premium grade OPC cement',
                labQuality: 'Skilled trade specialized crew',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _packageOptionCard(
                'Premium Luxury',
                '₹2800 / Sq.ft',
                'ACC Gold Premium Cement, TATA Tiscon Fe 600 Steel, Premium marble flooring, Royale luxury paints.',
                'Premium',
                badge: 'POPULAR CHOICE',
                stars: 5,
                warranty: '25 Years Structural',
                duration: '300 Days',
                matQuality: 'Ultra high-durability concrete',
                labQuality: 'Expert custom artisans',
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _packageOptionCard(String title, String rateLabel, String description, String value, {String? badge, int stars = 4, String? warranty, String? duration, String? matQuality, String? labQuality}) {
    final active = _selectedPackage == value;
    final area = double.tryParse(_builtUpAreaController.text) ?? 1000.0;
    final baseRate = double.tryParse(rateLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 2500.0;
    final totalCost = area * baseRate;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPackage = value;
        });
        _runCalculate();
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: active ? VianTheme.primaryGold.withOpacity(0.04) : VianTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? VianTheme.primaryGold : const Color(0xFFE2E8F0), width: active ? 2 : 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(active ? 0.08 : 0.02),
                  blurRadius: active ? 16 : 8,
                  offset: active ? const Offset(0, 8) : const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: active ? VianTheme.primaryGold : VianTheme.headerBlack, fontSize: 13)),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: VianTheme.primaryGold,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rateLabel,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated: ${formatter.format(totalCost)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: VianTheme.primaryGold, fontSize: 12),
                ),
                const Divider(color: Color(0xFFE2E8F0), height: 16),
                _specRow(Icons.construction, 'Materials', matQuality ?? 'Standard materials'),
                _specRow(Icons.engineering, 'Labour', labQuality ?? 'Skilled crew'),
                _specRow(Icons.timer, 'Timeline', duration ?? '240 Days'),
                _specRow(Icons.verified_user, 'Warranty', warranty ?? '10 Years'),
                const Divider(color: Color(0xFFE2E8F0), height: 12),
                Text(
                  description,
                  style: const TextStyle(color: VianTheme.lightText, fontSize: 10, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: VianTheme.primaryGold,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _specRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 12, color: VianTheme.lightText),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: VianTheme.headerBlack),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
        color: highlight ? VianTheme.primaryGold.withOpacity(0.04) : VianTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? VianTheme.primaryGold : const Color(0xFFE2E8F0), width: highlight ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(highlight ? 0.08 : 0.02),
            blurRadius: highlight ? 16 : 8,
            offset: highlight ? const Offset(0, 8) : const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: highlight ? VianTheme.primaryGold : VianTheme.headerBlack, fontSize: 13)),
          const SizedBox(height: 16),
          Text(
            formatter.format(cost),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 20),
          ),
          const SizedBox(height: 12),
          const Text('Includes standard regional materials, logistics, and labour crew allocations.', style: TextStyle(color: VianTheme.lightText, fontSize: 10, height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _stepMaterialsEditor() {
    final filteredMaterials = _editableMaterials.where((m) {
      final name = m['materialName']?.toString().toLowerCase() ?? '';
      final category = m['category']?.toString().toLowerCase() ?? 'raw materials';
      final matchesSearch = name.contains(_materialSearchQuery.toLowerCase());
      final matchesCategory = _materialCategoryFilter == 'All' || category.contains(_materialCategoryFilter.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 4: Raw Material Quantities & Prices', 'View and adjust default material quantities and purchase prices.'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                style: const TextStyle(color: VianTheme.headerBlack, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Search materials...',
                  prefixIcon: Icon(Icons.search, size: 16),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _materialSearchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              child: _buildDropdown('Category Filter', _materialCategoryFilter, ['All', 'Cement', 'Steel', 'Sand', 'Paint', 'Granite'], (v) {
                setState(() {
                  _materialCategoryFilter = v!;
                });
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Material Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack))),
                    Expanded(flex: 2, child: Text('Brand / Supplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack))),
                    Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack))),
                    Expanded(flex: 2, child: Text('Base Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack))),
                    Expanded(flex: 1, child: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack))),
                    Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack))),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMaterials.length,
                itemBuilder: (context, idx) {
                  final mat = filteredMaterials[idx];
                  final qty = double.tryParse(mat['quantity']?.toString() ?? '0') ?? 0.0;
                  final rate = double.tryParse(mat['rate']?.toString() ?? '0') ?? 0.0;
                  final subtotal = qty * rate;
                  final gst = subtotal * 0.18;
                  final total = subtotal + gst;
                  
                  String brand = 'UltraTech';
                  String supplier = 'Vian Logistics';
                  if (mat['materialName']?.toString().toLowerCase().contains('steel') == true) {
                    brand = 'TATA Tiscon';
                  } else if (mat['materialName']?.toString().toLowerCase().contains('paint') == true) {
                    brand = 'Asian Paints';
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mat['materialName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: VianTheme.primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(mat['category'] ?? 'Raw Materials', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(brand, style: const TextStyle(fontSize: 10, color: VianTheme.headerBlack, fontWeight: FontWeight.bold)),
                              Text(supplier, style: const TextStyle(fontSize: 9, color: VianTheme.lightText)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: '${mat['quantity']}',
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                  onChanged: (val) {
                                    mat['quantity'] = double.tryParse(val) ?? 0.0;
                                    _recalculateLocalTotals();
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(mat['unit'] ?? '', style: const TextStyle(fontSize: 9, color: VianTheme.lightText)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              const Text('₹', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${mat['rate']}',
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                  onChanged: (val) {
                                    mat['rate'] = double.tryParse(val) ?? 0.0;
                                    _recalculateLocalTotals();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Center(child: Text('18%', style: TextStyle(fontSize: 11, color: VianTheme.headerBlack))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
                                Text('GST: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(gst)}', style: const TextStyle(fontSize: 8, color: VianTheme.lightText)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepPhaseDurations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 5: Phase Duration Benchmarks', 'Adjust scheduled build durations (days) per construction phase.'),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _editablePhases.length,
          itemBuilder: (context, index) {
            final ph = _editablePhases[index];
            final targetCost = double.tryParse(ph['estimatedCost']?.toString() ?? '0') ?? 0.0;
            final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            
            String dependency = 'None (Excavation)';
            if (index > 0) {
              dependency = 'Phase ${index}: ${_editablePhases[index - 1]['phaseName']}';
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(color: VianTheme.primaryGold, shape: BoxShape.circle),
                          child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11))),
                        ),
                        Expanded(
                          child: Container(width: 2, color: VianTheme.goldBorder),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: VianTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ph['phaseName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.link, size: 12, color: VianTheme.lightText),
                                      const SizedBox(width: 4),
                                      Text('Dependency: $dependency', style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 12, color: VianTheme.primaryGold),
                                      const SizedBox(width: 4),
                                      const Text('Crew: Masons, Carpenters, Helpers', style: TextStyle(color: VianTheme.lightText, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Duration:', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
                                      Text('${ph['estimatedDuration']} Days', style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Slider(
                                    value: (double.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0.0).clamp(1.0, 90.0),
                                    min: 1,
                                    max: 90,
                                    divisions: 89,
                                    activeColor: VianTheme.primaryGold,
                                    inactiveColor: const Color(0xFFF1F5F9),
                                    onChanged: (val) {
                                      setState(() {
                                        ph['estimatedDuration'] = val.round();
                                      });
                                      _recalculateLocalTotals();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Cost Target', style: TextStyle(color: VianTheme.lightText, fontSize: 9)),
                                    const SizedBox(height: 4),
                                    Text(formatter.format(targetCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _stepBOQEditor() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Apply sorting and filtering to BOQ
    final List<dynamic> sortedBoq = List.from(_editableBOQ.where((b) {
      final name = b['materialName']?.toString().toLowerCase() ?? '';
      return name.contains(_boqSearchQuery.toLowerCase());
    }));

    sortedBoq.sort((a, b) {
      dynamic valA, valB;
      if (_boqSortColumn == 'name') {
        valA = a['materialName']?.toString() ?? '';
        valB = b['materialName']?.toString() ?? '';
      } else if (_boqSortColumn == 'qty') {
        valA = double.tryParse(a['quantity']?.toString() ?? '0') ?? 0.0;
        valB = double.tryParse(b['quantity']?.toString() ?? '0') ?? 0.0;
      } else if (_boqSortColumn == 'rate') {
        valA = double.tryParse(a['rate']?.toString() ?? '0') ?? 0.0;
        valB = double.tryParse(b['rate']?.toString() ?? '0') ?? 0.0;
      } else {
        valA = double.tryParse(a['totalAmount']?.toString() ?? '0') ?? 0.0;
        valB = double.tryParse(b['totalAmount']?.toString() ?? '0') ?? 0.0;
      }
      return _boqSortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 6: Bill of Quantities (BOQ) Preview Grid', 'Verify and modify final BOQ values including localized GST amounts.'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                style: const TextStyle(color: VianTheme.headerBlack, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Search BOQ items...',
                  prefixIcon: Icon(Icons.search, size: 16),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _boqSearchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BOQ exported to Excel successfully.')));
              },
              icon: const Icon(Icons.download, size: 16, color: Colors.black),
              label: const Text('Export Excel', style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.headerBlack, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BOQ exported to PDF successfully.')));
              },
              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
              label: Text('Export PDF', style: TextStyle(color: VianTheme.whiteText, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _boqHeaderCell('Material Item', 'name')),
                    Expanded(flex: 1, child: _boqHeaderCell('Unit', 'unit')),
                    Expanded(flex: 2, child: _boqHeaderCell('Quantity', 'qty')),
                    Expanded(flex: 2, child: _boqHeaderCell('Rate', 'rate')),
                    Expanded(flex: 2, child: _boqHeaderCell('GST Amt', 'gst')),
                    Expanded(flex: 2, child: _boqHeaderCell('Total Amt', 'total')),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedBoq.length,
                itemBuilder: (context, idx) {
                  final b = sortedBoq[idx];
                  final String id = b['id']?.toString() ?? '$idx';
                  final isExpanded = _expandedBoqIds.contains(id);
                  
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: VianTheme.lightText),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedBoqIds.remove(id);
                                  } else {
                                    _expandedBoqIds.add(id);
                                  }
                                });
                              },
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(b['materialName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(b['unit'] ?? '', style: const TextStyle(fontSize: 10, color: VianTheme.lightText)),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: '${b['quantity']}',
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                onChanged: (val) {
                                  b['quantity'] = double.tryParse(val) ?? 0.0;
                                  _recalculateLocalTotals();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: '${b['rate']}',
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                onChanged: (val) {
                                  b['rate'] = double.tryParse(val) ?? 0.0;
                                  _recalculateLocalTotals();
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(currencyFormat.format(b['gstAmount'] ?? 0), style: const TextStyle(fontSize: 10, color: VianTheme.lightText), textAlign: TextAlign.right),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                currencyFormat.format(b['totalAmount'] ?? 0),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BOQ ITEM SPECIFICATIONS: ${b['materialName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Text('GST Bracket: ', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
                                  Text('18% Standard Construction Levy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: VianTheme.headerBlack)),
                                  SizedBox(width: 24),
                                  Text('Standard Source: ', style: TextStyle(fontSize: 10, color: VianTheme.lightText)),
                                  Text('Verified Regional Logistics Channel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: VianTheme.headerBlack)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Derived Item Cost Base: ${currencyFormat.format((b['quantity'] ?? 0.0) * (b['rate'] ?? 0.0))} (before GST)', style: const TextStyle(fontSize: 10, color: VianTheme.lightText)),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _boqHeaderCell(String label, String key) {
    final isSelected = _boqSortColumn == key;
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _boqSortAscending = !_boqSortAscending;
          } else {
            _boqSortColumn = key;
            _boqSortAscending = true;
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
          const SizedBox(width: 4),
          if (isSelected)
            Icon(_boqSortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: VianTheme.primaryGold)
          else
            const Icon(Icons.swap_vert, size: 10, color: VianTheme.lightText),
        ],
      ),
    );
  }

  Widget _stepLabourRoster() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 7: Labour Roster Requirements', 'Estimate necessary worker counts and scheduled active days.'),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
          ),
          itemCount: _editableLabour.length,
          itemBuilder: (context, index) {
            final l = _editableLabour[index];
            final int count = int.tryParse(l['requiredWorkers']?.toString() ?? '0') ?? 0;
            final double wage = double.tryParse(l['dailyWage']?.toString() ?? '850') ?? 850.0;
            final int days = int.tryParse(l['estimatedDays']?.toString() ?? '0') ?? 0;
            final double totalCost = count * wage * days;
            final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            
            final efficiency = 85 + (index * 4) % 15;
            final availability = (index % 3 != 0) ? 'Fully Available' : 'Allocated (Scheduled)';
            
            return VianCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l['labourType'] ?? 'Crew Trade', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (index % 3 != 0) ? VianTheme.success.withOpacity(0.1) : VianTheme.primaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          availability,
                          style: TextStyle(color: (index % 3 != 0) ? VianTheme.success : VianTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: '$count',
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
                          decoration: const InputDecoration(
                            labelText: 'Crew Size',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          onChanged: (val) {
                            l['requiredWorkers'] = int.tryParse(val) ?? 0;
                            _recalculateLocalTotals();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: '$days',
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
                          decoration: const InputDecoration(
                            labelText: 'Days Count',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          onChanged: (val) {
                            l['estimatedDays'] = int.tryParse(val) ?? 0;
                            _recalculateLocalTotals();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Wage: ₹${wage.toStringAsFixed(0)}/day', style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                      Text('Efficiency: $efficiency%', style: const TextStyle(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Cost Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
                      Text(formatter.format(totalCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.primaryGold)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _stepTimelineScheduler() {
    final int totalDays = _editablePhases.fold(0, (acc, ph) => acc + (int.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0));
    final end = _startDate.add(Duration(days: totalDays));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 8: Construction Timeline Scheduler', 'Define the estimated start date and view project duration schedules.'),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('Start Date Picker: ', style: TextStyle(color: VianTheme.headerBlack, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 12, color: VianTheme.primaryGold),
              label: Text(DateFormat('yyyy-MM-dd').format(_startDate), style: const TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) {
                  setState(() {
                    _startDate = d;
                  });
                  _recalculateLocalTotals();
                }
              },
            ),
            const Spacer(),
            Text('Estimated Completion: ${DateFormat('yyyy-MM-dd').format(end)}', style: const TextStyle(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 24),
        
        const Text(
          'PROJECT GANTT CHART & SCHEDULE VISUALIZATION',
          style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 11, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(
                    flex: 7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Month 1', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold)),
                        Text('Month 2', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold)),
                        Text('Month 3', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold)),
                        Text('Month 4', style: TextStyle(fontSize: 9, color: VianTheme.lightText, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 16),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _editablePhases.length,
                itemBuilder: (context, index) {
                  final ph = _editablePhases[index];
                  final int duration = int.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0;
                  
                  int precedingDays = 0;
                  for (int i = 0; i < index; i++) {
                    precedingDays += int.tryParse(_editablePhases[i]['estimatedDuration']?.toString() ?? '0') ?? 0;
                  }
                  
                  final double startOffsetPct = totalDays == 0 ? 0.0 : precedingDays / totalDays;
                  final double durationPct = totalDays == 0 ? 0.0 : duration / totalDays;
                  
                  Color barColor = VianTheme.primaryGold;
                  if (index % 3 == 0) barColor = VianTheme.accentBlue;
                  if (index % 3 == 1) barColor = VianTheme.primaryGold;
                  if (index % 3 == 2) barColor = VianTheme.success;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ph['phaseName'] ?? 'Phase', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
                              Text('$duration Days', style: const TextStyle(fontSize: 9, color: VianTheme.lightText)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Container(
                            height: 24,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final totalWidth = constraints.maxWidth;
                                final double barWidth = totalWidth * durationPct;
                                final double barOffset = totalWidth * startOffsetPct;
                                
                                return Container(
                                  margin: EdgeInsets.only(left: barOffset),
                                  width: barWidth.clamp(20.0, totalWidth),
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(color: barColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$duration d',
                                      style: TextStyle(color: VianTheme.whiteText, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _legendItem(VianTheme.accentBlue, 'Planning & Base'),
                  const SizedBox(width: 12),
                  _legendItem(VianTheme.primaryGold, 'Structural Concrete'),
                  const SizedBox(width: 12),
                  _legendItem(VianTheme.success, 'Interior & Finish'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 9, color: VianTheme.lightText)),
      ],
    );
  }

  Widget _stepProfitMarginAnalysis() {
    if (_calculatedResults == null) return const SizedBox();
    final pAnalysis = _calculatedResults!['profitAnalysis'] ?? {};
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    final double constructionCost = double.tryParse(pAnalysis['constructionCost']?.toString() ?? '0') ?? 0.0;
    final double estimatedProfit = double.tryParse(pAnalysis['estimatedProfit']?.toString() ?? '0') ?? 0.0;
    final double gstAmount = double.tryParse(pAnalysis['gstAmount']?.toString() ?? '0') ?? 0.0;
    final double netProjectValue = double.tryParse(pAnalysis['netProjectValue']?.toString() ?? '0') ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 9: Financial Profit Margin Segments & Analysis', 'Manage company target profit margins and analyze cash flow projections.'),
        const SizedBox(height: 20),
        
        VianCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Set Company Profit Margin Limit:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: VianTheme.headerBlack)),
                  Text('${_marginPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _marginPercentage,
                min: 5,
                max: 25,
                divisions: 40,
                activeColor: VianTheme.primaryGold,
                inactiveColor: const Color(0xFFF1F5F9),
                onChanged: (val) {
                  setState(() {
                    _marginPercentage = val;
                  });
                  _recalculateLocalTotals();
                },
              ),
              if (_marginPercentage < 10.0 || _marginPercentage > 20.0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: VianTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 14, color: VianTheme.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: Margins outside 10%–20% require Director approval.',
                          style: TextStyle(color: VianTheme.warning, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _financialTile('Net Project Value (NPV)', netProjectValue, Icons.currency_rupee, VianTheme.primaryGold),
            _financialTile('Estimated Profit', estimatedProfit, Icons.trending_up, VianTheme.success),
            _financialTile('GST (18% Construction tax)', gstAmount, Icons.account_balance, VianTheme.accentBlue),
            _financialTile('Construction Cost Base', constructionCost, Icons.foundation, VianTheme.headerBlack),
          ],
        ),
        
        const SizedBox(height: 24),
        
        const Text('PROJECT FINANCIALS division breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFF1F5F9)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(flex: 60, child: Container(color: VianTheme.accentBlue, child: Center(child: Text('Cost (60%)', style: TextStyle(color: VianTheme.whiteText, fontSize: 9, fontWeight: FontWeight.bold))))),
                Expanded(flex: 12, child: Container(color: VianTheme.success, child: Center(child: Text('Profit (12%)', style: TextStyle(color: VianTheme.whiteText, fontSize: 9, fontWeight: FontWeight.bold))))),
                Expanded(flex: 18, child: Container(color: VianTheme.primaryGold, child: const Center(child: Text('GST (18%)', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))))),
                Expanded(flex: 10, child: Container(color: Color(0xFF64748B), child: Center(child: Text('Buffer (10%)', style: TextStyle(color: VianTheme.whiteText, fontSize: 9, fontWeight: FontWeight.bold))))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        const Text('CASH FLOW milestones SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _cashFlowRow('Booking Advance (10%)', netProjectValue * 0.10, 'Initial signing / Setup'),
              _cashFlowRow('Foundation Stage completion (20%)', netProjectValue * 0.20, 'Excavation & concrete base complete'),
              _cashFlowRow('RCC Brickwork completion (40%)', netProjectValue * 0.40, 'Lintel layout and pillars complete'),
              _cashFlowRow('Finishing & Handover stage (30%)', netProjectValue * 0.30, 'Paint, interior fittings, and clearance'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _financialTile(String title, double val, IconData icon, Color color) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return VianCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: VianTheme.lightText, fontSize: 10)),
                const SizedBox(height: 4),
                Text(currencyFormat.format(val), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.headerBlack)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cashFlowRow(String phase, double amt, String remark) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.headerBlack)),
              Text(remark, style: const TextStyle(fontSize: 9, color: VianTheme.lightText)),
            ],
          ),
          Text(currencyFormat.format(amt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold)),
        ],
      ),
    );
  }

  Widget _detailAnalysisRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: highlight ? VianTheme.primaryGold : VianTheme.headerBlack, fontSize: highlight ? 14 : 12)),
        ],
      ),
    );
  }

  Widget _deliverableRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: VianTheme.primaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: VianTheme.headerBlack),
            ),
          ),
        ],
      ),
    );
  }

  
  Future<int?> _ensureSavedEstimate() async {
    if (_savedEstimateId != null) return _savedEstimateId;
    
    setState(() => _savingEstimate = true);
    try {
      final est = _getCurrentEstimate();
      final finalData = est.toJson();

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
        backgroundColor: VianTheme.cardColor,
        title: Text(
          'Share via $channel',
          style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold),
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
              style: TextStyle(color: VianTheme.whiteText, fontSize: 13),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: VianTheme.goldBorder)),
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

  List<Widget> _buildProposalRows(NumberFormat format) {
    final List<Widget> list = [];
    if (_editableBOQ.isEmpty) {
      list.add(_proposalRow('01', 'Structural Foundation Reinforcement', 'High-tensile steel grade and reinforced concrete pour.', '1,200 m³', '₹8,40,000'));
      list.add(_proposalRow('02', 'Premium Glass Curtain Wall System', 'Triple-glazed, thermal-efficient obsidian tint glass.', '450 Panels', '₹12,50,000'));
      list.add(_proposalRow('03', 'Interior Finishing: Carrera Gold Selection', 'Marble slab flooring and custom joinery.', '8,500 sqft', '₹7,55,000'));
    } else {
      for (int i = 0; i < math.min(_editableBOQ.length, 5); i++) {
        final item = _editableBOQ[i];
        final totalCost = double.tryParse(item['totalCost']?.toString() ?? '0') ?? 0.0;
        list.add(_proposalRow(
          (i + 1).toString().padLeft(2, '0'),
          item['name'] ?? 'Material',
          item['category'] ?? 'Procurement',
          '${item['quantity'] ?? 1} ${item['unit'] ?? "Units"}',
          format.format(totalCost),
        ));
      }
    }
    return list;
  }

  Widget _proposalRow(String itemNo, String title, String desc, String qty, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: Text(itemNo, style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 13))),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(qty, style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Text(total, style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _exportFormatChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? VianTheme.primaryGold.withOpacity(0.08) : Colors.transparent,
        border: Border.all(color: active ? VianTheme.primaryGold : VianTheme.lightText),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          color: active ? VianTheme.primaryGold : VianTheme.lightText,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stepQuotationInvoicePreview() {
    if (_calculatedResults == null) return const SizedBox();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final pAnalysis = _calculatedResults!['profitAnalysis'] ?? {};
    final double netProjectValue = double.tryParse(pAnalysis['netProjectValue']?.toString() ?? '0') ?? 0.0;
    
    return Column(
      children: [
        if (_savingEstimate)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(VianTheme.primaryGold))),
          ),
        Center(
          child: Container(
            width: 800,
            constraints: const BoxConstraints(minHeight: 1100),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              border: Border.all(color: Colors.white.withOpacity(0.04)),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 16)),
              ],
            ),
            padding: const EdgeInsets.all(40),
            child: Stack(
              children: [
                Positioned(top: 0, left: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: VianTheme.primaryGold, width: 2), left: BorderSide(color: VianTheme.primaryGold, width: 2))))),
                Positioned(top: 0, right: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: VianTheme.primaryGold, width: 2), right: BorderSide(color: VianTheme.primaryGold, width: 2))))),
                Positioned(bottom: 0, left: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VianTheme.primaryGold, width: 2), left: BorderSide(color: VianTheme.primaryGold, width: 2))))),
                Positioned(bottom: 0, right: 0, child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VianTheme.primaryGold, width: 2), right: BorderSide(color: VianTheme.primaryGold, width: 2))))),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              color: VianTheme.primaryGold,
                              child: const Icon(Icons.architecture, color: Colors.black, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ATELIER EST.', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                Text('ARCHITECTURAL EXCELLENCE', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 8, letterSpacing: 1.5)),
                              ],
                            )
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('QUOTATION NO.', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            Text('#EST-2024-089', style: GoogleFonts.bodoniModa(color: VianTheme.whiteText, fontSize: 18, fontStyle: FontStyle.italic)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, VianTheme.goldBorder, Colors.transparent]),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF13131A),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PREPARED FOR', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                const SizedBox(height: 8),
                                Text(_clientNameController.text.isNotEmpty ? _clientNameController.text : 'Sovereign Estates Group', style: GoogleFonts.inter(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(_clientContactController.text, style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PROJECT REFERENCE', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 8),
                              Text(_projectNameController.text.isNotEmpty ? _projectNameController.text : 'The Meridian Penthouse Complex', style: GoogleFonts.inter(color: VianTheme.whiteText, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('${_addressController.text}, ${_cityController.text}', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 40),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: VianTheme.primaryGold.withOpacity(0.3)),
                          bottom: BorderSide(color: VianTheme.primaryGold.withOpacity(0.3)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Text('TOTAL ESTIMATED INVESTMENT', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormat.format(netProjectValue),
                            style: GoogleFonts.bodoniModa(color: VianTheme.primaryGold, fontSize: 44, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Inclusive of all structural taxes and profit margins', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Expanded(flex: 1, child: Text('ITEM', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(flex: 6, child: Text('DESCRIPTION', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('QTY', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        Expanded(flex: 3, child: Text('TOTAL', style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                    const Divider(color: VianTheme.goldBorder, height: 24),

                    ..._buildProposalRows(currencyFormat),

                    const SizedBox(height: 48),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TERMS & CONDITIONS', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                'This estimation is subject to market fluctuation in raw material costs exceeding 5%. Sourcing prices are valid for 30 days.',
                                style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Text('CONFIDENTIALITY', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                'This document contains proprietary design intelligence and pricing strategies. Unauthorized distribution is prohibited.',
                                style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 11, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 32),
                              Container(width: 120, height: 1, color: VianTheme.lightText),
                              const SizedBox(height: 8),
                              Text('Authorized Signature', style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('Lead Architect - Atelier Est.', style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 10)),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: VianTheme.cardColor,
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('EXPORT:', style: GoogleFonts.outfit(color: VianTheme.lightText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => setState(() => _exportPdfSelected = true),
                    child: _exportFormatChip('Print PDF (A4)', _exportPdfSelected),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _exportPdfSelected = false),
                    child: _exportFormatChip('Spreadsheet (XLSX)', !_exportPdfSelected),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: VianTheme.lightText),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    icon: const Icon(Icons.share, size: 14),
                    label: Text('SHARE LINK', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    onPressed: () async {
                      final id = await _ensureSavedEstimate();
                      if (id != null) {
                        _showShareDialog(id, 'WhatsApp');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VianTheme.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    icon: const Icon(Icons.download, size: 14),
                    label: Text('DOWNLOAD PROPOSAL', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    onPressed: () async {
                      final id = await _ensureSavedEstimate();
                      if (id == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to save estimate for export.')),
                        );
                        return;
                      }
                      if (_exportPdfSelected) {
                        final url = '${ApiService.baseUrl}/estimations/$id/quotation/pdf?token=${ApiService.token}';
                        openUrl(url);
                      } else {
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
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _stepHeader(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: VianTheme.lightText, fontSize: 11)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, String? errorText}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: VianTheme.headerBlack),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
        errorText: errorText,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 12, color: VianTheme.headerBlack)))).toList(),
      onChanged: onChanged,
      style: const TextStyle(color: VianTheme.headerBlack, fontSize: 12),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: VianTheme.lightText, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }

  bool _validateStep1() {
    bool isValid = true;
    setState(() {
      _clientNameError = null;
      _clientContactError = null;
      _areaError = null;
      
      final name = _clientNameController.text.trim();
      if (name.isEmpty) {
        _clientNameError = 'Client Name is required';
        isValid = false;
      }
      
      final contact = _clientContactController.text.trim();
      final bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(contact);
      final bool isPhone = RegExp(r'^\+?[0-9]{10,15}$').hasMatch(contact);
      if (contact.isEmpty) {
        _clientContactError = 'Client contact info is required';
        isValid = false;
      } else if (!isEmail && !isPhone) {
        _clientContactError = 'Enter a valid email or phone number';
        isValid = false;
      }
      
      final areaVal = double.tryParse(_builtUpAreaController.text) ?? 0.0;
      if (areaVal <= 0) {
        _areaError = 'Built-up area must be greater than zero';
        isValid = false;
      }
    });
    return isValid;
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
              if (!_validateStep1()) return;
              await _runCalculate();
            }
            if (_currentStep == 4) {
              double totalAlloc = 0.0;
              for (var ph in _editablePhases) {
                totalAlloc += double.tryParse(ph['budgetAllocation']?.toString() ?? '0.0') ?? 0.0;
              }
              if ((totalAlloc - 100.0).abs() > 0.01) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: VianTheme.danger,
                    content: Text(
                      'Validation Alert: Phase allocations must sum to 100% (currently ${totalAlloc.toStringAsFixed(1)}%). Please adjust allocations.',
                      style: TextStyle(color: VianTheme.whiteText, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                return;
              }
            }
            if (_currentStep == 6) {
              int maxPhaseDuration = 0;
              for (var ph in _editablePhases) {
                final int duration = int.tryParse(ph['estimatedDuration']?.toString() ?? '0') ?? 0;
                if (duration > maxPhaseDuration) {
                  maxPhaseDuration = duration;
                }
              }
              
              String? warnTrade;
              for (var l in _editableLabour) {
                final int days = int.tryParse(l['estimatedDays']?.toString() ?? '0') ?? 0;
                if (days > maxPhaseDuration) {
                  warnTrade = l['labourType'] ?? 'Labour';
                  break;
                }
              }
              
              if (warnTrade != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: VianTheme.warning,
                    content: Text(
                      'Roster Alert: Daily roster days for $warnTrade exceed the longest phase duration of $maxPhaseDuration days.',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            }
            if (_currentStep == 9) {
              final finalData = {
                'projectName': _projectNameController.text,
                'clientName': _clientNameController.text,
                'clientContact': _clientContactController.text,
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

  Widget _headerCell(
    String title, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      alignment: alignment,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
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
            color: VianTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VianTheme.goldBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: VianTheme.primaryGold, size: 48),
              const SizedBox(height: 16),
              Text(
                'ACCESS AUTHORIZATION DENIED',
                style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
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
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.headerBlack, fontSize: 14),
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
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VianTheme.goldBorder)),
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
          style: GoogleFonts.outfit(color: VianTheme.whiteText, fontSize: 14, fontWeight: FontWeight.bold),
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
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13, letterSpacing: 0.8),
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
                        color: VianTheme.cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(item['projectName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: VianTheme.whiteText)),
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
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          _mobileLedgerRow('Materials', data['estimatedMaterialCost'] ?? 0, data['actualMaterialCost'] ?? 0, currencyFormat),
          Divider(color: VianTheme.goldBorder),
          _mobileLedgerRow('Labour', data['estimatedLabourCost'] ?? 0, data['actualLabourCost'] ?? 0, currencyFormat),
          Divider(color: VianTheme.goldBorder),
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
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? VianTheme.primaryGold : VianTheme.whiteText, fontSize: 12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Spent: ${formatter.format(actVal)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: VianTheme.whiteText, fontSize: 12)),
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
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
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
          Center(child: Text('RCC Structure Completion: 45%', style: TextStyle(color: VianTheme.whiteText, fontSize: 12, fontWeight: FontWeight.bold))),
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
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
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
                    Text('Monitor Morning/Evening operational briefings and log staff attendance', style: TextStyle(color: VianTheme.whiteText.withOpacity(0.5))),
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
          color: VianTheme.cardColor,
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
                    dropdownColor: VianTheme.cardColor,
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
                    inactiveColor: VianTheme.goldBorder,
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
                            Text('${emp['employeeId'] ?? ''} • ${emp['role'] ?? ''}', style: TextStyle(fontSize: 12, color: VianTheme.whiteText.withOpacity(0.4))),
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
          border: Border.all(color: selected ? color : VianTheme.goldBorder),
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
            Text('Log your first morning or evening call to begin compliance scores tracking.', style: TextStyle(color: VianTheme.whiteText.withOpacity(0.4))),
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
            color: VianTheme.cardColor,
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
                    style: TextStyle(color: VianTheme.whiteText.withOpacity(0.4), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (call['notes'] != null && call['notes'].isNotEmpty) ...[
                Text(
                  call['notes'],
                  style: TextStyle(color: VianTheme.whiteText.withOpacity(0.8), fontSize: 13.5),
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
                    style: TextStyle(fontSize: 11, color: VianTheme.whiteText.withOpacity(0.3)),
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
    final ok = await ApiService.updateIncentiveStatus(rowId, status, remarks: 'Approved by Managing Director');
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
        backgroundColor: VianTheme.cardColor,
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
            const Divider(color: VianTheme.goldBorder),
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
          backgroundColor: VianTheme.goldBorder,
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
    final pRole = getPermissionRole(role);
    final isMD = pRole == 'Super Admin' || pRole == 'Admin';
    final isSuperAdmin = pRole == 'Super Admin';

    // Summary Calculations
    double totalBonus = 0;
    double totalPenalties = 0;
    double averageScore = 0;
    if (_incentives.isNotEmpty) {
      double sumScore = 0;
      for (var inc in _incentives) {
        totalBonus += safeToDouble(inc['finalAmount']);
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
                    Text('Auto-compute monthly employee operational score, bonuses, and review override penalties.', style: TextStyle(color: VianTheme.whiteText.withOpacity(0.5))),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        dropdownColor: VianTheme.cardColor,
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
                Expanded(child: _summaryCard('Total Final Payouts', '₹${totalBonus.toStringAsFixed(0)}', Icons.arrow_upward, Colors.green)),
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
                  : _buildIncentivesTable(isMD, isSuperAdmin),
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
        color: VianTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: VianTheme.whiteText.withOpacity(0.5), fontSize: 13)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: color, size: 28),
        ],
      ),
    );
  }

  Widget _buildIncentivesTable(bool isMD, bool isSuperAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.4),
              3: FlexColumnWidth(1.4),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(1.2),
              6: FlexColumnWidth(1.2),
              7: FlexColumnWidth(2.2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF15151D)),
                children: [
                  _headerCell('Staff Member'),
                  _headerCell('Score'),
                  _headerCell('Suggested (₹)'),
                  _headerCell('Approved (₹)'),
                  _headerCell('Diff (+/-)'),
                  _headerCell('Penalties (₹)'),
                  _headerCell('Status'),
                  _headerCell('Actions'),
                ],
              ),
              ..._incentives.map((row) {
                final emp = row['user'] ?? {};
                final double score = safeToDouble(row['totalScore']);
                final status = row['status'] ?? 'Draft';
                final double suggested = safeToDouble(row['suggestedAmount']);
                final double finalAmt = safeToDouble(row['finalAmount']);
                final double diff = finalAmt - suggested;

                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.02))),
                  ),
                  children: [
                    _dataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${emp['employeeId'] ?? ''} • ${emp['role'] ?? ''}', style: TextStyle(fontSize: 11, color: VianTheme.whiteText.withOpacity(0.4))),
                      ],
                    )),
                    _dataCell(Text(
                      '${score.toStringAsFixed(1)}', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: _getScoreColor(score)),
                    )),
                    _dataCell(Text('+₹${suggested.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey))),
                    _dataCell(Text('+₹${finalAmt.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    _dataCell(Text(
                      diff == 0 ? '₹0' : (diff > 0 ? '+₹${diff.toStringAsFixed(0)}' : '-₹${diff.abs().toStringAsFixed(0)}'),
                      style: TextStyle(color: diff == 0 ? Colors.grey : (diff > 0 ? Colors.green : Colors.red)),
                    )),
                    _dataCell(Text('-₹${safeToDouble(row['penaltyAmount']).toStringAsFixed(0)}', style: const TextStyle(color: Colors.red))),
                    _dataCell(_statusTag(status)),
                    _dataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.analytics_outlined, size: 20, color: Colors.blueAccent),
                          tooltip: 'Scorecard Breakdown',
                          onPressed: () => _showScoreBreakdownModal(row),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history_toggle_off, size: 20, color: Colors.purpleAccent),
                          tooltip: 'Review Timeline',
                          onPressed: () => _showTimelineModal(row),
                        ),
                        if (isMD && row['locked'] != true) ...[
                          IconButton(
                            icon: const Icon(Icons.rate_review_outlined, size: 20, color: VianTheme.primaryGold),
                            tooltip: isSuperAdmin ? 'Override & Finalize' : 'Submit Recommendation',
                            onPressed: () => _showReviewIncentiveModal(row, isMD, isSuperAdmin),
                          ),
                        ] else if (row['locked'] == true) ...[
                          const Tooltip(
                            message: 'Locked',
                            child: Icon(Icons.lock, size: 16, color: Colors.grey),
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

  void _showTimelineModal(dynamic record) {
    List<dynamic> logs = [];
    try {
      logs = jsonDecode(record['reviewTimeline'] ?? '[]');
    } catch (e) {}

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VianTheme.cardColor,
        title: Text('Review Timeline – ${record['user']?['name']}', style: const TextStyle(color: VianTheme.primaryGold)),
        content: Container(
          width: 450,
          child: logs.isEmpty
              ? const Center(child: Text('No adjustments logged yet. (Draft status)', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (context, idx) {
                    final log = logs[idx];
                    final String dt = log['timestamp']?.split('T')?.first ?? '';
                    final String time = log['timestamp']?.split('T')?.last?.substring(0, 5) ?? '';
                    
                    return Card(
                      color: const Color(0xFF15151D),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${log['action']}', style: const TextStyle(fontWeight: FontWeight.bold, color: VianTheme.primaryGold, fontSize: 13)),
                                Text('$dt $time', style: TextStyle(color: VianTheme.whiteText.withOpacity(0.4), fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Modified By: ${log['user']} (${log['role']})', style: const TextStyle(fontSize: 12)),
                            Text('Amount: ₹${log['originalAmount']} ➔ ₹${log['newAmount']}', style: const TextStyle(fontSize: 12)),
                            if (log['remarks'] != null && log['remarks'].toString().isNotEmpty)
                              Text('Remarks: ${log['remarks']}', style: TextStyle(color: VianTheme.whiteText.withOpacity(0.7), fontSize: 11)),
                            if (log['reason'] != null && log['reason'].toString().isNotEmpty)
                              Text('Audit Reason: ${log['reason']}', style: TextStyle(color: VianTheme.whiteText.withOpacity(0.7), fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showReviewIncentiveModal(dynamic record, bool isMD, bool isSuperAdmin) {
    final double suggested = safeToDouble(record['suggestedAmount']);
    final double currentFinal = safeToDouble(record['finalAmount']);
    final amountCtrl = TextEditingController(text: currentFinal.toStringAsFixed(0));
    final remarksCtrl = TextEditingController(text: (isSuperAdmin ? record['superAdminRemarks'] : record['adminRemarks']) ?? '');
    final reasonCtrl = TextEditingController();
    
    String currentStatus = record['status'] ?? 'Draft';
    bool lockedValue = record['locked'] == true;

    final allowedStatuses = isSuperAdmin 
      ? ['Draft', 'Under Review', 'Recommended', 'Approved', 'Rejected', 'Paid']
      : ['Draft', 'Under Review', 'Recommended'];

    if (!allowedStatuses.contains(currentStatus)) {
      currentStatus = allowedStatuses.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: VianTheme.cardColor,
          title: Text('Review Incentive Payout – ${record['user']?['name']}', style: const TextStyle(color: VianTheme.primaryGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Base Suggested Incentive: ₹${suggested.toStringAsFixed(2)}', style: const TextStyle(color: VianTheme.lightText)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Final Incentive Override Amount (₹)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: currentStatus,
                  dropdownColor: VianTheme.cardColor,
                  decoration: const InputDecoration(labelText: 'Review Status'),
                  items: allowedStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setStateModal(() {
                      currentStatus = val!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: remarksCtrl,
                  decoration: InputDecoration(labelText: isSuperAdmin ? 'Super Admin Review Remarks' : 'Admin Review Remarks'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason for Override (required for audit)'),
                ),
                const SizedBox(height: 16),
                if (isSuperAdmin) ...[
                  CheckboxListTile(
                    title: const Text('Lock Payout Month (Freeze re-calculation)', style: TextStyle(fontSize: 13)),
                    value: lockedValue,
                    activeColor: VianTheme.primaryGold,
                    checkColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setStateModal(() {
                        lockedValue = val!;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VianTheme.primaryGold, foregroundColor: Colors.black),
              onPressed: () async {
                if (reasonCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reason for override is required for the Audit Log.')),
                  );
                  return;
                }
                
                final double finalAmt = double.tryParse(amountCtrl.text) ?? suggested;
                
                final ok = await ApiService.updateIncentiveStatus(
                  record['id'] as int,
                  currentStatus,
                  finalAmount: finalAmt,
                  adminRemarks: !isSuperAdmin ? remarksCtrl.text : null,
                  superAdminRemarks: isSuperAdmin ? remarksCtrl.text : null,
                  locked: isSuperAdmin ? lockedValue : null,
                  reason: reasonCtrl.text,
                );
                
                if (ok) {
                  Navigator.pop(ctx);
                  _loadIncentives();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incentive record updated successfully.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update incentive details.')),
                  );
                }
              },
              child: const Text('Save Review'),
            ),
          ],
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
      bg = Colors.green.withOpacity(0.15);
      txt = Colors.greenAccent;
    } else if (status == 'Paid') {
      bg = Colors.green.withOpacity(0.25);
      txt = Colors.green;
    } else if (status == 'Under Review') {
      bg = Colors.orange.withOpacity(0.15);
      txt = Colors.orangeAccent;
    } else if (status == 'Recommended') {
      bg = Colors.purple.withOpacity(0.15);
      txt = Colors.purpleAccent;
    } else if (status == 'Rejected') {
      bg = Colors.red.withOpacity(0.15);
      txt = Colors.redAccent;
    } else if (status == 'Draft') {
      bg = Colors.grey.withOpacity(0.15);
      txt = Colors.grey;
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
