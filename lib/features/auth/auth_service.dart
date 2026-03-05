import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication service backed by VeriScan FastAPI.
/// Replaces the removed Firebase Auth + Firestore implementation.
class AuthService {
  static const _tokenKey = 'jwt_token';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey = 'user_role';

  final _storage = const FlutterSecureStorage();

  // ── Token helpers ──

  Future<String?> getStoredToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> saveUserMeta({required String email, required String role}) async {
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getStoredEmail() => _storage.read(key: _userEmailKey);
  Future<String?> getStoredRole() => _storage.read(key: _userRoleKey);

  /// Returns true if a JWT token is present in secure storage.
  Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  // ── Auth state stream (replaces Firebase authStateChanges) ──

  /// Emits [true] if logged in, [false] otherwise.
  /// Checked once on startup; BLoC/Notifier handles subsequent changes.
  Future<bool> checkAuthState() => isLoggedIn();

  // ── API calls (wired to FastAPI in next phase) ──

  /// Sign in with email and password.
  /// Calls POST /auth/login on the FastAPI backend.
  /// Returns the JWT token on success.
  Future<String> signInWithEmail(String email, String password) async {
    // TODO: wire to ApiService.post('/auth/login', {...})
    throw UnimplementedError('signInWithEmail: FastAPI not yet wired.');
  }

  /// Sign up with email and password.
  /// Calls POST /auth/register on the FastAPI backend.
  Future<String> signUpWithEmail(String email, String password) async {
    // TODO: wire to ApiService.post('/auth/register', {...})
    throw UnimplementedError('signUpWithEmail: FastAPI not yet wired.');
  }

  /// Save individual user profile.
  Future<void> saveIndividualProfile({
    required String fullName,
    required bool locationEnabled,
  }) async {
    // TODO: wire to ApiService.post('/auth/profile', {...})
    throw UnimplementedError('saveIndividualProfile: FastAPI not yet wired.');
  }

  /// Save professional user profile.
  Future<void> saveProfessionalProfile({
    required String organizationName,
    required String licenseId,
    required String businessAddress,
    required String roleType,
  }) async {
    // TODO: wire to ApiService.post('/auth/profile', {...})
    throw UnimplementedError('saveProfessionalProfile: FastAPI not yet wired.');
  }

  /// Sign out — clears all stored tokens.
  Future<void> signOut() async {
    await _storage.deleteAll();
  }
}
