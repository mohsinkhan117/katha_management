// lib/core/service/bluetooth_printer_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:katha_management/core/utils/loggers_utils/logger_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
// Not exported by the package's public barrel file — see the long comment
// on scan() below for why this app reaches past it anyway.
import 'package:unified_esc_pos_printer/src/platform/bluetooth_platform_channel.dart';

import 'bluetooth_adapter_channel.dart';
import 'printer_service.dart';

/// [PrinterService] backed by [PrinterManager], restricted to Bluetooth
/// Classic (SPP/RFCOMM) — the only transport this app targets per the
/// printing tech spec.
class BluetoothPrinterService implements PrinterService {
  BluetoothPrinterService({PrinterManager? manager})
    : _manager = manager ?? PrinterManager() {
    // Every RFCOMM connection lifecycle change flows through here, so this
    // single listener is the fastest way to see *why* a print/connect
    // failed (e.g. a remote disconnect shows up as connected -> error ->
    // disconnected even when no method call in this class threw).
    _manager.stateStream.listen((state) {
      LoggerUtils.logInfo(_tag, 'Connection state changed: $state');
    });
  }

  static const _tag = 'BluetoothPrinterService';

  static const _keySavedPrinters = 'saved_printers';
  static const _keyPaperSize = 'printer_paper_size';

  final PrinterManager _manager;

  PaperSize _paperSize = PaperSize.mm80;

  /// Most-recently-used first.
  final List<SavedPrinterInfo> _savedPrinters = [];

  @override
  Stream<PrinterConnectionState> get stateStream => _manager.stateStream;

  @override
  PrinterConnectionState get state => _manager.state;

  @override
  bool get isConnected => _manager.isConnected;

  @override
  PrinterDevice? get connectedDevice => _manager.connectedDevice;

  @override
  PaperSize get paperSize => _paperSize;

  @override
  List<SavedPrinterInfo> get savedPrinters => List.unmodifiable(_savedPrinters);

