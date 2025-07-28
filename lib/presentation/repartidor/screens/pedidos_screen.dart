import 'package:flutter/material.dart';
import 'notificaciones_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cliente/screens/login_screen.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../providers/pedidos_repartidor_provider.dart';

// pedidos_screen.dart - Pantalla de pedidos asignados para el repartidor
// Refactorizada para usar PedidosRepartidorProvider y separar lógica de negocio
class RepartidorPedidosScreen extends StatefulWidget {
  const RepartidorPedidosScreen({super.key});
  @override
  State<RepartidorPedidosScreen> createState() => _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PedidosRepartidorProvider>().inicializarPedidos(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidosRepartidorProvider>(
      builder: (context, pedidosProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(pedidosProvider.selectedIndex == 0 ? 'Pedidos disponibles' : 'Mis pedidos'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('isLoggedIn');
                  await prefs.remove('userRol');
                  await prefs.remove('userId');
                                     if (context.mounted) {
                     Provider.of<CarritoProvider>(context, listen: false).setUserEmail('');
                     Provider.of<CarritoProvider>(context, listen: false).setUserId('');
                     Provider.of<CarritoProvider>(context, listen: false).setRestauranteId(null);
                   }
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ClienteLoginScreen()),
                    (route) => false,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Ver notificaciones',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RepartidorNotificacionesScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: () => pedidosProvider.cargarAmbasListas(context),
              ),
            ],
          ),
          body: pedidosProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (pedidosProvider.notificaciones.isNotEmpty)
                    Container(
                      width: double.infinity,
                      color: Colors.green[50],
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pedidosProvider.notificaciones.map((n) => Text('🔔 $n', style: const TextStyle(color: Colors.green))).toList(),
                      ),
                    ),
                  Expanded(
                    child: pedidosProvider.selectedIndex == 0
                      ? _buildPedidosList(pedidosProvider.pedidosDisponibles, true, pedidosProvider)
                      : _buildPedidosList(pedidosProvider.misPedidos, false, pedidosProvider),
                  ),
                ],
              ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: pedidosProvider.selectedIndex,
            onTap: (index) => pedidosProvider.setSelectedIndex(index),
            items: [
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.assignment_turned_in),
                    if (pedidosProvider.pedidosDisponibles.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            pedidosProvider.pedidosDisponibles.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Disponibles',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Mis pedidos',
              ),
            ],
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  Widget _buildPedidosList(List<Map<String, dynamic>> pedidos, bool mostrarTomar, PedidosRepartidorProvider pedidosProvider) {
    if (pedidos.isEmpty) {
      return const Center(child: Text('No hay pedidos para mostrar.', style: TextStyle(color: Colors.grey)));
    }
    
    final pedidosOrdenados = pedidosProvider.getPedidosOrdenados(pedidos);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pedidosOrdenados.length,
      itemBuilder: (context, index) {
        final pedido = pedidosOrdenados[index];
        final productos = List<Map<String, dynamic>>.from(
          pedido['productos'] ?? [],
        );
        final total = pedidosProvider.calcularTotalPedido(productos);
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estado y fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pedido['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Folio: ${pedidosProvider.obtenerFolio(pedido['id']?.toString())}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          _formatearFechaPedido(pedido['created_at']?.toString()),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Productos
                Text(
                  'Productos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...productos.take(3).map(
                  (producto) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '• ${producto['nombre']?.toString() ?? 'Sin nombre'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          'x${producto['cantidad']?.toString() ?? '1'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                if (productos.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '... y ${productos.length - 3} más',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(),
                // Total y ubicación
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                    ),
                    // Mostrar dirección de entrega si existe en cualquier campo común
                    () {
                      final direccion = pedido['direccion_entrega'] ?? pedido['direccion'] ?? pedido['direccionEntrega'];
                      if (direccion != null && direccion.toString().isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  direccion,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                    // Mostrar referencias si existen (solo en 'Mis pedidos')
                    if (!mostrarTomar) ...[
                      if (pedido['referencias'] != null && pedido['referencias'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  pedido['referencias'],
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    // Botón para marcar como entregado debajo de la dirección en 'Mis pedidos'
                    if (!mostrarTomar && (pedido['estado']?.toString().toLowerCase() == 'en camino'))
                      Padding(
                        padding: const EdgeInsets.only(top: 14.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: pedidosProvider.isLoading ? null : () => pedidosProvider.marcarEntregado(context, pedido),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('Marcar como entregado'),
                          ),
                        ),
                      ),
                  ],
                ),
                // Botón para tomar pedido directamente debajo de la dirección
                if (mostrarTomar)
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: pedidosProvider.isLoading ? null : () async {
                          await pedidosProvider.tomarPedido(context, pedido);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tomar pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatearFechaPedido(String? fecha) {
    if (fecha == null) return '';
    try {
      final date = DateTime.parse(fecha);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Hoy';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }
} 