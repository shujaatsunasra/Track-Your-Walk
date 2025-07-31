import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Enterprise-level location service for million-dollar app quality
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Stream controllers for real-time location updates
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();
  final StreamController<LocationPermissionStatus> _permissionController =
      StreamController<LocationPermissionStatus>.broadcast();
  final StreamController<LocationServiceStatus> _serviceController =
      StreamController<LocationServiceStatus>.broadcast();

  // Getters for streams
  Stream<LocationData> get locationStream => _locationController.stream;
  Stream<LocationPermissionStatus> get permissionStream =>
      _permissionController.stream;
  Stream<LocationServiceStatus> get serviceStream => _serviceController.stream;

  // Current state tracking
  LocationData? _currentLocation;
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.unknown;
  LocationServiceStatus _serviceStatus = LocationServiceStatus.unknown;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _permissionCheckTimer;

  bool _isInitialized = false;
  bool _isTracking = false;

  /// Initialize the location service with enterprise-level error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
        '🌍 LocationService: Initializing enterprise location service...',
      );

      // Initial permission and service checks
      await _updatePermissionStatus();
      await _updateServiceStatus();

      // Start monitoring permission changes
      _startPermissionMonitoring();

      _isInitialized = true;
      debugPrint('✅ LocationService: Successfully initialized');
    } catch (e) {
      debugPrint('❌ LocationService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Request location permissions with enterprise UX flow
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      debugPrint('🔐 LocationService: Requesting location permissions...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _permissionStatus = LocationPermissionStatus.serviceDisabled;
        _permissionController.add(_permissionStatus);
        return _permissionStatus;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Update status based on permission result
      switch (permission) {
        case LocationPermission.whileInUse:
          _permissionStatus = LocationPermissionStatus.whileInUse;
          break;
        case LocationPermission.always:
          _permissionStatus = LocationPermissionStatus.always;
          break;
        case LocationPermission.denied:
          _permissionStatus = LocationPermissionStatus.denied;
          break;
        case LocationPermission.deniedForever:
          _permissionStatus = LocationPermissionStatus.deniedForever;
          break;
        case LocationPermission.unableToDetermine:
          _permissionStatus = LocationPermissionStatus.unknown;
          break;
      }

      _permissionController.add(_permissionStatus);
      debugPrint('✅ LocationService: Permission status: $_permissionStatus');

      return _permissionStatus;
    } catch (e) {
      debugPrint('❌ LocationService: Permission request failed: $e');
      _permissionStatus = LocationPermissionStatus.unknown;
      _permissionController.add(_permissionStatus);
      return _permissionStatus;
    }
  }

  /// Start location tracking with enterprise-level accuracy
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      debugPrint('📍 LocationService: Starting location tracking...');

      // Ensure permissions are granted
      final permissionStatus = await requestPermission();
      if (permissionStatus != LocationPermissionStatus.whileInUse &&
          permissionStatus != LocationPermissionStatus.always) {
        debugPrint('❌ LocationService: Insufficient permissions for tracking');
        return false;
      }

      // Start position stream
      _positionSubscription = Geolocator.getPositionStream().listen(
        _onLocationUpdate,
        onError: _onLocationError,
        cancelOnError: false,
      );

      // Get initial position
      try {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _onLocationUpdate(position);
      } catch (e) {
        debugPrint('⚠️ LocationService: Failed to get initial position: $e');
      }

      _isTracking = true;
      debugPrint('✅ LocationService: Location tracking started');
      return true;
    } catch (e) {
      debugPrint('❌ LocationService: Failed to start tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      debugPrint('🛑 LocationService: Stopping location tracking...');

      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _isTracking = false;

      debugPrint('✅ LocationService: Location tracking stopped');
    } catch (e) {
      debugPrint('❌ LocationService: Error stopping tracking: $e');
    }
  }

  /// Get current location with caching
  Future<LocationData?> getCurrentLocation() async {
    try {
      if (_currentLocation != null && _isLocationRecent()) {
        return _currentLocation;
      }

      final permissionStatus = await requestPermission();
      if (permissionStatus != LocationPermissionStatus.whileInUse &&
          permissionStatus != LocationPermissionStatus.always) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = LocationData.fromPosition(position);
      _currentLocation = locationData;
      _locationController.add(locationData);

      return locationData;
    } catch (e) {
      debugPrint('❌ LocationService: Failed to get current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(LatLng point1, LatLng point2) {
    return Geolocator.bearingBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Open app settings for permission management
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 LocationService: Disposing resources...');

    _positionSubscription?.cancel();
    _permissionCheckTimer?.cancel();
    _locationController.close();
    _permissionController.close();
    _serviceController.close();

    _isInitialized = false;
    _isTracking = false;
  }

  // Private methods

  void _onLocationUpdate(Position position) {
    final locationData = LocationData.fromPosition(position);
    _currentLocation = locationData;
    _locationController.add(locationData);

    debugPrint(
      '📍 LocationService: Location updated - '
      'Lat: ${position.latitude.toStringAsFixed(6)}, '
      'Lng: ${position.longitude.toStringAsFixed(6)}, '
      'Accuracy: ${position.accuracy.toStringAsFixed(1)}m',
    );
  }

  void _onLocationError(dynamic error) {
    debugPrint('❌ LocationService: Location error: $error');
    // Could emit error state to stream if needed
  }

  Future<void> _updatePermissionStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _permissionStatus = LocationPermissionStatus.serviceDisabled;
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        switch (permission) {
          case LocationPermission.whileInUse:
            _permissionStatus = LocationPermissionStatus.whileInUse;
            break;
          case LocationPermission.always:
            _permissionStatus = LocationPermissionStatus.always;
            break;
          case LocationPermission.denied:
            _permissionStatus = LocationPermissionStatus.denied;
            break;
          case LocationPermission.deniedForever:
            _permissionStatus = LocationPermissionStatus.deniedForever;
            break;
          case LocationPermission.unableToDetermine:
            _permissionStatus = LocationPermissionStatus.unknown;
            break;
        }
      }

      _permissionController.add(_permissionStatus);
    } catch (e) {
      debugPrint('❌ LocationService: Error updating permission status: $e');
    }
  }

  Future<void> _updateServiceStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _serviceStatus = serviceEnabled
          ? LocationServiceStatus.enabled
          : LocationServiceStatus.disabled;
      _serviceController.add(_serviceStatus);
    } catch (e) {
      debugPrint('❌ LocationService: Error updating service status: $e');
    }
  }

  void _startPermissionMonitoring() {
    // Check permission status every 30 seconds
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) async {
      await _updatePermissionStatus();
      await _updateServiceStatus();
    });
  }

  bool _isLocationRecent() {
    if (_currentLocation == null) return false;

    final now = DateTime.now();
    final locationTime = _currentLocation!.timestamp;
    final difference = now.difference(locationTime);

    // Consider location recent if it's less than 30 seconds old
    return difference.inSeconds < 30;
  }

  // Getters
  LocationData? get currentLocation => _currentLocation;
  LocationPermissionStatus get permissionStatus => _permissionStatus;
  LocationServiceStatus get serviceStatus => _serviceStatus;
  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking;
}

