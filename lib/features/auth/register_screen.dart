import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lab role model (inline)
// ─────────────────────────────────────────────────────────────────────────────

class _LabRole {
  final String emoji;
  final String title;
  final String description;
  final String apiValue;
  const _LabRole({
    required this.emoji,
    required this.title,
    required this.description,
    required this.apiValue,
  });
}

const List<_LabRole> _labRoles = [
  _LabRole(
    emoji: '🔬',
    title: 'Lab Technician',
    description: 'Performs daily laboratory tests and operates instruments',
    apiValue: 'lab_technician',
  ),
  _LabRole(
    emoji: '👨‍⚕️',
    title: 'Pathologist',
    description: 'Interprets test results and provides diagnoses',
    apiValue: 'pathologist',
  ),
  _LabRole(
    emoji: '💊',
    title: 'Pharmacist',
    description: 'Manages medications and validates prescriptions',
    apiValue: 'pharmacist',
  ),
  _LabRole(
    emoji: '🏥',
    title: 'Lab Manager',
    description: 'Oversees laboratory operations and quality standards',
    apiValue: 'lab_manager',
  ),
  _LabRole(
    emoji: '🩺',
    title: 'Clinical Researcher',
    description: 'Conducts clinical studies and research trials',
    apiValue: 'clinical_researcher',
  ),
  _LabRole(
    emoji: '📋',
    title: 'Quality Control Officer',
    description: 'Ensures test accuracy and regulatory compliance',
    apiValue: 'quality_control_officer',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// RegisterScreen
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ── Step ──
  int _step = 1; // 1 or 2

  // ── Step 1 controllers ──
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _labNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── Focus nodes ──
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _employeeIdFocus = FocusNode();
  final _labNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // ── Step 1 UI state ──
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _empFocused = false;
  bool _labFocused = false;
  bool _passFocused = false;
  bool _confirmFocused = false;

  // ── Step 2 ──
  _LabRole? _selectedRole;

  // ── Shared ──
  bool _isLoading = false;
  String? _errorMessage;

  // ── Fade animation ──
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    void listenFocus(FocusNode node, VoidCallback cb) =>
        node.addListener(() => setState(cb));

    listenFocus(_nameFocus, () => _nameFocused = _nameFocus.hasFocus);
    listenFocus(_emailFocus, () => _emailFocused = _emailFocus.hasFocus);
    listenFocus(_employeeIdFocus, () => _empFocused = _employeeIdFocus.hasFocus);
    listenFocus(_labNameFocus, () => _labFocused = _labNameFocus.hasFocus);
    listenFocus(_passwordFocus, () => _passFocused = _passwordFocus.hasFocus);
    listenFocus(
        _confirmPasswordFocus, () => _confirmFocused = _confirmPasswordFocus.hasFocus);
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _emailController,
      _employeeIdController,
      _labNameController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _emailFocus,
      _employeeIdFocus,
      _labNameFocus,
      _passwordFocus,
      _confirmPasswordFocus,
    ]) {
      f.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  // ── Helpers ──
  bool _isValidEmail(String e) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(e);

  void _animateTo(int step) {
    setState(() {
      _step = step;
      _errorMessage = null;
    });
    _fadeController.forward(from: 0);
  }

  void _validateAndNext() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final lab = _labNameController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || lab.isEmpty ||
        pass.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    _animateTo(2);
  }

  Future<void> _handleRegister() async {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole!.apiValue,
        labName: _labNameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/hub');
      }

    } catch (e) {
      // DEMO MODE — if backend not connected, still let user
      // proceed so UI can be tested without backend
      final errorStr = e.toString().toLowerCase();
      final isConnectionError =
          errorStr.contains('connection') ||
          errorStr.contains('timeout') ||
          errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('refused');

      if (isConnectionError) {
        // Save demo user data locally and proceed to hub
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'auth_token',
          value: 'demo_token_123'
        );
        await storage.write(
          key: 'user_data',
          value: jsonEncode({
            'full_name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _selectedRole!.apiValue,
            'lab_name': _labNameController.text.trim(),
            'employee_id': _employeeIdController.text.trim(),
          })
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/hub');
        }
      } else {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 2) _animateTo(1);
      },
      child: Scaffold(
        backgroundColor: VeriScanTheme.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _step == 1 ? _buildStep1() : _buildStep2(),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Personal Details
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          // Progress bar
          _buildProgressBar(1),
          const SizedBox(height: 24),
          // Heading
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your personal details to get started.',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 28),
          // Form card
          _glassCard(
            child: Column(
              children: [
                _buildField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  nextFocus: _emailFocus,
                  isFocused: _nameFocused,
                  label: 'FULL NAME',
                  hint: 'Dr. Jane Smith',
                  icon: Icons.person_rounded,
                ),
                _divider(),
                _buildField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _employeeIdFocus,
                  isFocused: _emailFocused,
                  label: 'EMAIL ADDRESS',
                  hint: 'jane@hospital.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                _divider(),
                _buildField(
                  controller: _employeeIdController,
                  focusNode: _employeeIdFocus,
                  nextFocus: _labNameFocus,
                  isFocused: _empFocused,
                  label: 'EMPLOYEE ID',
                  hint: 'EMP-0001 (Optional)',
                  icon: Icons.badge_rounded,
                ),
                _divider(),
                _buildField(
                  controller: _labNameController,
                  focusNode: _labNameFocus,
                  nextFocus: _passwordFocus,
                  isFocused: _labFocused,
                  label: 'LABORATORY NAME',
                  hint: 'City General Hospital Lab',
                  icon: Icons.local_hospital_rounded,
                ),
                _divider(),
                _buildPasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  nextFocus: _confirmPasswordFocus,
                  isFocused: _passFocused,
                  label: 'PASSWORD',
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                _divider(),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  isFocused: _confirmFocused,
                  label: 'CONFIRM PASSWORD',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onSubmitted: (_) => _validateAndNext(),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _errorBanner(_errorMessage!),
          ],
          const SizedBox(height: 24),
          // NEXT button
          _cyanButton(
            label: 'NEXT',
            icon: Icons.arrow_forward_rounded,
            onTap: _validateAndNext,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Select Lab Role
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    final bool canRegister = _selectedRole != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Back button → step 1
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => _animateTo(1),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          // Progress bar
          _buildProgressBar(2),
          const SizedBox(height: 24),
          // Heading
          const Text(
            'What is your role\nin the laboratory?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the role that best describes your position',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 24),
          // Role cards
          ..._labRoles.map((tappedRole) {
            final selected = _selectedRole == tappedRole;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _roleCard(
                role: tappedRole,
                selected: selected,
                onTap: () => setState(() {
                  _selectedRole = tappedRole;
                  _errorMessage = null;
                }),
              ),
            );
          }),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            _errorBanner(_errorMessage!),
          ],
          const SizedBox(height: 20),
          // REGISTER button
          _registerButton(canRegister),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reusable widgets
  // ─────────────────────────────────────────────────────────────────────────

  // Progress bar
  Widget _buildProgressBar(int step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $step of 2',
              style: const TextStyle(
                color: VeriScanTheme.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            Text(
              step == 1 ? 'Personal Details' : 'Select Role',
              style: const TextStyle(
                  color: Color(0xFF888888), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step == 1 ? 0.5 : 1.0,
            minHeight: 3,
            backgroundColor: Colors.white.withAlpha(20),
            valueColor:
                const AlwaysStoppedAnimation<Color>(VeriScanTheme.cyan),
          ),
        ),
      ],
    );
  }

  // Glass card wrapper
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withAlpha(25),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // Field label
  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // Divider
  Widget _divider() => Divider(color: Colors.white.withAlpha(12), height: 1);

  // Text field
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required bool isFocused,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction:
              nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onSubmitted: onSubmitted ??
              (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF555555), fontSize: 14),
            prefixIcon: Icon(
              icon,
              color: isFocused ? VeriScanTheme.cyan : const Color(0xFF555555),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
      ],
    );
  }

  // Password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required bool isFocused,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          textInputAction:
              nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onSubmitted: onSubmitted ??
              (_) {
                if (nextFocus != null) {
                  FocusScope.of(context).requestFocus(nextFocus);
                }
              },
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 18,
              letterSpacing: 3,
            ),
            prefixIcon: Icon(
              Icons.lock_rounded,
              color: isFocused ? VeriScanTheme.cyan : const Color(0xFF555555),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isFocused
                    ? VeriScanTheme.cyan.withAlpha(180)
                    : const Color(0xFF555555),
                size: 20,
              ),
              onPressed: onToggle,
              splashRadius: 18,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
      ],
    );
  }

  // Error banner
  Widget _errorBanner(String message) {
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
          const Icon(Icons.error_rounded, color: VeriScanTheme.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: VeriScanTheme.red, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // Cyan full-width button
  Widget _cyanButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [VeriScanTheme.cyan, VeriScanTheme.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: VeriScanTheme.cyan.withAlpha(70),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // Role card
  Widget _roleCard({
    required _LabRole role,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? VeriScanTheme.cyan.withAlpha(15)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? VeriScanTheme.cyan
                : Colors.white.withAlpha(30),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: VeriScanTheme.cyan.withAlpha(50),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji
            Text(role.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark when selected
            if (selected) ...[
              const SizedBox(width: 12),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VeriScanTheme.cyan.withAlpha(30),
                  border: Border.all(color: VeriScanTheme.cyan, width: 1.5),
                ),
                child: const Icon(Icons.check_rounded,
                    color: VeriScanTheme.cyan, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Register button (active/disabled/loading)
  Widget _registerButton(bool active) {
    return GestureDetector(
      onTap: (active && !_isLoading) ? _handleRegister : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? const LinearGradient(
                  colors: [VeriScanTheme.cyan, VeriScanTheme.purple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF2A2D35), Color(0xFF2A2D35)],
                ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: VeriScanTheme.cyan.withAlpha(70),
                    blurRadius: 22,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.how_to_reg_rounded,
                      color: active ? Colors.white : const Color(0xFF555555),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'REGISTER',
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF555555),
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
}
