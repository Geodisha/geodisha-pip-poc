// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Not using dotenv

class AppConfig {
  static late String apiBaseUrl;
  static late String environment;
  static late bool isProduction;
  
  static void initialize() {
    // Hard-coded for development - no dotenv needed
    environment = 'development';
    isProduction = false;
    
    // Using localhost for development
    apiBaseUrl = 'http://localhost:8000';
  }
  
  // API Endpoints (Legacy - not actively used)
  static String get authLoginUrl => '$apiBaseUrl/api/v1/auth/login';
  static String get authRegisterUrl => '$apiBaseUrl/api/v1/auth/register';
  static String get grievancesUrl => '$apiBaseUrl/api/v1/grievances';
  static String get visitsUrl => '$apiBaseUrl/api/v1/visits';
  static String get promisesUrl => '$apiBaseUrl/api/v1/promises';
  static String get intelligenceUrl => '$apiBaseUrl/api/v1/intelligence';
  static String get analyticsUrl => '$apiBaseUrl/api/v1/analytics';
}
