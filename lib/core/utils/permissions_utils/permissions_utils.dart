// lib/core/utils/permissions_utils/permissions_utils.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:katha_management/core/utils/loggers_utils/logger_utils.dart';

import 'dart:io';

class PermissionUtils {
  static Future<bool> cameraMicrophoneAndStoragePermissionGranted() async {
    PermissionStatus cameraPermissionStatus = await getCameraPermission();
    PermissionStatus storagePermissionStatus = await getStoragePermission();
    PermissionStatus microphonePermissionStatus =
        await getMicrophonePermission();

    if (cameraPermissionStatus == PermissionStatus.granted &&
        microphonePermissionStatus == PermissionStatus.granted &&
        storagePermissionStatus == PermissionStatus.granted) {
      return true;
    } else {
      _handleInvalidPermission(
        cameraPermissionStatus,
        microphonePermissionStatus,
        storagePermissionStatus,
      );
      return false;
    }
  }

  static Future<PermissionStatus> getCameraPermission() async {
    var status = await Permission.camera.status;
    if (status == PermissionStatus.denied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
      ].request();
      return statuses[Permission.camera] ?? PermissionStatus.limited;
    } else {
      return status;
    }
  }

  static Future<PermissionStatus> getMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status == PermissionStatus.denied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
      ].request();
      return statuses[Permission.microphone] ?? PermissionStatus.limited;
    } else {
      return status;
    }
  }

  static Future<PermissionStatus> getStoragePermission() async {
    // Use different permissions based on platform and Android version
    Permission storagePermission;

    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use photos permission for reading media
      // For older versions, use storage permission
      storagePermission = Permission.photos;
    } else {
      // For iOS, use photos permission
      storagePermission = Permission.photos;
    }

    var status = await storagePermission.status;
    if (status == PermissionStatus.denied) {
      Map<Permission, PermissionStatus> statuses = await [
        storagePermission,
      ].request();
      return statuses[storagePermission] ?? PermissionStatus.limited;
    } else {
      return status;
    }
  }

  static void _handleInvalidPermission(
    PermissionStatus cameraPermissionStatus,
    PermissionStatus microphonePermissionStatus,
    PermissionStatus storagePermissionStatus,
  ) {
    if (cameraPermissionStatus == PermissionStatus.denied &&
        microphonePermissionStatus == PermissionStatus.denied) {
      throw PlatformException(
        code: "PERMISSION_DENIED",
        message: "Access to Camera and Microphone denied",
        details: "null",
      );
    } else if (cameraPermissionStatus == PermissionStatus.restricted &&
        microphonePermissionStatus == PermissionStatus.restricted) {
      throw PlatformException(
        code: "PERMISSION_RESTRICTED",
        message: "Location data is not available on device",
        details: "null",
      );
    } else if (storagePermissionStatus == PermissionStatus.restricted &&
        storagePermissionStatus == PermissionStatus.restricted) {
      throw PlatformException(
        code: "PERMISSION_RESTRICTED",
        message: "Storage permission is not allowed on device",
        details: "null",
      );
    }
  }

  static Future<PermissionResult> checkAndRequestStoragePermissions() async {
    try {
      Permission storagePermission;

      if (Platform.isAndroid) {
        // For Android, try photos permission first (Android 13+)
        storagePermission = Permission.photos;
      } else {
        // For iOS, use photos permission
        storagePermission = Permission.photos;
      }

      PermissionStatus status = await storagePermission.status;

      // If already granted, return early
      if (status.isGranted) {
        return PermissionResult(
          granted: true,
          isPermanentlyDenied: false,
          message: 'Storage permission granted',
        );
      }

      // If not permanently denied, request permission
      if (!status.isPermanentlyDenied) {
        status = await storagePermission.request();

        if (status.isGranted) {
          return PermissionResult(
            granted: true,
            isPermanentlyDenied: false,
            message: 'Storage permission granted',
          );
        } else if (status.isPermanentlyDenied) {
          return PermissionResult(
            granted: false,
            isPermanentlyDenied: true,
            message:
                'Storage permission permanently denied. Please enable in settings.',
          );
        } else {
          return PermissionResult(
            granted: false,
            isPermanentlyDenied: false,
            message: 'Storage permission denied',
          );
        }
      } else {
        return PermissionResult(
          granted: false,
          isPermanentlyDenied: true,
          message:
              'Storage permission permanently denied. Please enable in settings.',
        );
      }
    } catch (e) {
      return PermissionResult(
        granted: false,
        isPermanentlyDenied: false,
        message: 'Error checking storage permissions: ${e.toString()}',
      );
    }
  }

  static const _bluetoothPermTag = 'PermissionUtils.bluetooth';

  /// Requests Bluetooth permissions needed for printer scan/connect.
  ///
  /// `Permission.bluetoothScan`/`bluetoothConnect` are declared unconditionally
  /// in the manifest, so on Android below API 31 (where those permission
  /// strings don't exist as a runtime concept) permission_handler auto-resolves
  /// them as granted with no dialog.
  ///
  /// `Permission.location` is different: the manifest declares
  /// `ACCESS_FINE_LOCATION` with `maxSdkVersion="30"` (matching the tech spec —
  /// API 31+ doesn't need it since `BLUETOOTH_SCAN` is declared with
  /// `neverForLocation`), so on API 31+ that permission is genuinely NOT
  /// declared at all, and permission_handler always resolves it to `denied`
  /// there — never granted, no dialog. So `location` must NOT be required for
  /// [PermissionResult.granted] to be true, or Bluetooth would be permanently
  /// blocked on every Android 12+ device. It's still requested best-effort,
  /// since Bluetooth Classic discovery genuinely needs it on API < 31.
  static Future<PermissionResult> checkAndRequestBluetoothPermissions() async {
    try {
      if (!Platform.isAndroid) {
        return PermissionResult(
          granted: true,
          isPermanentlyDenied: false,
          message: 'No runtime Bluetooth permission needed on this platform',
        );
      }

      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      for (final entry in statuses.entries) {
        LoggerUtils.logDebug(
          _bluetoothPermTag,
          '${entry.key} -> ${entry.value}',
        );
      }

      final PermissionStatus scanStatus =
          statuses[Permission.bluetoothScan] ?? PermissionStatus.granted;
      final PermissionStatus connectStatus =
          statuses[Permission.bluetoothConnect] ?? PermissionStatus.granted;

      final bool coreGranted = scanStatus.isGranted && connectStatus.isGranted;
      final bool corePermanentlyDenied =
          scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied;

      if (coreGranted) {
        return PermissionResult(
          granted: true,
          isPermanentlyDenied: false,
          message: 'Bluetooth permissions granted',
        );
      } else if (corePermanentlyDenied) {
        return PermissionResult(
          granted: false,
          isPermanentlyDenied: true,
          message:
              'Bluetooth permissions permanently denied. Please enable in settings.',
        );
      } else {
        return PermissionResult(
          granted: false,
          isPermanentlyDenied: false,
          message: 'Bluetooth permissions denied',
        );
      }
    } catch (e) {
      LoggerUtils.logError(
        _bluetoothPermTag,
        'Error requesting Bluetooth permissions: $e',
      );
      return PermissionResult(
        granted: false,
        isPermanentlyDenied: false,
        message: 'Error requesting Bluetooth permissions: ${e.toString()}',
      );
    }
  }

  static Future<PermissionResult> checkAndRequestPermissions() async {
    try {
      // Check for photos permission instead of storage on newer Android versions
      PermissionStatus cameraStatus = await Permission.camera.status;
      PermissionStatus storageStatus = await Permission.photos.status;

      // If already granted, return early
      if (cameraStatus.isGranted && storageStatus.isGranted) {
        return PermissionResult(
          granted: true,
          isPermanentlyDenied: false,
          message: 'All permissions granted',
        );
      }

      // If not permanently denied, request permissions
      if (!cameraStatus.isPermanentlyDenied &&
          !storageStatus.isPermanentlyDenied) {
        // Request permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.camera,
          Permission.photos,
        ].request();

        // Check results after requesting
        bool allGranted = statuses.values.every((status) => status.isGranted);
        bool anyPermanentlyDenied = statuses.values.any(
          (status) => status.isPermanentlyDenied,
        );

        if (allGranted) {
          return PermissionResult(
            granted: true,
            isPermanentlyDenied: false,
            message: 'All permissions granted',
          );
        } else if (anyPermanentlyDenied) {
          return PermissionResult(
            granted: false,
            isPermanentlyDenied: true,
            message:
                'Permissions permanently denied. Please enable in settings.',
          );
        } else {
          return PermissionResult(
            granted: false,
            isPermanentlyDenied: false,
            message: 'Required permissions not granted',
          );
        }
      } else {
        // Handle permanently denied case
        return PermissionResult(
          granted: false,
          isPermanentlyDenied: true,
          message: 'Permissions permanently denied. Please enable in settings.',
        );
      }
    } catch (e) {
      return PermissionResult(
        granted: false,
        isPermanentlyDenied: false,
        message: 'Error checking permissions: ${e.toString()}',
      );
    }
  }
}

// ======================== PermissionResult ========================
class PermissionResult {
  final bool granted;
  final bool isPermanentlyDenied;
  final String message;

  PermissionResult({
    required this.granted,
    required this.isPermanentlyDenied,
    required this.message,
  });
}
