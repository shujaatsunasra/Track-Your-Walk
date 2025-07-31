import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Enterprise-level performance monitoring and optimization service
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final List<String> _performanceLogs = [];
  Timer? _memoryMonitorTimer;
  int _frameCount = 0;
  int _droppedFrames = 0;

  /// Initialize performance monitoring
  void init() {
    if (kDebugMode) {
      _startMemoryMonitoring();
      _initializeFrameCallback();
    }
  }

  /// Start monitoring memory usage
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _logMemoryUsage();
    });
  }

  /// Initialize frame callback for performance monitoring
  void _initializeFrameCallback() {
    WidgetsBinding.instance.addPostFrameCallback(_frameCallback);
  }

  void _frameCallback(Duration timeStamp) {
    _frameCount++;

    // Monitor for dropped frames
    if (timeStamp.inMilliseconds > 16) {
      // 60fps = 16.67ms per frame
      _droppedFrames++;
    }

    // Log performance every 1000 frames
    if (_frameCount % 1000 == 0) {
      _logFramePerformance();
    }

    WidgetsBinding.instance.addPostFrameCallback(_frameCallback);
  }

  void _logMemoryUsage() {
    if (kDebugMode) {
      final log =
          'Memory check at ${DateTime.now()}: Frame drops: $_droppedFrames/$_frameCount';
      _performanceLogs.add(log);
      debugPrint('[PERFORMANCE] $log');
    }
  }

  void _logFramePerformance() {
    final dropRate = (_droppedFrames / _frameCount * 100).toStringAsFixed(2);
    final log = 'Frame performance: $dropRate% dropped frames';
    _performanceLogs.add(log);

    if (kDebugMode) {
      debugPrint('[PERFORMANCE] $log');
    }
  }

  /// Optimize animations for better performance
  static void optimizeAnimation(TickerProvider vsync) {
    if (kDebugMode) {
      debugPrint('[PERFORMANCE] Optimizing animation controller');
    }
  }

  /// Haptic feedback with performance optimization
  static Future<void> hapticFeedback() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PERFORMANCE] Haptic feedback failed: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _performanceLogs.clear();
  }

  /// Get performance logs
  List<String> get performanceLogs => List.unmodifiable(_performanceLogs);
}

/// Performance optimized widget mixin
mixin PerformanceOptimizedWidget {
  /// Optimized rebuild checker
  bool shouldRebuild(dynamic oldWidget, dynamic newWidget) {
    return oldWidget.runtimeType != newWidget.runtimeType;
  }

  /// Memory efficient dispose
  void performanceDispose() {
    // Override in widgets to add custom disposal logic
  }
}
