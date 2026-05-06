import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

/// Service for Module 5: Promises Tracker
class PromisesService {
  final ApiService _apiService;

  PromisesService(this._apiService);

  /// Get promises dashboard
  Future<Map<String, dynamic>> getPromisesDashboard({
    String? status,
    String? category,
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.promisesDashboard,
        queryParameters: {
          if (status != null) 'status': status,
          if (category != null) 'category': category,
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load promises dashboard: $e');
    }
  }

  /// Get overdue promises
  Future<Map<String, dynamic>> getPromisesOverdue({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.promisesOverdue,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load overdue promises: $e');
    }
  }

  /// Get promises by category
  Future<Map<String, dynamic>> getPromisesByCategory({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.promisesByCategory,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load promises by category: $e');
    }
  }

  /// Get promise completion rate
  Future<Map<String, dynamic>> getPromiseCompletionRate({
    String userRole = 'admin',
    String? constituencyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.promiseCompletionRate,
        queryParameters: {
          'user_role': userRole,
          if (constituencyId != null) 'user_constituency_id': constituencyId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load promise completion rate: $e');
    }
  }
}
