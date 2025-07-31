import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../theme/global_theme.dart';

/// Simple interactive map widget for fitness tracking
class InteractiveMapWidget extends StatefulWidget {
  final bool showCurrentLocation;
  final bool showRoute;
  final bool enableTracking;
  final Function(LatLng)? onLocationTap;
  final Color? routeColor;
  final Color? accentColor;

  const InteractiveMapWidget({
    super.key,
    this.showCurrentLocation = true,
    this.showRoute = true,
    this.enableTracking = false,
    this.onLocationTap,
    this.routeColor,
    this.accentColor,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget>
    with TickerProviderStateMixin {
  late MapController _mapController;
  late AnimationController _pulseController;
  late AnimationController _mapRevealController;
  late AnimationController _loadingController;
  late AnimationController _interactionController;

  // Enhanced animations for better UX
  late Animation<double> _mapRevealAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  // State
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isMapReady = false;
  bool _isMapControllerReady = false;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers with staggered timing
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _mapRevealController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _interactionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize sophisticated animations
    _mapRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapRevealController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mapRevealController,
            curve: Curves.easeOutCubic,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mapRevealController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _mapRevealController, curve: Curves.easeOutBack),
    );

    // Initialize map controller
    _mapController = MapController();
    _isMapControllerReady = true;

    // Delay map initialization to ensure proper widget tree setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapRevealController.dispose();
    _loadingController.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      debugPrint('🗺️ MapWidget: Starting map initialization...');

      // Start loading animation for better UX
      if (mounted) {
        _loadingController.repeat(reverse: true);
      }

      // Simulate service initialization with realistic timing
      await Future.delayed(const Duration(milliseconds: 800));

      // Set default location and route points
      setState(() {
        _currentLocation = const LatLng(51.5074, -0.1278); // London
        _routePoints = [
          const LatLng(51.5074, -0.1278),
          const LatLng(51.5084, -0.1288),
          const LatLng(51.5094, -0.1298),
        ];
        _isLoading = false;
        _isMapReady = true;
      });

      // Start reveal animation with slight delay for smoother transition
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        _mapRevealController.forward();
        _pulseController.repeat(reverse: true);
        _loadingController.stop();
      }

