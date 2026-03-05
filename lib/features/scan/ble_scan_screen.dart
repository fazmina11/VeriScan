import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────
  StreamSubscription? _scanSub;
  bool _found = false;
  String _statusMessage = 'Searching for VeriScan...';
  BluetoothCharacteristic? _characteristic;
  List<double> spectralValues = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  BluetoothDevice? _foundDevice;
  StreamSubscription? _adapterSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Constants ──────────────────────────────────────────────────────────
  static const String kDeviceName = 'VeriScan';
  static const Color kPrimary = Color(0xFF00D4AA);
  static const Color kBackground = Color(0xFF0A0E1A);
  static const Color kSurface = Color(0xFF151B2E);
  static const Color kError = Color(0xFFFF4757);

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenToAdapterState();
    
    // Auto-start scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBLEScan();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanSub?.cancel();
    _adapterSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // ── Bluetooth adapter listener ─────────────────────────────────────────
  void _listenToAdapterState() {
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off && mounted) {
        setState(() {
          _statusMessage = 'Please turn on Bluetooth';
          _isScanning = false;
        });
      }
    });
  }

  // ── Permissions ────────────────────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted,
    );

    if (!allGranted && mounted) {
      setState(() {
        _statusMessage = 'Bluetooth permissions are required';
      });
    }
    return allGranted;
  }

  // ── Scan ───────────────────────────────────────────────────────────────
  Future<void> _startBLEScan() async {
    final granted = await _requestPermissions();
    if (!granted) return;

    setState(() {
      _found = false;
      _isScanning = true;
      _statusMessage = 'Scanning...';
    });

    await FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(milliseconds: 500));

    _scanSub?.cancel();

    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      for (final r in results) {
        final name = (r.device.platformName + r.advertisementData.advName)
            .toUpperCase();
        if (name.contains('VERISCAN') || name.contains('ESP32')) {
          if (_found) return;
          _found = true;
          await FlutterBluePlus.stopScan();
          setState(() {
            _isScanning = false;
            _statusMessage = 'Found device! Connecting...';
            _foundDevice = r.device;
          });
          await _connectAndSubscribe(r.device);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );

    await Future.delayed(const Duration(seconds: 16));
    _scanSub?.cancel();

    if (!_found && mounted) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Device not found. Is ESP32 powered on?';
      });
    }
  }

  // ── Connect ────────────────────────────────────────────────────────────
  Future<void> _connectAndSubscribe(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Connected! Reading sensor...';
      });

      final services = await device.discoverServices();
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify) {
            await c.setNotifyValue(true);
            c.lastValueStream.listen((bytes) {
              if (bytes.isEmpty) return;
              try {
                final str = utf8.decode(bytes);
                final vals = str.split(',')
                    .map((v) => (double.tryParse(v.trim()) ?? 0.0) / 65535.0)
                    .toList();
                setState(() {
                  spectralValues = vals;
                  _statusMessage = 'Live NIR Data — ${vals.length} channels ✓';
                });
              } catch (_) {}
            });
            setState(() => _characteristic = c);
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Connection failed: $e';
        });
      }
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connect Device',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildBluetoothAnimation(),
              const SizedBox(height: 40),
              _buildStatusCard(),
              const SizedBox(height: 32),
              if (spectralValues.isEmpty)
                _buildActionButton(),
              const SizedBox(height: 16),
              if (spectralValues.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/scanning', arguments: spectralValues);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'PROCEED TO SCAN',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _buildHelpText(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            if (_isScanning)
              Container(
                width: 180 * _pulseAnimation.value,
                height: 180 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimary.withOpacity(
                      0.3 * (1 - (_pulseAnimation.value - 0.8) / 0.2),
                    ),
                    width: 2,
                  ),
                ),
              ),
            // Middle ring
            if (_isScanning)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
              ),
            // Main circle
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSurface,
                border: Border.all(
                  color: _foundDevice != null ? kPrimary : Colors.white24,
                  width: 2,
                ),
                boxShadow: _foundDevice != null
                    ? [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                _foundDevice != null
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
                size: 48,
                color: _foundDevice != null ? kPrimary : Colors.white54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _foundDevice != null ? kPrimary.withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
              ),
            ),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (_foundDevice != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _foundDevice!.platformName,
                  style: GoogleFonts.orbitron(
                    color: kPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isScanning || _isConnecting ? null : _startBLEScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          disabledBackgroundColor: kPrimary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isScanning || _isConnecting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isConnecting ? 'CONNECTING…' : 'SCANNING…',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                _foundDevice != null ? 'SCAN AGAIN' : 'SCAN',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }


  Widget _buildHelpText() {
    return Text(
      'Make sure your VeriScan hardware device\nis powered on and nearby.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: Colors.white30,
        fontSize: 12,
        height: 1.6,
      ),
    );
  }
}