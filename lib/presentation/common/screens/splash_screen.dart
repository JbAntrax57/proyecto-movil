// splash_screen.dart - Pantalla de carga inicial (splash)
// Muestra un mensaje de carga mientras se inicializa la app.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  // Pantalla de splash/carga inicial
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Scaffold principal con mensaje de carga
    return const Scaffold(
      body: Center(child: Text('Cargando...')),
    );
  }
}
// Fin de splash_screen.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 