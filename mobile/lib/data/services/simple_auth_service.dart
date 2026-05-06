import 'dart:async';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// User roles in the system
enum UserRole {
  admin('Admin'),
  mpMla('MP/MLA'),
  minister('Minister'),
  volunteer('Volunteer');

  final String displayName;
  const UserRole(this.displayName);

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'mp/mla':
      case 'mpmla':
        return UserRole.mpMla;
      case 'minister':
        return UserRole.minister;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        return UserRole.volunteer; // Default to least privilege
    }
  }
}

/// Permission levels for different modules
enum ModulePermission {
  commandCenter,
  aiIntelligenceHub,
  groundReality,
  electionWarRoom,
  promiseTracker,
  alertsCrisis,
  userManagement,
  constituencySwitcher,
}

/// Simple Email + OTP Authentication Service
/// Perfect for demos - no Firebase needed
/// Can be easily replaced with real backend later
class SimpleAuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  // Demo users - can login with these emails
  static const List<String> allowedEmails = [
    'demo@geodisha.com',
    'admin@geodisha.com',
    'test@geodisha.com',
  ];

  // In-memory storage for demo OTPs
  final Map<String, String> _otpStorage = {};
  final Map<String, DateTime> _otpExpiry = {};

  // Stream controller for auth state
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  Stream<bool> get authStateChanges => _authStateController.stream;

  // Singleton pattern
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  /// Get current user email
  Future<String?> getCurrentUserEmail() async {
    return await _storage.read(key: 'user_email');
  }

  /// Get user profile
  Future<Map<String, String?>> getUserProfile() async {
    final email = await _storage.read(key: 'user_email');
    final name = await _storage.read(key: 'user_name');
    final constituency = await _storage.read(key: 'user_constituency');
    final role = await _storage.read(key: 'user_role');

    return {
      'email': email,
      'name': name,
      'constituency': constituency,
      'role': role,
    };
  }

  /// Get user role
  Future<UserRole> getUserRole() async {
    final roleString = await _storage.read(key: 'user_role');
    return UserRole.fromString(roleString);
  }

  /// Get user constituency
  Future<String?> getUserConstituency() async {
    return await _storage.read(key: 'user_constituency');
  }

  /// Get selected constituency (for Admin who can switch)
  Future<String?> getSelectedConstituency() async {
    final role = await getUserRole();
    if (role == UserRole.admin) {
      // For admin, check if they've selected a specific constituency
      final selected = await _storage.read(key: 'selected_constituency');
      return selected;
    } else {
      // For non-admin, return their assigned constituency
      return await getUserConstituency();
    }
  }

  /// Set selected constituency (Admin only)
  Future<void> setSelectedConstituency(String constituency) async {
    final role = await getUserRole();
    if (role == UserRole.admin) {
      await _storage.write(key: 'selected_constituency', value: constituency);
      _logger.i('Admin selected constituency: $constituency');
    } else {
      _logger.w('Only Admin can switch constituencies');
    }
  }

  /// Get constituencies accessible to user
  /// - Admin: all constituencies
  /// - Minister: multiple assigned constituencies
  /// - MP/MLA: single constituency
  /// - Volunteer: single constituency (limited data)
  Future<List<String>> getAccessibleConstituencies() async {
    final role = await getUserRole();
    
    if (role == UserRole.admin) {
      // Admin has access to all constituencies
      return getAllConstituencies();
    } else if (role == UserRole.minister) {
      // Minister might have multiple constituencies
      // For now, return their assigned one, but this could be expanded
      final constituency = await getUserConstituency();
      return constituency != null ? [constituency] : [];
    } else {
      // MP/MLA and Volunteer have single constituency
      final constituency = await getUserConstituency();
      return constituency != null ? [constituency] : [];
    }
  }

  /// Check if user has permission for a module
  Future<bool> hasPermission(ModulePermission permission) async {
    final role = await getUserRole();

    switch (permission) {
      case ModulePermission.commandCenter:
        // All roles can access Command Center (but with filtered data)
        return true;

      case ModulePermission.aiIntelligenceHub:
        // Only Admin, MP/MLA, and Minister
        return role == UserRole.admin || 
               role == UserRole.mpMla || 
               role == UserRole.minister;

      case ModulePermission.groundReality:
        // All roles can access
        return true;

      case ModulePermission.electionWarRoom:
        // Only Admin, MP/MLA, and Minister
        return role == UserRole.admin || 
               role == UserRole.mpMla || 
               role == UserRole.minister;

      case ModulePermission.promiseTracker:
        // All roles can access
        return true;

      case ModulePermission.alertsCrisis:
        // All roles can access
        return true;

      case ModulePermission.userManagement:
        // Only Admin
        return role == UserRole.admin;

      case ModulePermission.constituencySwitcher:
        // Only Admin
        return role == UserRole.admin;
    }
  }

  /// Check if user can view sensitive data
  Future<bool> canViewSensitiveData() async {
    final role = await getUserRole();
    return role != UserRole.volunteer;
  }

  /// Check if user can edit data
  Future<bool> canEditData() async {
    final role = await getUserRole();
    return role == UserRole.admin || role == UserRole.mpMla;
  }

  /// Check if user can manage promises
  Future<bool> canManagePromises() async {
    final role = await getUserRole();
    return role == UserRole.admin || 
           role == UserRole.mpMla || 
           role == UserRole.minister;
  }

  /// Get demo list of all constituencies
  /// In production, this would come from backend
  List<String> getAllConstituencies() {
    return [
      'Bhubaneswar Central',
      'Bhubaneswar North',
      'Bhubaneswar South',
      'Puri',
      'Cuttack',
      'Berhampur',
      'Rourkela',
      'Sambalpur',
      'Balasore',
      'Bhadrak',
    ];
  }

  /// Send OTP to email
  /// For demo: generates a 6-digit OTP and stores it in memory
  /// In production: this would call your backend API to send real email
  Future<bool> sendOTP(String email) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        _logger.e('Invalid email format: $email');
        return false;
      }

      // Check if email is allowed (for demo)
      // In production: remove this check
      if (!allowedEmails.contains(email.toLowerCase())) {
        _logger.w('Email not in demo list: $email');
        // For demo, we'll allow any email but warn
      }

      // Generate 6-digit OTP
      final otp = _generateOTP();

      // Store OTP with 5-minute expiry
      _otpStorage[email.toLowerCase()] = otp;
      _otpExpiry[email.toLowerCase()] =
          DateTime.now().add(const Duration(minutes: 5));

      _logger.i('OTP generated for $email: $otp');
      _logger.i('📱 DEMO OTP: $otp (Valid for 5 minutes)');

      return true;
    } catch (e) {
      _logger.e('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final emailLower = email.toLowerCase();

      // Check if OTP exists
      if (!_otpStorage.containsKey(emailLower)) {
        _logger.e('No OTP found for email: $email');
        return false;
      }

      // Check if OTP is expired
      final expiry = _otpExpiry[emailLower];
      if (expiry == null || DateTime.now().isAfter(expiry)) {
        _logger.e('OTP expired for email: $email');
        _otpStorage.remove(emailLower);
        _otpExpiry.remove(emailLower);
        return false;
      }

      // Verify OTP
      final storedOTP = _otpStorage[emailLower];
      if (storedOTP != otp) {
        _logger.e('Invalid OTP for email: $email');
        return false;
      }

      // OTP verified successfully
      _logger.i('OTP verified successfully for: $email');

      // Generate auth token
      final token = _generateToken();

      // Store user session
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_email', value: email);

      // Clean up OTP
      _otpStorage.remove(emailLower);
      _otpExpiry.remove(emailLower);

      // Notify auth state changed
      _authStateController.add(true);

      return true;
    } catch (e) {
      _logger.e('Error verifying OTP: $e');
      return false;
    }
  }

  /// Save user profile after OTP verification
  Future<void> saveUserProfile({
    required String name,
    required String constituency,
    required String role,
  }) async {
    try {
      await _storage.write(key: 'user_name', value: name);
      await _storage.write(key: 'user_constituency', value: constituency);
      await _storage.write(key: 'user_role', value: role);
      _logger.i('User profile saved successfully');
    } catch (e) {
      _logger.e('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _storage.deleteAll();
      _authStateController.add(false);
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error logging out: $e');
      rethrow;
    }
  }

  /// Get OTP for demo purposes (to display on screen)
  /// Remove this in production!
  String? getDemoOTP(String email) {
    return _otpStorage[email.toLowerCase()];
  }

  // Helper: Generate 6-digit OTP
  String _generateOTP() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  // Helper: Generate auth token
  String _generateToken() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return 'token_${timestamp}_$randomPart';
  }

  // Helper: Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Dispose
  void dispose() {
    _authStateController.close();
  }
}
