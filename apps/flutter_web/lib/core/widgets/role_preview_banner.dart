import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive top banner displayed ONLY to Developer accounts allowing in-memory role preview
class RolePreviewBanner extends StatelessWidget {
  final String? activePreviewRole;
  final ValueChanged<String?> onRoleSelected;

  const RolePreviewBanner({
    super.key,
    required this.activePreviewRole,
    required this.onRoleSelected,
  });

  static const List<String> previewRoles = [
    'Super Admin',
    'Managing Director',
    'Admin',
    'Project Manager',
    'Architect',
    'Site Engineer',
    'Accountant',
    'Client'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1B4B), // Deep indigo
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ROLE PREVIEW',
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Viewing UI as:',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: activePreviewRole,
                dropdownColor: const Color(0xFF1E1B4B),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.amber, size: 18),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                isDense: true,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Default (Developer)', style: GoogleFonts.inter(color: Colors.amber)),
                  ),
                  ...previewRoles.map((role) {
                    return DropdownMenuItem<String?>(
                      value: role,
                      child: Text(role),
                    );
                  }),
                ],
                onChanged: onRoleSelected,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Note: In-memory preview only. Real JWT token remains Developer.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
          ),
          if (activePreviewRole != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => onRoleSelected(null),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Reset to Developer',
                style: GoogleFonts.inter(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
