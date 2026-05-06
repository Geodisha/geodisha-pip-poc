import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/simple_auth_service.dart';
import '../../../data/services/constituency_service.dart';
import '../../../core/services/api_service.dart';
import '../dashboard_screen_new.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SimpleAuthService _authService = SimpleAuthService();
  late ConstituencyService _constituencyService;
  
  String _selectedRole = 'MP/MLA';
  String? _selectedConstituency;
  bool _isLoading = false;
  bool _loadingConstituencies = false;
  List<Constituency> _constituencies = [];

  final List<String> _roles = ['Admin', 'MP/MLA', 'Minister', 'Volunteer'];

  @override
  void initState() {
    super.initState();
    _constituencyService = ConstituencyService(ApiService());
    _loadConstituencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadConstituencies() async {
    setState(() => _loadingConstituencies = true);
    
    try {
      final constituencies = await _constituencyService.getAllConstituencies();
      setState(() {
        _constituencies = constituencies;
        _loadingConstituencies = false;
      });
    } catch (e) {
      print('Error loading constituencies: $e');
      setState(() {
        _loadingConstituencies = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    // Admin doesn't need to select a constituency
    if (_selectedRole != 'Admin' && _selectedConstituency == null) {
      _showError('Please select your constituency');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.saveUserProfile(
        name: _nameController.text,
        constituency: _selectedConstituency ?? 'N/A',
        role: _selectedRole,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.backgroundLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us personalize your experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),

                // Profile Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Constituency Field (hidden for Admin)
                      if (_selectedRole != 'Admin') ...[
                        const Text(
                          'Constituency',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _loadingConstituencies
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Loading constituencies...'),
                                    ],
                                  ),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedConstituency,
                                    isExpanded: true,
                                    hint: const Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Select your constituency'),
                                      ],
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down),
                                    items: _constituencies.map((constituency) {
                                      return DropdownMenuItem(
                                        value: constituency.id, // Use ID as value
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 20,
                                              color: AppTheme.primaryColor,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                constituency.name, // Display name
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedConstituency = value);
                                    },
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Role Selection
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getRoleIcon(role),
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(role),
                                    const SizedBox(width: 8),
                                    Text(
                                      '- ${_getRoleDescription(role)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                  // Clear constituency when switching to Admin
                                  if (value == 'Admin') {
                                    _selectedConstituency = null;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Continue to Dashboard',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'MP/MLA':
        return Icons.account_balance;
      case 'Minister':
        return Icons.badge;
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Volunteer':
        return Icons.volunteer_activism;
      default:
        return Icons.person;
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'Admin':
        return 'Full access to all constituencies';
      case 'MP/MLA':
        return 'Manage your constituency';
      case 'Minister':
        return 'Multi-constituency view';
      case 'Volunteer':
        return 'Limited data access';
      default:
        return '';
    }
  }
}
