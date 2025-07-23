import 'package:flutter/material.dart';
import '../../cliente/screens/login_screen.dart';

// Redirige al login funcional de cliente
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const ClienteLoginScreen(); // Usa el login funcional
  }
}
// Fin de login_screen.dart (común)
// Este archivo redirige al login funcional de cliente para evitar duplicidad. 