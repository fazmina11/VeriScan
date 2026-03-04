import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';

class PurchaseLocationScreen extends StatelessWidget {
  const PurchaseLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(
          color: VeriScanTheme.red,
          radius: 0.6,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // ── Back Button ──
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                // ── Step Indicator ──
                _buildStepIndicator(context, currentStep: 1),
                const SizedBox(height: 32),
                // ── Title ──
                Text(
                  'Where was this\npurchased?',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us locate the source of the counterfeit medicine.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                // ── Option Cards ──
                _buildOptionCard(
                  context,
                  icon: Icons.local_pharmacy_rounded,
                  title: 'Select Pharmacy from Map',
                  subtitle: 'Choose from registered pharmacies',
                  onTap: () => Navigator.pushNamed(context, '/report-map'),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan Pharmacy QR Code',
                  subtitle: 'Scan the code on your receipt',
                  onTap: () => Navigator.pushNamed(context, '/report-map'),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  context,
                  icon: Icons.pin_drop_rounded,
                  title: 'Drop Pin on Market Stall',
                  subtitle: 'Mark the exact purchase location',
                  onTap: () => Navigator.pushNamed(context, '/report-map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VeriScanTheme.red.withAlpha(25),
            ),
            child: Icon(icon, color: VeriScanTheme.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: VeriScanTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, {required int currentStep}) {
    return Row(
      children: List.generate(5, (i) {
        final isActive = i < currentStep;
        final isCurrent = i == currentStep - 1;
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCurrent
                  ? VeriScanTheme.red
                  : isActive
                      ? VeriScanTheme.red.withAlpha(100)
                      : Colors.white.withAlpha(20),
              boxShadow: isCurrent
                  ? [BoxShadow(color: VeriScanTheme.red.withAlpha(100), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
