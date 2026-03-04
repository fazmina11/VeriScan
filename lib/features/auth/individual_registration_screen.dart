import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import 'auth_provider.dart';


class IndividualRegistrationScreen extends ConsumerStatefulWidget {
  const IndividualRegistrationScreen({super.key});

  @override
  ConsumerState<IndividualRegistrationScreen> createState() =>
      _IndividualRegistrationScreenState();
}

class _IndividualRegistrationScreenState
    extends ConsumerState<IndividualRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  bool _locationEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;

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
    _nameController.dispose();
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
                    'Set Up Your Profile',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Protect yourself and your family from counterfeit medicines.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  // ── Full Name ──
                  Text('FULL NAME',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: VeriScanTheme.textMuted,
                          )),
                  const SizedBox(height: 8),
                  _buildNeonTextField(
                    controller: _nameController,
                    hint: 'Enter your full name',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 32),
                  // ── Location Toggle ──
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VeriScanTheme.cyan.withAlpha(20),
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: VeriScanTheme.cyan, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enable Location',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(
                                'For Verified Pharmacy Map',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        _buildNeonSwitch(_locationEnabled, (val) {
                          setState(() => _locationEnabled = val);
                        }),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!,
                        style: const TextStyle(
                            color: VeriScanTheme.red, fontSize: 13)),
                  ],
                  const Spacer(),
                  // ── Complete Setup ──
                  GlowingButton(
                    label: _isLoading ? 'SAVING...' : 'COMPLETE SETUP',
                    icon: Icons.check_circle_rounded,
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

  Widget _buildNeonSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value
              ? VeriScanTheme.cyan.withAlpha(40)
              : Colors.white.withAlpha(15),
          border: Border.all(
            color: value
                ? VeriScanTheme.cyan
                : Colors.white.withAlpha(30),
            width: 1,
          ),
          boxShadow: value
              ? [BoxShadow(color: VeriScanTheme.cyan.withAlpha(60), blurRadius: 10)]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? VeriScanTheme.cyan : VeriScanTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleComplete() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
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
        await authService.saveIndividualProfile(
          uid: user.uid,
          fullName: name,
          locationEnabled: _locationEnabled,
        );

        // Ask about biometric
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/hub');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save profile. Try again.';
      });
    }
  }

}

