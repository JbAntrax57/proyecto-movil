import 'package:flutter/material.dart';

class ActualizarEstadoScreen extends StatefulWidget {
  const ActualizarEstadoScreen({super.key});

  @override
  State<ActualizarEstadoScreen> createState() => _ActualizarEstadoScreenState();
}

class _ActualizarEstadoScreenState extends State<ActualizarEstadoScreen> {
  bool entregado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar estado del pedido'), centerTitle: true),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + 0.05 * value,
              child: child,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                entregado ? Icons.check_circle : Icons.delivery_dining,
                color: entregado ? Colors.green : Colors.orange,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                entregado ? '¡Pedido entregado!' : '¿Marcar como entregado?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: entregado
                    ? () => Navigator.pop(context)
                    : () => setState(() => entregado = true),
                child: Text(entregado ? 'Volver' : 'Marcar como entregado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 