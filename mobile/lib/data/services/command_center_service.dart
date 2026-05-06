import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Service for Module 1: Command Center
class CommandCenterService {
  final ApiService _apiService;

  CommandCenterService(this._apiService);

  /// Get constituency overview
  Future<Map<String, dynamic>> getConstituencyOverview({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.constituencyOverview,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load constituency overview: $e');
    }
  }

  /// Get KPI trends
  Future<Map<String, dynamic>> getKpiTrends({
    int days = 30,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.kpiTrends,
        queryParameters: {
          'days': days,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load KPI trends: $e');
    }
  }

  /// Get executive summary
  Future<Map<String, dynamic>> getExecutiveSummary({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.executiveSummary,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load executive summary: $e');
    }
  }

  /// Get trends summary
  Future<Map<String, dynamic>> getTrendsSummary({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.trendsSummary,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load trends summary: $e');
    }
  }
}
