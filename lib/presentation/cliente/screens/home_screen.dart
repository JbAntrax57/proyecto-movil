// home_screen.dart - Pantalla de inicio para el cliente
// Muestra un mensaje de bienvenida o contenido principal del home del cliente.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';

class ClienteHomeScreen extends StatelessWidget {
  // Pantalla de inicio para el cliente
  const ClienteHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Scaffold principal con mensaje de bienvenida
    return const Scaffold(
      body: Center(child: Text('Home Cliente')),
    );
  }
}
// Fin de home_screen.dart (cliente)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 