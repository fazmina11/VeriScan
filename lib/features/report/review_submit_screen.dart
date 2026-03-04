import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';

class ReviewSubmitScreen extends StatelessWidget {
  const ReviewSubmitScreen({super.key});

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
              _buildStepIndicator(context, currentStep: 4),
              const SizedBox(height: 32),
              Text(
                'Review & Submit',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Verify the details before submitting your fraud report.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              // ── Summary Card ──
              Expanded(
                child: SingleChildScrollView(
                  child: GlassCard(
                    borderColor: VeriScanTheme.red.withAlpha(40),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          context,
                          icon: Icons.warning_rounded,
                          label: 'Spectral Analysis',
                          value: 'FAILED — No Match',
                          valueColor: VeriScanTheme.red,
                        ),
                        _buildDivider(),
                        _buildSummaryRow(
                          context,
                          icon: Icons.gps_fixed_rounded,
                          label: 'GPS Coordinates',
                          value: '24.8607° N, 67.0011° E',
                          valueColor: VeriScanTheme.textSecondary,
                        ),
                        _buildDivider(),
                        _buildSummaryRow(
                          context,
                          icon: Icons.local_pharmacy_rounded,
                          label: 'Pharmacy',
                          value: 'Khan Medical Store',
                          valueColor: VeriScanTheme.textSecondary,
                        ),
                        _buildDivider(),
                        _buildSummaryRow(
                          context,
                          icon: Icons.location_on_rounded,
                          label: 'Address',
                          value: 'Block 7, Clifton, Karachi',
                          valueColor: VeriScanTheme.textSecondary,
                        ),
                        _buildDivider(),
                        // Photo preview placeholder
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.photo_camera_rounded,
                                color: VeriScanTheme.textMuted, size: 20),
                            const SizedBox(width: 12),
                            Text('Evidence Photo',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha(15),
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.image_rounded,
                                color: VeriScanTheme.textMuted, size: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Submit Button ──
              GlowingButton(
                label: 'SUBMIT FRAUD REPORT',
                icon: Icons.send_rounded,
                type: GlowButtonType.danger,
                onPressed: () =>
                    Navigator.pushNamed(context, '/report-confirmation'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: VeriScanTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: VeriScanTheme.textMuted,
                          fontSize: 12,
                        )),
                const SizedBox(height: 2),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withAlpha(10),
      height: 1,
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
