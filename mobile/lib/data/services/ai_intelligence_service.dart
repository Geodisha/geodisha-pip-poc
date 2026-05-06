import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Service for Module 2: AI Intelligence Hub
class AIIntelligenceService {
  final ApiService _apiService;

  AIIntelligenceService(this._apiService);

  /// Get AI recommendations
  Future<Map<String, dynamic>> getRecommendations({
    String? status,
    String? priority,
    String? category,
    int limit = 50,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.aiRecommendations,
        queryParameters: {
          if (status != null) 'status': status,
          if (priority != null) 'priority': priority,
          if (category != null) 'category': category,
          'limit': limit,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load AI recommendations: $e');
    }
  }

  /// Get media briefing
  Future<Map<String, dynamic>> getMediaBriefing({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.mediaBriefing,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load media briefing: $e');
    }
  }

  /// Get influencer map
  Future<Map<String, dynamic>> getInfluencerMap({
    int minScore = 0,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.influencerMap,
        queryParameters: {
          'min_score': minScore,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load influencer map: $e');
    }
  }

  /// Get visit priority list
  Future<Map<String, dynamic>> getVisitPriorityList({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.visitPriorityList,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load visit priority list: $e');
    }
  }
}
