import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/repositories/constituency_repository.dart';
import '../../data/models/visit_model.dart';
import '../../data/models/constituency_model.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Repository Providers
final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VisitRepository(apiService);
});

final constituencyRepositoryProvider = Provider<ConstituencyRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConstituencyRepository(apiService);
});

// Visits State Provider
final visitsProvider = FutureProvider.autoDispose<List<VisitModel>>((ref) async {
  final repository = ref.watch(visitRepositoryProvider);
  return await repository.getVisits(limit: 50);
});

// Visit Statistics Provider
final visitStatisticsProvider = FutureProvider.autoDispose<VisitStatistics>((ref) async {
  final repository = ref.watch(visitRepositoryProvider);
  return await repository.getVisitStatistics();
});

// Constituencies Provider
final constituenciesProvider = FutureProvider.autoDispose<List<ConstituencyModel>>((ref) async {
  final repository = ref.watch(constituencyRepositoryProvider);
  return await repository.getConstituencies();
});

// Selected Constituency Provider
final selectedConstituencyIdProvider = StateProvider<String?>((ref) => null);

// Constituency Data Provider (based on selected constituency)
final selectedConstituencyDataProvider = FutureProvider.autoDispose<ConstituencyModel?>((ref) async {
  final constituencyId = ref.watch(selectedConstituencyIdProvider);
  if (constituencyId == null) return null;
  
  final repository = ref.watch(constituencyRepositoryProvider);
  return await repository.getConstituencyById(constituencyId);
});

// Constituency Visits Provider (based on selected constituency)
final constituencyVisitsProvider = FutureProvider.autoDispose<List<VisitModel>>((ref) async {
  final constituencyId = ref.watch(selectedConstituencyIdProvider);
  if (constituencyId == null) return [];
  
  final repository = ref.watch(constituencyRepositoryProvider);
  return await repository.getConstituencyVisits(constituencyId);
});
