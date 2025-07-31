import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Production-ready animated location marker for million-dollar app quality
class AnimatedLocationMarker extends StatefulWidget {
  final Color primaryColor;
  final Color? rippleColor;
  final double size;
  final bool isTracking;
  final IconData icon;
  final VoidCallback? onTap;

  const AnimatedLocationMarker({
    super.key,
    required this.primaryColor,
    this.rippleColor,
    this.size = 32.0,
    this.isTracking = false,
    this.icon = Icons.my_location,
    this.onTap,
  });

  Color get effectiveRippleColor => rippleColor ?? primaryColor;

  @override
  State<AnimatedLocationMarker> createState() => _AnimatedLocationMarkerState();
}

class _AnimatedLocationMarkerState extends State<AnimatedLocationMarker>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _dropController;
  late AnimationController _rotationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _dropAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for continuous heartbeat effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Ripple animation for tracking state
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Drop animation for initial appearance
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Rotation animation for dynamic feel
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Create animations
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _dropAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.bounceOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    // Drop in effect when marker appears
    _dropController.forward();

    // Continuous pulse
    _pulseController.repeat(reverse: true);

    // Tracking-specific animations
    if (widget.isTracking) {
      _rippleController.repeat();
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTracking != oldWidget.isTracking) {
      if (widget.isTracking) {
        _rippleController.repeat();
        _rotationController.repeat();
      } else {
        _rippleController.stop();
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _dropController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _rippleController,
          _dropController,
          _rotationController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _dropAnimation.value),
            child: SizedBox(
              width: widget.size * 3,
              height: widget.size * 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple effect (only when tracking)
                  if (widget.isTracking) ...[
                    _buildRipple(widget.size * 2.5, 0.1),
                    _buildRipple(widget.size * 2.0, 0.2),
                    _buildRipple(widget.size * 1.5, 0.3),
                  ],

                  // Main marker container with shadow
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.primaryColor,
                            widget.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: widget.isTracking ? _rotationAnimation.value : 0,
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: widget.size * 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Accuracy circle (subtle)
                  Container(
                    width: widget.size * 1.8,
                    height: widget.size * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRipple(double size, double opacity) {
    return Transform.scale(
      scale: _rippleAnimation.value,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.effectiveRippleColor.withOpacity(
              opacity * (1 - _rippleAnimation.value),
            ),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Modern floating action button for map controls
class AnimatedMapFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final String tooltip;
  final bool isLoading;

  const AnimatedMapFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.tooltip = '',
    this.isLoading = false,
  });

  @override
  State<AnimatedMapFAB> createState() => _AnimatedMapFABState();
}

class _AnimatedMapFABState extends State<AnimatedMapFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isPressed ? 0.4 : 0.2),
                      blurRadius: _isPressed ? 6 : 12,
                      offset: Offset(0, _isPressed ? 2 : 6),
                    ),
                  ],
                ),
                child: widget.isLoading
                    ? Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          Icons.refresh,
                          color: widget.iconColor,
                          size: 24,
                        ),
                      )
                    : Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shimmer loading effect for map initialization
class MapShimmerLoader extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;
  final String message;

  const MapShimmerLoader({
    super.key,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.message = 'Loading map...',
  });

  @override
  State<MapShimmerLoader> createState() => _MapShimmerLoaderState();
}

class _MapShimmerLoaderState extends State<MapShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: [
                  math.max(0.0, _animation.value - 0.3),
                  _animation.value,
                  math.min(1.0, _animation.value + 0.3),
                ],
              ).createShader(bounds);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
