/// Covers all new seed-data endpoints:
/// voter_segments, opposition_intelligence, ward_intelligence,
/// monitoring_metrics, booth_scores, executive_summary, constituency data
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';

class IntelligenceService {
  final ApiService _api;
  IntelligenceService(this._api);

  /// Unwrap Dio Response → Map
  /// On Flutter Web, Dio returns Map<dynamic,dynamic> not Map<String,dynamic>,
  /// and some endpoints return a bare List — handle all cases defensively.
  Future<Map<String, dynamic>> _get(String path) async {
    final Response res = await _api.get(path);
    final body = res.data;
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    // bare list — wrap so callers can always do snap.data?['data'] as List
    return {'success': true, 'data': body};
  }

  // NOTE: ApiService baseUrl already ends with /api/v1 — no prefix needed here.

  Future<Map<String, dynamic>> getConstituencyOverview({String? cid}) =>
      _get('/constituency/overview${cid != null ? '?constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getConstituencyKpis({String? cid, int limit = 30}) =>
      _get('/constituency/kpis?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getConstituencyTrends({String? cid, String? metric, int limit = 60}) =>
      _get('/constituency/trends?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}${metric != null ? '&metric=$metric' : ''}');

  Future<Map<String, dynamic>> getExecutiveSummary({String? cid, int limit = 12}) =>
      _get('/executive-summary?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getWardIntelligence({String? cid, int limit = 30}) =>
      _get('/ground-reality/ward-intelligence?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getVisitStats({String? cid, String period = 'monthly'}) =>
      _get('/ground-reality/visit-stats?period_type=$period${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getVisitPlanning({String? cid, int limit = 20}) =>
      _get('/ground-reality/visit-planning?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getVoterSegments({String? cid, int limit = 30}) =>
      _get('/voter-segments?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getOppositionIntelligence({String? cid, int limit = 20}) =>
      _get('/opposition-intelligence?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getPromiseUpdates({String? cid, int limit = 20}) =>
      _get('/promises/updates?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getPromiseBeneficiaries({String? cid, int limit = 20}) =>
      _get('/promises/beneficiaries?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getAlertEscalations({String? cid, int limit = 20}) =>
      _get('/alerts/escalations?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getMonitoringLatest({String cid = 'PC01'}) =>
      _get('/monitoring/latest?constituency_id=$cid');

  Future<Map<String, dynamic>> getMonitoringMetrics({String? cid, int limit = 30}) =>
      _get('/monitoring/metrics?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getBoothScores({String? cid, int limit = 30}) =>
      _get('/booth-scores?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');

  Future<Map<String, dynamic>> getBoothScoreTrends({String? cid, int limit = 30}) =>
      _get('/booth-scores/trends?limit=$limit${cid != null ? '&constituency_id=$cid' : ''}');
}
