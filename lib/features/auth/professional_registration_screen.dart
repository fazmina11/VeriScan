import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import 'auth_provider.dart';


class ProfessionalRegistrationScreen extends ConsumerStatefulWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  ConsumerState<ProfessionalRegistrationScreen> createState() =>
      _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState
    extends ConsumerState<ProfessionalRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _orgController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  String _roleType = 'Pharmacist';
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;

  final List<String> _roleTypes = [
    'Pharmacist',
    'Quality Inspector',
    'Supply Chain Manager',
    'Regulatory Officer',
    'Research Analyst',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _orgController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(
          color: VeriScanTheme.purple,
          radius: 0.6,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
                parent: _fadeController, curve: Curves.easeOut),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Professional Setup',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register your organization to verify medicine supply chains.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  // ── Scrollable Form ──
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('ORGANIZATION NAME'),
                          const SizedBox(height: 8),
                          _buildNeonTextField(
                            controller: _orgController,
                            hint: 'Enter organization name',
                            icon: Icons.business_rounded,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('PHARMACY LICENSE ID'),
                          const SizedBox(height: 8),
                          _buildNeonTextField(
                            controller: _licenseController,
                            hint: 'e.g. PH-2026-XXXX',
                            icon: Icons.badge_rounded,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('BUSINESS ADDRESS'),
                          const SizedBox(height: 8),
                          _buildNeonTextField(
                            controller: _addressController,
                            hint: 'Full business address',
                            icon: Icons.location_city_rounded,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('ROLE TYPE'),
                          const SizedBox(height: 8),
                          _buildRoleDropdown(),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(_errorMessage!,
                                style: const TextStyle(
                                    color: VeriScanTheme.red, fontSize: 13)),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  // ── Complete Registration ──
                  GlowingButton(
                    label: _isLoading
                        ? 'REGISTERING...'
                        : 'COMPLETE REGISTRATION',
                    icon: Icons.verified_rounded,
                    type: GlowButtonType.success,
                    onPressed: _isLoading ? null : _handleComplete,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: VeriScanTheme.textMuted,
            ));
  }

  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: VeriScanTheme.textMuted),
          prefixIcon: Icon(icon, color: VeriScanTheme.cyan, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roleType,
          isExpanded: true,
          dropdownColor: VeriScanTheme.surface,
          icon: const Icon(Icons.expand_more_rounded,
              color: VeriScanTheme.cyan),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: _roleTypes
              .map((r) =>
                  DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _roleType = v ?? 'Pharmacist'),
        ),
      ),
    );
  }

  Future<void> _handleComplete() async {
    final org = _orgController.text.trim();
    final license = _licenseController.text.trim();
    final address = _addressController.text.trim();

    if (org.isEmpty || license.isEmpty || address.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;

      if (user != null) {
        await authService.saveProfessionalProfile(
          uid: user.uid,
          organizationName: org,
          licenseId: license,
          businessAddress: address,
          roleType: _roleType,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/hub');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Registration failed. Please try again.';
      });
    }
  }

}

