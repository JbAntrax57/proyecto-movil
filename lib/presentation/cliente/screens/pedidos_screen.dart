import 'package:flutter/material.dart';

class ClientePedidosScreen extends StatelessWidget {
  const ClientePedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pedidos = [
      {'id': 1, 'estado': 'En camino', 'total': 190},
      {'id': 2, 'estado': 'Entregado', 'total': 80},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: ListView.builder(
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
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