import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final usuarios = 10;
    final negocios = 3;
    final pedidos = 25;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Administrador'), centerTitle: true),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.people, color: Colors.blue, size: 36),
                  title: Text('Usuarios registrados: $usuarios', style: const TextStyle(fontSize: 20)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gestión de usuarios (simulado)')),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.store, color: Colors.green, size: 36),
                  title: Text('Negocios activos: $negocios', style: const TextStyle(fontSize: 20)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gestión de negocios (simulado)')),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.deepOrange, size: 36),
                  title: Text('Pedidos totales: $pedidos', style: const TextStyle(fontSize: 20)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gestión de pedidos (simulado)')),
                      );
                    },
                    child: const Text('Gestionar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 