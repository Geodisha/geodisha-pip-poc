import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/visit_model.dart';

class VisitRepository {
  final ApiService _apiService;

  VisitRepository(this._apiService);

  /// Get all visits with optional filters
  Future<List<VisitModel>> getVisits({
    String? constituencyId,
    String? userId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      
      if (constituencyId != null) {
        queryParams['constituency_id'] = constituencyId;
      }
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _apiService.get(
        '/visits',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['visits'] ?? [];
        return data.map((json) => VisitModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load visits: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error fetching visits: ${e.message}');
      throw Exception('Failed to fetch visits: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Get visit statistics
  Future<VisitStatistics> getVisitStatistics({
    String? constituencyId,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (constituencyId != null) {
        queryParams['constituency_id'] = constituencyId;
      }
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _apiService.get(
        '/visits/statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return VisitStatistics.fromJson(response.data);
      } else {
        throw Exception('Failed to load statistics: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error fetching statistics: ${e.message}');
      throw Exception('Failed to fetch statistics: ${e.message}');
    }
  }

  /// Get visit timeline
  Future<List<Map<String, dynamic>>> getVisitTimeline({
    String? constituencyId,
    String? userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (constituencyId != null) {
        queryParams['constituency_id'] = constituencyId;
      }
      if (userId != null) {
        queryParams['user_id'] = userId;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate;
      }

      final response = await _apiService.get(
        '/visits/timeline',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['timeline'] ?? []);
      } else {
        throw Exception('Failed to load timeline: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error fetching timeline: ${e.message}');
      throw Exception('Failed to fetch timeline: ${e.message}');
    }
  }

  /// Search visits
  Future<List<VisitModel>> searchVisits({
    String? query,
    String? visitType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (visitType != null) {
        queryParams['visit_type'] = visitType;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate;
      }

      final response = await _apiService.get(
        '/visits/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['visits'] ?? [];
        return data.map((json) => VisitModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search visits: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error searching visits: ${e.message}');
      throw Exception('Failed to search visits: ${e.message}');
    }
  }
}
