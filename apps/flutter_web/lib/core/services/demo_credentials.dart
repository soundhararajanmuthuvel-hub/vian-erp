import 'package:flutter/foundation.dart';

enum DemoRole {
  superAdmin,
  managingDirector,
  admin,
  projectManager,
  architect,
  siteEngineer,
  accountant,
  client,
}

class DemoAccount {
  final DemoRole role;
  final String displayName;
  final String description;
  final String iconEmoji;

  const DemoAccount({
    required this.role,
    required this.displayName,
    required this.description,
    required this.iconEmoji,
  });
}

class DemoAccountService {
  static const bool showDevLogin = bool.fromEnvironment('SHOW_DEV_LOGIN', defaultValue: true);
  static const bool enableDemoLogin = bool.fromEnvironment('ENABLE_DEMO_LOGIN', defaultValue: true);
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  static bool get shouldShow {
    if (environment.toLowerCase() == 'production' || environment.toLowerCase() == 'prod') {
      return false;
    }
    return kDebugMode || showDevLogin || enableDemoLogin;
  }

  static const List<DemoAccount> accounts = [
    DemoAccount(
      role: DemoRole.superAdmin,
      displayName: 'Super Admin',
      description: 'System Administration',
      iconEmoji: '👑',
    ),
    DemoAccount(
      role: DemoRole.managingDirector,
      displayName: 'Managing Director',
      description: 'Executive Control',
      iconEmoji: '🏛',
    ),
    DemoAccount(
      role: DemoRole.admin,
      displayName: 'Admin',
      description: 'Office & Admin Ops',
      iconEmoji: '🛡',
    ),
    DemoAccount(
      role: DemoRole.projectManager,
      displayName: 'Project Manager',
      description: 'Projects & Planning',
      iconEmoji: '📋',
    ),
    DemoAccount(
      role: DemoRole.architect,
      displayName: 'Architect',
      description: 'Design & Engineering',
      iconEmoji: '📐',
    ),
    DemoAccount(
      role: DemoRole.siteEngineer,
      displayName: 'Site Engineer',
      description: 'On-Site Operations',
      iconEmoji: '👷',
    ),
    DemoAccount(
      role: DemoRole.accountant,
      displayName: 'Accountant',
      description: 'Financial Management',
      iconEmoji: '💰',
    ),
    DemoAccount(
      role: DemoRole.client,
      displayName: 'Client',
      description: 'Project Portal',
      iconEmoji: '👤',
    ),
  ];

  // Private credentials mapping
  static const Map<DemoRole, Map<String, String>> _credentials = {
    DemoRole.superAdmin: {
      'email': 'superadmin@demo.vianerp.test',
      'username': 'demo_superadmin',
      'password': 'Demo@12345',
    },
    DemoRole.managingDirector: {
      'email': 'md@demo.vianerp.test',
      'username': 'demo_md',
      'password': 'Demo@12345',
    },
    DemoRole.admin: {
      'email': 'admin@demo.vianerp.test',
      'username': 'demo_admin',
      'password': 'Demo@12345',
    },
    DemoRole.projectManager: {
      'email': 'pm@demo.vianerp.test',
      'username': 'demo_pm',
      'password': 'Demo@12345',
    },
    DemoRole.architect: {
      'email': 'architect@demo.vianerp.test',
      'username': 'demo_architect',
      'password': 'Demo@12345',
    },
    DemoRole.siteEngineer: {
      'email': 'siteengineer@demo.vianerp.test',
      'username': 'demo_siteengineer',
      'password': 'Demo@12345',
    },
    DemoRole.accountant: {
      'email': 'accountant@demo.vianerp.test',
      'username': 'demo_accountant',
      'password': 'Demo@12345',
    },
    DemoRole.client: {
      'email': 'client@demo.vianerp.test',
      'username': 'demo_client',
      'password': 'Demo@12345',
    },
  };

  // Internal package access only
  static Map<String, String>? getCredentialsInternal(DemoRole role) {
    if (!shouldShow) return null;
    return _credentials[role];
  }
}
