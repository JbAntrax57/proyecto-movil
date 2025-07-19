import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase

// carrito_screen.dart - Pantalla de carrito de compras para el cliente
// Permite ver, modificar y eliminar productos del carrito, calcular el total y realizar el pedido.
// Incluye selección de ubicación (actual o manual) antes de enviar el pedido.
class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>().carrito;
    final total = carrito.fold(
      0,
      (int sum, item) =>
          sum + (item['precio'] as int) * (item['cantidad'] as int),
    );
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

    // Lógica para realizar el pedido usando Supabase
    void _realizarPedido() async {
      if (carrito.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El carrito está vacío')),
        );
        return;
      }
      // Aquí implementarías la lógica para crear el pedido en Supabase
      try {
        // Crear el pedido en Supabase
        await Supabase.instance.client.from('pedidos').insert({
          'usuarioId': context.read<CarritoProvider>().userEmail,
          'productos': carrito,
          'total': total,
          'estado': 'pendiente',
          'timestamp': DateTime.now().toIso8601String(),
        });
        // Limpiar el carrito
        context.read<CarritoProvider>().limpiarCarrito();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pedido realizado con éxito!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al realizar el pedido: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Carrito de compras'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, carrito);
          },
        ),
        actions: [
          if (carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _limpiarCarrito,
              tooltip: 'Vaciar carrito',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: carrito.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu carrito está vacío',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega algunos productos para comenzar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
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
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen del producto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['img'] as String,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Detalles del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['nombre'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['descripcion'] as String? ??
                                            'Delicioso y recién hecho',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${item['precio']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Controles de cantidad
                                Column(
                                  children: [
                                    // Botón para eliminar
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarProducto(index),
                                      tooltip: 'Eliminar producto',
                                    ),
                                    const SizedBox(height: 8),
                                    // Controles de cantidad
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Botón para disminuir cantidad
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: item['cantidad'] > 1
                                                ? () {
                                                    context
                                                        .read<CarritoProvider>()
                                                        .modificarCantidad(
                                                          index,
                                                          -1,
                                                        );
                                                  }
                                                : null,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                          ),
                                        ),
                                        // Cantidad
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '${item['cantidad']}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Botón para aumentar cantidad
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: () {
                                              context
                                                  .read<CarritoProvider>()
                                                  .modificarCantidad(
                                                    index,
                                                    1,
                                                  );
                                            },
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Resumen del pedido y botón de realizar pedido
          if (carrito.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Resumen del total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$$total',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Botón para realizar pedido
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _realizarPedido,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Realizar Pedido'),
                    ),
                  ),
                ],
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

  // Obtiene la ubicación actual usando geolocator y la convierte a dirección legible
  Future<void> _obtenerUbicacion() async {
    setState(() => buscando = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      // Geocoding inverso
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        ubicacionActual =
            '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}';
      } else {
        ubicacionActual = 'Lat: ${pos.latitude}, Lng: ${pos.longitude}';
      }
      setState(() => buscando = false);
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
              Padding(
                padding: EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  'Detalles adicionales',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[950],
                  ),
                ),
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Color de casa, nombre de la calle, etc.',
                ),
                onChanged: (v) => setState(() => direccionManual = v),
              ),
              const SizedBox(height: 16),
              // Botón para confirmar ubicación
              ElevatedButton.icon(
                onPressed: () async {
                  // Obtenemos la ubicación y los detalles adicionales ingresados por el usuario
                  final ubic = ubicacionActual;
                  final detallesAdicionales = direccionManual ?? '';
                  // Validamos que ambos campos no estén vacíos
                  if (ubic == null ||
                      ubic.isEmpty ||
                      detallesAdicionales.isEmpty) {
                    // Mostramos un AlertDialog si faltan los detalles
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Faltan detalles'),
                        content: const Text(
                          'Debes ingresar los detalles adicionales.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Si todo está correcto, cerramos el modal y devolvemos la ubicación y los detalles adicionales como string
                    Navigator.pop(context, {
                      'ubicacion': ubic,
                      'detallesAdicionales': detallesAdicionales,
                    });
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
