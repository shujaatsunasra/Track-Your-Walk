import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enterprise-level logging system
/// Provides comprehensive logging, analytics, and error tracking
class EnterpriseLogger {
  static final EnterpriseLogger _instance = EnterpriseLogger._internal();
  factory EnterpriseLogger() => _instance;
  EnterpriseLogger._internal();

  // Log storage with size limits
  final Queue<LogEntry> _logs = Queue<LogEntry>();
  static const int maxLogEntries = 1000;

  // Performance metrics
  int _totalErrors = 0;
  int _totalWarnings = 0;
  int _totalInfo = 0;
  DateTime? _sessionStartTime;

  /// Initialize logging system
  void initialize() {
    _sessionStartTime = DateTime.now();

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      logError('Flutter Error', details.exception, details.stack);
    };

    // Set up platform dispatcher error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      logError('Platform Error', error, stack);
      return true;
    };

    logInfo('Enterprise Logger', 'Logging system initialized');
  }

  /// Log error with stack trace
  void logError(String category, dynamic error, StackTrace? stackTrace) {
    _totalErrors++;
    final entry = LogEntry(
      level: LogLevel.error,
      category: category,
      message: error.toString(),
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );

    _addLog(entry);

    if (kDebugMode) {
      debugPrint('🔴 [ERROR] [$category] ${error.toString()}');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log warning
  void logWarning(
    String category,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    _totalWarnings++;
    final entry = LogEntry(
      level: LogLevel.warning,
      category: category,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _addLog(entry);

    if (kDebugMode) {
      debugPrint('🟡 [WARNING] [$category] $message');
    }
  }

  /// Log info
  void logInfo(
    String category,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    _totalInfo++;
    final entry = LogEntry(
      level: LogLevel.info,
      category: category,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _addLog(entry);

    if (kDebugMode) {
      debugPrint('🔵 [INFO] [$category] $message');
    }
  }

  /// Log performance metrics
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final performanceData = {
      'duration_ms': duration.inMilliseconds,
      'operation': operation,
      ...?metadata,
    };

    logInfo(
      'Performance',
      '$operation completed in ${duration.inMilliseconds}ms',
      metadata: performanceData,
    );
  }

  /// Log user interaction
  void logUserInteraction(
    String action,
    String screen, {
    Map<String, dynamic>? metadata,
  }) {
    final interactionData = {
      'action': action,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };

    logInfo(
      'User Interaction',
      '$action on $screen',
      metadata: interactionData,
    );
  }

  /// Log navigation events
  void logNavigation(String from, String to, {Duration? duration}) {
    final navigationData = {
      'from': from,
      'to': to,
      'navigation_time': DateTime.now().toIso8601String(),
      if (duration != null) 'duration_ms': duration.inMilliseconds,
    };

    logInfo(
      'Navigation',
      'Navigated from $from to $to',
      metadata: navigationData,
    );
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get logs by category
  List<LogEntry> getLogsByCategory(String category) {
    return _logs.where((log) => log.category == category).toList();
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs([int count = 50]) {
    final logList = _logs.toList();
    return logList.take(count).toList();
  }

  /// Get session statistics
  SessionStatistics getSessionStatistics() {
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;

    return SessionStatistics(
      sessionDuration: sessionDuration,
      totalLogs: _logs.length,
      totalErrors: _totalErrors,
      totalWarnings: _totalWarnings,
      totalInfo: _totalInfo,
      sessionStart: _sessionStartTime,
    );
  }

  /// Export logs for analysis
  String exportLogs({LogLevel? level, String? category}) {
    var logsToExport = _logs.toList();

    if (level != null) {
      logsToExport = logsToExport.where((log) => log.level == level).toList();
    }

    if (category != null) {
      logsToExport = logsToExport
          .where((log) => log.category == category)
          .toList();
    }

    final buffer = StringBuffer();
    buffer.writeln('=== FITNESS MOBILE APP LOGS ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total logs: ${logsToExport.length}');
    buffer.writeln('');

    for (final log in logsToExport) {
      buffer.writeln(log.toString());
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Clear old logs to manage memory
  void clearOldLogs() {
    while (_logs.length > maxLogEntries) {
      _logs.removeFirst();
    }
  }

  /// Private helper methods
  void _addLog(LogEntry entry) {
    _logs.addLast(entry);

    // Manage memory by removing old logs
    if (_logs.length > maxLogEntries) {
      _logs.removeFirst();
    }
  }

  /// Dispose logger
  void dispose() {
    _logs.clear();
    logInfo('Enterprise Logger', 'Logger disposed');
  }
}

/// Log levels for categorization
enum LogLevel { error, warning, info, debug }

/// Log entry with comprehensive metadata
class LogEntry {
  final LogLevel level;
  final String category;
  final String message;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.metadata,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[$category] ');
    buffer.write(message);

    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write(' | Metadata: $metadata');
    }

    if (stackTrace != null) {
      buffer.write('\nStack trace: $stackTrace');
    }

    return buffer.toString();
  }
}

/// Session statistics for monitoring
class SessionStatistics {
  final Duration sessionDuration;
  final int totalLogs;
  final int totalErrors;
  final int totalWarnings;
  final int totalInfo;
  final DateTime? sessionStart;

  const SessionStatistics({
    required this.sessionDuration,
    required this.totalLogs,
    required this.totalErrors,
    required this.totalWarnings,
    required this.totalInfo,
    this.sessionStart,
  });

  double get errorRate => totalLogs > 0 ? (totalErrors / totalLogs) : 0.0;
  double get warningRate => totalLogs > 0 ? (totalWarnings / totalLogs) : 0.0;

  @override
  String toString() {
    return 'SessionStats('
        'duration: ${sessionDuration.inMinutes}min, '
        'logs: $totalLogs, '
        'errors: $totalErrors, '
        'warnings: $totalWarnings, '
        'error rate: ${(errorRate * 100).toStringAsFixed(1)}%)';
  }
}
