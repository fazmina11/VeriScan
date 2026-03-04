import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/neon_styles.dart';
import 'auth_provider.dart';

/// Decides where to send the user based on auth state.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Not logged in — redirect to login screen
          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          }
          return _buildLoadingScreen('Redirecting to login...');
        }

        // Logged in — redirect to hub
        if (!_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/hub');
            }
          });
        }
        return _buildLoadingScreen('Loading...');
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
