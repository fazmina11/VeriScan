import 'package:flutter/material.dart';

/// Replaced by RegisterScreen. Redirects to /login to prevent errors.
class ProfessionalRegistrationScreen extends StatelessWidget {
  const ProfessionalRegistrationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
