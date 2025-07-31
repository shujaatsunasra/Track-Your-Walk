import 'package:fitness_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/permission_service.dart';
import '../../services/location_service.dart';
import '../../components/modern_ui_components.dart';
import '../../theme/global_theme.dart';

/// Enterprise-level permission onboarding flow
class PermissionOnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;
  final bool canSkip;

  const PermissionOnboardingFlow({
    super.key,
    required this.onComplete,
    this.canSkip = true,
  });

  @override
  State<PermissionOnboardingFlow> createState() =>
      _PermissionOnboardingFlowState();
}

class _PermissionOnboardingFlowState extends State<PermissionOnboardingFlow>
    with TickerProviderStateMixin {
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();

  late PageController _pageController;
  late AnimationController _progressController;

  int _currentPage = 0;
  bool _isLoading = false;
  PermissionState _permissionState = PermissionState.unknown;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Fitness Pro',
      subtitle: 'Your personal fitness companion',
      description:
          'Track your runs, monitor your progress, and achieve your fitness goals with precision GPS tracking.',
      icon: Icons.fitness_center,
      color: GlobalTheme.primaryAccent,
    ),
    OnboardingPage(
      title: 'Location Tracking',
      subtitle: 'Accurate GPS for precise tracking',
      description:
          'We use GPS to track your running routes, calculate distance, pace, and provide detailed workout analytics.',
      icon: Icons.location_on,
      color: GlobalTheme.primaryAction,
    ),
    OnboardingPage(
      title: 'Activity Recognition',
      subtitle: 'Intelligent workout detection',
      description:
          'Automatically detect different types of workouts and optimize tracking for each activity type.',
      icon: Icons.directions_run,
      color: GlobalTheme.primaryNeon,
    ),
    OnboardingPage(
      title: 'Motion Sensors',
      subtitle: 'Enhanced step counting',
      description:
          'Access to motion sensors enables accurate step counting and cadence measurement during your workouts.',
      icon: Icons.sensors,
      color: Colors.deepOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _permissionService.initialize();
    await _locationService.initialize();

    // Listen to permission changes
    _permissionService.permissionStream.listen((state) {
      if (mounted) {
        setState(() {
          _permissionState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _requestPermissions();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _permissionService.requestFitnessPermissions();

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      widget.onComplete();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: GlobalTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Permissions Required',
              style: const TextStyle(color: GlobalTheme.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Some features may not work properly without these permissions. You can change them later in the app settings.',
          style: const TextStyle(color: GlobalTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.canSkip) {
                widget.onComplete();
              }
            },
            child: Text(
              widget.canSkip ? 'Continue Anyway' : 'OK',
              style: const TextStyle(color: GlobalTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalTheme.primaryNeon,
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _progressController.animateTo((index + 1) / _pages.length);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  onPressed: _previousPage,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: GlobalTheme.textSecondary,
                  ),
                ),
              const Spacer(),
              if (widget.canSkip)
                TextButton(
                  onPressed: widget.onComplete,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: GlobalTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentPage + 1) / _pages.length,
            backgroundColor: GlobalTheme.textTertiary.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _pages[_currentPage].color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),

          // Icon
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 60, color: page.color),
              )
              .animate(key: ValueKey(index))
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 2000.ms, color: page.color.withOpacity(0.3)),

          const SizedBox(height: 48),

          // Title
          Text(
                page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Subtitle
          Text(
                page.subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: page.color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )
              .animate(key: ValueKey('subtitle_$index'))
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 24),

          // Description
          Text(
                page.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
              .animate(key: ValueKey('description_$index'))
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.3, end: 0),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Permission status indicator (on last page)
          if (_currentPage == _pages.length - 1 &&
              _permissionState != PermissionState.unknown)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StatusIndicator(
                status: _permissionService.getPermissionStatusText(),
                color: _getStatusColor(),
                icon: _getStatusIcon(),
                isPulsing: _permissionState == PermissionState.denied,
              ),
            ),

          // Main action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pages[_currentPage].color,
                foregroundColor: _getButtonTextColor(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentPage == _pages.length - 1
                          ? 'Grant Permissions'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5, end: 0);
  }

  Color _getStatusColor() {
    switch (_permissionState) {
      case PermissionState.allGranted:
        return AppTheme.neonGreen;
      case PermissionState.partiallyGranted:
        return Colors.orange;
      case PermissionState.denied:
      case PermissionState.permanentlyDenied:
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (_permissionState) {
      case PermissionState.allGranted:
        return Icons.check_circle;
      case PermissionState.partiallyGranted:
        return Icons.warning;
      case PermissionState.denied:
      case PermissionState.permanentlyDenied:
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getButtonTextColor() {
    final color = _pages[_currentPage].color;
    // Calculate if the color is light or dark to determine text color
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Onboarding page data model
class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
