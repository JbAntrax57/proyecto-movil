// mapa_screen.dart - Pantalla de mapa de entrega para el repartidor
// Muestra un mapa simulado y permite volver a la lista de pedidos.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';

class MapaScreen extends StatelessWidget {
  // Pantalla de mapa de entrega para el repartidor
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold principal con animación y visualización de mapa
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de entrega'), centerTitle: true),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contenedor que simula el mapa
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Icon(Icons.map, size: 120, color: Colors.blueAccent),
              ),
              const SizedBox(height: 32),
              // Botón para volver
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Fin de mapa_screen.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 