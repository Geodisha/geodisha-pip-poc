class AppConstants {
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.geodisha.com',
  );
  
  static const String apiVersion = 'v1';
  static const int connectionTimeout = 30000; // milliseconds
  static const int receiveTimeout = 30000;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String constituenciesCollection = 'constituencies';
  static const String grievancesCollection = 'grievances';
  static const String visitsCollection = 'visits';
  static const String promisesCollection = 'promises';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleMLA = 'mla';
  static const String roleMP = 'mp';
  static const String roleMinister = 'minister';
  static const String roleStaff = 'staff';
  static const String roleCitizen = 'citizen';
  
  // Local Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyConstituencyId = 'constituency_id';
  
  // App Settings
  static const String appName = 'GeoDisha';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat = 'hh:mm a';
  
  // Map Configuration
  static const double defaultZoom = 12.0;
  static const double defaultLatitude = 20.5937;
  static const double defaultLongitude = 78.9629; // India center
  
  // Notification Channels
  static const String channelIdDefault = 'geodisha_default';
  static const String channelIdAlerts = 'geodisha_alerts';
  static const String channelIdReminders = 'geodisha_reminders';
  
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDebugLogging = bool.fromEnvironment('DEBUG', defaultValue: false);
}
