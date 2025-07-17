// pedidos_screen.dart - Pantalla de pedidos recibidos para el dueño de negocio
// Permite ver pedidos, simular nuevos pedidos, actualizar estado y ver notificaciones.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'menu_screen.dart';

class DuenioPedidosScreen extends StatefulWidget {
  // Pantalla de pedidos recibidos para el dueño de negocio
  const DuenioPedidosScreen({super.key});
  @override
  State<DuenioPedidosScreen> createState() => _DuenioPedidosScreenState();
}

class _DuenioPedidosScreenState extends State<DuenioPedidosScreen> {
  // Lista simulada de pedidos
  List<Map<String, dynamic>> pedidos = [
    {'id': 1, 'cliente': 'Juan', 'estado': 'Pendiente'},
    {'id': 2, 'cliente': 'Ana', 'estado': 'En preparación'},
  ];
  final List<String> notificaciones = [];

  // Simula la llegada de un nuevo pedido
  void _agregarPedidoSimulado() {
    setState(() {
      final nuevoId = (pedidos.isNotEmpty ? pedidos.last['id'] as int : 0) + 1;
      pedidos.add({'id': nuevoId, 'cliente': 'Cliente $nuevoId', 'estado': 'Pendiente'});
      notificaciones.add('Nuevo pedido recibido de Cliente $nuevoId');
    });
  }

  // Actualiza el estado de un pedido y notifica si está listo para entregar
  void _actualizarEstado(int index, String nuevoEstado) {
    setState(() {
      pedidos[index]['estado'] = nuevoEstado;
      if (nuevoEstado == 'Listo para entregar') {
        notificaciones.add('Pedido #${pedidos[index]['id']} listo para repartidor');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Estado actualizado a "$nuevoEstado"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold principal con lista de pedidos y notificaciones
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos recibidos'), centerTitle: true),
      body: Column(
        children: [
          // Notificaciones de nuevos pedidos o cambios de estado
          if (notificaciones.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.orange[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notificaciones.map((n) => Text('🔔 $n', style: const TextStyle(color: Colors.deepOrange))).toList(),
              ),
            ),
          // Lista de pedidos
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
                        backgroundColor: Colors.orange[100],
                        child: Text(pedido['id'].toString()),
                      ),
                      title: Text('Pedido #${pedido['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cliente: ${pedido['cliente'] as String}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(pedido['estado'] as String, style: const TextStyle(color: Colors.deepOrange)),
                          const SizedBox(height: 8),
                          // Botón para actualizar estado
                          ElevatedButton(
                            onPressed: () async {
                              final nuevoEstado = await showDialog<String>(
                                context: context,
                                builder: (context) => SimpleDialog(
                                  title: const Text('Actualizar estado'),
                                  children: [
                                    SimpleDialogOption(
                                      onPressed: () => Navigator.pop(context, 'En preparación'),
                                      child: const Text('En preparación'),
                                    ),
                                    SimpleDialogOption(
                                      onPressed: () => Navigator.pop(context, 'Listo para entregar'),
                                      child: const Text('Listo para entregar'),
                                    ),
                                    SimpleDialogOption(
                                      onPressed: () => Navigator.pop(context, 'Entregado'),
                                      child: const Text('Entregado'),
                                    ),
                                  ],
                                ),
                              );
                              if (nuevoEstado != null) {
                                _actualizarEstado(index, nuevoEstado);
                              }
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                            child: const Icon(Icons.edit, size: 18),
                          ),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Botones flotantes para simular pedido y ver menú
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _agregarPedidoSimulado,
            icon: const Icon(Icons.add_alert),
            label: const Text('Simular pedido'),
            heroTag: 'simular',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const DuenioMenuScreen(),
            )),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Ver menú'),
            heroTag: 'menu',
          ),
        ],
      ),
    );
  }
}
// Fin de pedidos_screen.dart (dueño)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 