  @override
  Future<void> init() async {
    LoggerUtils.logInfo(_tag, 'Loading saved printer + paper size preferences');
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getStringList(_keySavedPrinters) ?? const [];
      _savedPrinters
        ..clear()
        ..addAll(
          raw.map((entry) {
            final map = jsonDecode(entry) as Map<String, dynamic>;
            return SavedPrinterInfo(
              name: map['name'] as String,
              address: map['address'] as String,
            );
          }),
        );

      final savedPaperSize = prefs.getString(_keyPaperSize);
      _paperSize = PaperSize.values.firstWhere(
        (p) => p.name == savedPaperSize,
        orElse: () => PaperSize.mm80,
      );

      LoggerUtils.logSuccess(
        _tag,
        'Loaded ${_savedPrinters.length} saved printer(s), paper size $_paperSize',
      );
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Failed to load printer preferences: $e');
      LoggerUtils.logDebug(_tag, 'init() stack trace', data: st);
      rethrow;
    }
  }

  @override
  Future<void> initAndAutoConnect() async {
    try {
      await init();
    } catch (e) {
      LoggerUtils.logError(_tag, 'initAndAutoConnect(): init() failed: $e');
      return;
    }

    if (_savedPrinters.isEmpty || isConnected) return;

    LoggerUtils.logInfo(_tag, 'Auto-connecting to saved printer on startup');
    try {
      await reconnectSaved();
    } catch (e) {
      // Expected/common (printer off, out of range) — this is a best-effort
      // background attempt, not a user-initiated action to report an error for.
      LoggerUtils.logWarning(_tag, 'Startup auto-connect did not succeed: $e');
    }
  }

  @override
  Future<bool> isBluetoothEnabled() => BluetoothAdapterChannel.isEnabled();

  @override
  Future<void> openBluetoothSettings() =>
      BluetoothAdapterChannel.openSettings();

  @override
  Stream<List<PrinterDevice>> scan({
    // Android's classic Bluetooth (BR/EDR) inquiry takes ~12s to complete a
    // full discovery pass. A shorter timeout cancels discovery before any
    // newly-found (unbonded) device can be reported, so the result silently
    // looks like "only paired devices" even though discovery is working.
    Duration timeout = const Duration(seconds: 30),
  }) async* {
    // `PrinterManager.scanPrinters()` (via `BluetoothConnector.scan()` in
    // the package) is NOT used here on purpose. Its own error handling
    // swallows failures: if `startBtDiscovery()` throws for any reason, it
    // just does `if (found.isNotEmpty) return;` and returns whatever bonded
    // devices it already had — silently, with the underlying exception
    // never reaching this app at all. That's exactly how a real native bug
    // (missing RECEIVER_EXPORTED flag on Android 13+, patched separately in
    // the plugin's Kotlin) showed up as a clean "success" in our own logs.
    // Driving the platform channel directly here — the same one
    // `BluetoothConnector` uses internally — means every step gets its own
    // log line instead of trusting a result that might be hiding a swallowed
    // exception underneath it.
    LoggerUtils.logInfo(
      _tag,
      'Scanning for Bluetooth printers (timeout: ${timeout.inSeconds}s)',
    );

    final platform = BluetoothPlatformChannel.instance;
    final Map<String, BluetoothPrinterDevice> found = {};

    try {
      final granted = await platform.requestBluetoothPermissions();
      LoggerUtils.logInfo(
        _tag,
        'Native requestBluetoothPermissions() -> $granted',
      );
    } catch (e, st) {
      LoggerUtils.logError(
        _tag,
        'Native requestBluetoothPermissions() threw: $e',
      );
      LoggerUtils.logDebug(
        _tag,
        'requestBluetoothPermissions() stack trace',
        data: st,
      );
    }

    try {
      final bonded = await platform.getBondedDevices();
      LoggerUtils.logInfo(
        _tag,
        'Native getBondedDevices() -> ${bonded.length} device(s)',
      );
      for (final d in bonded) {
        final address = d['address'] as String;
        found[address] = BluetoothPrinterDevice(
          name: (d['name'] as String?) ?? address,
          address: address,
        );
      }
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Native getBondedDevices() threw: $e');
      LoggerUtils.logDebug(_tag, 'getBondedDevices() stack trace', data: st);
    }

    // Yield bonded devices immediately (near-instant) rather than making
    // the caller wait for the full discovery window before seeing anything —
    // this is the main "feels faster" win, since the actual OS discovery
    // duration can't be shortened.
    if (found.isNotEmpty) yield found.values.toList();

    final discoveryUpdates = StreamController<List<PrinterDevice>>();
    final sub = platform.btDiscoveryResults.listen(
      (devices) {
        for (final d in devices) {
          final address = d['address'] as String;
          found[address] = BluetoothPrinterDevice(
            name: (d['name'] as String?) ?? address,
            address: address,
          );
        }
        LoggerUtils.logDebug(
          _tag,
          'Discovery update — ${found.length} device(s) total so far',
        );
        if (!discoveryUpdates.isClosed) {
          discoveryUpdates.add(found.values.toList());
        }
      },
      onError: (Object e) =>
          LoggerUtils.logError(_tag, 'btDiscoveryResults stream error: $e'),
    );

    try {
      await platform.startBtDiscovery(timeoutMs: timeout.inMilliseconds);
      LoggerUtils.logInfo(
        _tag,
        'Native startBtDiscovery() call succeeded — discovering for ${timeout.inSeconds}s',
      );
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Native startBtDiscovery() threw: $e');
      LoggerUtils.logDebug(_tag, 'startBtDiscovery() stack trace', data: st);
      await sub.cancel();
      await discoveryUpdates.close();
      LoggerUtils.logSuccess(
        _tag,
        'Scan finished — found ${found.length} device(s)',
      );
      return;
    }

    final closeTimer = Timer(timeout, () {
      if (!discoveryUpdates.isClosed) discoveryUpdates.close();
    });

    try {
      yield* discoveryUpdates.stream;
    } finally {
      closeTimer.cancel();
      await sub.cancel();
      try {
        await platform.stopBtDiscovery();
      } catch (e) {
        LoggerUtils.logWarning(
          _tag,
          'stopBtDiscovery() threw during cleanup: $e',
        );
      }
      await discoveryUpdates.close();
    }

    LoggerUtils.logSuccess(
      _tag,
      'Scan finished — found ${found.length} device(s)',
    );
  }

  @override
  Future<void> connect(PrinterDevice device) async {
    LoggerUtils.logInfo(
      _tag,
      'Connecting to ${device.name} (${_addressOf(device)})',
    );
    try {
      await _manager.connect(device);
      await _rememberDevice(device);
      LoggerUtils.logSuccess(_tag, 'Connected to ${device.name}');
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Connect to ${device.name} failed: $e');
      LoggerUtils.logDebug(_tag, 'connect() stack trace', data: st);
      rethrow;
    }
  }

  @override
  Future<void> reconnectSaved() async {
    if (_savedPrinters.isEmpty) {
      LoggerUtils.logWarning(
        _tag,
        'reconnectSaved() called with no saved printer',
      );
      return;
    }

    final target = _savedPrinters.first;
    LoggerUtils.logInfo(
      _tag,
      'Reconnecting to saved printer ${target.name} (${target.address})',
    );
    try {
      await _manager.connect(
        BluetoothPrinterDevice(name: target.name, address: target.address),
      );
      LoggerUtils.logSuccess(_tag, 'Reconnected to ${target.name}');
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Reconnect to ${target.name} failed: $e');
      LoggerUtils.logDebug(_tag, 'reconnectSaved() stack trace', data: st);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    LoggerUtils.logInfo(_tag, 'Disconnecting');
    try {
      await _manager.disconnect();
      LoggerUtils.logSuccess(_tag, 'Disconnected');
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Disconnect failed: $e');
      LoggerUtils.logDebug(_tag, 'disconnect() stack trace', data: st);
      rethrow;
    }
  }

  @override
  Future<void> forgetPrinter(String address) async {
    final removed = _savedPrinters.any((p) => p.address == address);
    _savedPrinters.removeWhere((p) => p.address == address);
    await _persistSavedPrinters();
    LoggerUtils.logInfo(
      _tag,
      removed
          ? 'Forgot saved printer $address'
          : 'forgetPrinter() called for unknown address $address',
    );
  }

  @override
  Future<void> setPaperSize(PaperSize size) async {
    _paperSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPaperSize, size.name);
    LoggerUtils.logInfo(_tag, 'Paper size set to $size');
  }

  @override
  Future<void> testPrint() async {
    LoggerUtils.logInfo(_tag, 'Printing test ticket (paper: $_paperSize)');
    try {
      final ticket = await Ticket.create(_paperSize);
      ticket.text(
        'PEARL HOTEL',
        style: const PrintTextStyle(
          bold: true,
          height: TextSize.size2,
          width: TextSize.size2,
        ),
        align: PrintAlign.center,
        linesAfter: 1,
      );
      ticket.text('Test Print', align: PrintAlign.center, linesAfter: 1);
      ticket.separator();
      ticket.text('Printer : ${connectedDevice?.name ?? '-'}');
      ticket.text('Paper   : ${_paperSize.widthMM}mm');
      ticket.feed(2);
      ticket.cut();
      await _manager.printTicket(ticket);
      LoggerUtils.logSuccess(_tag, 'Test ticket sent');
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'Test print failed: $e');
      LoggerUtils.logDebug(_tag, 'testPrint() stack trace', data: st);
      rethrow;
    }
  }

  @override
  Future<void> printTicket(Ticket ticket) async {
    LoggerUtils.logInfo(_tag, 'Sending ticket (${ticket.bytes.length} bytes)');
    try {
      await _manager.printTicket(ticket);
      LoggerUtils.logSuccess(_tag, 'Ticket sent');
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'printTicket() failed: $e');
      LoggerUtils.logDebug(_tag, 'printTicket() stack trace', data: st);
      rethrow;
    }
  }

  @override
  Future<void> dispose() => _manager.dispose();

  Future<void> _rememberDevice(PrinterDevice device) async {
    if (device is! BluetoothPrinterDevice) return;
    _savedPrinters.removeWhere((p) => p.address == device.address);
    _savedPrinters.insert(
      0,
      SavedPrinterInfo(name: device.name, address: device.address),
    );
    await _persistSavedPrinters();
  }

  Future<void> _persistSavedPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _savedPrinters
        .map((p) => jsonEncode({'name': p.name, 'address': p.address}))
        .toList();
    await prefs.setStringList(_keySavedPrinters, encoded);
  }

  String _addressOf(PrinterDevice device) =>
      device is BluetoothPrinterDevice ? device.address : device.name;
}
