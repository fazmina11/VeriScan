import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/ble_service.dart';
import 'core/theme.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'features/onboarding/role_selection_screen.dart';
import 'features/hub/control_center_screen.dart';
import 'features/scan/scanning_screen.dart';
import 'features/scan/processing_screen.dart';
import 'features/results/authentic_result_screen.dart';
import 'features/results/danger_result_screen.dart';
import 'features/report/purchase_location_screen.dart';
import 'features/report/map_pin_screen.dart';
import 'features/report/evidence_upload_screen.dart';
import 'features/report/review_submit_screen.dart';
import 'features/report/report_confirmation_screen.dart';
import 'features/map/community_map_screen.dart';
// ── Auth screens ──
import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/individual_registration_screen.dart';
import 'features/auth/professional_registration_screen.dart';
import 'features/hub/settings_screen.dart';
import 'features/ble/ble_connect_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: VeriScanTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => BleService(),
        child: const VeriScanApp(),
      ),
    ),
  );
}

class VeriScanApp extends ConsumerWidget {
  const VeriScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'VeriScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.neonLight,
      darkTheme: VeriScanTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/auth-gate',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      // ── Auth routes ──
      case '/auth-gate':
        page = const AuthGate();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/signup':
      case '/register':          // primary registration entry point
        page = const RegisterScreen();
        break;
      case '/register-individual':
        page = const IndividualRegistrationScreen();
        break;
      case '/register-professional':
        page = const ProfessionalRegistrationScreen();
        break;
      // ── Existing routes (unchanged) ──
      case '/':
        page = const RoleSelectionScreen();
        break;
      case '/hub':
        page = const ControlCenterScreen();
        break;
      case '/scanning':
        page = const ScanningScreen();
        break;
      case '/processing':
        page = const ProcessingScreen();
        break;
      case '/result-authentic':
        page = const AuthenticResultScreen();
        break;
      case '/result-danger':
        page = const DangerResultScreen();
        break;
      case '/report-location':
        page = const PurchaseLocationScreen();
        break;
      case '/report-map':
        page = const MapPinScreen();
        break;
      case '/report-evidence':
        page = const EvidenceUploadScreen();
        break;
      case '/report-review':
        page = const ReviewSubmitScreen();
        break;
      case '/report-confirmation':
        page = const ReportConfirmationScreen();
        break;
      case '/community-map':
        page = const CommunityMapScreen();
        break;
      case '/settings':
        page = const SettingsScreen();
        break;
      case '/ble-connect':
        page = const BleConnectScreen();
        break;
      default:
        page = const AuthGate();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var slideTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
