import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import 'auth_provider.dart';

/// Decides where to send the user based on stored JWT token.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushReplacementNamed(
              context,
              isLoggedIn ? '/hub' : '/login',
            );
          }
        });
        return _buildLoadingScreen(isLoggedIn ? 'Loading...' : 'Redirecting to login...');
      },
      loading: () => _buildLoadingScreen('Connecting...'),
      error: (e, _) => _buildLoadingScreen('Connection Error'),
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: Container(
        decoration: NeonStyles.radialGlow(color: VeriScanTheme.purple),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(VeriScanTheme.cyan),
                ),
              ),
              const SizedBox(height: 20),
              Text(message,
                  style: const TextStyle(color: VeriScanTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
