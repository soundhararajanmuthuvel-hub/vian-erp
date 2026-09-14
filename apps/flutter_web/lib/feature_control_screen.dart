import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/feature_visibility_service.dart';
import 'core/theme/theme.dart';

/// Developer & Super Admin Feature Control Management Screen
class FeatureControlScreen extends ConsumerStatefulWidget {
  const FeatureControlScreen({super.key});

  @override
  ConsumerState<FeatureControlScreen> createState() => _FeatureControlScreenState();
}

class _FeatureControlScreenState extends ConsumerState<FeatureControlScreen> {
  String _selectedRole = 'Site Engineer';
  bool _isSaving = false;
  String? _statusMessage;

  final List<String> _roles = [
    'Super Admin',
    'Managing Director',
    'Admin',
    'Project Manager',
    'Architect',
    'Site Engineer',
    'Accountant',
    'Client',
  ];

  final Map<String, String> _featureLabels = {
    'dashboard': 'Dashboard & Workspaces',
    'clients': 'Clients Management',
    'projects': 'Projects & Timeline',
    'photos': 'Site Photos Gallery & Upload',
    'documents': 'Drawings & Documents',
    'tasks': 'Tasks & Stage Checklists',
    'billing': 'Billing, Invoices & Quotations',
    'reports': 'Reports & Daily Logs',
    'users': 'Staff & User Management',
    'settings': 'System Settings & Config',
    'advanced': 'Advanced System Controls',
    'inventory': 'Inventory & Materials',
    'crm': 'CRM & Inquiries',
    'ai': 'AI Features & Analytics',
  };

  @override
  Widget build(BuildContext context) {
    final featureState = ref.watch(featureVisibilityProvider);
    final roleMatrix = featureState.matrix[_selectedRole] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.tune, color: VianTheme.primaryGold, size: 20),
            const SizedBox(width: 10),
            Text(
              'FEATURE VISIBILITY CONTROL',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restart_alt, color: Colors.orange, size: 18),
            label: Text('Reset Defaults', style: GoogleFonts.inter(color: Colors.orange, fontSize: 12)),
            onPressed: _isSaving ? null : _confirmReset,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            if (_statusMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Text(
                  _statusMessage!,
                  style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: VianTheme.primaryGold, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progressive Disclosure & Feature Toggling',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toggling a feature OFF hides it from navigation and dashboard quick actions without deleting database records or removing backend APIs.',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role Selector
            Row(
              children: [
                Text(
                  'Select Role to Configure:',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VianTheme.primaryGold.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      dropdownColor: const Color(0xFF27272A),
                      icon: const Icon(Icons.arrow_drop_down, color: VianTheme.primaryGold),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Feature Switch Grid
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: featureState.availableFeatures.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final key = featureState.availableFeatures[index];
                  final isEnabled = roleMatrix[key] ?? true;
                  final label = _featureLabels[key] ?? key.toUpperCase();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(
                      label,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Feature key: $key',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                    ),
                    trailing: Switch(
                      value: isEnabled,
                      activeColor: VianTheme.primaryGold,
                      onChanged: _isSaving
                          ? null
                          : (val) async {
                              setState(() => _isSaving = true);
                              final ok = await ref.read(featureVisibilityProvider.notifier).updateFeature(
                                role: _selectedRole,
                                featureKey: key,
                                enabled: val,
                              );
                              setState(() {
                                _isSaving = false;
                                _statusMessage = ok
                                    ? "'$label' set to ${val ? 'ENABLED' : 'DISABLED'} for $_selectedRole."
                                    : "Failed to update feature setting.";
                              });
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        title: const Text('Reset Feature Controls?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will reset all feature visibility rules across all roles to their standard defaults.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSaving = true);
              final ok = await ref.read(featureVisibilityProvider.notifier).resetToDefaults();
              setState(() {
                _isSaving = false;
                _statusMessage = ok ? "All feature controls reset to defaults." : "Failed to reset features.";
              });
            },
            child: const Text('Reset', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
