import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glowing_button.dart';
import 'auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(
          color: VeriScanTheme.cyan,
          radius: 0.7,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
                parent: _fadeController, curve: Curves.easeOut),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // ── Icon ──
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: VeriScanTheme.primaryGradient,
                      boxShadow: NeonStyles.cyanGlow,
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      shadows: NeonStyles.textGlow(VeriScanTheme.cyan),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join VeriScan to fight counterfeiting',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  // ── Email Field ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: TextStyle(color: VeriScanTheme.textMuted),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: VeriScanTheme.cyan, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Password Field ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 characters)',
                        hintStyle: TextStyle(color: VeriScanTheme.textMuted),
                        prefixIcon: const Icon(Icons.key_rounded,
                            color: VeriScanTheme.cyan, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: VeriScanTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Confirm Password Field ──
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: TextStyle(color: VeriScanTheme.textMuted),
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: VeriScanTheme.cyan, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: VeriScanTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 14),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: VeriScanTheme.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: VeriScanTheme.red.withAlpha(80), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: VeriScanTheme.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(
                                    color: VeriScanTheme.red, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // ── Sign Up Button ──
                  GlowingButton(
                    label: _isLoading ? 'CREATING ACCOUNT...' : 'SIGN UP',
                    icon: _isLoading ? null : Icons.person_add_rounded,
                    onPressed: _isLoading ? null : _handleSignUp,
                  ),
                  const SizedBox(height: 20),
                  // ── Login Link ──
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                            color: VeriScanTheme.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: VeriScanTheme.cyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(email, password);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('UnimplementedError')
            ? 'Backend not yet connected. Coming soon!'
            : 'Sign up failed. Please try again.';
      });
    }
  }
}
