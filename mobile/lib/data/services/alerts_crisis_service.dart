import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Service for Module 6: Alerts & Crisis Management
class AlertsCrisisService {
  final ApiService _apiService;

  AlertsCrisisService(this._apiService);

  /// Get active alerts
  Future<Map<String, dynamic>> getActiveAlerts({
    String? priority,
    String? alertType,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.alertsActive,
        queryParameters: {
          if (priority != null) 'priority': priority,
          if (alertType != null) 'alert_type': alertType,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load active alerts: $e');
    }
  }

  /// Get alerts statistics
  Future<Map<String, dynamic>> getAlertsStatistics({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.alertsStatistics,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load alerts statistics: $e');
    }
  }

  /// Get crisis dashboard
  Future<Map<String, dynamic>> getCrisisDashboard({
    String? severityLevel,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.crisisDashboard,
        queryParameters: {
          if (severityLevel != null) 'severity_level': severityLevel,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load crisis dashboard: $e');
    }
  }

  /// Get alert resolution metrics
  Future<Map<String, dynamic>> getAlertResolutionMetrics({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.alertResolutionMetrics,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load alert resolution metrics: $e');
    }
  }

  /// Get risk alerts (active alerts filtered by type 'risk')
  Future<Map<String, dynamic>> getRiskAlerts({
    String? priority,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.alertsActive,
        queryParameters: {
          'alert_type': 'risk',
          if (priority != null) 'priority': priority,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load risk alerts: $e');
    }
  }

  /// Get crisis warnings
  Future<Map<String, dynamic>> getCrisisWarnings({
    String? severityLevel,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.crisisDashboard,
        queryParameters: {
          if (severityLevel != null) 'severity_level': severityLevel,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load crisis warnings: $e');
    }
  }

  /// Get reminders (active alerts filtered by type 'reminder')
  Future<Map<String, dynamic>> getReminders({
    String? priority,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.alertsActive,
        queryParameters: {
          'alert_type': 'reminder',
          if (priority != null) 'priority': priority,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load reminders: $e');
    }
  }
}