      debugPrint('✅ MapWidget: Map initialization completed successfully');
    } catch (e) {
      debugPrint('❌ MapWidget: Error during initialization - $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize map. Please try again.';
        });
        _loadingController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? GlobalTheme.primaryNeon;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale:
              1.0 +
              (_pulseController.value * 0.002), // Very subtle breathing effect
          child: Container(
            height: screenHeight * 0.8, // Improved height ratio
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                28,
              ), // Increased for modern feel
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GlobalTheme.backgroundPrimary.withOpacity(0.95),
                  GlobalTheme.backgroundSecondary.withOpacity(0.98),
                  Colors.black.withOpacity(0.05),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                // Primary shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 20),
                ),
                // Accent glow effect with subtle animation
                BoxShadow(
                  color: accent.withOpacity(
                    0.15 + (_pulseController.value * 0.05),
                  ),
                  blurRadius: 80,
                  spreadRadius: 5,
                  offset: const Offset(0, 40),
                ),
                // Inner highlight
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
              border: Border.all(
                color: accent.withOpacity(0.2 + (_pulseController.value * 0.1)),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Enhanced backdrop with sophisticated glassmorphism effect
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.02),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Safety fallback layer when map has no data
                  if (!_isMapReady && !_isLoading && !_hasError)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GlobalTheme.backgroundPrimary.withOpacity(0.9),
                            GlobalTheme.backgroundSecondary.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent.withOpacity(0.2),
                                        accent.withOpacity(0.1),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accent.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.map_outlined,
                                    size: 48,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Map Ready',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: GlobalTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to explore your route',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: GlobalTheme.textSecondary
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Map layer with sophisticated reveal animation
                  if (_isMapReady && !_hasError)
                    AnimatedBuilder(
                      animation: _mapRevealController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: FadeTransition(
                              opacity: _mapRevealAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: _buildMap(accent),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Top overlay with timer and stats
                  _buildTopOverlay(theme, accent),

                  // Enhanced loading state with polished glassmorphism
                  if (_isLoading)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GlobalTheme.backgroundPrimary.withOpacity(0.95),
                            GlobalTheme.backgroundSecondary.withOpacity(0.9),
                            Colors.black.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Enhanced loading container with gradient and animation
                                AnimatedBuilder(
                                  animation: _loadingController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1.0 +
                                          (_loadingController.value * 0.1),
                                      child: Container(
                                        padding: const EdgeInsets.all(28),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accent.withOpacity(0.3),
                                              accent.withOpacity(0.1),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: accent.withOpacity(0.4),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accent.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 5,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.gps_fixed,
                                          size: 52,
                                          color: accent,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Text(
                                      'Initializing GPS...',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Enhanced circular progress indicator
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accent.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: CircularProgressIndicator(
                                    color: accent,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Error state
                  if (_hasError)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            GlobalTheme.backgroundPrimary,
                            GlobalTheme.statusError.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: GlobalTheme.statusError.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 48,
                                color: GlobalTheme.statusError,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Map Error',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: GlobalTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: GlobalTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasError = false;
                                  _isMapReady = false;
                                });
                                _initializeMap();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Map controls overlay - properly positioned
                  if (_isMapReady && !_hasError) _buildMapControls(accent),

                  // Bottom control bar
                  if (_isMapReady && !_hasError)
                    _buildBottomControls(theme, accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMap(Color accent) {
    try {
      // Safety check for map controller
      if (!_isMapControllerReady) {
        return _buildMapFallback(accent);
      }

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Enhanced FlutterMap with improved error handling
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentLocation ?? const LatLng(51.5074, -0.1278),
                  initialZoom: 15.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, point) {
                    if (widget.onLocationTap != null) {
                      widget.onLocationTap!(point);
                    }
                  },
                  onMapReady: () {
                    debugPrint('✅ MapWidget: FlutterMap is ready');
                    // Start loading animation
                    if (mounted) {
                      _loadingController.repeat(reverse: true);
                    }
                  },
                ),
                children: [
                  // Base map tiles with enhanced loading
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fitness.mobile',
                    // Enhanced tile display options for better loading experience
                    tileDisplay: const TileDisplay.fadeIn(
                      duration: Duration(milliseconds: 300),
                    ),
                  ),

                  // Route polylines with enhanced styling
                  if (widget.showRoute && _routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        // Enhanced route polyline with better styling
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: widget.routeColor ?? accent,
                        ),
                        // Shadow polyline for depth
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 8.0,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),

                  // Enhanced marker layers
                  if (widget.showCurrentLocation && _currentLocation != null)
                    MarkerLayer(
                      markers: [
                        // Current location marker with advanced animation
                        Marker(
                          point: _currentLocation!,
                          width: 60,
                          height: 60,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              // Create multiple pulse rings with different delays
                              return Stack(
                                alignment: Alignment.center,
                                children:
                                    List.generate(3, (index) {
                                      final delay = index * 0.3;
                                      return AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          final progress =
                                              (_pulseController.value + delay) %
                                              1.0;
                                          return Transform.scale(
                                            scale: 0.5 + (progress * 1.5),
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: accent.withOpacity(
                                                    0.6 - (progress * 0.6),
                                                  ),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    })..add(
                                      // Center marker
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accent,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Enhanced glassmorphism overlay with better blur effects
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ MapWidget: Error building map - $e');
      return _buildMapFallback(accent);
    }
  }

  Widget _buildMapFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GlobalTheme.backgroundPrimary.withOpacity(0.9),
            GlobalTheme.backgroundSecondary.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.2),
                          accent.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.map_outlined, size: 48, color: accent),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Map Ready',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: GlobalTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to explore your route',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GlobalTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay(ThemeData theme, Color accent) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('00:15:32', 'TIME', accent),
                _buildStatCard('1.2 km', 'DISTANCE', accent),
                _buildStatCard('125', 'AVG BPM', accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(Color accent) {
    return Positioned(
      right: 16,
      top: 140,
      child: Column(
        children: [
          // Current location button
          if (_currentLocation != null)
            _buildMapControlButton(
              icon: _isLocationLoading
                  ? Icons.gps_not_fixed
                  : Icons.my_location,
              onPressed: _centerOnCurrentLocation,
              tooltip: 'Center on Location',
              accent: accent,
              isLoading: _isLocationLoading,
            ),
          const SizedBox(height: 12),
          // Fit to route button
          if (_routePoints.isNotEmpty)
            _buildMapControlButton(
              icon: Icons.zoom_out_map,
              onPressed: _fitToRoute,
              tooltip: 'Fit to Route',
              accent: accent,
              isLoading: _isLocationLoading,
            ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color accent,
    bool isLoading = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading
              ? null
              : () {
                  onPressed();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tooltip),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    )
                  : Icon(icon, color: accent, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, Color accent) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  onPressed: () {},
                  accent: accent,
                  isPrimary: true,
                ),
                _buildBottomButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onPressed: () {},
                  accent: accent,
                ),
                _buildBottomButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  onPressed: () {},
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color accent,
    bool isPrimary = false,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.02),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(colors: [accent, accent.withOpacity(0.8)])
                  : LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary
                    ? Colors.white.withOpacity(0.3)
                    : accent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPrimary ? accent : Colors.black).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _interactionController.forward().then((_) {
                    _interactionController.reverse();
                  });
                  onPressed();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: AnimatedBuilder(
                    animation: _interactionController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 - (_interactionController.value * 0.1),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: isPrimary ? Colors.black : accent,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: isPrimary ? Colors.black : accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null && _isMapControllerReady) {
      setState(() => _isLocationLoading = true);

      _mapController.move(_currentLocation!, 16.0);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLocationLoading = false);
        }
      });
    }
  }

  void _fitToRoute() {
    if (_routePoints.isNotEmpty && _isMapControllerReady) {
      setState(() => _isLocationLoading = true);

      // Calculate bounds for route points
      double minLat = _routePoints.first.latitude;
      double maxLat = _routePoints.first.latitude;
      double minLng = _routePoints.first.longitude;
      double maxLng = _routePoints.first.longitude;

      for (final point in _routePoints) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLocationLoading = false);
        }
      });
    }
  }
}
