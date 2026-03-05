import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ── State ──
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  // ── Animations ──
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Logo cyan pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Screen fade-in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Button shimmer sweep
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Focus border listeners
    _emailFocus.addListener(
        () => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passwordFocus.addListener(
        () => setState(() => _passwordFocused = _passwordFocus.hasFocus));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Helpers ──
  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email, password);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/hub');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _mapError(e.toString());
      });
    }
  }

  String _mapError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('not found')) {
      return 'No account found with this email address.';
    } else if (raw.contains('wrong-password') || raw.contains('password')) {
      return 'Incorrect password. Please try again.';
    } else if (raw.contains('invalid-email')) {
      return 'Invalid email format.';
    } else if (raw.contains('user-disabled')) {
      return 'This account has been suspended.';
    } else if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (raw.contains('UnimplementedError')) {
      return 'Backend not yet connected. (Development mode)';
    } else if (raw.contains('SocketException') ||
        raw.contains('Connection refused')) {
      return 'Cannot reach server. Check your network connection.';
    }
    return 'Login failed. Please check your credentials and try again.';
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: VeriScanTheme.background,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 52),
                      _buildLogoSection(),
                      const SizedBox(height: 44),
                      _buildFormCard(),
                      const SizedBox(height: 32),
                      _buildRegisterLink(),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background gradient pulse ──
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.45),
              radius: 0.85,
              colors: [
                VeriScanTheme.purple
                    .withAlpha((_pulseAnimation.value * 38).toInt()),
                VeriScanTheme.background,
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Logo + badge ──
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Pulsing rings + core icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outermost diffuse glow
                Container(
                  width: 110 + (_pulseAnimation.value * 18),
                  height: 110 + (_pulseAnimation.value * 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VeriScanTheme.cyan
                            .withAlpha((_pulseAnimation.value * 55).toInt()),
                        blurRadius: 44,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Middle ring border
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VeriScanTheme.cyan
                          .withAlpha((_pulseAnimation.value * 110).toInt()),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core gradient circle with icon
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [VeriScanTheme.purple, VeriScanTheme.cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VeriScanTheme.cyan
                            .withAlpha((_pulseAnimation.value * 90).toInt()),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ],
            );
          },
          child: const Icon(Icons.biotech_rounded,
              color: Colors.white, size: 34),
        ),
        const SizedBox(height: 24),
        // VeriScan wordmark — glow pulses with animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            return Text(
              'VeriScan',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: VeriScanTheme.cyan,
                letterSpacing: 3.2,
                shadows: [
                  Shadow(
                    color: VeriScanTheme.cyan.withAlpha(
                        (_pulseAnimation.value * 190).toInt()),
                    blurRadius: 26,
                  ),
                  Shadow(
                    color: VeriScanTheme.cyan.withAlpha(
                        (_pulseAnimation.value * 110).toInt()),
                    blurRadius: 52,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        // Subtitle
        const Text(
          'Laboratory Test Interpretation Assistant',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: VeriScanTheme.textSecondary,
            letterSpacing: 0.3,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        // "Authorized Personnel Only" amber badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9500).withAlpha(22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF9500).withAlpha(130),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded,
                  color: Color(0xFFFF9500), size: 13),
              SizedBox(width: 6),
              Text(
                'Authorized Personnel Only',
                style: TextStyle(
                  color: Color(0xFFFF9500),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Form card ──
  Widget _buildFormCard() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 24,
      borderColor: VeriScanTheme.cyan.withAlpha(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('EMAIL ADDRESS', Icons.science_rounded),
          const SizedBox(height: 8),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildFieldLabel('PASSWORD', Icons.lock_rounded),
          const SizedBox(height: 8),
          _buildPasswordField(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
          const SizedBox(height: 28),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: VeriScanTheme.textMuted, size: 13),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: VeriScanTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0D0F14),
        border: Border.all(
          color: _emailFocused
              ? VeriScanTheme.cyan.withAlpha(180)
              : Colors.white.withAlpha(20),
          width: _emailFocused ? 1.5 : 1,
        ),
        boxShadow: _emailFocused
            ? [
                BoxShadow(
                    color: VeriScanTheme.cyan.withAlpha(40), blurRadius: 14)
              ]
            : null,
      ),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) =>
            FocusScope.of(context).requestFocus(_passwordFocus),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'lab.staff@hospital.com',
          hintStyle:
              TextStyle(color: VeriScanTheme.textMuted, fontSize: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.science_rounded,
              color: _emailFocused
                  ? VeriScanTheme.cyan
                  : VeriScanTheme.textMuted,
              size: 20,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0D0F14),
        border: Border.all(
          color: _passwordFocused
              ? VeriScanTheme.cyan.withAlpha(180)
              : Colors.white.withAlpha(20),
          width: _passwordFocused ? 1.5 : 1,
        ),
        boxShadow: _passwordFocused
            ? [
                BoxShadow(
                    color: VeriScanTheme.cyan.withAlpha(40), blurRadius: 14)
              ]
            : null,
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _isLoading ? null : _handleLogin(),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: TextStyle(
            color: VeriScanTheme.textMuted,
            fontSize: 18,
            letterSpacing: 3,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.lock_rounded,
              color: _passwordFocused
                  ? VeriScanTheme.cyan
                  : VeriScanTheme.textMuted,
              size: 20,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: _passwordFocused
                  ? VeriScanTheme.cyan.withAlpha(180)
                  : VeriScanTheme.textMuted,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            splashRadius: 18,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VeriScanTheme.red.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VeriScanTheme.red.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded,
              color: VeriScanTheme.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                  color: VeriScanTheme.red, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGIN button with shimmer + glow ──
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _isLoading
                  ? LinearGradient(colors: [
                      VeriScanTheme.cyan.withAlpha(120),
                      VeriScanTheme.purple.withAlpha(120),
                    ])
                  : LinearGradient(
                      colors: const [
                        VeriScanTheme.cyan,
                        VeriScanTheme.purple,
                        VeriScanTheme.cyan,
                      ],
                      stops: [
                        (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                        _shimmerAnimation.value.clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      transform:
                          GradientRotation(_shimmerAnimation.value * math.pi / 8),
                    ),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: VeriScanTheme.cyan.withAlpha(70),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: VeriScanTheme.purple.withAlpha(50),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: child,
          );
        },
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'LOGIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Register link ──
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: TextStyle(
              color: VeriScanTheme.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: const Text(
            'Register here',
            style: TextStyle(
              color: VeriScanTheme.cyan,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: VeriScanTheme.cyan,
            ),
          ),
        ),
      ],
    );
  }
}
