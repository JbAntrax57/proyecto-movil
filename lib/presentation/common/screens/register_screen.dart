import 'package:flutter/material.dart';

// register_screen.dart (común) - Pantalla de registro genérica
// Muestra un formulario de registro simple para cualquier rol.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class RegisterScreen extends StatelessWidget {
  // Pantalla de registro genérica
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Scaffold principal con AppBar y mensaje de registro
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: const Center(child: Text('Formulario de registro aquí')),
    );
  }
}
// Fin de register_screen.dart (común)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 