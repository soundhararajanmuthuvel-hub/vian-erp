import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Riverpod Provider for Role Preview (Developer only, strictly in-memory UI preview)
final rolePreviewProvider = StateProvider<String?>((ref) => null);

// Riverpod Provider for Feature Visibility
final featureVisibilityProvider = StateNotifierProvider<FeatureVisibilityNotifier, FeatureVisibilityState>((ref) {
  return FeatureVisibilityNotifier();
});

class FeatureVisibilityState {
  final Map<String, Map<String, bool>> matrix;
  final List<String> availableFeatures;
  final bool isLoading;
  final String? error;

  const FeatureVisibilityState({
    required this.matrix,
    required this.availableFeatures,
    this.isLoading = false,
    this.error,
  });

  FeatureVisibilityState copyWith({
    Map<String, Map<String, bool>>? matrix,
    List<String>? availableFeatures,
    bool? isLoading,
    String? error,
  }) {
    return FeatureVisibilityState(
      matrix: matrix ?? this.matrix,
      availableFeatures: availableFeatures ?? this.availableFeatures,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFeatureEnabled(String role, String featureKey) {
    final normalizedRole = _normalizeRole(role);
    final roleMap = matrix[normalizedRole];
    if (roleMap == null) return true; // Default to visible if role not restricted
    return roleMap[featureKey.toLowerCase()] ?? true;
  }

  static String _normalizeRole(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'super admin' || r == 'managing director') return 'Super Admin';
    if (r.contains('admin') || r.contains('office manager')) return 'Admin';
    if (r.contains('project manager') || r == 'pm') return 'Project Manager';
    if (r.contains('architect') || r.contains('design engineer')) return 'Architect';
    if (r.contains('site') || r.contains('supervisor') || r.contains('labour manager')) return 'Site Engineer';
    if (r.contains('accountant') || r.contains('finance')) return 'Accountant';
    if (r.contains('client')) return 'Client';
    if (r.contains('developer')) return 'Developer';
    return role;
  }
}

class FeatureVisibilityNotifier extends StateNotifier<FeatureVisibilityState> {
  FeatureVisibilityNotifier() : super(FeatureVisibilityState(
    matrix: _defaultMatrix,
    availableFeatures: _defaultFeatures,
  )) {
    loadFeatures();
  }

  static const List<String> _defaultFeatures = [
    'dashboard', 'clients', 'projects', 'photos', 'documents',
    'tasks', 'billing', 'reports', 'users', 'settings',
    'advanced', 'inventory', 'crm', 'ai'
  ];

  static const Map<String, Map<String, bool>> _defaultMatrix = {
    'Super Admin': {
      'dashboard': true, 'clients': true, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': true, 'reports': true, 'users': true, 'settings': true,
      'advanced': true, 'inventory': true, 'crm': true, 'ai': true
    },
    'Managing Director': {
      'dashboard': true, 'clients': true, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': true, 'reports': true, 'users': true, 'settings': true,
      'advanced': false, 'inventory': true, 'crm': true, 'ai': true
    },
    'Admin': {
      'dashboard': true, 'clients': true, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': true, 'reports': true, 'users': false, 'settings': false,
      'advanced': false, 'inventory': true, 'crm': true, 'ai': false
    },
    'Project Manager': {
      'dashboard': true, 'clients': true, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': true, 'reports': true, 'users': false, 'settings': false,
      'advanced': false, 'inventory': false, 'crm': false, 'ai': false
    },
    'Architect': {
      'dashboard': true, 'clients': true, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': false, 'reports': false, 'users': false, 'settings': false,
      'advanced': false, 'inventory': false, 'crm': false, 'ai': false
    },
    'Site Engineer': {
      'dashboard': true, 'clients': false, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': false, 'reports': false, 'users': false, 'settings': false,
      'advanced': false, 'inventory': false, 'crm': false, 'ai': false
    },
    'Accountant': {
      'dashboard': true, 'clients': false, 'projects': false, 'photos': false, 'documents': false,
      'tasks': false, 'billing': true, 'reports': true, 'users': false, 'settings': false,
      'advanced': false, 'inventory': false, 'crm': false, 'ai': false
    },
    'Client': {
      'dashboard': true, 'clients': false, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': true, 'reports': false, 'users': false, 'settings': false,
      'advanced': false, 'inventory': false, 'crm': false, 'ai': false
    },
    'Developer': {
      'dashboard': true, 'clients': true, 'projects': true, 'photos': true, 'documents': true,
      'tasks': true, 'billing': true, 'reports': true, 'users': true, 'settings': true,
      'advanced': true, 'inventory': true, 'crm': true, 'ai': true
    },
  };

  Future<void> loadFeatures() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = ApiService.token;
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/features'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['features'] != null) {
          final rawMatrix = Map<String, dynamic>.from(data['features']);
          final parsedMatrix = <String, Map<String, bool>>{};
          
          rawMatrix.forEach((role, featureMap) {
            if (featureMap is Map) {
              parsedMatrix[role] = Map<String, bool>.from(
                featureMap.map((k, v) => MapEntry(k.toString(), v == true)),
              );
            }
          });

          final available = data['availableFeatures'] != null
              ? List<String>.from(data['availableFeatures'])
              : _defaultFeatures;

          state = state.copyWith(
            matrix: parsedMatrix,
            availableFeatures: available,
            isLoading: false,
          );
          return;
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Failed to load feature controls: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateFeature({
    required String role,
    required String featureKey,
    required bool enabled,
  }) async {
    try {
      final token = ApiService.token;
      if (token == null || token.isEmpty) return false;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/features/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'role': role,
          'featureKey': featureKey,
          'enabled': enabled,
        }),
      );

      if (response.statusCode == 200) {
        final updatedMatrix = Map<String, Map<String, bool>>.from(state.matrix);
        final roleMap = Map<String, bool>.from(updatedMatrix[role] ?? {});
        roleMap[featureKey] = enabled;
        updatedMatrix[role] = roleMap;

        state = state.copyWith(matrix: updatedMatrix);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to update feature control: $e');
      return false;
    }
  }

  Future<bool> resetToDefaults() async {
    try {
      final token = ApiService.token;
      if (token == null || token.isEmpty) return false;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/features/reset'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(matrix: _defaultMatrix);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to reset feature controls: $e');
      return false;
    }
  }
}
