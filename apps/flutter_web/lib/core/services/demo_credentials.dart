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
  static const bool showDevLogin = bool.fromEnvironment('SHOW_DEV_LOGIN', defaultValue: false);
  static const bool enableDemoLogin = bool.fromEnvironment('ENABLE_DEMO_LOGIN', defaultValue: false);
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  static bool get shouldShow {
    if (kReleaseMode) {
      if (!enableDemoLogin && !showDevLogin) return false;
    }
    if (environment.toLowerCase() == 'production' || environment.toLowerCase() == 'prod') {
      if (!enableDemoLogin && !showDevLogin) return false;
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

  // Private credentials mapping to real seeded system accounts
  static const Map<DemoRole, Map<String, String>> _credentials = {
    DemoRole.superAdmin: {
      'username': 'superadmin',
      'email': 'superadmin@vianarchitects.com',
      'password': 'superadmin123',
    },
    DemoRole.managingDirector: {
      'username': 'anand',
      'email': 'anand@vianarchitects.com',
      'password': 'anand123',
    },
    DemoRole.admin: {
      'username': 'admin',
      'email': 'admin@vianarchitects.com',
      'password': 'admin123',
    },
    DemoRole.projectManager: {
      'username': 'pm',
      'email': 'pm@vianarchitects.com',
      'password': 'pm123',
    },
    DemoRole.architect: {
      'username': 'architect',
      'email': 'architect@vianarchitects.com',
      'password': 'architect123',
    },
    DemoRole.siteEngineer: {
      'username': 'siteengineer',
      'email': 'siteengineer@vianarchitects.com',
      'password': 'siteengineer123',
    },
    DemoRole.accountant: {
      'username': 'accountant',
      'email': 'accountant@vianarchitects.com',
      'password': 'accountant123',
    },
    DemoRole.client: {
      'username': 'client',
      'email': 'client@vianarchitects.com',
      'password': 'client123',
    },
  };

  // Internal package access only
  static Map<String, String>? getCredentialsInternal(DemoRole role) {
    if (!shouldShow) return null;
    return _credentials[role];
  }
}
