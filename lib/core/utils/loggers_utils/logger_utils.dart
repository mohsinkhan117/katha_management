// lib/core/utils/loggers_utils/logger_utils.dart

import 'package:intl/intl.dart';

class LoggerUtils {
  static void logInfo(String tag, String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    print('🟢 [INFO] [$timestamp] [$tag] $message');
  }

  static void logWarning(String tag, String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    print('🟠 [WARNING] [$timestamp] [$tag] $message');
  }

  static void logError(String tag, String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    print('🔴 [ERROR] [$timestamp] [$tag] $message');
  }

  static void logSuccess(String tag, String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    print('✅ [SUCCESS] [$timestamp] [$tag] $message');
  }

  static void logDebug(String tag, String message, {dynamic data}) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    print('🪲 [DEBUG] [$timestamp] [$tag] $message');
    if (data != null) {
      print('🪲 [DEBUG DATA] $data');
    }
  }

  static void logLargeString(String tag, String message) {
    const chunkSize = 800; // Split the message into smaller chunks
    for (var i = 0; i < message.length; i += chunkSize) {
      final end =
          (i + chunkSize < message.length) ? i + chunkSize : message.length;
      logInfo(tag, message.substring(i, end)); // Use logInfo for logging
    }
  }
}
