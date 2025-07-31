import 'package:flutter/services.dart';

/// Simple haptic feedback service to replace MobileServiceManager
class HapticService {
  /// Provides fitness-related haptic feedback
  static Future<void> fitnessHaptic([String? type]) async {
    try {
      if (type == 'heavy') {
        await HapticFeedback.heavyImpact();
      } else if (type == 'medium') {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }
}
