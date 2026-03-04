import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';

class EvidenceUploadScreen extends StatelessWidget {
  const EvidenceUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              // ── Step Indicator ──
              _buildStepIndicator(context, currentStep: 3),
              const SizedBox(height: 32),
              Text(
                'Upload Evidence',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Photos will help investigators verify your report.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              // ── Packaging Photo ──
              _buildUploadCard(
                context,
                icon: Icons.camera_alt_rounded,
                title: 'Upload Packaging Photo',
                subtitle: 'Required — take a clear photo of the tablet packaging',
                isRequired: true,
              ),
              const SizedBox(height: 20),
              // ── Receipt ──
              _buildUploadCard(
                context,
                icon: Icons.receipt_long_rounded,
                title: 'Upload Receipt (Optional)',
                subtitle: 'If you have the receipt, upload it here',
                isRequired: false,
              ),
              const Spacer(),
              GlowingButton(
                label: 'CONTINUE',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, '/report-review'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRequired,
  }) {
    return GlassCard(
      child: Column(
        children: [
          // Camera Preview Placeholder
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRequired
                    ? VeriScanTheme.red.withAlpha(40)
                    : Colors.white.withAlpha(15),
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isRequired ? VeriScanTheme.red : VeriScanTheme.purple)
                        .withAlpha(25),
                  ),
                  child: Icon(icon,
                      color:
                          isRequired ? VeriScanTheme.red : VeriScanTheme.purple,
                      size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to capture',
                  style: TextStyle(
                    color: VeriScanTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
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
