import 'package:flutter/material.dart';
import 'mapa_screen.dart';
import 'actualizar_estado_screen.dart';

// pedidos_screen.dart - Pantalla de pedidos asignados para el repartidor
// Permite ver pedidos asignados, simular nuevos pedidos preparados, navegar al mapa y actualizar estado de entrega.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class RepartidorPedidosScreen extends StatefulWidget {
  // Pantalla de pedidos asignados para el repartidor
  const RepartidorPedidosScreen({super.key});
  @override
  State<RepartidorPedidosScreen> createState() => _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  // Lista simulada de pedidos asignados
  List<Map<String, dynamic>> pedidos = [
    {'id': 1, 'direccion': 'Calle 1 #123', 'estado': 'En camino'},
    {'id': 2, 'direccion': 'Av. Central 45', 'estado': 'Pendiente'},
  ];
  final List<String> notificaciones = [];

  // Simula la llegada de un nuevo pedido preparado
  void _agregarPedidoPreparado() {
    setState(() {
      final nuevoId = (pedidos.isNotEmpty ? pedidos.last['id'] as int : 0) + 1;
      pedidos.add({'id': nuevoId, 'direccion': 'Dirección simulada', 'estado': 'Listo para entregar'});
      notificaciones.add('Nuevo pedido #$nuevoId listo para entregar');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold principal con lista de pedidos y notificaciones
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos asignados'), centerTitle: true),
      body: Column(
        children: [
          // Notificaciones de nuevos pedidos preparados
          if (notificaciones.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.green[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notificaciones.map((n) => Text('🔔 $n', style: const TextStyle(color: Colors.green))).toList(),
              ),
            ),
          // Lista de pedidos asignados
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                // Animación de aparición para cada pedido
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
                          // Botón para actualizar estado (navega a pantalla de actualización)
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
                      // Al tocar el pedido, navega al mapa de entrega
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
          ),
        ],
      ),
      // Botón flotante para simular pedido preparado
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPedidoPreparado,
        icon: const Icon(Icons.notifications_active),
        label: const Text('Simular pedido preparado'),
      ),
    );
  }
}
// Fin de pedidos_screen.dart (repartidor)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 