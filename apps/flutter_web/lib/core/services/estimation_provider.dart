import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estimation.dart';
import 'api_service.dart';

class EstimationState {
  final List<Estimate> estimates;
  final List<MaterialRate> marketPrices;
  final EstimationEngineSettings? settings;
  final Map<String, dynamic> dashboardStats;
  final Map<String, dynamic>? selectedBudgetVsActual;

  EstimationState({
    required this.estimates,
    required this.marketPrices,
    this.settings,
    required this.dashboardStats,
    this.selectedBudgetVsActual,
  });

  EstimationState copyWith({
    List<Estimate>? estimates,
    List<MaterialRate>? marketPrices,
    EstimationEngineSettings? settings,
    Map<String, dynamic>? dashboardStats,
    Map<String, dynamic>? selectedBudgetVsActual,
  }) {
    return EstimationState(
      estimates: estimates ?? this.estimates,
      marketPrices: marketPrices ?? this.marketPrices,
      settings: settings ?? this.settings,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      selectedBudgetVsActual: selectedBudgetVsActual ?? this.selectedBudgetVsActual,
    );
  }
}

class EstimationNotifier extends StateNotifier<EstimationState> {
  EstimationNotifier()
      : super(EstimationState(
          estimates: [],
          marketPrices: [],
          dashboardStats: {},
        ));

  Future<void> loadAllData() async {
    try {
      final estimatesRes = await ApiService.getEstimates();
      final statsRes = await ApiService.getEstimationDashboard();
      final settingsRes = await ApiService.getEstimationSettings();
      final pricesRes = await ApiService.getMarketPrices();

      final List<Estimate> loadedEstimates = [];
      for (final e in estimatesRes) {
        if (e is Map<String, dynamic>) {
          loadedEstimates.add(Estimate.fromJson(e));
        }
      }

      final List<MaterialRate> loadedPrices = [];
      for (final p in pricesRes) {
        if (p is Map<String, dynamic>) {
          loadedPrices.add(MaterialRate.fromJson(p));
        }
      }

      final loadedSettings = EstimationEngineSettings.fromJson(settingsRes);

      state = state.copyWith(
        estimates: loadedEstimates,
        marketPrices: loadedPrices,
        settings: loadedSettings,
        dashboardStats: statsRes,
      );
    } catch (e) {
      // Fallback/log
    }
  }

  Future<Map<String, dynamic>> saveEstimate(Map<String, dynamic> data) async {
    final res = await ApiService.saveEstimate(data);
    await loadAllData();
    return res;
  }

  Future<Map<String, dynamic>> approveEstimate(int id) async {
    final res = await ApiService.approveEstimate(id);
    await loadAllData();
    return res;
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await ApiService.updateEstimationSettings(data);
    await loadAllData();
  }

  Future<void> addMarketPrice(Map<String, dynamic> data) async {
    await ApiService.createMarketPrice(data);
    await loadAllData();
  }

  Future<void> updateMarketPrice(Map<String, dynamic> data) async {
    await ApiService.updateMarketPrice(data);
    await loadAllData();
  }

  Future<void> deleteMarketPrice(int id) async {
    await ApiService.deleteMarketPrice(id);
    await loadAllData();
  }

  Future<void> fetchBudgetVsActual(int id) async {
    try {
      final res = await ApiService.getBudgetVsActual(id);
      state = state.copyWith(selectedBudgetVsActual: res);
    } catch (e) {
      // handle error
    }
  }

  void clearBudgetVsActual() {
    state = state.copyWith(selectedBudgetVsActual: null);
  }
}

final estimationProvider = StateNotifierProvider<EstimationNotifier, EstimationState>((ref) {
  return EstimationNotifier();
});
