import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enterprise-level permission management service
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Stream controller for permission state changes
  final StreamController<PermissionState> _permissionController =
      StreamController<PermissionState>.broadcast();

  Stream<PermissionState> get permissionStream => _permissionController.stream;

  PermissionState _currentState = PermissionState.unknown;
  Timer? _permissionMonitor;

  /// Initialize permission service
  Future<void> initialize() async {
    debugPrint('🔐 PermissionService: Initializing...');
    await _updatePermissionState();
    _startPermissionMonitoring();
    debugPrint('✅ PermissionService: Initialized');
  }

  /// Request all necessary permissions for fitness tracking
  Future<PermissionRequestResult> requestFitnessPermissions() async {
    debugPrint('🔐 PermissionService: Requesting fitness permissions...');

    final results = <Permission, PermissionStatus>{};

    try {
      // Request essential location permissions only
      final locationStatus = await Permission.location.request();
      results[Permission.location] = locationStatus;

      // Try activity recognition but don't fail if not available
      try {
        final activityStatus = await Permission.activityRecognition.request();
        results[Permission.activityRecognition] = activityStatus;
      } catch (e) {
        debugPrint('⚠️ Activity recognition permission not available: $e');
      }

      await _updatePermissionState();

      final hasEssentialPermissions =
          results[Permission.location]?.isGranted == true;

      debugPrint(
        '✅ PermissionService: Permission request completed - Essential granted: $hasEssentialPermissions',
      );

      return PermissionRequestResult(
        isSuccess: hasEssentialPermissions,
        permissions: results,
        hasPartialAccess: hasEssentialPermissions,
      );
    } catch (e) {
      debugPrint('❌ PermissionService: Error requesting permissions: $e');
      return PermissionRequestResult(
        isSuccess: false,
        permissions: results,
        hasPartialAccess: false,
        error: e.toString(),
      );
    }
  }

  /// Request location permissions specifically
  /// Check current permission state
  Future<PermissionState> checkPermissionState() async {
    await _updatePermissionState();
    return _currentState;
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    try {
      debugPrint('🔐 PermissionService: Opening app settings...');
      return await openAppSettings();
    } catch (e) {
      debugPrint('❌ PermissionService: Error opening app settings: $e');
      return false;
    }
  }

  /// Show permission rationale dialog
  Future<bool> showPermissionRationale(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionRationaleDialog(
            title: title ?? 'Location Access Required',
            message:
                message ??
                'This app needs access to your location to track your fitness activities, '
                    'calculate distances, and provide accurate workout metrics. Your privacy '
                    'is important to us - location data is only used for fitness tracking.',
          ),
        ) ??
        false;
  }

  /// Get user-friendly permission status text
  String getPermissionStatusText() {
    switch (_currentState) {
      case PermissionState.allGranted:
        return 'All permissions granted - Ready to track!';
      case PermissionState.partiallyGranted:
        return 'Some permissions granted - Limited functionality';
      case PermissionState.denied:
        return 'Permissions denied - Please grant access';
      case PermissionState.permanentlyDenied:
        return 'Permissions permanently denied - Please enable in settings';
      case PermissionState.unknown:
        return 'Checking permissions...';
    }
  }

  /// Get recommended action for current permission state
  PermissionAction getRecommendedAction() {
    switch (_currentState) {
      case PermissionState.allGranted:
        return PermissionAction.none;
      case PermissionState.partiallyGranted:
        return PermissionAction.requestRemaining;
      case PermissionState.denied:
        return PermissionAction.request;
      case PermissionState.permanentlyDenied:
        return PermissionAction.openSettings;
      case PermissionState.unknown:
        return PermissionAction.check;
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 PermissionService: Disposing...');
    _permissionMonitor?.cancel();
    _permissionController.close();
  }

  // Private methods

  Future<void> _updatePermissionState() async {
    try {
      final locationStatus = await Permission.location.status;
      final activityStatus = await Permission.activityRecognition.status;
      final sensorsStatus = await Permission.sensors.status;

      final permissions = [locationStatus, activityStatus, sensorsStatus];
      final granted = permissions.where((s) => s == PermissionStatus.granted);
      final permanentlyDenied = permissions.where(
        (s) => s == PermissionStatus.permanentlyDenied,
      );

      PermissionState newState;

      if (permanentlyDenied.isNotEmpty) {
        newState = PermissionState.permanentlyDenied;
      } else if (granted.isEmpty) {
        newState = PermissionState.denied;
      } else if (granted.length == permissions.length) {
        newState = PermissionState.allGranted;
      } else {
        newState = PermissionState.partiallyGranted;
      }

      if (_currentState != newState) {
        _currentState = newState;
        _permissionController.add(_currentState);
        debugPrint('🔐 PermissionService: State changed to $_currentState');
      }
    } catch (e) {
      debugPrint('❌ PermissionService: Error updating permission state: $e');
    }
  }

  void _startPermissionMonitoring() {
    _permissionMonitor = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updatePermissionState(),
    );
  }

  // Getters
  PermissionState get currentState => _currentState;
}

/// Permission state enum
enum PermissionState {
  unknown,
  allGranted,
  partiallyGranted,
  denied,
  permanentlyDenied,
}

/// Recommended action enum
enum PermissionAction { none, check, request, requestRemaining, openSettings }

/// Permission request result
class PermissionRequestResult {
  final bool isSuccess;
  final Map<Permission, PermissionStatus> permissions;
  final bool hasPartialAccess;
  final String? error;

  const PermissionRequestResult({
    required this.isSuccess,
    required this.permissions,
    required this.hasPartialAccess,
    this.error,
  });

  @override
  String toString() {
    return 'PermissionRequestResult(success: $isSuccess, partial: $hasPartialAccess, '
        'permissions: ${permissions.length}, error: $error)';
  }
}

/// Permission rationale dialog
class PermissionRationaleDialog extends StatelessWidget {
  final String title;
  final String message;

  const PermissionRationaleDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Not Now',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Grant Access'),
        ),
      ],
    );
  }
}
