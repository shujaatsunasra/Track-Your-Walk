import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../theme/global_theme.dart';

/// Permission denied screen for location services
class PermissionDeniedScreen extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onSkip;

  const PermissionDeniedScreen({
    super.key,
    this.onPermissionGranted,
    this.onSkip,
  });

  @override
  State<PermissionDeniedScreen> createState() => _PermissionDeniedScreenState();
}

class _PermissionDeniedScreenState extends State<PermissionDeniedScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: GlobalTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(GlobalTheme.spacing24),
            child: Column(
              children: [
                // Header
                _buildHeader(theme),

                const SizedBox(height: GlobalTheme.spacing40),

                // Main content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Permission icon with animation
                      _buildPermissionIcon(),

                      const SizedBox(height: GlobalTheme.spacing32),

                      // Title and description
                      _buildContent(theme),

                      const SizedBox(height: GlobalTheme.spacing40),

                      // Permission steps
                      _buildPermissionSteps(theme),

                      const SizedBox(height: GlobalTheme.spacing40),

                      // Action buttons
                      _buildActionButtons(theme),
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

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Back button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.surfaceCard,
            borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
            boxShadow: GlobalTheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: GlobalTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(width: GlobalTheme.spacing16),

        Text(
          'Location Permission',
          style: theme.textTheme.titleLarge?.copyWith(
            color: GlobalTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildPermissionIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * _pulseController.value),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GlobalTheme.statusError.withOpacity(0.8),
                  GlobalTheme.statusError,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: GlobalTheme.statusError.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
        );
      },
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Location Access Required',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: GlobalTheme.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: GlobalTheme.spacing16),

        Text(
          'To track your runs and provide accurate fitness data, FitTracker needs access to your device\'s location services.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: GlobalTheme.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: GlobalTheme.spacing24),

        Container(
          padding: const EdgeInsets.all(GlobalTheme.spacing16),
          decoration: BoxDecoration(
            color: GlobalTheme.statusWarning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
            border: Border.all(
              color: GlobalTheme.statusWarning.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(GlobalTheme.spacing8),
                decoration: BoxDecoration(
                  color: GlobalTheme.statusWarning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(GlobalTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: GlobalTheme.statusWarning,
                  size: 20,
                ),
              ),
              const SizedBox(width: GlobalTheme.spacing12),
              Expanded(
                child: Text(
                  'Without location access, run tracking and route mapping won\'t be available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GlobalTheme.statusWarning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildPermissionSteps(ThemeData theme) {
    final steps = [
      {
        'icon': Icons.touch_app_rounded,
        'title': 'Tap "Enable Location"',
        'description': 'We\'ll open the system settings for you',
      },
      {
        'icon': Icons.location_on_rounded,
        'title': 'Allow Location Access',
        'description': 'Choose "While Using App" or "Always"',
      },
      {
        'icon': Icons.check_circle_rounded,
        'title': 'Start Tracking',
        'description': 'Return to the app and start your first run',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(GlobalTheme.spacing20),
      decoration: BoxDecoration(
        gradient: GlobalTheme.cardGradient,
        borderRadius: BorderRadius.circular(GlobalTheme.radiusLarge),
        border: Border.all(color: GlobalTheme.surfaceBorder, width: 1),
        boxShadow: GlobalTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Enable Location',
            style: theme.textTheme.titleMedium?.copyWith(
              color: GlobalTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: GlobalTheme.spacing20),

          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;

            return Container(
                  margin: EdgeInsets.only(
                    bottom: index < steps.length - 1
                        ? GlobalTheme.spacing16
                        : 0,
                  ),
                  child: Row(
                    children: [
                      // Step number
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: index == 0
                              ? GlobalTheme.primaryGradient
                              : null,
                          color: index == 0 ? null : GlobalTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(
                            GlobalTheme.radiusMedium,
                          ),
                          border: index > 0
                              ? Border.all(color: GlobalTheme.surfaceBorder)
                              : null,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          color: index == 0
                              ? Colors.black
                              : GlobalTheme.textTertiary,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: GlobalTheme.spacing16),

                      // Step content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: GlobalTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: GlobalTheme.spacing4),
                            Text(
                              step['description'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GlobalTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 900 + (index * 200)),
                  duration: 400.ms,
                )
                .slideX(begin: 0.3, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Primary action - Enable location
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRequestingPermission
                ? null
                : _requestLocationPermission,
            icon: _isRequestingPermission
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.location_on_rounded),
            label: Text(
              _isRequestingPermission
                  ? 'Opening Settings...'
                  : 'Enable Location',
            ),
            style: theme.elevatedButtonTheme.style?.copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: GlobalTheme.spacing16),
              ),
            ),
          ),
        ),

        const SizedBox(height: GlobalTheme.spacing16),

        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('App Settings'),
              ),
            ),

            const SizedBox(width: GlobalTheme.spacing16),

            Expanded(
              child: TextButton.icon(
                onPressed: _skipForNow,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Skip for Now'),
                style: TextButton.styleFrom(
                  foregroundColor: GlobalTheme.textTertiary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: GlobalTheme.spacing24),

        // Help text
        Container(
          padding: const EdgeInsets.all(GlobalTheme.spacing16),
          decoration: BoxDecoration(
            color: GlobalTheme.statusInfo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
            border: Border.all(color: GlobalTheme.statusInfo.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: GlobalTheme.statusInfo,
                size: 20,
              ),
              const SizedBox(width: GlobalTheme.spacing12),
              Expanded(
                child: Text(
                  'Your location data is processed locally and never shared without your permission.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: GlobalTheme.statusInfo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isRequestingPermission = true;
    });

    try {
      // Check current permission status
      final status = await Permission.location.status;

      if (status.isDenied || status.isRestricted) {
        // Request permission
        final result = await Permission.location.request();

        if (result.isGranted) {
          // Permission granted
          widget.onPermissionGranted?.call();
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else if (result.isPermanentlyDenied) {
          // Open app settings
          await _openAppSettings();
        } else {
          // Show feedback that permission was denied
          if (mounted) {
            _showPermissionDeniedFeedback();
          }
        }
      } else if (status.isPermanentlyDenied) {
        // Open app settings directly
        await _openAppSettings();
      } else if (status.isGranted) {
        // Already granted
        widget.onPermissionGranted?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        _showErrorFeedback();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();

      // Show guidance
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                SizedBox(width: GlobalTheme.spacing8),
                Expanded(
                  child: Text(
                    'Find FitTracker in the app list and enable location access.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: GlobalTheme.statusInfo,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(GlobalTheme.spacing16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorFeedback();
      }
    }
  }

  void _skipForNow() {
    widget.onSkip?.call();
    Navigator.of(context).pop();

    // Show informational feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: GlobalTheme.spacing8),
            Expanded(
              child: Text(
                'You can enable location access later in Settings.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: GlobalTheme.statusWarning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(GlobalTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPermissionDeniedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white, size: 18),
            SizedBox(width: GlobalTheme.spacing8),
            Expanded(
              child: Text(
                'Location access is required for run tracking. Please try again or use App Settings.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: GlobalTheme.statusError,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(GlobalTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: _openAppSettings,
        ),
      ),
    );
  }

  void _showErrorFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: GlobalTheme.spacing8),
            Text(
              'Unable to open settings. Please try manually.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: GlobalTheme.statusError,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(GlobalTheme.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalTheme.radiusMedium),
        ),
      ),
    );
  }
}
