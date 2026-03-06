import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
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
  String selectedMedicine = '';
  List<String> availableMedicines = ['Paracetamol', 'Combiflam'];

  // ── Internal ──
  BluetoothDevice? _device;
  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;
  bool _connecting = false;

  // ── CHANGE THIS to your laptop WiFi IP from Step 5 above ──
  static const String _laptopIp = '192.168.221.44';
  static const String _predictUrl = 'http://$_laptopIp:8001/predict';

  // ─────────────────────────────────────────
  // SCAN FOR ESP32
  // ─────────────────────────────────────────
  Future<void> startScan() async {
    if (isScanning || _connecting) return;

    final granted = await _requestPermissions();
    if (!granted) return;

    isScanning = true;
    _connecting = false;
    rawBleString = '';
    serverVerdict = '';
    connectionStatus = 'Scanning...';
    notifyListeners();

    _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(milliseconds: 500));

    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      for (final r in results) {
        if (_connecting || isConnected) return;

        final n1 = r.device.platformName;
        final n2 = r.advertisementData.advName;
        final id = r.device.remoteId.toString().toUpperCase();

        // Show EVERY device found — for debugging
        connectionStatus = 'Seeing: "${n1}" / "${n2}" / $id';
        notifyListeners();

        final combined = (n1 + n2).toUpperCase();
        final bool nameMatch = combined.contains('VERISCAN') ||
            combined.contains('ESP32') ||
            combined.contains('BLE');

        // Also match by exact MAC address of your ESP32
        final bool macMatch = id == '70:4B:CA:26:10:6E';

        final serviceUuids = r.advertisementData.serviceUuids
            .map((u) => u.toString().toLowerCase())
            .toList();
        final bool uuidMatch = serviceUuids
            .contains('4fafc201-1fb5-459e-8fcc-c5c9c331914b');

        if (nameMatch || uuidMatch || macMatch) {
          _connecting = true;
          isScanning = false;
          connectionStatus = 'Found! Connecting to ${n1.isNotEmpty ? n1 : id}...';
          notifyListeners();
          _scanSub?.cancel();
          await FlutterBluePlus.stopScan();
          await _connect(r.device);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 20),
      androidUsesFineLocation: true,
    );

    await FlutterBluePlus.isScanning.where((v) => v == false).first;

    if (!isConnected && !_connecting) {
      isScanning = false;
      connectionStatus = 'Not found. Make sure nRF is disconnected.';
      notifyListeners();
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdk();
      
      List<Permission> permissions = [];
      
      if (sdk >= 31) {
        // Android 12+ — use new BLE permissions
        permissions = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ];
      } else {
        // Android 11 and below
        permissions = [
          Permission.location,
        ];
      }
      
      final statuses = await permissions.request();
      final denied = statuses.values.where(
        (s) => s.isDenied || s.isPermanentlyDenied
      ).toList();
      
      if (denied.isNotEmpty) {
        connectionStatus = 'Please grant Bluetooth & Location permissions\nThen tap Scan again';
        isScanning = false;
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<int> _getAndroidSdk() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return 31; // assume Android 12+ if unknown
    }
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
      return {'error': 'No sensor data received from ESP32.'};
    }

    List<int> channels;
    try {
      channels = rawBleString
          .trim()
          .split(',')
          .map((e) => double.parse(e.trim()).round())
          .toList();
    } catch (e) {
      return {'error': 'Could not parse sensor data: $e'};
    }

    if (channels.length != 18) {
      return {
        'error': 'Expected 18 channels, got ${channels.length}.'
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
            body: jsonEncode({
              'channels': channels,
              'medicine': selectedMedicine,
            }),
          )
          .timeout(const Duration(seconds: 15));

      isSendingToServer = false;

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody.containsKey('error')) {
          connectionStatus = 'AI error: ${jsonBody['error']}';
          notifyListeners();
          return {'error': jsonBody['error']};
        }
        serverVerdict = jsonBody['verdict'] ?? 'Unknown';
        connectionStatus = 'Verdict: $serverVerdict ✓';
        notifyListeners();
        return jsonBody;
      } else {
        final msg = 'Server error ${response.statusCode}';
        connectionStatus = msg;
        notifyListeners();
        return {'error': msg};
      }
    } catch (e) {
      isSendingToServer = false;
      connectionStatus = 'Cannot reach server. Same WiFi?';
      notifyListeners();
      return {'error': e.toString()};
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

  void resetState() {
    isScanning = false;
    isConnected = false;
    _connecting = false;
    rawBleString = '';
    lastSpectralValues = [];
    serverVerdict = '';
    connectionStatus = 'Not connected';
    _scanSub?.cancel();
    _connSub?.cancel();
    _device = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}