/// Enterprise-level location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      timestamp: position.timestamp,
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  String toString() {
    return 'LocationData(lat: ${latitude.toStringAsFixed(6)}, '
        'lng: ${longitude.toStringAsFixed(6)}, '
        'accuracy: ${accuracy.toStringAsFixed(1)}m)';
  }
}

/// Permission status enum for better state management
enum LocationPermissionStatus {
  unknown,
  denied,
  deniedForever,
  whileInUse,
  always,
  serviceDisabled,
}

/// Service status enum
enum LocationServiceStatus { unknown, enabled, disabled }

/// Extension for permission status display
extension LocationPermissionStatusExtension on LocationPermissionStatus {
  String get displayName {
    switch (this) {
      case LocationPermissionStatus.unknown:
        return 'Unknown';
      case LocationPermissionStatus.denied:
        return 'Denied';
      case LocationPermissionStatus.deniedForever:
        return 'Permanently Denied';
      case LocationPermissionStatus.whileInUse:
        return 'While Using App';
      case LocationPermissionStatus.always:
        return 'Always Allowed';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location Service Disabled';
    }
  }

  bool get isGranted =>
      this == LocationPermissionStatus.whileInUse ||
      this == LocationPermissionStatus.always;

  bool get isPermanentlyDenied =>
      this == LocationPermissionStatus.deniedForever;

  bool get requiresAppSettings =>
      this == LocationPermissionStatus.deniedForever ||
      this == LocationPermissionStatus.serviceDisabled;
}
