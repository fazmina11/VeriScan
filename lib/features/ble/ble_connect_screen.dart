import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../services/ble_service.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';

class BleConnectScreen extends StatefulWidget {
  const BleConnectScreen({super.key});

  @override
  State<BleConnectScreen> createState() => _BleConnectScreenState();
}

class _BleConnectScreenState extends State<BleConnectScreen> {
  @override
  void initState() {
    super.initState();
    // Reset BLE state every time this screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleService = Provider.of<BleService>(context, listen: false);
      bleService.resetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleService = Provider.of<BleService>(context);
    final selectedMedicine = 
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    
    if (selectedMedicine.isNotEmpty) {
      // Keep provider in sync with the route argument locally without side effect builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (bleService.selectedMedicine != selectedMedicine) {
            bleService.selectedMedicine = selectedMedicine;
        }
      });
    }

    return Scaffold(
      backgroundColor: VeriScanTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Connect Device',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VeriScanTheme.surface,
                  boxShadow: bleService.isConnected
                      ? NeonStyles.greenGlow
                      : bleService.isScanning
                          ? NeonStyles.cyanGlow
                          : NeonStyles.purpleGlow,
                  border: Border.all(
                    color: bleService.isConnected
                        ? VeriScanTheme.green
                        : bleService.isScanning
                            ? VeriScanTheme.cyan
                            : VeriScanTheme.purple,
                    width: 2,
                  ),
                ),
                child: Icon(
                  bleService.isConnected
                      ? Icons.bluetooth_connected_rounded
                      : bleService.isScanning
                          ? Icons.bluetooth_searching_rounded
                          : Icons.bluetooth_rounded,
                  color: bleService.isConnected
                      ? VeriScanTheme.green
                      : bleService.isScanning
                          ? VeriScanTheme.cyan
                          : VeriScanTheme.purple,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                bleService.connectionStatus,
                style: TextStyle(
                  color: bleService.isConnected
                      ? VeriScanTheme.green
                      : VeriScanTheme.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: FlutterBluePlus.onScanResults,
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) return const SizedBox();
                  return Column(
                    children: results.take(5).map((r) {
                      final name = r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : r.advertisementData.advName.isNotEmpty
                              ? r.advertisementData.advName
                              : r.device.remoteId.toString();
                      return Text(
                        '📡 $name  RSSI:${r.rssi}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              if (bleService.lastSpectralValues.isNotEmpty)
                Text(
                  '✓ Receiving NIR Data — ${bleService.lastSpectralValues.length} channels',
                  style: const TextStyle(
                    color: VeriScanTheme.green,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (bleService.isScanning) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(VeriScanTheme.cyan),
                ),
              ],
              const SizedBox(height: 24),
              if (bleService.isConnected &&
                  bleService.lastSpectralValues.isNotEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE NIR DATA',
                        style: TextStyle(
                          color: VeriScanTheme.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: bleService.lastSpectralValues
                              .take(12)
                              .map((v) => Container(
                                    width: 16,
                                    height: (v * 60).clamp(4.0, 60.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          VeriScanTheme.purple,
                                          VeriScanTheme.cyan,
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (!bleService.isConnected)
                GlowingButton(
                  label: bleService.isScanning
                      ? 'SCANNING...'
                      : 'SCAN FOR DEVICE',
                  icon: Icons.bluetooth_searching_rounded,
                  onPressed: bleService.isScanning ? null : () async {
                    await bleService.startScan();
                  },
                ),
              if (bleService.isConnected) ...[
                GlowingButton(
                  label: 'PROCEED TO SCAN',
                  icon: Icons.radar_rounded,
                  type: GlowButtonType.success,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/scanning'),
                ),
                const SizedBox(height: 12),
                GlowingButton(
                  label: 'DISCONNECT',
                  icon: Icons.bluetooth_disabled_rounded,
                  type: GlowButtonType.danger,
                  onPressed: bleService.disconnect,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
