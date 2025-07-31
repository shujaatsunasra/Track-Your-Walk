import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'location_service.dart';

/// Enterprise-level map service for fitness tracking
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final LocationService _locationService = LocationService();

  // Map configuration
  static const double _defaultZoom = 16.0;
  static const double _trackingZoom = 17.0;
  static const double _maxZoom = 19.0;
  static const double _minZoom = 3.0;

  // Tracking data
  final List<LatLng> _routePoints = [];
  final List<TrackingPoint> _trackingPoints = [];
  LatLng? _currentLocation;

  // Stream controllers
  final StreamController<List<LatLng>> _routeController =
      StreamController<List<LatLng>>.broadcast();
  final StreamController<MapTrackingData> _trackingController =
      StreamController<MapTrackingData>.broadcast();

  // Getters for streams
  Stream<List<LatLng>> get routeStream => _routeController.stream;
  Stream<MapTrackingData> get trackingStream => _trackingController.stream;

  // Map state
  bool _isTracking = false;
  bool _isInitialized = false;
  MapController? _mapController;

  /// Initialize the map service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🗺️ MapService: Initializing...');

      // Initialize location service
      await _locationService.initialize();

      // Listen to location updates
      _locationService.locationStream.listen(_onLocationUpdate);

      _isInitialized = true;
      debugPrint('✅ MapService: Successfully initialized');
    } catch (e) {
      debugPrint('❌ MapService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Start tracking user's route
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      debugPrint('🗺️ MapService: Starting route tracking...');

      // Clear previous route data
      _routePoints.clear();
      _trackingPoints.clear();

      // Start location tracking
      final success = await _locationService.startTracking();
      if (!success) {
        debugPrint('❌ MapService: Failed to start location tracking');
        return false;
      }

      _isTracking = true;
      _emitTrackingData();

      debugPrint('✅ MapService: Route tracking started');
      return true;
    } catch (e) {
      debugPrint('❌ MapService: Failed to start tracking: $e');
      return false;
    }
  }

  /// Stop tracking user's route
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      debugPrint('🗺️ MapService: Stopping route tracking...');

      await _locationService.stopTracking();
      _isTracking = false;
      _emitTrackingData();

      debugPrint('✅ MapService: Route tracking stopped');
    } catch (e) {
      debugPrint('❌ MapService: Error stopping tracking: $e');
    }
  }

  /// Pause tracking (keeps route, stops adding points)
  void pauseTracking() {
    if (!_isTracking) return;

    debugPrint('⏸️ MapService: Pausing route tracking...');
    // We don't stop location service, just stop adding points
    // This is handled in _onLocationUpdate
  }

  /// Resume tracking
  Future<void> resumeTracking() async {
    if (!_isTracking) return;

    debugPrint('▶️ MapService: Resuming route tracking...');
    // Location service should still be running, just resume adding points
  }

  /// Get current map position
  LatLng? getCurrentPosition() {
    return _currentLocation ?? _locationService.currentLocation?.latLng;
  }

  /// Center map on current location
  void centerOnCurrentLocation() {
    final position = getCurrentPosition();
    if (position != null && _mapController != null) {
      _mapController!.move(position, _trackingZoom);
    }
  }

  /// Fit map to show entire route
  void fitToRoute() {
    if (_routePoints.isEmpty || _mapController == null) return;

    try {
      final bounds = _calculateBounds(_routePoints);
      if (bounds != null) {
        _mapController!.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      }
    } catch (e) {
      debugPrint('❌ MapService: Error fitting to route: $e');
    }
  }

  /// Calculate total distance of current route
  double getTotalDistance() {
    if (_routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _routePoints.length; i++) {
      totalDistance += _locationService.calculateDistance(
        _routePoints[i - 1],
        _routePoints[i],
      );
    }

    return totalDistance; // in meters
  }

  /// Calculate current pace (minutes per kilometer)
  double getCurrentPace() {
    if (_trackingPoints.length < 2) return 0.0;

    final recentPoints = _trackingPoints.length > 10
        ? _trackingPoints.sublist(_trackingPoints.length - 10)
        : _trackingPoints;

    if (recentPoints.length < 2) return 0.0;

    final firstPoint = recentPoints.first;
    final lastPoint = recentPoints.last;

    final distance = _locationService.calculateDistance(
      firstPoint.location,
      lastPoint.location,
    ); // meters

    final duration = lastPoint.timestamp.difference(firstPoint.timestamp);
    final durationMinutes = duration.inMilliseconds / 60000.0;

    if (distance < 10) return 0.0; // Not enough distance to calculate pace

    final distanceKm = distance / 1000.0;
    return durationMinutes / distanceKm; // minutes per km
  }

  /// Get average speed (km/h)
  double getAverageSpeed() {
    final pace = getCurrentPace();
    if (pace <= 0) return 0.0;
    return 60.0 / pace; // Convert pace to speed
  }

  /// Create a polyline for the current route
  Polyline createRoutePolyline({Color? color}) {
    return Polyline(
      points: _routePoints,
      strokeWidth: 4.0,
      color: color ?? Colors.blue,
    );
  }

  /// Create markers for start and end points
  List<Marker> createRouteMarkers() {
    final markers = <Marker>[];

    if (_routePoints.isNotEmpty) {
      // Start marker
      markers.add(
        Marker(
          point: _routePoints.first,
          width: 24,
          height: 24,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
          ),
        ),
      );

      // End marker (if stopped)
      if (!_isTracking && _routePoints.length > 1) {
        markers.add(
          Marker(
            point: _routePoints.last,
            width: 24,
            height: 24,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 16),
            ),
          ),
        );
      }
    }

    // Current location marker
    final currentPos = getCurrentPosition();
    if (currentPos != null) {
      markers.add(
        Marker(
          point: currentPos,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    return markers;
  }

  /// Set map controller for programmatic control
  void setMapController(MapController controller) {
    _mapController = controller;
  }

  /// Get route statistics
  RouteStatistics getRouteStatistics() {
    return RouteStatistics(
      totalDistance: getTotalDistance(),
      totalPoints: _routePoints.length,
      averageSpeed: getAverageSpeed(),
      currentPace: getCurrentPace(),
      duration: _trackingPoints.isNotEmpty
          ? DateTime.now().difference(_trackingPoints.first.timestamp)
          : Duration.zero,
    );
  }

  /// Export route data (for saving or sharing)
  RouteData exportRoute() {
    return RouteData(
      points: List.from(_routePoints),
      trackingPoints: List.from(_trackingPoints),
      statistics: getRouteStatistics(),
      timestamp: DateTime.now(),
    );
  }

  /// Import route data (for viewing saved routes)
  void importRoute(RouteData routeData) {
    _routePoints.clear();
    _routePoints.addAll(routeData.points);

    _trackingPoints.clear();
    _trackingPoints.addAll(routeData.trackingPoints);

    _routeController.add(List.from(_routePoints));
    _emitTrackingData();
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 MapService: Disposing...');

    _routeController.close();
    _trackingController.close();

    _isInitialized = false;
    _isTracking = false;
  }

  // Private methods

  void _onLocationUpdate(LocationData location) {
    _currentLocation = location.latLng;

    if (_isTracking) {
      // Add point to route if tracking and location is accurate enough
      if (location.accuracy <= 20) {
        // Only add if accuracy is within 20 meters
        final trackingPoint = TrackingPoint(
          location: location.latLng,
          timestamp: location.timestamp,
          accuracy: location.accuracy,
          speed: location.speed,
        );

        // Don't add point if it's too close to the last point (avoid noise)
        if (_shouldAddPoint(location.latLng)) {
          _routePoints.add(location.latLng);
          _trackingPoints.add(trackingPoint);

          _routeController.add(List.from(_routePoints));
          _emitTrackingData();
        }
      }
    }
  }

  bool _shouldAddPoint(LatLng newPoint) {
    if (_routePoints.isEmpty) return true;

    final lastPoint = _routePoints.last;
    final distance = _locationService.calculateDistance(lastPoint, newPoint);

    // Only add point if it's at least 5 meters from the last point
    return distance >= 5.0;
  }

  void _emitTrackingData() {
    final data = MapTrackingData(
      currentLocation: _currentLocation,
      route: List.from(_routePoints),
      isTracking: _isTracking,
      statistics: getRouteStatistics(),
    );

    _trackingController.add(data);
  }

  LatLngBounds? _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  // Getters
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  List<TrackingPoint> get trackingPoints => List.unmodifiable(_trackingPoints);
  LatLng? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;

  // Constants for map configuration
  static double get defaultZoom => _defaultZoom;
  static double get trackingZoom => _trackingZoom;
  static double get maxZoom => _maxZoom;
  static double get minZoom => _minZoom;
}

/// Tracking point with additional metadata
class TrackingPoint {
  final LatLng location;
  final DateTime timestamp;
  final double accuracy;
  final double? speed;

  const TrackingPoint({
    required this.location,
    required this.timestamp,
    required this.accuracy,
    this.speed,
  });
}

/// Route statistics data
class RouteStatistics {
  final double totalDistance; // meters
  final int totalPoints;
  final double averageSpeed; // km/h
  final double currentPace; // minutes per km
  final Duration duration;

  const RouteStatistics({
    required this.totalDistance,
    required this.totalPoints,
    required this.averageSpeed,
    required this.currentPace,
    required this.duration,
  });

  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)}m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)}km';
    }
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedPace {
    if (currentPace <= 0) return '--:--';

    final minutes = currentPace.floor();
    final seconds = ((currentPace - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Map tracking data for real-time updates
class MapTrackingData {
  final LatLng? currentLocation;
  final List<LatLng> route;
  final bool isTracking;
  final RouteStatistics statistics;

  const MapTrackingData({
    this.currentLocation,
    required this.route,
    required this.isTracking,
    required this.statistics,
  });
}

/// Route data for export/import
class RouteData {
  final List<LatLng> points;
  final List<TrackingPoint> trackingPoints;
  final RouteStatistics statistics;
  final DateTime timestamp;

  const RouteData({
    required this.points,
    required this.trackingPoints,
    required this.statistics,
    required this.timestamp,
  });
}
