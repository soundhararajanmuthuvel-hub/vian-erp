import 'package:flutter/foundation.dart';

enum DemoRole {
  superAdmin,
  admin,
  seniorEngineer,
  engineer,
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
  static const bool enableDemoLogin = bool.fromEnvironment('ENABLE_DEMO_LOGIN', defaultValue: false);

  static bool get shouldShow =>
      !kReleaseMode &&
      (kDebugMode || enableDemoLogin);

  static const List<DemoAccount> accounts = [
    DemoAccount(
      role: DemoRole.superAdmin,
      displayName: 'Super Admin',
      description: 'System Administration',
      iconEmoji: '👑',
    ),
    DemoAccount(
      role: DemoRole.admin,
      displayName: 'Admin',
      description: 'Operations Management',
      iconEmoji: '🛡',
    ),
    DemoAccount(
      role: DemoRole.seniorEngineer,
      displayName: 'Senior Engineer',
      description: 'Project Management',
      iconEmoji: '🏗',
    ),
    DemoAccount(
      role: DemoRole.engineer,
      displayName: 'Engineer',
      description: 'Daily Site Operations',
      iconEmoji: '👷',
    ),
  ];

  // Private credentials mapping
  static const Map<DemoRole, Map<String, String>> _credentials = {
    DemoRole.superAdmin: {
      'email': 'superadmin@vianerp.com',
      'password': 'Super@123',
    },
    DemoRole.admin: {
      'email': 'admin@vianerp.com',
      'password': 'Admin@123',
    },
    DemoRole.seniorEngineer: {
      'email': 'senior@vianerp.com',
      'password': 'Senior@123',
    },
    DemoRole.engineer: {
      'email': 'engineer@vianerp.com',
      'password': 'Engineer@123',
    },
  };

  // Internal package access only
  static Map<String, String>? getCredentialsInternal(DemoRole role) {
    if (!shouldShow) return null;
    return _credentials[role];
  }
}
