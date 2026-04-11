// lib/providers/plan_provider.dart
import 'package:flutter/foundation.dart';
import '../models/plan_model.dart';
import '../services/api_service.dart';

class PlanProvider extends ChangeNotifier {
  List<PlanModel> _plans = [];
  PlanModel? _selectedPlan;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  List<PlanModel> get plans => _plans;
  List<PlanModel> get activePlans => _plans.where((p) => p.isActive).toList();
  PlanModel? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;

  final ApiService _api = ApiService();

  Future<void> loadPlans() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.getPlans();
      _plans = (res['data']['plans'] as List)
          .map((p) => PlanModel.fromJson(p))
          .toList();
    } catch (e) {
      debugPrint('Load plans error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPlan(String planId) async {
    try {
      final res = await _api.getPlan(planId);
      _selectedPlan = PlanModel.fromJson(res['data']['plan']);
      notifyListeners();
    } catch (e) {
      debugPrint('Load plan error: $e');
    }
  }

  Future<Map<String, dynamic>?> completeTask(
    String planId, String taskId, {int? studyMinutes}
  ) async {
    try {
      final res = await _api.completeTask(planId, taskId, studyMinutes: studyMinutes);
      if (res['success'] == true) {
        // Update local plan
        final idx = _plans.indexWhere((p) => p.id == planId);
        if (idx != -1) {
          await loadPlan(planId);
          _plans[idx] = _selectedPlan!;
        }
        notifyListeners();
        return res['data'];
      }
    } catch (e) {
      debugPrint('Complete task error: $e');
    }
    return null;
  }

  Future<PlanModel?> createPlan(Map<String, dynamic> data) async {
    try {
      final res = await _api.createPlan(data);
      if (res['success'] == true) {
        final plan = PlanModel.fromJson(res['data']['plan']);
        _plans.insert(0, plan);
        notifyListeners();
        return plan;
      }
    } catch (e) {
      debugPrint('Create plan error: $e');
    }
    return null;
  }

  Future<bool> deletePlan(String planId) async {
    try {
      await _api.deletePlan(planId);
      _plans.removeWhere((p) => p.id == planId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadStats() async {
    try {
      final res = await _api.getStats();
      _stats = res['data'] ?? {};
      notifyListeners();
    } catch (e) {
      debugPrint('Load stats error: $e');
    }
  }

  void addAIPlan(PlanModel plan) {
    _plans.insert(0, plan);
    notifyListeners();
  }
}
