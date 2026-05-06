import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/alerts_crisis_service.dart';
import '../../core/services/api_service.dart';

class RaiseAlertScreen extends ConsumerStatefulWidget {
  const RaiseAlertScreen({super.key});

  @override
  ConsumerState<RaiseAlertScreen> createState() => _RaiseAlertScreenState();
}

class _RaiseAlertScreenState extends ConsumerState<RaiseAlertScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late AlertsCrisisService _alertsService;

  // Animation controllers
  late AnimationController _submitButtonController;
  late AnimationController _successAnimationController;
  late Animation<double> _submitButtonAnimation;
  late Animation<double> _successAnimation;

  String _selectedCategory = 'Infrastructure';
  String _selectedPriority = 'High';
  List<XFile> _selectedImages = [];
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  // Form validation
  String? _titleError;
  String? _descriptionError;

  final List<String> _categories = [
    'Infrastructure',
    'Water Supply',
    'Health',
    'Education',
    'Safety',
    'Sanitation',
    'Other',
  ];

  final List<String> _priorities = ['Critical', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _alertsService = AlertsCrisisService(ApiService());
    
    // Initialize animation controllers
    _submitButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _submitButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _submitButtonController,
      curve: Curves.easeInOut,
    ));
    
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _submitButtonController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(5 - _selectedImages.length));
        });
      }
    } catch (e) {
      _showError('Failed to pick images');
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showError('Failed to capture image');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = position;
      });
      _showSuccessMessage('Location captured successfully');
    } catch (e) {
      _showError('Failed to get location');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submitAlert() async {
    // Clear previous errors
    setState(() {
      _titleError = null;
      _descriptionError = null;
    });

    // Validate form
    bool isValid = true;
    if (_titleController.text.isEmpty) {
      setState(() => _titleError = 'Please enter a title');
      isValid = false;
    }

    if (_descriptionController.text.isEmpty) {
      setState(() => _descriptionError = 'Please enter a description');
      isValid = false;
    }

    if (!isValid) {
      _showErrorWithAnimation('Please fill in all required fields');
      return;
    }

    // Start submit animation
    setState(() => _isSubmitting = true);
    _submitButtonController.forward();

    try {
      // TODO: Implement API call to submit alert
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        // Success animation
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });
        
        _submitButtonController.reverse();
        _successAnimationController.forward();
        
        _showSuccessWithAnimation('Alert submitted successfully! 🎉');
        
        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _submitButtonController.reverse();
        _showErrorWithAnimation('Failed to submit alert. Please try again.');
      }
    }
  }

  void _showErrorWithAnimation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessWithAnimation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppTheme.errorColor;
      case 'High':
        return AppTheme.warningColor;
      case 'Medium':
        return AppTheme.primaryColor;
      case 'Low':
        return AppTheme.successColor;
      default:
        return AppTheme.mediumGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Alert'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.infoColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your alert will be sent to the admin team and tracked until resolved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title Field with Enhanced Styling
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert Title *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Brief title for the issue',
                      prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      errorText: _titleError,
                      errorStyle: TextStyle(color: AppTheme.errorColor),
                    ),
                    onChanged: (value) {
                      if (_titleError != null && value.isNotEmpty) {
                        setState(() => _titleError = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category with Enhanced Design
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade50,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(_getCategoryIcon(category), 
                                   color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Text(category, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Priority with Enhanced Chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _priorities.map((priority) {
                    final isSelected = _selectedPriority == priority;
                    final color = _getPriorityColor(priority);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ChoiceChip(
                        label: Text(
                          priority,
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        backgroundColor: color.withOpacity(0.1),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPriority = priority);
                          }
                        },
                        side: BorderSide(
                          color: color,
                          width: isSelected ? 0 : 1,
                        ),
                        elevation: isSelected ? 3 : 0,
                        shadowColor: color.withOpacity(0.4),
                        avatar: isSelected 
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description Field with Enhanced Styling
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.description, color: AppTheme.primaryColor),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      errorText: _descriptionError,
                      errorStyle: TextStyle(color: AppTheme.errorColor),
                    ),
                    onChanged: (value) {
                      if (_descriptionError != null && value.isNotEmpty) {
                        setState(() => _descriptionError = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Location
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _currentLocation != null
                    ? 'Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                    : 'Capture Current Location',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: BorderSide(
                  color: _currentLocation != null
                      ? AppTheme.successColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Photos
            const Text(
              'Attach Photos (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _selectedImages.length < 5 ? _captureImage : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _selectedImages.length < 5 ? _pickImages : null,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 40),

            // Enhanced Animated Submit Button
            AnimatedBuilder(
              animation: _submitButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _submitButtonAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showSuccess 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isSubmitting ? 0 : 4,
                        shadowColor: AppTheme.errorColor.withOpacity(0.3),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showSuccess
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: const Key('success'),
                                children: [
                                  ScaleTransition(
                                    scale: _successAnimation,
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Alert Submitted!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : _isSubmitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    key: const Key('loading'),
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Submitting Alert...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    key: const Key('submit'),
                                    children: [
                                      const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Submit Alert',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to get category icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Infrastructure':
        return Icons.construction;
      case 'Water Supply':
        return Icons.water_drop;
      case 'Health':
        return Icons.local_hospital;
      case 'Education':
        return Icons.school;
      case 'Safety':
        return Icons.security;
      case 'Sanitation':
        return Icons.cleaning_services;
      default:
        return Icons.info;
    }
  }
}
