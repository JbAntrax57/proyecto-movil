import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';

// carrito_screen.dart - Pantalla de carrito de compras para el cliente
// Permite ver, modificar y eliminar productos del carrito, calcular el total y realizar el pedido.
// Incluye selección de ubicación (actual o manual) antes de enviar el pedido.
class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>().carrito;
    final total = carrito.fold(0, (int sum, item) => sum + (item['precio'] as int) * (item['cantidad'] as int));
    String? ubicacion; // Ubicación seleccionada para el pedido
    bool pedidoRealizado = false; // Indica si el pedido fue realizado

    // Lógica para eliminar un producto del carrito con confirmación
    void _eliminarProducto(int index) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar producto'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este producto del carrito?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        context.read<CarritoProvider>().eliminarProducto(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado del carrito')),
        );
      }
    }

    // Lógica para limpiar todo el carrito con confirmación
    void _limpiarCarrito() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vaciar carrito'),
          content: const Text(
            '¿Estás seguro de que deseas vaciar todo el carrito?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Vaciar'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        context.read<CarritoProvider>().limpiarCarrito();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Carrito vaciado')));
      }
    }

    // Lógica para realizar el pedido: solicita ubicación y limpia el carrito
    void _realizarPedido() async {
      if (carrito.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El carrito está vacío')), // Validación
        );
        return;
      }
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => UbicacionModal(),
      );
      if (result != null && result.isNotEmpty) {
        // Agrupar productos por restaurante
        final productosPorRestaurante = <String, List<Map<String, dynamic>>>{};
        final restauranteInfo = <String, Map<String, dynamic>>{};
        for (final producto in carrito) {
          final restauranteId = producto['restauranteId'] as String? ?? 'sin_id';
          if (!productosPorRestaurante.containsKey(restauranteId)) {
            productosPorRestaurante[restauranteId] = [];
            restauranteInfo[restauranteId] = {
              'restauranteNombre': producto['restaurante'] ?? 'Restaurante',
              'restauranteId': restauranteId,
            };
          }
          productosPorRestaurante[restauranteId]!.add(producto);
        }
        // Obtener datos del usuario actual
        final userProvider = Provider.of<CarritoProvider>(context, listen: false);
        final usuarioId = userProvider.userEmail ?? 'sin_uid';
        String usuarioNombre = '';
        try {
          final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId).get();
          usuarioNombre = userDoc.data()?['nombre'] ?? '';
        } catch (_) {}
        // Crear un pedido por restaurante
        bool allOk = true;
        for (final entry in productosPorRestaurante.entries) {
          final restauranteId = entry.key;
          final productos = entry.value;
          final info = restauranteInfo[restauranteId]!;
          final total = productos.fold(0, (int sum, item) => sum + (item['precio'] as int) * (item['cantidad'] as int));
          try {
            await FirebaseFirestore.instance.collection('pedidos').add({
              'usuarioId': usuarioId,
              'usuarioNombre': usuarioNombre,
              'restauranteId': restauranteId,
              'restauranteNombre': info['restauranteNombre'],
              'productos': productos,
              'total': total,
              'ubicacion': result,
              'estado': 'pendiente',
              'timestamp': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            allOk = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al crear pedido: $e')),
            );
          }
        }
        if (allOk) {
          context.read<CarritoProvider>().limpiarCarrito();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Pedido realizado! El negocio ha sido notificado.'),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de compras'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, carrito);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: carrito.isEmpty
                ? Center(
                    child: pedidoRealizado
                        ? const Text(
                            '¡Pedido realizado! Espera la confirmación del negocio.',
                          )
                        : const Text('El carrito está vacío'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      // Animación de aparición para cada producto
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
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar con inicial del producto
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(item['nombre'].toString()[0]),
                                ),
                                const SizedBox(width: 12),
                                // Detalles del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['nombre'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          // Botón para disminuir cantidad
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: item['cantidad'] > 1
                                                ? () {
                                                    context.read<CarritoProvider>().modificarCantidad(index, -1);
                                                  }
                                                : null,
                                          ),
                                          Text(
                                            'Cantidad: ${item['cantidad']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          // Botón para aumentar cantidad
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              context.read<CarritoProvider>().modificarCantidad(index, 1);
                                            },
                                          ),
                                          // Botón para eliminar producto
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _eliminarProducto(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Precio total del producto
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    '\$${(item['precio'] as int) * (item['cantidad'] as int)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Resumen y botón de pedido
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '\$$total',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: carrito.isEmpty ? null : _realizarPedido,
                  icon: const Icon(Icons.send),
                  label: const Text('Realizar pedido'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Muestra la ubicación seleccionada si existe
          if (ubicacion != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ubicación: $ubicacion',
                style: const TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}

// Modal para seleccionar ubicación (actual o manual)
class UbicacionModal extends StatefulWidget {
  @override
  State<UbicacionModal> createState() => _UbicacionModalState();
}

class _UbicacionModalState extends State<UbicacionModal> {
  String? direccionManual;
  String? ubicacionActual;
  bool buscando = false;

  // Obtiene la ubicación actual usando geolocator
  Future<void> _obtenerUbicacion() async {
    setState(() => buscando = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        ubicacionActual = 'Lat: ${pos.latitude}, Lng: ${pos.longitude}';
        buscando = false;
      });
    } catch (e) {
      setState(() => buscando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modal con opciones para ubicación actual o dirección manual
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona tu ubicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Botón para obtener ubicación actual
              ElevatedButton.icon(
                onPressed: buscando ? null : _obtenerUbicacion,
                icon: const Icon(Icons.my_location),
                label: const Text('Usar ubicación actual'),
              ),
              if (ubicacionActual != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Ubicación actual: $ubicacionActual',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const Divider(height: 32),
              // Campo para dirección manual
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Dirección manual',
                ),
                onChanged: (v) => setState(() => direccionManual = v),
              ),
              const SizedBox(height: 16),
              // Botón para confirmar ubicación
              ElevatedButton.icon(
                onPressed: () {
                  final ubic = ubicacionActual ?? direccionManual;
                  if (ubic == null || ubic.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes ingresar o seleccionar una ubicación.',
                        ),
                      ),
                    );
                  } else {
                    Navigator.pop(context, ubic);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirmar ubicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
