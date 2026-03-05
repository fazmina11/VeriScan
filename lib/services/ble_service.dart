import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class BleService extends ChangeNotifier {
  // ── State ──
  bool isScanning = false;
  bool isConnected = false;
  bool isSendingToServer = false;
  String connectionStatus = 'Not connected';
  String rawBleString = '';
  List<double> lastSpectralValues = [];
  String serverVerdict = '';
  double confidence = 0.0;

  // ── Internal ──
  BluetoothDevice? _device;
  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;
  bool _connecting = false;

  // ── CHANGE THIS to your laptop WiFi IP from Step 5 above ──
  static const String _laptopIp = '192.168.221.44';
  static const String _predictUrl = 'http://$_laptopIp:8000/predict';

  // ─────────────────────────────────────────
  // SCAN FOR ESP32
  // ─────────────────────────────────────────
  Future<void> startScan() async {
    if (isScanning || _connecting) return;

    // Request permissions first
    final granted = await _requestPermissions();
    if (!granted) return;

    isScanning = true;
    _connecting = false;
    rawBleString = '';
    serverVerdict = '';
    connectionStatus = 'Scanning for VeriScan device...';
    notifyListeners();

    _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(milliseconds: 500));

    // Listen BEFORE starting scan
    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      // results is a list — check ALL of them, not just first
      for (final r in results) {
        final n1 = r.device.platformName.toUpperCase();
        final n2 = r.advertisementData.advName.toUpperCase();
        final combined = n1 + n2;

        if (combined.contains('VERISCAN') || combined.contains('ESP32')) {
          if (_connecting || isConnected) return;
          _connecting = true;
          isScanning = false;
          connectionStatus = 'Found ${r.device.platformName}! Connecting...';
          notifyListeners();

          _scanSub?.cancel();
          await FlutterBluePlus.stopScan();
          await _connect(r.device);
          return; // exit after finding device
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );

    await FlutterBluePlus.isScanning.where((v) => v == false).first;

    if (!isConnected && !_connecting) {
      isScanning = false;
      connectionStatus = 'Device not found. Is ESP32 powered on?';
      notifyListeners();
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );

    if (!allGranted) {
      connectionStatus = 'Permissions denied. Please allow Bluetooth and Location.';
      isScanning = false;
      notifyListeners();
    }
    return allGranted;
  }

  // ─────────────────────────────────────────
  // CONNECT TO DEVICE
  // ─────────────────────────────────────────
  Future<void> _connect(BluetoothDevice device) async {
    try {
      connectionStatus = 'Connecting to ${device.platformName}...';
      notifyListeners();

      await device.connect(
        timeout: const Duration(seconds: 20),
        autoConnect: false,
      );

      _device = device;
      isConnected = true;
      _connecting = false;
      connectionStatus = 'Connected ✓';
      notifyListeners();

      // Watch for disconnection
      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected = false;
          _device = null;
          connectionStatus = 'Disconnected';
          notifyListeners();
        }
      });

      await _listenToData();
    } catch (e) {
      isConnected = false;
      _connecting = false;
      connectionStatus = 'Connection failed. Try again.\n($e)';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // LISTEN TO SENSOR DATA
  // ─────────────────────────────────────────
  Future<void> _listenToData() async {
    try {
      connectionStatus = 'Reading sensor channels...';
      notifyListeners();

      final services = await _device!.discoverServices();

      for (final service in services) {
        for (final char in service.characteristics) {
          if (!char.properties.notify) continue;

          await char.setNotifyValue(true);

          char.lastValueStream.listen((bytes) {
            if (bytes.isEmpty) return;
            try {
              final str = utf8.decode(bytes).trim();
              if (!str.contains(',')) return;

              rawBleString = str;

              // Parse for visualization
              final parts = str.split(',');
              lastSpectralValues = parts
                  .map((p) => (double.tryParse(p.trim()) ?? 0.0) / 65535.0)
                  .toList();

              connectionStatus =
                  'Live Data ✓  |  ${parts.length} channels received';
              notifyListeners();
            } catch (_) {}
          });

          connectionStatus = 'Connected — Receiving NIR data ✓';
          notifyListeners();
          return; // Found notify char, done
        }
      }

      connectionStatus = 'Connected but no data stream found';
      notifyListeners();
    } catch (e) {
      connectionStatus = 'Sensor read error: $e';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // SEND TO FASTAPI AND GET VERDICT
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> analyzeWithAI() async {
    if (rawBleString.isEmpty) {
      return {'error': 'No sensor data. Connect ESP32 first.'};
    }

    // Parse raw string into list of ints
    List<int> channels;
    try {
      channels = rawBleString
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
    } catch (e) {
      return {'error': 'Could not parse sensor data: $e'};
    }

    if (channels.length != 18) {
      return {
        'error': 'Expected 18 channels, got ${channels.length}. Wait for full reading.'
      };
    }

    isSendingToServer = true;
    connectionStatus = 'Sending to AI server...';
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse(_predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'channels': channels}),
          )
          .timeout(const Duration(seconds: 10));

      isSendingToServer = false;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        serverVerdict = json['verdict'] ?? 'Unknown';
        confidence = (json['confidence'] ?? 0.0).toDouble();
        connectionStatus = 'Analysis complete ✓';
        notifyListeners();
        return json;
      } else {
        connectionStatus = 'Server error: ${response.statusCode}';
        notifyListeners();
        return {'error': 'Server returned ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      isSendingToServer = false;
      connectionStatus = 'Network error — same WiFi?';
      notifyListeners();
      return {'error': 'Cannot reach server. Are phone and laptop on same WiFi?\n$e'};
    }
  }

  // ─────────────────────────────────────────
  // DISCONNECT
  // ─────────────────────────────────────────
  Future<void> disconnect() async {
    _scanSub?.cancel();
    _connSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    isConnected = false;
    _connecting = false;
    _device = null;
    rawBleString = '';
    lastSpectralValues = [];
    connectionStatus = 'Disconnected';
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}