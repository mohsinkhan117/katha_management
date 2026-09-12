// lib/core/service/printer_service.dart

import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

/// A previously-connected printer remembered for quick reconnect, shown in
/// the Printer Settings screen's "Saved" tab.
class SavedPrinterInfo {
  final String name;
  final String address;

  const SavedPrinterInfo({required this.name, required this.address});
}

/// Keeps invoice/UI code from talking to Bluetooth directly, per the
/// printing tech spec's layering:
/// InvoiceView -> InvoiceService -> PrinterService -> PrinterManager -> RFCOMM socket -> Printer.
abstract class PrinterService {
  /// Broadcast stream of connection lifecycle changes.
  Stream<PrinterConnectionState> get stateStream;

  PrinterConnectionState get state;
  bool get isConnected;
  PrinterDevice? get connectedDevice;
  PaperSize get paperSize;

  /// Every printer ever connected to, most-recently-used first, persisted
  /// across app restarts.
  List<SavedPrinterInfo> get savedPrinters;

  /// Loads persisted saved-printer + paper-size preferences. Must be called
  /// once before any other member is used.
  Future<void> init();

  /// [init] plus a best-effort, silent reconnect to the most-recently-used
  /// saved printer, if any. Errors are swallowed — this is meant to be
  /// fired once at app startup (see main.dart) so a printer connected in a
  /// previous session is often already connected by the time the user
  /// reaches any screen, not just after visiting Printer Settings.
  Future<void> initAndAutoConnect();

  /// Whether the Bluetooth radio itself is turned on. Independent of app
  /// permissions — `scan`/`getBondedDevices` return empty and `connect`
  /// fails identically whether the radio is off or nothing is simply
  /// nearby, so callers should check this first to tell the user "turn on
  /// Bluetooth" instead of "no printers found".
  Future<bool> isBluetoothEnabled();

  /// Opens the OS Bluetooth settings screen so the user can turn it on.
  Future<void> openBluetoothSettings();

  /// Scans for Bluetooth Classic (SPP) printers only. Yields incrementally —
  /// bonded/paired devices first (near-instant), then an updated cumulative
  /// list every time a new nearby device is discovered — so callers can
  /// show results immediately instead of only after the full [timeout].
  Stream<List<PrinterDevice>> scan({Duration timeout});

  /// Connects to [device] and adds/moves it to the front of [savedPrinters].
  Future<void> connect(PrinterDevice device);

  /// Reconnects to the most-recently-used entry in [savedPrinters], if any.
  Future<void> reconnectSaved();

  Future<void> disconnect();

  /// Removes the printer at [address] from [savedPrinters].
  Future<void> forgetPrinter(String address);

  Future<void> setPaperSize(PaperSize size);

  /// Prints a short sample ticket to confirm the connection and paper size.
  Future<void> testPrint();

  /// Sends a fully-built [Ticket] (e.g. a real invoice) to the connected
  /// printer as a single atomic write.
  Future<void> printTicket(Ticket ticket);

  Future<void> dispose();
}
