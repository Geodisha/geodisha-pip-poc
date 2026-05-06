class ApiEndpoints {
  // Base URL
  // 10.0.2.2:8000  → Android emulator loopback
  // localhost:8000  → Chrome web / macOS desktop
  // 127.0.0.1:8000 → iOS simulator / macOS direct
  // Change to your LAN IP (e.g. 192.168.x.x) for physical devices
  static const String baseUrl = 'http://localhost:8000';
  
  // API version
  static const String apiVersion = '/api/v1';
  
  // Full base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  // ============================================================================
  // MODULE 1: COMMAND CENTER
  // ============================================================================
  static String get constituencyOverview => '$apiBaseUrl/command-center/overview';
  static String get kpiTrends => '$apiBaseUrl/command-center/kpi-trends';
  static String get executiveSummary => '$apiBaseUrl/command-center/executive-summary';
  static String get trendsSummary => '$apiBaseUrl/command-center/trends-summary';
  
  // ============================================================================
  // MODULE 2: AI INTELLIGENCE HUB
  // ============================================================================
  static String get aiRecommendations => '$apiBaseUrl/ai-intelligence/recommendations';
  static String get mediaBriefing => '$apiBaseUrl/ai-intelligence/media-briefing';
  static String get influencerMap => '$apiBaseUrl/ai-intelligence/influencer-map';
  static String get visitPriorityList => '$apiBaseUrl/ai-intelligence/visit-priority-list';
  
  // ============================================================================
  // MODULE 3: GROUND REALITY
  // ============================================================================
  static String get visitsEnhanced => '$apiBaseUrl/ground-reality/visits';
  static String get heatmapCurrent => '$apiBaseUrl/ground-reality/heatmap';
  static String get wardCoverage => '$apiBaseUrl/ground-reality/ward-coverage';
  static String get visitTrends => '$apiBaseUrl/ground-reality/visit-trends';
  
  // ============================================================================
  // MODULE 4: ELECTION WAR ROOM
  // ============================================================================
  static String get boothScores => '$apiBaseUrl/election-war-room/booth-scores';
  static String get electionReadiness => '$apiBaseUrl/election-war-room/readiness';
  static String get boothRiskMatrix => '$apiBaseUrl/election-war-room/risk-matrix';
  static String get swingAnalysis => '$apiBaseUrl/election-war-room/swing-analysis';
  
  // ============================================================================
  // MODULE 5: PROMISES
  // ============================================================================
  static String get promisesDashboard => '$apiBaseUrl/promises/dashboard';
  static String get promisesOverdue => '$apiBaseUrl/promises/overdue';
  static String get promisesByCategory => '$apiBaseUrl/promises/by-category';
  static String get promiseCompletionRate => '$apiBaseUrl/promises/completion-rate';
  
  // ============================================================================
  // MODULE 6: ALERTS & CRISIS
  // ============================================================================
  static String get alertsActive => '$apiBaseUrl/alerts/active';
  static String get alertsStatistics => '$apiBaseUrl/alerts/statistics';
  static String get crisisDashboard => '$apiBaseUrl/alerts/crisis-dashboard';
  static String get alertResolutionMetrics => '$apiBaseUrl/alerts/resolution-metrics';
  
  // ============================================================================
  // LEGACY ENDPOINTS (Original)
  // ============================================================================
  // Visits endpoints
  static String get visits => '$apiBaseUrl/visits';
  static String visitStatistics(String? constituencyId) {
    final params = constituencyId != null ? '?constituency_id=$constituencyId' : '';
    return '$apiBaseUrl/visits/statistics$params';
  }
  static String get visitTimeline => '$apiBaseUrl/visits/timeline';
  static String get visitSearch => '$apiBaseUrl/visits/search';
  
  // Constituencies endpoints
  static String get constituencies => '$apiBaseUrl/constituencies';
  static String constituencyData(String constituencyId) => 
      '$apiBaseUrl/constituencies/$constituencyId';
  static String constituencyVisits(String constituencyId) => 
      '$apiBaseUrl/constituencies/$constituencyId/visits';
  
  // Auth endpoints (not yet connected to BigQuery)
  static String get login => '$apiBaseUrl/auth/login';
  static String get register => '$apiBaseUrl/auth/register';
  static String get refreshToken => '$apiBaseUrl/auth/refresh';
  
  // Health check
  static String get health => '$baseUrl/health';
}
