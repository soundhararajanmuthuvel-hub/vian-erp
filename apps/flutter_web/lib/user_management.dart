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
  const UserManagementTab({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends ConsumerState<UserManagementTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  int _activeTab = 0; // 0 = Users List, 1 = Permission Matrix, 2 = Audit Logs
  
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
  }

  bool _canEditUser(dynamic targetUser, String requesterRole, String requesterDept) {
    final String r = requesterRole.toLowerCase();
    final bool isReqSuper = r == 'super admin' || r == 'managing director';
    if (isReqSuper) return true;

    final bool isReqAdmin = r.contains('admin');
    if (isReqAdmin) {
      final String tRole = (targetUser['role'] ?? 'Employee').toLowerCase();
      final bool isTargetSuper = tRole == 'super admin' || tRole == 'managing director';
      final bool isTargetAdmin = tRole.contains('admin');
      if (isTargetSuper || isTargetAdmin) return false;
      return targetUser['department'] == requesterDept;
    }
    return false;
  }

  bool _canDeleteUser(dynamic targetUser, String requesterRole) {
    final String r = requesterRole.toLowerCase();
    final bool isReqSuper = r == 'super admin' || r == 'managing director';
    return isReqSuper;
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
    final passwordCtrl = TextEditingController(text: existingUser != null ? (existingUser['password'] ?? 'Vian@123') : 'Vian@123');
    final roleCtrl = TextEditingController(text: existingUser != null ? existingUser['role'] : 'Employee');
    final deptCtrl = TextEditingController(text: existingUser != null ? existingUser['department'] : 'Site Team');
    bool obscurePassword = true;
    
    final requesterRole = ApiService.currentUser?['role'] ?? 'Client';
    final isRequesterSuperAdmin = requesterRole == 'Super Admin' || requesterRole == 'Managing Director';
    final List<String> availableRoles = isRequesterSuperAdmin 
        ? ['Employee', 'Site Manager', 'Architect', 'Admin', 'Super Admin']
        : ['Employee', 'Site Manager', 'Architect'];

    // Ensure roleCtrl.text matches one of availableRoles
    if (!availableRoles.contains(roleCtrl.text)) {
      roleCtrl.text = availableRoles.first;
    }

    Widget formContent(StateSetter setStateDlg) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            existingUser != null ? 'Edit User' : 'Create New User Account',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: VianTheme.headerBlack,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Ar. Rajesh Kumar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'name@vianarchitects.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: roleCtrl.text,
            decoration: const InputDecoration(
              labelText: 'Access Permission Role',
              border: OutlineInputBorder(),
            ),
            items: availableRoles.map((r) {
              return DropdownMenuItem(value: r, child: Text(r));
            }).toList(),
            onChanged: (val) => setStateDlg(() => roleCtrl.text = val!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: deptCtrl.text,
            decoration: const InputDecoration(
              labelText: 'Assigned Department',
              border: OutlineInputBorder(),
            ),
            items: ['Site Team', 'Designing Team', 'Core Team', 'Executive', 'Administration'].map((d) {
              return DropdownMenuItem(value: d, child: Text(d));
            }).toList(),
            onChanged: (val) => setStateDlg(() => deptCtrl.text = val!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordCtrl,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Account Password',
              hintText: 'Enter login password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setStateDlg(() => obscurePassword = !obscurePassword),
              ),
            ),
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
                  backgroundColor: VianTheme.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                    final Map<String, dynamic> payload = {
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'role': roleCtrl.text,
                      'department': deptCtrl.text,
                      'password': passwordCtrl.text,
                    };
                    
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
                    }
                  }
                },
                child: Text(existingUser != null ? 'Save Changes' : 'Save User'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile || isTablet) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            color: Colors.white,
            elevation: 16,
            child: Container(
              width: 480,
              height: double.infinity,
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
    
    final isSuperAdmin = userRole == 'Super Admin' || userRole == 'Managing Director';

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
                      'User Accounts Control',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: VianTheme.headerBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure permissions, roles, and deactivations',
                      style: TextStyle(color: VianTheme.lightText, fontSize: 13),
                    ),
                  ],
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VianTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onPressed: () => _showAddUserForm(context, isMobile, isTablet),
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Segment Selector
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE4DFD5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _segmentButton(0, 'Users List', Icons.people_outline),
                  if (isSuperAdmin) ...[
                    _segmentButton(1, 'Permission Matrix', Icons.grid_on_outlined),
                    _segmentButton(2, 'Audit Logs', Icons.history_toggle_off_outlined),
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
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: VianTheme.primaryGold,
              foregroundColor: Colors.white,
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
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? VianTheme.headerBlack : VianTheme.lightText),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? VianTheme.headerBlack : VianTheme.lightText,
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
    final String requesterDept = currentUser?['department'] ?? 'Site Team';
    final int currentUserId = currentUser?['id'] ?? 0;

    if (isMobile) {
      return ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          final bool showEdit = _canEditUser(u, userRole, requesterDept);
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
                      child: Text(u['name']?[0] ?? 'U', style: const TextStyle(color: VianTheme.primaryGold)),
                    ),
                    title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['email'] ?? '', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
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
      );
    }

    if (isTablet) {
      return ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          final bool showEdit = _canEditUser(u, userRole, requesterDept);
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
                    child: Text(u['name']?[0] ?? 'U', style: const TextStyle(color: VianTheme.primaryGold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(u['email'] ?? '', style: const TextStyle(color: VianTheme.lightText, fontSize: 12)),
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
      );
    }

    // Desktop view
    return VianCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table header
          Container(
            color: const Color(0xFFF7F4EE),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('NAME / EMAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText))),
                Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText))),
                Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText))),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: VianTheme.lightText)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: VianTheme.goldBorder),
              itemBuilder: (context, index) {
                final u = _users[index];
                final bool isActive = u['isActive'] ?? true;
                final bool showEdit = _canEditUser(u, userRole, requesterDept);
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
                              child: Text(u['name']?[0] ?? 'U', style: const TextStyle(color: VianTheme.primaryGold)),
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
                          u['department'] ?? 'Site Team',
                          style: const TextStyle(color: VianTheme.lightText),
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
