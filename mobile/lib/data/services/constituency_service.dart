import '../../core/services/api_service.dart';

/// Model for constituency data
class Constituency {
  final String id;
  final String name;

  Constituency({required this.id, required this.name});

  factory Constituency.fromJson(Map<String, dynamic> json) {
    return Constituency(
      id: json['constituency_id']?.toString() ?? '',
      name: json['constituency_name']?.toString() ?? '',
    );
  }
}

/// Service for fetching constituency/PC data from BigQuery
class ConstituencyService {
  final ApiService _apiService;

  ConstituencyService(this._apiService);

  /// Get list of all constituencies from BigQuery
  Future<List<Constituency>> getAllConstituencies({
    String userRole = 'admin',
  }) async {
    try {
      final response = await _apiService.get(
        '/constituencies',  // Fixed: removed /api/v1 prefix (already in baseUrl)
        queryParameters: {
          'user_role': userRole,
        },
      );
      
      final data = response.data['data'] as List?;
      if (data == null || data.isEmpty) {
        // Return fallback constituencies if API fails
        return _getFallbackConstituencies();
      }
      
      // Parse constituencies from BigQuery response
      return data
          .map((item) => Constituency.fromJson(item))
          .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error fetching constituencies: $e');
      // Return fallback constituencies if API fails
      return _getFallbackConstituencies();
    }
  }

  /// Fallback list if API fails
  List<Constituency> _getFallbackConstituencies() {
    return [
      Constituency(id: 'PC01', name: 'Bhubaneswar Central'),
      Constituency(id: 'PC02', name: 'Bhubaneswar North'),
      Constituency(id: 'PC03', name: 'Bhubaneswar South'),
      Constituency(id: 'PC04', name: 'Puri'),
      Constituency(id: 'PC05', name: 'Cuttack'),
      Constituency(id: 'PC06', name: 'Berhampur'),
      Constituency(id: 'PC07', name: 'Rourkela'),
      Constituency(id: 'PC08', name: 'Sambalpur'),
      Constituency(id: 'PC09', name: 'Balasore'),
      Constituency(id: 'PC10', name: 'Bhadrak'),
    ];
  }
}
