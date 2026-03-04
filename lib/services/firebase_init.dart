import 'package:firebase_core/firebase_core.dart';

/// Initialize Firebase services.
/// NOTE: Requires google-services.json (Android) and
/// GoogleService-Info.plist (iOS) to be configured in the project.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
}
