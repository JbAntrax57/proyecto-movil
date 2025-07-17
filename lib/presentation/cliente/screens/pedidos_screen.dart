import 'package:flutter/material.dart';

// pedidos_screen.dart - Pantalla de pedidos del cliente
// Permite ver el historial de pedidos realizados y su estado.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class ClientePedidosScreen extends StatelessWidget {
  // Pantalla de historial de pedidos del cliente
  const ClientePedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista simulada de pedidos del cliente
    final pedidos = [
      {'id': 1, 'estado': 'En camino', 'total': 190},
      {'id': 2, 'estado': 'Entregado', 'total': 80},
    ];
    // Scaffold principal con lista de pedidos
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: ListView.builder(
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
          // Muestra información básica del pedido
          return ListTile(
            title: Text('Pedido #${pedido['id']}'),
            subtitle: Text('Estado: ${pedido['estado']}'),
            trailing: Text(' 24${pedido['total']}'),
          );
        },
      ),
    );
  }
}
// Fin de pedidos_screen.dart (cliente)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 