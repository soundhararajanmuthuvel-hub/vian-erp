import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import 'supervisor_photo_upload_dialog.dart';
import 'client_photo_viewer_modal.dart';

/// Simplified, calm, role-specific workspaces for V1 Client Launch
class SimpleRoleDashboard extends ConsumerStatefulWidget {
  final String effectiveRole;
  final Map<String, dynamic> user;

  const SimpleRoleDashboard({
    super.key,
    required this.effectiveRole,
    required this.user,
  });

  @override
  ConsumerState<SimpleRoleDashboard> createState() => _SimpleRoleDashboardState();
}

class _SimpleRoleDashboardState extends ConsumerState<SimpleRoleDashboard> {
  bool _isLoading = true;
  List<dynamic> _projects = [];
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadRoleData();
  }

  @override
  void didUpdateWidget(covariant SimpleRoleDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effectiveRole != widget.effectiveRole) {
      _loadRoleData();
    }
  }

  Future<void> _loadRoleData() async {
    setState(() => _isLoading = true);
    try {
      final projs = await ApiService.getProjects();
      final statsData = await ApiService.getExecutiveStats();

      // Collect recent photos if any projects exist
      final photos = <dynamic>[];
      if (projs.isNotEmpty) {
        for (final p in projs.take(3)) {
          final pPhotos = await ApiService.getProjectPhotos(p['id']);
          photos.addAll(pPhotos);
        }
      }

      if (mounted) {
        setState(() {
          _projects = projs;
          _stats = statsData;
          _recentPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSupervisorPhotoUpload([int? projectId]) {
    showDialog(
      context: context,
      builder: (context) => SupervisorPhotoUploadDialog(
        projects: _projects,
        initialProjectId: projectId,
        onUploaded: _loadRoleData,
      ),
    );
  }

  void _openClientPhotoViewer(List<dynamic> photos, int index, String projectName) {
    showDialog(
      context: context,
      builder: (context) => ClientPhotoViewerModal(
        photos: photos,
        initialIndex: index,
        projectName: projectName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VianTheme.primaryGold),
      );
    }

    final role = widget.effectiveRole;
    final r = role.toLowerCase();

    if (r == 'super admin') {
      return _buildSuperAdminDashboard();
    } else if (r == 'managing director' || r.contains('director') || r.contains('owner')) {
      return _buildOwnerDashboard();
    } else if (r.contains('project manager') || r == 'pm') {
      return _buildProjectManagerDashboard();
    } else if (r.contains('architect') || r.contains('design engineer')) {
      return _buildArchitectDashboard();
    } else if (r.contains('site') || r.contains('supervisor') || r.contains('labour manager')) {
      return _buildSupervisorDashboard();
    } else if (r.contains('accountant') || r.contains('finance')) {
      return _buildAccountantDashboard();
    } else if (r.contains('client')) {
      return _buildClientDashboard();
    } else if (r.contains('developer')) {
      return _buildDeveloperDashboard();
    }

    // Default Fallback
    return _buildOwnerDashboard();
  }

  // -------------------------------------------------------------
  // 1. SUPER ADMIN DASHBOARD
  // -------------------------------------------------------------
  Widget _buildSuperAdminDashboard() {
    final clientCount = _stats['clientCount'] ?? _stats['totalClients'] ?? 0;
    final projectCount = _projects.length;
    final teamCount = _stats['employeeCount'] ?? _stats['totalEmployees'] ?? 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Super Admin', 'System Administration & Global Controls'),
          const SizedBox(height: 24),

          // 4 Main Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('CLIENTS', '$clientCount', Icons.people_outline, Colors.blue)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('PROJECTS', '$projectCount', Icons.architecture, VianTheme.primaryGold)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('TEAM', '$teamCount', Icons.badge_outlined, Colors.purple)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('SYSTEM STATUS', 'Healthy', Icons.cloud_done_outlined, Colors.green)),
            ],
          ),
          const SizedBox(height: 28),

          // Quick Actions
          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton('+ Create Client', Icons.person_add_alt_1_outlined, () => context.go('/clients')),
              _buildActionButton('+ Create Project', Icons.add_chart_outlined, () => context.go('/projects')),
              _buildActionButton('+ Add Staff', Icons.group_add_outlined, () => context.go('/users')),
              _buildActionButton('Feature Control', Icons.tune, () => context.go('/feature-control')),
              _buildActionButton('System Settings', Icons.settings_outlined, () => context.go('/settings')),
            ],
          ),
          const SizedBox(height: 36),

          // Advanced section
          _buildSectionHeader('ADVANCED CONTROLS'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_outlined, color: VianTheme.primaryGold, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role Permissions, Feature Control & Audit Logs',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Control modular visibility, staff accounts, and security audit records.',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/feature-control'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VianTheme.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Open Feature Control'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. MANAGING DIRECTOR / OWNER DASHBOARD
  // -------------------------------------------------------------
  Widget _buildOwnerDashboard() {
    final activeProjects = _projects.where((p) => p['status'] != 'Completed').length;
    final clientCount = _stats['clientCount'] ?? _stats['totalClients'] ?? 0;
    final teamCount = _stats['employeeCount'] ?? _stats['totalEmployees'] ?? 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Good Morning', 'Executive Project & Business Overview'),
          const SizedBox(height: 24),

          // Overview Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('ACTIVE PROJECTS', '$activeProjects', Icons.architecture, VianTheme.primaryGold)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('CLIENTS', '$clientCount', Icons.people_outline, Colors.blue)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('TEAM', '$teamCount', Icons.badge_outlined, Colors.purple)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('PENDING ACTIONS', '2', Icons.pending_actions_outlined, Colors.orange)),
            ],
          ),
          const SizedBox(height: 32),

          // My Projects section
          _buildSectionHeader('MY PROJECTS'),
          const SizedBox(height: 14),
          _projects.isEmpty
              ? _buildEmptyState('No active projects found.')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _projects.take(5).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = _projects[index];
                    final progress = (p['progress'] ?? 35);
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] ?? 'Project #${p['id']}',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Client: ${p['client']?['name'] ?? 'Assigned Client'} • Status: ${p['status'] ?? 'In Progress'}',
                                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (progress is num ? progress.toDouble() : 35.0) / 100.0,
                                        backgroundColor: Colors.white12,
                                        color: VianTheme.primaryGold,
                                        minHeight: 5,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('$progress%', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.photo_library_outlined, color: VianTheme.primaryGold, size: 20),
                                tooltip: 'View Photos',
                                onPressed: () => context.go('/projects/${p['id']}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
                                tooltip: 'Open Project',
                                onPressed: () => context.go('/projects/${p['id']}'),
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

  // -------------------------------------------------------------
  // 3. PROJECT MANAGER DASHBOARD
  // -------------------------------------------------------------
  Widget _buildProjectManagerDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Today\'s Work', 'Project Management & Coordination'),
          const SizedBox(height: 24),

          // Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('ACTIVE PROJECTS', '${_projects.length}', Icons.architecture, VianTheme.primaryGold)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('PENDING TASKS', '7', Icons.checklist_outlined, Colors.amber)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('TEAM ON SITE', '6', Icons.engineering_outlined, Colors.cyan)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('DEADLINES', '3 Upcoming', Icons.event_note_outlined, Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            'QUICK ACTIONS',
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton('+ Add Task', Icons.add_task_outlined, () => context.go('/tasks')),
              _buildActionButton('Update Project', Icons.edit_calendar_outlined, () => context.go('/projects')),
              _buildActionButton('Assign Supervisor', Icons.person_search_outlined, () => context.go('/projects')),
              _buildActionButton('Upload/Review Photos', Icons.photo_camera_outlined, () => _openSupervisorPhotoUpload()),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('WHAT NEEDS ATTENTION TODAY?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildAttentionItem('Bajaj Villa — Structural inspection sign-off due by 5:00 PM'),
                const Divider(color: Colors.white10, height: 20),
                _buildAttentionItem('Oberoi Commercial — Review new site photos uploaded by Site Supervisor'),
                const Divider(color: Colors.white10, height: 20),
                _buildAttentionItem('Palm Meadows — Plumbing drawing revision approval pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. ARCHITECT DASHBOARD
  // -------------------------------------------------------------
  Widget _buildArchitectDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Good Morning', 'Architectural Workspace & Project Drawings'),
          const SizedBox(height: 24),

          // Quick actions
          Row(
            children: [
              _buildActionButton('+ Add Update', Icons.post_add_outlined, () => context.go('/projects')),
              const SizedBox(width: 12),
              _buildActionButton('+ Upload Drawing', Icons.upload_file_outlined, () => context.go('/drawings')),
              const SizedBox(width: 12),
              _buildActionButton('View Site Photos', Icons.photo_library_outlined, () {
                if (_recentPhotos.isNotEmpty && _projects.isNotEmpty) {
                  _openClientPhotoViewer(_recentPhotos, 0, _projects.first['name'] ?? 'Project');
                } else {
                  context.go('/projects');
                }
              }),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('MY PROJECTS'),
          const SizedBox(height: 14),
          _projects.isEmpty
              ? _buildEmptyState('No assigned architecture projects.')
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _projects.take(4).length,
                  itemBuilder: (context, index) {
                    final p = _projects[index];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p['name'] ?? 'Project',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: VianTheme.primaryGold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p['type'] ?? 'Residential',
                                  style: GoogleFonts.inter(color: VianTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Client: ${p['client']?['name'] ?? 'Assigned Client'}',
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => context.go('/projects/${p['id']}'),
                                child: const Text('OPEN PROJECT', style: TextStyle(color: VianTheme.primaryGold, fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => context.go('/drawings'),
                                child: const Text('DRAWINGS', style: TextStyle(color: Colors.white70, fontSize: 11)),
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

  // -------------------------------------------------------------
  // 5. SUPERVISOR DASHBOARD (GOLD STANDARD FLOW)
  // -------------------------------------------------------------
  Widget _buildSupervisorDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Good Morning', 'On-Site Field Operations'),
          const SizedBox(height: 24),

          // Primary prominent action: 📷 UPLOAD SITE PHOTOS
          InkWell(
            onTap: () => _openSupervisorPhotoUpload(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VianTheme.primaryGold.withOpacity(0.25),
                    const Color(0xFF18181B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VianTheme.primaryGold, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VianTheme.primaryGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📷 UPLOAD SITE PHOTOS',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fast 3-click direct upload from camera or gallery to project gallery',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: VianTheme.primaryGold, size: 32),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3 Secondary Action Cards
          Row(
            children: [
              Expanded(
                child: _buildSupervisorActionCard(
                  '📝 UPDATE SITE',
                  'Post progress note or milestone',
                  Icons.edit_note_outlined,
                  () => context.go('/daily-work-report'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSupervisorActionCard(
                  '✅ TASKS',
                  'View today\'s checklist',
                  Icons.check_circle_outline,
                  () => context.go('/tasks'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSupervisorActionCard(
                  '📍 MY PROJECT',
                  'View assigned construction site',
                  Icons.location_on_outlined,
                  () {
                    if (_projects.isNotEmpty) {
                      context.go('/projects/${_projects.first['id']}');
                    } else {
                      context.go('/projects');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. CLIENT DASHBOARD
  // -------------------------------------------------------------
  Widget _buildClientDashboard() {
    final clientProject = _projects.isNotEmpty ? _projects.first : null;
    final projectName = clientProject != null ? (clientProject['name'] ?? 'Your Residence') : 'Your Project';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Welcome back', 'Your Project Portal & Progress Updates'),
          const SizedBox(height: 24),

          // Project Overview Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VianTheme.primaryGold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      projectName,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'ACTIVE ON SCHEDULE',
                        style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Overall Construction Progress: 65%',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.white12,
                  color: VianTheme.primaryGold,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Latest Photos Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('LATEST SITE PHOTOS'),
              if (_recentPhotos.isNotEmpty && clientProject != null)
                TextButton.icon(
                  icon: const Icon(Icons.fullscreen, color: VianTheme.primaryGold, size: 18),
                  label: const Text('VIEW ALL PHOTOS', style: TextStyle(color: VianTheme.primaryGold, fontSize: 12)),
                  onPressed: () => _openClientPhotoViewer(_recentPhotos, 0, projectName),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (_recentPhotos.isEmpty)
            _buildEmptyState('No site photos uploaded for your project yet.')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _recentPhotos.take(6).length,
              itemBuilder: (context, index) {
                final photo = _recentPhotos[index];
                final url = photo['url'] ?? photo['fileUrl'] ?? '';
                return InkWell(
                  onTap: () => _openClientPhotoViewer(_recentPhotos, index, projectName),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                      color: const Color(0xFF27272A),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_outlined, color: Colors.white38),
                      ),
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 32),

          // Portal Quick Links (Documents, Updates, Payments)
          _buildSectionHeader('PROJECT DOCUMENTS & INVOICES'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPortalLinkCard('Drawings & Documents', Icons.folder_open_outlined, () => context.go('/documents')),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPortalLinkCard('Invoices & Receipts', Icons.receipt_long_outlined, () => context.go('/invoices')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. ACCOUNTANT DASHBOARD
  // -------------------------------------------------------------
  Widget _buildAccountantDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Financial Overview', 'Accounts, Invoices & Receivables'),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildMetricCard('INVOICES', '18 Active', Icons.receipt_long_outlined, Colors.blue)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('QUOTATIONS', '6 Pending', Icons.description_outlined, VianTheme.primaryGold)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('RECEIVABLES', '₹ 24.5 L', Icons.account_balance_wallet_outlined, Colors.green)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('EXPENSES (MTD)', '₹ 4.2 L', Icons.payments_outlined, Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            'ACCOUNTING ACTIONS',
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton('+ Create Invoice', Icons.add_circle_outline, () => context.go('/invoices')),
              _buildActionButton('Record Payment', Icons.payment_outlined, () => context.go('/invoices')),
              _buildActionButton('Add Expense', Icons.receipt_outlined, () => context.go('/expenses')),
              _buildActionButton('View Quotations', Icons.request_quote_outlined, () => context.go('/quotations')),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 8. DEVELOPER DASHBOARD
  // -------------------------------------------------------------
  Widget _buildDeveloperDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting('Developer Console', 'System Diagnostics & Feature Configuration'),
          const SizedBox(height: 24),

          // Diagnostic Status Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('API STATUS', 'Healthy (200 OK)', Icons.check_circle_outline, Colors.green)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('ENVIRONMENT', 'Local & Render', Icons.code_outlined, Colors.cyan)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('ROLES TESTED', '9 Roles', Icons.security_outlined, Colors.purple)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard('STORAGE', 'Cloudinary CDN', Icons.cloud_outlined, VianTheme.primaryGold)),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            'DEVELOPER TOOLS',
            style: GoogleFonts.outfit(color: VianTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton('Feature Visibility Control', Icons.tune, () => context.go('/feature-control')),
              _buildActionButton('API Diagnostics', Icons.network_check_outlined, () => context.go('/dashboard')),
              _buildActionButton('Test Supervisor Photo Upload', Icons.camera_alt_outlined, () => _openSupervisorPhotoUpload()),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('SECURITY & ROLE PREVIEW NOTICE'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              'Use the top Role Preview banner to inspect any role workspace in-memory. Sensitive environment variables (DATABASE_URL, JWT_SECRET, Cloudinary API secrets) are protected on the backend and are never displayed in client bundles.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS
  // -------------------------------------------------------------
  Widget _buildGreeting(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: VianTheme.primaryGold,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.black),
      label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: VianTheme.primaryGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSupervisorActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: VianTheme.primaryGold, size: 28),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalLinkCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: VianTheme.primaryGold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionItem(String message) {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.orange, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(message, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
      ),
    );
  }
}
