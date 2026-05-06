import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Service for Module 3: Ground Reality
class GroundRealityService {
  final ApiService _apiService;

  GroundRealityService(this._apiService);

  /// Get enhanced visits
  Future<Map<String, dynamic>> getVisitsEnhanced({
    String? startDate,
    String? endDate,
    String? visitType,
    int limit = 100,
    int offset = 0,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.visitsEnhanced,
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (visitType != null) 'visit_type': visitType,
          'limit': limit,
          'offset': offset,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load enhanced visits: $e');
    }
  }

  /// Get current heatmap
  Future<Map<String, dynamic>> getHeatmap({
    String? riskLevel,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.heatmapCurrent,
        queryParameters: {
          if (riskLevel != null) 'risk_level': riskLevel,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load heatmap: $e');
    }
  }

  /// Get ward coverage
  Future<Map<String, dynamic>> getWardCoverage({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.wardCoverage,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load ward coverage: $e');
    }
  }

  /// Get visit trends
  Future<Map<String, dynamic>> getVisitTrends({
    int days = 30,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.visitTrends,
        queryParameters: {
          'days': days,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load visit trends: $e');
    }
  }
}
