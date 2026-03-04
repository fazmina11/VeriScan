import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(
          color: VeriScanTheme.purple,
          radius: 0.8,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // ── Logo / Icon ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: VeriScanTheme.primaryGradient,
                      boxShadow: NeonStyles.cyanGlow,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ── Title ──
                  Text(
                    'VeriScan',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      shadows: NeonStyles.textGlow(VeriScanTheme.cyan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How will you use VeriScan?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 60),
                  // ── Role Cards ──
                  _buildRoleCard(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Individual',
                    description: 'Protect yourself and your family from counterfeit medicines',
                    role: 'individual',
                  ),
                  const SizedBox(height: 20),
                  _buildRoleCard(
                    context,
                    icon: Icons.business_center_rounded,
                    title: 'Professional',
                    description: 'Verify medicine supply chains at scale',
                    role: 'professional',
                  ),
                  const Spacer(),
                  // ── Continue ──
                  GlowingButton(
                    label: 'CONTINUE',
                    onPressed: _selectedRole != null
                        ? () => Navigator.pushReplacementNamed(context, '/hub')
                        : null,
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

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String role,
  }) {
    final isSelected = _selectedRole == role;
    return GlassCard(
      borderColor: isSelected ? VeriScanTheme.cyan : null,
      onTap: () => setState(() => _selectedRole = role),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? VeriScanTheme.cyan.withAlpha(30)
                  : Colors.white.withAlpha(10),
            ),
            child: Icon(
              icon,
              color: isSelected ? VeriScanTheme.cyan : VeriScanTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSelected ? VeriScanTheme.cyan : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: VeriScanTheme.cyan, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.check, color: VeriScanTheme.cyan, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
