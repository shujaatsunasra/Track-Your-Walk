import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../models/fitness_models.dart';

/// Real-time animated route tracking with smooth updates
class RealTimeRouteTracker extends StatefulWidget {
  final List<LatLng> routePoints;
  final LatLng? currentLocation;
  final ActivityType activityType;
  final Color routeColor;
  final double routeWidth;
  final bool showPaceVariation;
  final List<double>? paceData; // pace in minutes per km
  final MapController mapController;
  final bool followUser;
  final Function(LatLng)? onLocationUpdate;

  const RealTimeRouteTracker({
    super.key,
    required this.routePoints,
    this.currentLocation,
    required this.activityType,
    required this.routeColor,
    this.routeWidth = 4.0,
    this.showPaceVariation = true,
    this.paceData,
    required this.mapController,
    this.followUser = true,
    this.onLocationUpdate,
  });

  @override
  State<RealTimeRouteTracker> createState() => _RealTimeRouteTrackerState();
}

class _RealTimeRouteTrackerState extends State<RealTimeRouteTracker>
    with TickerProviderStateMixin {
  late AnimationController _routeController;
  late AnimationController _cameraController;
  late Animation<double> _routeAnimation;

  List<LatLng> _animatedPoints = [];
  int _lastPointCount = 0;

  @override
  void initState() {
    super.initState();

    _routeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cameraController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeController, curve: Curves.easeOutCubic),
    );

    _animatedPoints = List.from(widget.routePoints);
    _lastPointCount = widget.routePoints.length;

    _routeController.addListener(_updateRoute);
  }

  @override
  void didUpdateWidget(RealTimeRouteTracker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if new points were added
    if (widget.routePoints.length > _lastPointCount) {
      _animateNewPoints();
    }

    // Update camera position if following user
    if (widget.followUser &&
        widget.currentLocation != null &&
        widget.currentLocation != oldWidget.currentLocation) {
      _smoothCameraUpdate();
    }
  }

  void _animateNewPoints() {
    _lastPointCount = widget.routePoints.length;
    _routeController.reset();
    _routeController.forward();
  }

  void _updateRoute() {
    if (_routeAnimation.value < 1.0) {
      final targetLength = widget.routePoints.length;
      final currentLength =
          (_lastPointCount +
                  (targetLength - _lastPointCount) * _routeAnimation.value)
              .round();

      setState(() {
        _animatedPoints = widget.routePoints.take(currentLength).toList();
      });
    }
  }

  void _smoothCameraUpdate() {
    if (widget.currentLocation == null) return;

    final currentZoom = widget.mapController.camera.zoom;
    final targetZoom = _getOptimalZoom();

    // Smooth camera movement
    _cameraController.reset();
    _cameraController.forward().then((_) {
      widget.mapController.move(
        widget.currentLocation!,
        math.max(currentZoom, targetZoom),
      );
    });
  }

  double _getOptimalZoom() {
    switch (widget.activityType) {
      case ActivityType.running:
        return 17.0;
      case ActivityType.cycling:
        return 15.0;
      case ActivityType.hiking:
        return 16.0;
      case ActivityType.walking:
        return 18.0;
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _routeAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Main route line
            if (_animatedPoints.isNotEmpty)
              AnimatedRoutePolyline(
                points: _animatedPoints,
                color: widget.routeColor,
                width: widget.routeWidth,
                activityType: widget.activityType,
                paceData: widget.paceData,
                showPaceVariation: widget.showPaceVariation,
              ),

            // Progress indicator
            if (widget.currentLocation != null && _animatedPoints.isNotEmpty)
              RouteProgressIndicator(
                routePoints: _animatedPoints,
                currentLocation: widget.currentLocation!,
                routeColor: widget.routeColor,
              ),
          ],
        );
      },
    );
  }
}

/// Animated polyline with pace-based coloring
class AnimatedRoutePolyline extends StatelessWidget {
  final List<LatLng> points;
  final Color color;
  final double width;
  final ActivityType activityType;
  final List<double>? paceData;
  final bool showPaceVariation;

  const AnimatedRoutePolyline({
    super.key,
    required this.points,
    required this.color,
    required this.width,
    required this.activityType,
    this.paceData,
    this.showPaceVariation = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showPaceVariation ||
        paceData == null ||
        paceData!.length < points.length) {
      // Simple single-color route
      return PolylineLayer(
        polylines: [
          Polyline(
            points: points,
            strokeWidth: width,
            color: color,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],
      );
    }

    // Multi-colored route based on pace
    return PolylineLayer(polylines: _createPaceBasedPolylines());
  }

  List<Polyline> _createPaceBasedPolylines() {
    List<Polyline> polylines = [];

    for (int i = 0; i < points.length - 1; i++) {
      if (i < paceData!.length) {
        final pace = paceData![i];
        final segmentColor = _getPaceColor(pace);

        polylines.add(
          Polyline(
            points: [points[i], points[i + 1]],
            strokeWidth: width,
            color: segmentColor,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      }
    }

    return polylines;
  }

  Color _getPaceColor(double pace) {
    // Determine pace intensity (faster = green, slower = red)
    final normalizedPace = math.max(
      0.0,
      math.min(1.0, (pace - 3.0) / 7.0),
    ); // 3-10 min/km range

    if (normalizedPace < 0.33) {
      // Fast pace - bright green
      return const Color(0xFF00E676);
    } else if (normalizedPace < 0.67) {
      // Medium pace - yellow/orange
      return Color.lerp(
        const Color(0xFF00E676),
        const Color(0xFFFF9800),
        (normalizedPace - 0.33) / 0.34,
      )!;
    } else {
      // Slow pace - red
      return Color.lerp(
        const Color(0xFFFF9800),
        const Color(0xFFE53935),
        (normalizedPace - 0.67) / 0.33,
      )!;
    }
  }
}

/// Progress indicator showing user position on route
class RouteProgressIndicator extends StatefulWidget {
  final List<LatLng> routePoints;
  final LatLng currentLocation;
  final Color routeColor;

  const RouteProgressIndicator({
    super.key,
    required this.routePoints,
    required this.currentLocation,
    required this.routeColor,
  });

  @override
  State<RouteProgressIndicator> createState() => _RouteProgressIndicatorState();
}

class _RouteProgressIndicatorState extends State<RouteProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return MarkerLayer(
          markers: [
            // Progress indicator on route
            Marker(
              point: widget.currentLocation,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.routeColor,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.routeColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Smooth camera follow controller
class SmoothCameraController {
  final MapController mapController;
  final Duration animationDuration;

  SmoothCameraController({
    required this.mapController,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  void followUser(LatLng location, {double? targetZoom}) {
    final currentZoom = mapController.camera.zoom;
    final zoom = targetZoom ?? currentZoom;

    mapController.move(location, zoom);
  }

  void fitToRoute(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(50),
  }) {
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: padding));
  }

  void animateToLocation(LatLng location, double zoom) {
    mapController.move(location, zoom);
  }
}
