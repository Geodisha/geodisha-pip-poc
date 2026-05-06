import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Service for Module 4: Election War Room
class ElectionWarRoomService {
  final ApiService _apiService;

  ElectionWarRoomService(this._apiService);

  /// Get booth scores summary
  Future<Map<String, dynamic>> getBoothScores({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.boothScores,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load booth scores: $e');
    }
  }

  /// Get election readiness
  Future<Map<String, dynamic>> getElectionReadiness({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.electionReadiness,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load election readiness: $e');
    }
  }

  /// Get booth risk matrix
  Future<Map<String, dynamic>> getBoothRiskMatrix({
    String? riskCategory,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.boothRiskMatrix,
        queryParameters: {
          if (riskCategory != null) 'risk_category': riskCategory,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load booth risk matrix: $e');
    }
  }

  /// Get swing analysis
  Future<Map<String, dynamic>> getSwingAnalysis({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.swingAnalysis,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load swing analysis: $e');
    }
  }
}
