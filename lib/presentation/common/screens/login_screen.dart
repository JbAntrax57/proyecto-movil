import 'package:flutter/material.dart';

// login_screen.dart (común) - Pantalla de login genérica
// Muestra un formulario de login simple para cualquier rol.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class LoginScreen extends StatelessWidget {
  // Pantalla de login genérica
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Scaffold principal con AppBar y mensaje de login
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: const Center(child: Text('Formulario de login aquí')),
    );
  }
}
// Fin de login_screen.dart (común)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 