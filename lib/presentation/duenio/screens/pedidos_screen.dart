// pedidos_screen.dart - Pantalla de pedidos recibidos para el dueño de negocio
// Permite ver pedidos, simular nuevos pedidos, actualizar estado y ver notificaciones.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';
import '../../cliente/providers/carrito_provider.dart';

class DuenioPedidosScreen extends StatefulWidget {
  // Pantalla de pedidos recibidos para el dueño de negocio
  const DuenioPedidosScreen({super.key});
  @override
  State<DuenioPedidosScreen> createState() => _DuenioPedidosScreenState();
}

class _DuenioPedidosScreenState extends State<DuenioPedidosScreen> {
  final List<String> notificaciones = [];

  // Actualiza el estado de un pedido en Firestore y notifica
  Future<void> _actualizarEstado(String pedidoId, String nuevoEstado) async {
    await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update(
      {'estado': nuevoEstado},
    );
    if (nuevoEstado == 'Listo para entregar') {
      notificaciones.add('Pedido $pedidoId listo para repartidor');
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Estado actualizado a "$nuevoEstado"')),
    );
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where('restauranteId', isEqualTo: restauranteId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar pedidos'));
                }
                final pedidos = snapshot.data?.docs ?? [];
                if (pedidos.isEmpty) {
                  return const Center(
                    child: Text('No hay pedidos para este restaurante.'),
                  );
                }
                // Agrupamos los pedidos por estado
                final Map<String, List<QueryDocumentSnapshot>>
                pedidosPorEstado = {};
                for (final pedido in pedidos) {
                  final data = pedido.data() as Map<String, dynamic>;
                  final estado = (data['estado'] ?? 'pendiente')
                      .toString()
                      .toLowerCase();
                  pedidosPorEstado.putIfAbsent(estado, () => []).add(pedido);
                }
                // Definimos el orden de los estados
                final ordenEstados = [
                  'pendiente',
                  'en preparación',
                  'listo para entregar',
                  'entregado',
                ];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final estado in ordenEstados)
                      if (pedidosPorEstado[estado]?.isNotEmpty ?? false) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            estado[0].toUpperCase() + estado.substring(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ...pedidosPorEstado[estado]!.map((pedido) {
                          final data = pedido.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              // Al dar clic, mostramos un diálogo con el detalle del pedido
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final productos = (data['productos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
                                  final total = data['total'] ?? 0;
                                  return AlertDialog(
                                    title: const Text('Detalle del pedido'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Cliente: ${data['usuarioNombre'] ?? ''}'),
                                          const SizedBox(height: 8),
                                          Text('Dirección: ${data['ubicacion'] ?? ''}'),
                                          if ((data['detallesAdicionales'] ?? '').toString().isNotEmpty)
                                            Text('Detalles: ${data['detallesAdicionales']}'),
                                          const Divider(height: 18),
                                          const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ...productos.map((p) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Text('- ${p['nombre']} x${p['cantidad']} ( \$${p['precio']})'),
                                          )),
                                          const Divider(height: 18),
                                          Text('Total:  \$$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Card(
                              color: _colorPorEstado(data['estado'] ?? ''), // Color según estado
                              elevation: 5,
                              margin: const EdgeInsets.only(bottom: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Avatar con iniciales
                                    CircleAvatar(
                                      backgroundColor: Colors.orange[100],
                                      child: Text('${pedido.id.substring(0, 2)}'),
                                    ),
                                    const SizedBox(width: 12),
                                    // Contenido principal del pedido
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Pedido', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Cliente: ${data['usuarioNombre'] ?? ''}'),
                                          Text('Estado: ${data['estado']}'),
                                          // Resumen de productos pedidos
                                          if ((data['productos'] as List?) != null && (data['productos'] as List).isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                'Productos: ' +
                                                  (data['productos'] as List)
                                                    .map((p) => '${p['nombre']} x${p['cantidad']}')
                                                    .join(', '),
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Estado y botón en columna
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          data['estado'] as String,
                                          style: const TextStyle(color: Colors.deepOrange),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final nuevoEstado = await showDialog<String>(
                                              context: context,
                                              builder: (context) => SimpleDialog(
                                                title: const Text('Actualizar estado'),
                                                children: [
                                                  SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
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
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (nuevoEstado != null) {
                                              await _actualizarEstado(pedido.id, nuevoEstado);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(32, 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Icon(Icons.edit, size: 18),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                  ],
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