import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'core/theme/theme.dart';
import 'core/widgets/custom_widgets.dart';
import 'core/services/api_service.dart';

class HapticTapEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HapticTapEffect({Key? key, required this.child, required this.onTap}) : super(key: key);

  @override
  State<HapticTapEffect> createState() => _HapticTapEffectState();
}

class _HapticTapEffectState extends State<HapticTapEffect> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _active = true),
      onTapUp: (_) => setState(() => _active = false),
      onTapCancel: () => setState(() => _active = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _active ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class UserManagementTab extends ConsumerStatefulWidget {
  final bool showCreateDialog;
  final String? editUserId;

  const UserManagementTab({
    Key? key,
    this.showCreateDialog = false,
    this.editUserId,
  }) : super(key: key);

  @override
  ConsumerState<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends ConsumerState<UserManagementTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  int _activeTab = 0; // 0 = Users List, 1 = Permission Matrix, 2 = Audit Logs

  // Search, filter, pagination variables
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';
  int _currentPage = 1;
  final int _itemsPerPage = 6;

  // Simulated audit logs
  final List<Map<String, dynamic>> _auditLogs = [
    {
      'actor': 'Ar. Anand Sathiesivam',
      'action': 'Created user account',
      'target': 'Ar. Kishore Kumar (Junior Architect)',
      'time': '10 mins ago',
      'icon': Icons.person_add_alt_1_outlined,
    },
    {
      'actor': 'Ar. Vijay Vinthan',
      'action': 'Updated geofence permissions',
      'target': 'Er. Anthony Richard (Site Engineer)',
      'time': '1 hour ago',
      'icon': Icons.security_outlined,
    },
    {
      'actor': 'Ar. Anand Sathiesivam',
      'action': 'Suspended inactive worker credentials',
      'target': 'Worker ID #108 (Labourer)',
      'time': '3 hours ago',
      'icon': Icons.block_outlined,
    },
  ];

  // Helper methods for password strength checking
  String _checkPasswordStrength(String password) {
    if (password.isEmpty) return '';
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Weak': return Colors.red;
      case 'Fair': return Colors.orange;
      case 'Good': return Colors.blue;
      case 'Strong': return Colors.green;
      default: return Colors.transparent;
    }
  }

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final rand = math.Random();
    return List.generate(12, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final list = await ApiService.getEmployees();
    setState(() {
      _users = list;
      _loading = false;
    });

    if (widget.showCreateDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        _showAddUserForm(context, size.width < 650, size.width >= 650 && size.width < 1000);
      });
    } else if (widget.editUserId != null) {
      final targetId = int.tryParse(widget.editUserId!);
      if (targetId != null) {
        final existing = list.firstWhere((element) => element['id'] == targetId, orElse: () => null);
        if (existing != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final size = MediaQuery.of(context).size;
            _showAddUserForm(context, size.width < 650, size.width >= 650 && size.width < 1000, existingUser: existing);
          });
        }
      }
    }
  }

  bool _canEditUser(dynamic targetUser, String requesterRole) {
    final String r = requesterRole.toLowerCase();
    final bool isReqSuper = r == 'super admin' || r == 'managing director';
    if (isReqSuper) return true;

    final bool isReqAdmin = r.contains('admin');
    if (isReqAdmin) {
      final String tRole = (targetUser['role'] ?? 'Employee').toLowerCase();
      final bool isTargetSuper = tRole == 'super admin' || tRole == 'managing director';
      return !isTargetSuper;
    }
    return false;
  }

  bool _canDeleteUser(dynamic targetUser, String requesterRole) {
    final String r = requesterRole.toLowerCase();
    final bool isReqSuper = r == 'super admin' || r == 'managing director';
    if (isReqSuper) return true;

    final bool isReqAdmin = r.contains('admin');
    if (isReqAdmin) {
      final String tRole = (targetUser['role'] ?? 'Employee').toLowerCase();
      final bool isTargetSuper = tRole == 'super admin' || tRole == 'managing director';
      return !isTargetSuper;
    }
    return false;
  }

  void _confirmDeleteUser(dynamic targetUser, bool isMobile) {
    final String name = targetUser['name'] ?? 'User';
    final String role = targetUser['role'] ?? 'Employee';
    final int userId = targetUser['id'];

    Widget modalContent() {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: VianTheme.danger, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete $name?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: VianTheme.headerBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'User: $name ($role)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: VianTheme.headerBlack),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will deactivate and remove this user\'s access immediately. This action cannot be undone.',
              style: TextStyle(color: VianTheme.lightText, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VianTheme.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () async {
                    final ok = await ApiService.deleteEmployee(userId);
                    if (ok['success'] == true) {
                      Navigator.of(context).pop();
                      _loadUsers();
                    }
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => modalContent(),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 450,
            child: modalContent(),
          ),
        ),
      );
    }
  }

  void _showMobileActions(BuildContext context, dynamic u, bool showEdit, bool showDelete, bool isSelf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEdit)
              HapticTapEffect(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddUserForm(context, true, false, existingUser: u);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Color(0xFF6B6560)),
                      SizedBox(width: 16),
                      Text('Edit User Info', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            if (showDelete)
              HapticTapEffect(
                onTap: isSelf 
                    ? () {} // disabled
                    : () {
                        Navigator.of(ctx).pop();
                        _confirmDeleteUser(u, true);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: isSelf ? Colors.grey : const Color(0xFFB33A3A)),
                      const SizedBox(width: 16),
                      Text(
                        isSelf ? 'Delete User (Disabled: Self)' : 'Delete User Account',
                        style: TextStyle(
                          color: isSelf ? Colors.grey : const Color(0xFFB33A3A),
                          fontWeight: FontWeight.bold,
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
  }

  void _showAddUserForm(BuildContext context, bool isMobile, bool isTablet, {dynamic existingUser}) {
    final nameCtrl = TextEditingController(text: existingUser != null ? existingUser['name'] : '');
    final emailCtrl = TextEditingController(text: existingUser != null ? existingUser['email'] : '');
    final passwordCtrl = TextEditingController(text: '');
    final confirmPasswordCtrl = TextEditingController(text: '');
    final roleCtrl = TextEditingController(text: existingUser != null ? existingUser['role'] : 'Employee');
    final deptCtrl = TextEditingController(text: existingUser != null ? existingUser['department'] : 'Site Team');
    bool obscurePassword = true;
    bool showPasswordFields = existingUser == null;
    
    final requesterRole = ApiService.currentUser?['role'] ?? 'Client';
    final isRequesterSuperAdmin = requesterRole == 'Super Admin' || requesterRole == 'Managing Director';
    final List<String> availableRoles = isRequesterSuperAdmin 
        ? ['Employee', 'Site Manager', 'Architect', 'Admin', 'Super Admin']
        : ['Employee', 'Site Manager', 'Architect'];

    // Ensure roleCtrl.text matches one of availableRoles
    if (!availableRoles.contains(roleCtrl.text)) {
      roleCtrl.text = availableRoles.first;
    }

    Widget formContent(StateSetter setStateDlg) => Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: VianTheme.primaryGold,
        colorScheme: const ColorScheme.dark(
          primary: VianTheme.primaryGold,
          surface: VianTheme.cardColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.outfit(
            color: VianTheme.primaryGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: VianTheme.goldBorder),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: VianTheme.primaryGold, width: 1.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existingUser != null ? 'EDIT PROFILE' : 'CREATE USER ACCOUNT',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LIVE UPDATE CONSOLE',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: VianTheme.primaryGold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'FULL LEGAL NAME',
                hintText: 'e.g. Sebastian Thorne',
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'EXECUTIVE EMAIL',
                hintText: 's.thorne@atelier-exec.com',
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: roleCtrl.text,
              dropdownColor: VianTheme.cardColor,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'ROLE ACCESS',
              ),
              items: availableRoles.map((r) {
                return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white)));
              }).toList(),
              onChanged: (val) => setStateDlg(() => roleCtrl.text = val!),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: deptCtrl.text,
              dropdownColor: VianTheme.cardColor,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'DEPARTMENT',
              ),
              items: ['Site Team', 'Designing Team', 'Core Team', 'Executive', 'Administration'].map((d) {
                return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Colors.white)));
              }).toList(),
              onChanged: (val) => setStateDlg(() => deptCtrl.text = val!),
            ),
            if (existingUser != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: showPasswordFields,
                    activeColor: VianTheme.primaryGold,
                    checkColor: VianTheme.cardColor,
                    onChanged: (val) => setStateDlg(() => showPasswordFields = val ?? false),
                  ),
                  Text('RESET / CHANGE PASSWORD', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: VianTheme.primaryGold, letterSpacing: 0.5)),
                ],
              ),
            ],
            if (showPasswordFields) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      onChanged: (_) => setStateDlg(() {}),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'PASSWORD',
                        hintText: 'Enter password',
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: VianTheme.primaryGold, size: 18),
                          onPressed: () => setStateDlg(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: VianTheme.primaryGold),
                    tooltip: 'Generate Random Password',
                    onPressed: () {
                      final pass = _generateRandomPassword();
                      setStateDlg(() {
                        passwordCtrl.text = pass;
                        confirmPasswordCtrl.text = pass;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (passwordCtrl.text.isNotEmpty) ...[
                (() {
                  final strength = _checkPasswordStrength(passwordCtrl.text);
                  final color = _getPasswordStrengthColor(strength);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STRENGTH: ${strength.toUpperCase()}', style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(4, (index) {
                          final filled = (strength == 'Weak' && index == 0) ||
                                         (strength == 'Fair' && index <= 1) ||
                                         (strength == 'Good' && index <= 2) ||
                                         (strength == 'Strong');
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: filled ? color : Colors.white10,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                })(),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: obscurePassword,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'CONFIRM PASSWORD',
                  hintText: 'Re-enter password',
                ),
              ),
            ],
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: VianButton(
                    text: existingUser != null ? 'COMMIT CHANGES' : 'CREATE USER',
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                        if (showPasswordFields) {
                          if (passwordCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password cannot be empty.')),
                            );
                            return;
                          }
                          if (passwordCtrl.text != confirmPasswordCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match.')),
                            );
                            return;
                          }
                        }
                        
                        final Map<String, dynamic> payload = {
                          'name': nameCtrl.text,
                          'email': emailCtrl.text,
                          'role': roleCtrl.text,
                          'department': deptCtrl.text,
                        };
                        
                        if (showPasswordFields) {
                          payload['password'] = passwordCtrl.text;
                        }
                        
                        final Map<String, dynamic> ok;
                        if (existingUser != null) {
                          ok = await ApiService.updateEmployee(existingUser['id'], payload);
                        } else {
                          payload['username'] = emailCtrl.text.split('@').first;
                          payload['isActive'] = true;
                          ok = await ApiService.createEmployee(payload);
                        }
                        if (ok['success'] == true) {
                          Navigator.of(context).pop();
                          _loadUsers();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok['message'] ?? 'Action failed.')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VianTheme.lightText,
                    side: const BorderSide(color: VianTheme.goldBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('RESET', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isMobile || isTablet) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: VianTheme.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDlgState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(child: formContent(setDlgState)),
          ),
        ),
      );
    } else {
      // Desktop Slide-Over Panel
      showDialog(
        context: context,
        builder: (ctx) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: VianTheme.cardColor,
            elevation: 16,
            child: Container(
              width: 480,
              height: double.infinity,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: VianTheme.goldBorder, width: 1)),
              ),
              child: StatefulBuilder(
                builder: (ctx, setDlgState) => formContent(setDlgState),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _toggleUserStatus(int userId, String name, bool currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          currentStatus ? 'Suspend Account' : 'Reactivate Account',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          currentStatus 
              ? 'Are you sure you want to suspend the user account of "$name"?' 
              : 'Are you sure you want to reactivate the user account of "$name"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? VianTheme.danger : VianTheme.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final ok = await ApiService.updateEmployee(userId, {'isActive': !currentStatus});
              if (ok['success'] == true) {
                Navigator.of(ctx).pop();
                _loadUsers();
              }
            },
            child: Text(currentStatus ? 'Suspend' : 'Reactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;
    final isTablet = size.width >= 650 && size.width < 1000;
    final currentUser = ref.watch(userProvider);
    final userRole = currentUser?['role'] ?? 'Client';
    
    final r = userRole.toLowerCase();
    final isSuperAdmin = r == 'super admin' || r == 'managing director';
    final isAdmin = r.contains('admin');
    final isPM = r.contains('project manager') || r.contains('manager');
    final hasAccess = isSuperAdmin || isAdmin || isPM;

    if (!hasAccess) {
      return const Scaffold(
        backgroundColor: VianTheme.darkBackground,
        body: Center(
          child: Text('Access Denied: You do not have permissions to manage users.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: VianTheme.darkBackground,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stepper segments / top controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Directory',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage organization access and hierarchical roles.',
                      style: GoogleFonts.inter(color: VianTheme.lightText, fontSize: 13),
                    ),
                  ],
                ),
                if (!isMobile && (isSuperAdmin || isAdmin))
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VianTheme.primaryGold,
                      side: const BorderSide(color: VianTheme.primaryGold),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => _showAddUserForm(context, isMobile, isTablet),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('ADD NEW USER', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Segment Selector
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VianTheme.cardColor,
                border: Border.all(color: VianTheme.goldBorder),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  _segmentButton(0, 'USERS DIRECTORY', Icons.people_outline),
                  if (isSuperAdmin) ...[
                    _segmentButton(1, 'PERMISSION MATRIX', Icons.grid_on_outlined),
                    _segmentButton(2, 'AUDIT LOGS', Icons.history_toggle_off_outlined),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _activeTab == 0
                  ? _buildUsersList(isMobile, isTablet)
                  : (_activeTab == 1 ? _buildPermissionMatrix() : _buildAuditLogs()),
            ),
          ],
        ),
      ),
      floatingActionButton: (isMobile && (isSuperAdmin || isAdmin))
          ? FloatingActionButton(
              backgroundColor: VianTheme.primaryGold,
              foregroundColor: VianTheme.cardColor,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              onPressed: () => _showAddUserForm(context, isMobile, isTablet),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _segmentButton(int index, String label, IconData icon) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: active ? VianTheme.primaryGold.withOpacity(0.08) : Colors.transparent,
            border: active ? Border.all(color: VianTheme.primaryGold.withOpacity(0.3)) : null,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? VianTheme.primaryGold : VianTheme.lightText),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: active ? VianTheme.primaryGold : VianTheme.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(bool isMobile, bool isTablet) {
    final currentUser = ref.watch(userProvider);
    final String userRole = currentUser?['role'] ?? 'Client';
    final int currentUserId = currentUser?['id'] ?? 0;

    // 1. Perform client-side filter and search
    final filteredUsers = _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(query) || email.contains(query);

      final roleStr = (u['role'] ?? 'Employee').toString();
      final matchesRole = _selectedRoleFilter == 'All' || 
          roleStr.toLowerCase() == _selectedRoleFilter.toLowerCase() ||
          (roleStr.toLowerCase().contains('admin') && _selectedRoleFilter == 'Admin') ||
          (roleStr.toLowerCase().contains('project manager') && _selectedRoleFilter == 'Project Manager');

      final bool isActive = u['isActive'] ?? true;
      final matchesStatus = _selectedStatusFilter == 'All' || 
          (_selectedStatusFilter == 'Active' && isActive) ||
          (_selectedStatusFilter == 'Suspended' && !isActive);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    // 2. Perform pagination
    final int totalItems = filteredUsers.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = math.min(startIndex + _itemsPerPage, totalItems);
    
    final paginatedUsers = (startIndex < totalItems) 
        ? filteredUsers.sublist(startIndex, endIndex) 
        : <dynamic>[];

    // Filter controls UI
    final Widget searchAndFilterRow = Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'SEARCH DIRECTORY...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12, letterSpacing: 0.5),
                prefixIcon: const Icon(Icons.search, color: VianTheme.primaryGold, size: 18),
                fillColor: VianTheme.cardColor,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: VianTheme.goldBorder),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: VianTheme.goldBorder),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: VianTheme.primaryGold, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: VianTheme.goldBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: VianTheme.cardColor,
                value: _selectedRoleFilter,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                items: ['All', 'Super Admin', 'Admin', 'Project Manager', 'Engineer', 'Staff'].map((r) {
                  return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRoleFilter = val ?? 'All';
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: VianTheme.cardColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: VianTheme.goldBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: VianTheme.cardColor,
                value: _selectedStatusFilter,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                items: ['All', 'Active', 'Suspended'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStatusFilter = val ?? 'All';
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );

    // Pagination controls UI
    final Widget paginationRow = totalPages <= 1 ? const SizedBox() : Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: VianTheme.primaryGold),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text(
            'Page $_currentPage of $totalPages',
            style: const TextStyle(color: VianTheme.headerBlack, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: VianTheme.primaryGold),
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          searchAndFilterRow,
          Expanded(
            child: ListView.builder(
              itemCount: paginatedUsers.length,
              itemBuilder: (context, index) {
                final u = paginatedUsers[index];
                final bool showEdit = _canEditUser(u, userRole);
                final bool showDelete = _canDeleteUser(u, userRole);
                final bool isSelf = u['id'] == currentUserId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: VianCard(
                    child: Stack(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: VianTheme.darkBackground,
                            child: Text((u['name']?.toString() ?? '').isNotEmpty ? u['name'].toString().substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: VianTheme.primaryGold)),
                          ),
                          title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['email'] ?? '', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${u['createdAt'] != null ? u['createdAt'].toString().split('T').first : '2026-06-15'}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'Last Login: ${u['lastLogin'] ?? 'Active Now'}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              _buildRoleBadge(u['role'] ?? 'Employee'),
                            ],
                          ),
                        ),
                        if (showEdit || showDelete)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: HapticTapEffect(
                              onTap: () => _showMobileActions(context, u, showEdit, showDelete, isSelf),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.more_vert, size: 20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          paginationRow,
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          searchAndFilterRow,
          Expanded(
            child: ListView.builder(
              itemCount: paginatedUsers.length,
              itemBuilder: (context, index) {
                final u = paginatedUsers[index];
                final bool showEdit = _canEditUser(u, userRole);
                final bool showDelete = _canDeleteUser(u, userRole);
                final bool isSelf = u['id'] == currentUserId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: VianCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: VianTheme.darkBackground,
                          radius: 20,
                          child: Text((u['name']?.toString() ?? '').isNotEmpty ? u['name'].toString().substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: VianTheme.primaryGold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(u['email'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${u['createdAt'] != null ? u['createdAt'].toString().split('T').first : '2026-06-15'} | Last Login: ${u['lastLogin'] ?? 'Active Now'}',
                                style: const TextStyle(color: VianTheme.lightText, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        _buildRoleBadge(u['role'] ?? 'Employee'),
                        const SizedBox(width: 24),
                        if (showEdit || showDelete)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showAddUserForm(context, false, true, existingUser: u);
                              } else if (val == 'delete') {
                                _confirmDeleteUser(u, false);
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (showEdit)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B6560)),
                                      SizedBox(width: 8),
                                      Text('Edit User'),
                                    ],
                                  ),
                                ),
                              if (showDelete)
                                PopupMenuItem(
                                  value: 'delete',
                                  enabled: !isSelf,
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 16, color: isSelf ? Colors.grey : Color(0xFFB33A3A)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete User',
                                        style: TextStyle(color: isSelf ? Colors.grey : Color(0xFFB33A3A)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          paginationRow,
        ],
      );
    }

    // Desktop view
    return Column(
      children: [
        searchAndFilterRow,
        Expanded(
          child: CustomPaint(
            painter: AtelierBracketPainter(color: VianTheme.primaryGold),
            child: VianCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Table header
                  Container(
                    color: const Color(0xFF1A1B1F),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('NAME / EMAIL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 0.8))),
                        Expanded(flex: 2, child: Text('ROLE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 0.8))),
                        Expanded(flex: 2, child: Text('CREATED DATE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 0.8))),
                        Expanded(flex: 2, child: Text('LAST LOGIN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 0.8))),
                        Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 0.8))),
                        Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTIONS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.primaryGold, letterSpacing: 0.8)))),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: paginatedUsers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: VianTheme.goldBorder),
                    itemBuilder: (context, index) {
                      final u = paginatedUsers[index];
                      final bool isActive = u['isActive'] ?? true;
                      final bool showEdit = _canEditUser(u, userRole);
                      final bool showDelete = _canDeleteUser(u, userRole);
                      final bool isSelf = u['id'] == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: VianTheme.darkBackground,
                                    child: Text((u['name']?.toString() ?? '').isNotEmpty ? u['name'].toString().substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: VianTheme.primaryGold)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(u['email'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 11.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildRoleBadge(u['role'] ?? 'Employee'),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                u['createdAt'] != null
                                    ? u['createdAt'].toString().split('T').first
                                    : '2026-06-15',
                                style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                u['lastLogin'] ?? 'Active Now',
                                style: const TextStyle(color: VianTheme.lightText, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Switch(
                                    value: isActive,
                                    activeColor: VianTheme.success,
                                    onChanged: (val) => _toggleUserStatus(u['id'], u['name'], isActive),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isActive ? 'Active' : 'Suspended',
                                    style: TextStyle(
                                      color: isActive ? VianTheme.success : VianTheme.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (showEdit)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B6560)),
                                      onPressed: () => _showAddUserForm(context, false, false, existingUser: u),
                                      tooltip: 'Edit User',
                                    ),
                                  if (showEdit && showDelete)
                                    const SizedBox(width: 8),
                                  if (showDelete)
                                    isSelf
                                        ? const Tooltip(
                                            message: 'You cannot delete your own account.',
                                            child: IconButton(
                                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                              onPressed: null,
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB33A3A)),
                                            onPressed: () => _confirmDeleteUser(u, false),
                                            tooltip: 'Delete User',
                                          ),
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
        ),
        paginationRow,
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final bool isSuper = role.toLowerCase().contains('super') || role.toLowerCase().contains('managing');
    final bool isAdmin = role.toLowerCase().contains('admin') && !isSuper;

    if (isSuper) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: VianTheme.primaryGold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 12, color: VianTheme.primaryGold),
            SizedBox(width: 4),
            Text(
              'Superadmin',
              style: TextStyle(color: VianTheme.primaryGold, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (isAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: VianTheme.accentBlue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VianTheme.accentBlue.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 12, color: VianTheme.accentBlue),
            SizedBox(width: 4),
            Text(
              'Admin',
              style: TextStyle(color: VianTheme.accentBlue, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: VianTheme.lightText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: const TextStyle(color: VianTheme.lightText, fontSize: 10.5),
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    final modules = ['CRM & Leads', 'Client Database', 'Project Workspace', 'Attendance Management', 'Expenses & Invoices', 'Settings Console'];
    
    return VianCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF7F4EE),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('MODULE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText))),
                Expanded(flex: 2, child: Text('SUPERADMIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('ADMIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('STAFF / SITE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: modules.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: VianTheme.goldBorder),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          modules[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Center(
                          child: Icon(Icons.check_circle, color: VianTheme.success, size: 20),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Icon(
                            index == 5 ? Icons.cancel : Icons.check_circle,
                            color: index == 5 ? VianTheme.danger : VianTheme.success,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Icon(
                            index >= 3 ? Icons.cancel : Icons.check_circle,
                            color: index >= 3 ? VianTheme.danger : VianTheme.success,
                            size: 20,
                          ),
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
  }

  Widget _buildAuditLogs() {
    return VianCard(
      child: ListView.separated(
        itemCount: _auditLogs.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: VianTheme.goldBorder),
        itemBuilder: (context, index) {
          final log = _auditLogs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: VianTheme.darkBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(log['icon'] as IconData, color: VianTheme.primaryGold, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log['actor'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            log['time'] as String,
                            style: const TextStyle(color: VianTheme.lightText, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log['action']} on: ${log['target']}',
                        style: const TextStyle(color: VianTheme.lightText, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
