import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// pedidos_screen.dart - Pantalla de pedidos del cliente
// Permite ver el historial de pedidos realizados y su estado.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class ClientePedidosScreen extends StatefulWidget {
  // Pantalla de historial de pedidos del cliente
  const ClientePedidosScreen({super.key});

  @override
  State<ClientePedidosScreen> createState() => _ClientePedidosScreenState();
}

class _ClientePedidosScreenState extends State<ClientePedidosScreen> {
  // Obtiene los pedidos del usuario desde Supabase
  Future<List<Map<String, dynamic>>> obtenerPedidos(String userEmail) async {
    final data = await Supabase.instance.client
        .from('pedidos')
        .select()
        .eq('usuarioId', userEmail)
        .order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Obtiene el color del estado del pedido
  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtiene el ícono del estado del pedido
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.schedule;
      case 'preparando':
        return Icons.restaurant;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<CarritoProvider>().userEmail;
    
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Mis Pedidos'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerPedidos(userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pedidos = snapshot.data ?? [];
          if (pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes pedidos aún',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Realiza tu primer pedido para verlo aquí',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
              final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
              final estado = pedido['estado'] as String;
              final total = pedido['total'] as int;
              final timestamp = DateTime.parse(pedido['timestamp'] as String);
              
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
                  elevation: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEstadoColor(estado),
                      child: Icon(
                        _getEstadoIcon(estado),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Pedido #${pedido['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getEstadoIcon(estado),
                              size: 16,
                              color: _getEstadoColor(estado),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                color: _getEstadoColor(estado),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$$total',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${productos.length} productos',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      // Lista de productos del pedido
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: productos.map((producto) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  // Imagen del producto
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      producto['img'] as String,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.fastfood,
                                          size: 24,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Detalles del producto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          producto['nombre'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Cantidad: ${producto['cantidad']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Precio del producto
                                  Text(
                                    '\$${(producto['precio'] as int) * (producto['cantidad'] as int)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Barra de progreso del estado (opcional)
                      if (estado != 'entregado' && estado != 'cancelado')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: _getEstadoProgress(estado),
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getEstadoColor(estado),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(_getEstadoProgress(estado) * 100).round()}%',
                                    style: TextStyle(
                                      color: _getEstadoColor(estado),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Calcula el progreso del pedido basado en el estado
  double _getEstadoProgress(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 0.25;
      case 'preparando':
        return 0.5;
      case 'en camino':
        return 0.75;
      case 'entregado':
        return 1.0;
      case 'cancelado':
        return 0.0;
      default:
        return 0.0;
    }
  }
}
// Fin de pedidos_screen.dart (cliente)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 