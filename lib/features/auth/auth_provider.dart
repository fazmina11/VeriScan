import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Provides a singleton [AuthService] instance (no Firebase).
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Async provider that checks if a valid JWT token is stored.
/// Returns [true] if logged in, [false] if not.
final authStateProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.checkAuthState();
});
