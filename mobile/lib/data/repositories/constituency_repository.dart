import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../models/constituency_model.dart';
import '../models/visit_model.dart';

class ConstituencyRepository {
  final ApiService _apiService;

  ConstituencyRepository(this._apiService);

  /// Get all constituencies
  Future<List<ConstituencyModel>> getConstituencies({
    String? state,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (state != null) {
        queryParams['state'] = state;
      }
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        '/constituencies',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['constituencies'] ?? [];
        return data.map((json) => ConstituencyModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load constituencies: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error fetching constituencies: ${e.message}');
      throw Exception('Failed to fetch constituencies: ${e.message}');
    }
  }

  /// Get constituency data by ID
  Future<ConstituencyModel> getConstituencyById(String constituencyId) async {
    try {
      final response = await _apiService.get(
        '/constituencies/$constituencyId',
      );

      if (response.statusCode == 200) {
        return ConstituencyModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load constituency: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error fetching constituency: ${e.message}');
      throw Exception('Failed to fetch constituency: ${e.message}');
    }
  }

  /// Get visits for a constituency
  Future<List<VisitModel>> getConstituencyVisits(
    String constituencyId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/constituencies/$constituencyId/visits',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['visits'] ?? [];
        return data.map((json) => VisitModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load constituency visits: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error fetching constituency visits: ${e.message}');
      throw Exception('Failed to fetch constituency visits: ${e.message}');
    }
  }
}
