import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Cache entry types for categorization
enum CacheType { image, data, computed, animation }

/// Cache entry with metadata
class CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;
  final CacheType type;
  final int size;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
    required this.type,
    this.size = 1,
  });

  bool get isExpired => DateTime.now().isAfter(createdAt.add(ttl));
}

/// Enterprise-level cache management system
/// Provides intelligent caching for images, data, and computed values
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Multi-tier caching system
  final LinkedHashMap<String, CacheEntry> _memoryCache = LinkedHashMap();
  final Map<String, Timer> _expirationTimers = {};

  // Cache configuration
  static const int maxMemoryCacheSize = 100; // Maximum cache entries
  static const Duration defaultTtl = Duration(minutes: 30);
  static const Duration imageCacheTtl = Duration(hours: 2);
  static const Duration dataCacheTtl = Duration(minutes: 10);

  // Cache statistics for monitoring
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Store data in cache with automatic expiration
  void put<T>(
    String key,
    T data, {
    Duration? ttl,
    CacheType type = CacheType.data,
    int size = 1,
  }) {
    try {
      // Remove existing entry if present
      remove(key);

      // Ensure cache size limit
      _ensureCacheLimit();

      final entry = CacheEntry(
        data: data,
        createdAt: DateTime.now(),
        ttl: ttl ?? _getDefaultTtl(type),
        type: type,
        size: size,
      );

      _memoryCache[key] = entry;

      // Set expiration timer
      _setExpirationTimer(key, entry.ttl);

      if (kDebugMode) {
        print('CacheManager: Cached $key (${type.name}) TTL: ${entry.ttl}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheManager: Error caching $key: $e');
      }
    }
  }

  /// Retrieve data from cache
  T? get<T>(String key) {
    try {
      final entry = _memoryCache[key];

      if (entry == null) {
        _misses++;
        return null;
      }

      if (entry.isExpired) {
        remove(key);
        _misses++;
        return null;
      }

      // Move to end (LRU implementation)
      _memoryCache.remove(key);
      _memoryCache[key] = entry;

      _hits++;
      return entry.data as T?;
    } catch (e) {
      if (kDebugMode) {
        print('CacheManager: Error retrieving $key: $e');
      }
      _misses++;
      return null;
    }
  }

  /// Get or compute value with caching
  Future<T> getOrCompute<T>(
    String key,
    Future<T> Function() computer, {
    Duration? ttl,
    CacheType type = CacheType.computed,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    try {
      final computed = await computer();
      put(key, computed, ttl: ttl, type: type);
      return computed;
    } catch (e) {
      if (kDebugMode) {
        print('CacheManager: Error computing $key: $e');
      }
      rethrow;
    }
  }

  /// Remove specific entry from cache
  void remove(String key) {
    final removed = _memoryCache.remove(key);
    if (removed != null) {
      _cancelExpirationTimer(key);
      if (kDebugMode) {
        print('CacheManager: Removed $key from cache');
      }
    }
  }

  /// Clear all cache entries
  void clear() {
    _memoryCache.clear();
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
    _evictions = 0;

    if (kDebugMode) {
      print('CacheManager: Cache cleared');
    }
  }

  /// Clear cache by type
  void clearByType(CacheType type) {
    final keysToRemove = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.type == type) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      remove(key);
    }

    if (kDebugMode) {
      print(
        'CacheManager: Cleared ${keysToRemove.length} ${type.name} entries',
      );
    }
  }

  /// Get cache statistics
  CacheStatistics getStatistics() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests) : 0.0;

    return CacheStatistics(
      hits: _hits,
      misses: _misses,
      evictions: _evictions,
      hitRate: hitRate,
      size: _memoryCache.length,
      maxSize: maxMemoryCacheSize,
    );
  }

  /// Preload critical data
  Future<void> preloadCriticalData() async {
    try {
      // Preload commonly used assets or data
      if (kDebugMode) {
        print('CacheManager: Preloading critical data...');
      }

      // Example: Preload theme data
      put('app_theme', 'cached_theme_data', type: CacheType.data);

      // Example: Preload animation configurations
      put('animation_configs', {
        'fade_duration': 250,
        'slide_duration': 350,
        'bounce_curve': 'elasticOut',
      }, type: CacheType.animation);
    } catch (e) {
      if (kDebugMode) {
        print('CacheManager: Error preloading data: $e');
      }
    }
  }

  /// Optimize cache for memory pressure
  void optimizeForMemoryPressure() {
    // Remove expired entries
    final expiredKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      remove(key);
    }

    // If still over limit, remove oldest entries
    if (_memoryCache.length > maxMemoryCacheSize * 0.8) {
      final entriesToRemove = _memoryCache.length - (maxMemoryCacheSize ~/ 2);
      final keysToRemove = _memoryCache.keys.take(entriesToRemove).toList();

      for (final key in keysToRemove) {
        remove(key);
        _evictions++;
      }
    }

    if (kDebugMode) {
      print(
        'CacheManager: Optimized cache, removed ${expiredKeys.length} expired entries',
      );
    }
  }

  /// Private helper methods
  void _ensureCacheLimit() {
    if (_memoryCache.length >= maxMemoryCacheSize) {
      // Remove oldest entry (LRU)
      final oldestKey = _memoryCache.keys.first;
      remove(oldestKey);
      _evictions++;
    }
  }

  Duration _getDefaultTtl(CacheType type) {
    switch (type) {
      case CacheType.image:
        return imageCacheTtl;
      case CacheType.data:
        return dataCacheTtl;
      case CacheType.computed:
      case CacheType.animation:
        return defaultTtl;
    }
  }

  void _setExpirationTimer(String key, Duration ttl) {
    _expirationTimers[key] = Timer(ttl, () {
      remove(key);
    });
  }

  void _cancelExpirationTimer(String key) {
    final timer = _expirationTimers.remove(key);
    timer?.cancel();
  }
}

/// Cache statistics for monitoring
class CacheStatistics {
  final int hits;
  final int misses;
  final int evictions;
  final double hitRate;
  final int size;
  final int maxSize;

  const CacheStatistics({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.hitRate,
    required this.size,
    required this.maxSize,
  });

  @override
  String toString() {
    return 'CacheStats(hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, size: $size/$maxSize)';
  }
}
