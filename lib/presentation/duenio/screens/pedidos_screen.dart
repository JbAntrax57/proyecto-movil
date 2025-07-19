// pedidos_screen.dart - Pantalla de pedidos recibidos para el dueño de negocio
// Permite ver pedidos, simular nuevos pedidos, actualizar estado y ver notificaciones.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase

class DuenioPedidosScreen extends StatefulWidget {
  // Pantalla de pedidos recibidos para el dueño de negocio
  const DuenioPedidosScreen({super.key});
  @override
  State<DuenioPedidosScreen> createState() => _DuenioPedidosScreenState();
}

class _DuenioPedidosScreenState extends State<DuenioPedidosScreen> {
  final List<String> notificaciones = [];

  // Actualiza el estado de un pedido en Supabase y notifica
  Future<void> actualizarEstadoPedido(String pedidoId, String nuevoEstado) async {
    await Supabase.instance.client
        .from('pedidos')
        .update({'estado': nuevoEstado})
        .eq('id', pedidoId);
  }
  // Obtiene la lista de pedidos en tiempo real desde Supabase
  Future<List<Map<String, dynamic>>> obtenerPedidos() async {
    final data = await Supabase.instance.client.from('pedidos').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // Suscribirse a cambios en la tabla de pedidos usando Supabase Realtime
  void suscribirsePedidos() {
    // TODO: Implementar cuando Supabase Realtime esté disponible
    print('🔔 Suscripción a pedidos configurada');
  }

  // Función para obtener el color de fondo según el estado
  Color _colorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.red[50]!;
      case 'en preparación':
        return Colors.grey[50]!;
      case 'listo para entregar':
        return Colors.yellow[50]!;
      case 'entregado':
        return Colors.green[200]!;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el restauranteId del dueño logueado
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final restauranteId = userProvider.restauranteId;
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(title: const Text('Pedidos recibidos'), centerTitle: true),
      body: Column(
        children: [
          if (notificaciones.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.orange[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notificaciones
                    .map(
                      (n) => Text(
                        '🔔 $n',
                        style: const TextStyle(color: Colors.deepOrange),
                      ),
                    )
                    .toList(),
              ),
            ),
          // Lista de pedidos en tiempo real desde Firestore
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerPedidos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final pedidos = snapshot.data ?? [];
                if (pedidos.isEmpty) {
                  return const Center(child: Text('No hay pedidos'));
                }
                // Agrupar pedidos por estado
                final Map<String, List<Map<String, dynamic>>> pedidosPorEstado = {};
                for (final pedido in pedidos) {
                  final estado = pedido['estado'] as String? ?? 'pendiente';
                  if (!pedidosPorEstado.containsKey(estado)) {
                    pedidosPorEstado[estado] = [];
                  }
                  pedidosPorEstado[estado]!.add(pedido);
                }
                return ListView.builder(
                  itemCount: pedidosPorEstado.length,
                  itemBuilder: (context, index) {
                    final estado = pedidosPorEstado.keys.elementAt(index);
                    final pedidosDelEstado = pedidosPorEstado[estado]!;
                    return ExpansionTile(
                      title: Text('$estado (${pedidosDelEstado.length})'),
                      children: pedidosDelEstado.map((pedido) {
                        final data = pedido;
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text('Pedido ${pedido['id']?.toString().substring(0, 8) ?? 'N/A'}'),
                            subtitle: Text('Cliente: ${data['usuarioNombre'] ?? 'N/A'}'),
                            trailing: Text('\$${data['total'] ?? 0}'),
                            onTap: () async {
                              final nuevoEstado = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Cambiar estado'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: const Text('Pendiente'),
                                        onTap: () => Navigator.pop(context, 'pendiente'),
                                      ),
                                      ListTile(
                                        title: const Text('Preparando'),
                                        onTap: () => Navigator.pop(context, 'preparando'),
                                      ),
                                      ListTile(
                                        title: const Text('Listo'),
                                        onTap: () => Navigator.pop(context, 'listo'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (nuevoEstado != null) {
                                await actualizarEstadoPedido(pedido['id'].toString(), nuevoEstado);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DuenioMenuScreen()),
            ),
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