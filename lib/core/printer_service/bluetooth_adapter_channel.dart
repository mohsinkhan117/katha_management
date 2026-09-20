// lib/core/service/bluetooth_adapter_channel.dart

import 'package:flutter/services.dart';

/// Talks directly to the two extra native methods added to the (locally
/// patched) `unified_esc_pos_printer` plugin — `btIsEnabled`/
/// `btOpenSettings` — for checking whether the Bluetooth radio itself is on
/// and, if not, sending the user to the OS Bluetooth toggle screen.
///
/// The package has no public API for this (only permission checks, not
/// adapter power state), and its own Dart wrapper class isn't exported by
/// its public barrel file, so this uses the same method channel name
/// directly rather than depending on unexported package internals.
class BluetoothAdapterChannel {
  BluetoothAdapterChannel._();

  static const MethodChannel _channel = MethodChannel(
    'com.elriztechnology.unified_esc_pos_printer/methods',
  );

  static Future<bool> isEnabled() async {
    return await _channel.invokeMethod<bool>('btIsEnabled') ?? false;
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod<void>('btOpenSettings');
  }
}
