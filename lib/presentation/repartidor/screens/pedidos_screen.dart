import 'package:flutter/material.dart';
import 'mapa_screen.dart';
import 'actualizar_estado_screen.dart';

class RepartidorPedidosScreen extends StatelessWidget {
  const RepartidorPedidosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pedidos = [
      {'id': 1, 'direccion': 'Calle 1 #123', 'estado': 'En camino'},
      {'id': 2, 'direccion': 'Av. Central 45', 'estado': 'Pendiente'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos asignados'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + index * 100),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            ),
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.only(bottom: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text(pedido['id'].toString()),
                ),
                title: Text('Pedido #${pedido['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Dirección: ${pedido['direccion'] as String}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pedido['estado'] as String, style: const TextStyle(color: Colors.blue)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ActualizarEstadoScreen(),
                        ));
                      },
                      style: ElevatedButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                      child: const Icon(Icons.check, size: 18),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const MapaScreen(),
                  ));
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 