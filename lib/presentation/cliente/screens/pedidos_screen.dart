import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/pedidos_provider.dart';

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
  @override
  void initState() {
    super.initState();
    // Inicializar el provider con el email del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail != null) {
        context.read<PedidosProvider>().setUserEmail(userEmail);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Mis Pedidos'),
        centerTitle: true,
      ),
      body: Consumer<PedidosProvider>(
        builder: (context, pedidosProvider, child) {
          // Mostrar loading
          if (pedidosProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mostrar error
          if (pedidosProvider.error != null) {
            return Center(child: Text('Error: ${pedidosProvider.error}'));
          }

          // Mostrar estado vacío
          if (!pedidosProvider.tienePedidos) {
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => pedidosProvider.recargarPedidos(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidosProvider.pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidosProvider.pedidos[index];
                final productos = pedidosProvider.getProductosPedido(pedido);
                final estado = pedido['estado'] as String;
                final total = pedidosProvider.calcularTotalPedido(pedido);
                final fechaFormateada = pedidosProvider.formatearFechaPedido(pedido);

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
                      backgroundColor: pedidosProvider.getEstadoColor(estado),
                      child: Icon(pedidosProvider.getEstadoIcon(estado), color: Colors.white),
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
                              pedidosProvider.getEstadoIcon(estado),
                              size: 16,
                              color: pedidosProvider.getEstadoColor(estado),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                color: pedidosProvider.getEstadoColor(estado),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fechaFormateada,
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
                          '\$${total.toStringAsFixed(2)}',
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                      if (pedidosProvider.isPedidoActivo(estado))
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
                                      value: pedidosProvider.getEstadoProgress(estado),
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        pedidosProvider.getEstadoColor(estado),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(pedidosProvider.getEstadoProgress(estado) * 100).round()}%',
                                    style: TextStyle(
                                      color: pedidosProvider.getEstadoColor(estado),
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
          ),
        );
        },
      ),
    );
  }
}
// Fin de pedidos_screen.dart (cliente)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 