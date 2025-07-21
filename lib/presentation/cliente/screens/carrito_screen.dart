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
    print('Carrito en screen: $carrito'); // Debug
    print('Longitud del carrito: ${carrito.length}'); // Debug

    // Verificar si todos los productos tienen negocio_id
    final productosSinNegocio = carrito
        .where((item) => item['negocio_id'] == null)
        .toList();
    final tieneProductosSinNegocio = productosSinNegocio.isNotEmpty;

    final total = carrito.fold(0, (int sum, item) {
      // Helper para convertir precio de forma segura
      int parsePrecio(dynamic precio) {
        if (precio is int) return precio;
        if (precio is String) return int.tryParse(precio) ?? 0;
        if (precio is double) return precio.toInt();
        return 0;
      }

      // Helper para convertir cantidad de forma segura
      int parseCantidad(dynamic cantidad) {
        if (cantidad is int) return cantidad;
        if (cantidad is String) return int.tryParse(cantidad) ?? 1;
        if (cantidad is double) return cantidad.toInt();
        return 1;
      }

      final precio = parsePrecio(item['precio']);
      final cantidad = parseCantidad(item['cantidad']);
      return sum + (precio * cantidad);
    });
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

    // Mostrar modal para seleccionar ubicación
    Future<Map<String, String>?> _mostrarModalUbicacion() async {
      return await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => const UbicacionModal(),
      );
    }

    // Lógica para realizar el pedido usando Supabase
    void _realizarPedido() async {
      if (carrito.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
        return;
      }

      // Mostrar modal de ubicación primero
      final ubicacionData = await _mostrarModalUbicacion();
      if (ubicacionData == null) {
        // Usuario canceló la selección de ubicación
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Verificar que el email del usuario no sea null
        final userEmail = context.read<CarritoProvider>().userEmail;
        print('Email del usuario: $userEmail'); // Debug

        if (userEmail == null || userEmail.isEmpty) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: No se pudo identificar al usuario. Por favor, inicia sesión nuevamente.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        print('Creando pedido con email: $userEmail'); // Debug

        // Obtener el negocio_id del primer producto del carrito
        final negocioId = carrito.isNotEmpty
            ? carrito.first['negocio_id']
            : null;
        print('Negocio ID: $negocioId'); // Debug

        // Debug: mostrar datos del primer producto
        if (carrito.isNotEmpty) {
          print('Primer producto del carrito: ${carrito.first}'); // Debug
        }

        // Verificar que el negocio_id no sea null
        if (negocioId == null) {
          Navigator.pop(context); // Cerrar loading
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error en el carrito'),
              content: const Text(
                'Algunos productos en tu carrito no tienen información del negocio. Esto puede suceder si agregaste productos antes de una actualización. Por favor, vacía el carrito y agrega los productos nuevamente.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<CarritoProvider>().limpiarCarrito();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Carrito vaciado. Puedes agregar productos nuevamente.',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Vaciar carrito'),
                ),
              ],
            ),
          );
          return;
        }

        print(
          'Datos del pedido: ${{'usuario_email': userEmail, 'negocio_id': negocioId, 'productos': carrito, 'total': total, 'estado': 'pendiente', 'direccion_entrega': ubicacionData['ubicacion'], 'referencias': ubicacionData['referencias'], 'created_at': DateTime.now().toIso8601String()}}',
        ); // Debug

        // Crear el pedido en Supabase
        await Supabase.instance.client.from('pedidos').insert({
          'usuario_email': userEmail,
          'restaurante_id': negocioId,
          'productos': carrito,
          'total': total,
          'estado': 'pendiente',
          'direccion_entrega': ubicacionData['ubicacion'],
          'referencias': ubicacionData['referencias'],
          'created_at': DateTime.now().toIso8601String(),
        });

        // Cerrar loading
        Navigator.pop(context);

        // Limpiar el carrito
        context.read<CarritoProvider>().limpiarCarrito();

        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido realizado con éxito!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Regresar a la pantalla anterior
        Navigator.pop(context);
      } catch (e) {
        // Cerrar loading
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar el pedido: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    return Container(
      color: Colors
          .blue[50], // Fondo uniforme para toda la pantalla, incluyendo el área segura superior
      child: SafeArea(
        top:
            false, // Permite que el color de fondo cubra la parte superior (barra de estado)
        child: Scaffold(
          extendBody:
              true, // Permite que el contenido se extienda detrás de widgets flotantes
          backgroundColor:
              Colors.transparent, // El fondo lo pone el Container exterior
          appBar: AppBar(
            backgroundColor: Colors.white, // Igual que historial de pedidos
            elevation: 2,
            title: const Text(
              'Carrito de compras',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green, // Mismo color que historial de pedidos
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.green,
              ), // Mismo color que historial de pedidos
              onPressed: () {
                Navigator.pop(context, carrito);
              },
            ),
            actions: [
              if (carrito.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: Colors.green,
                  ), // Mismo color que historial de pedidos
                  onPressed: _limpiarCarrito,
                  tooltip: 'Vaciar carrito',
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              bottom: 80,
            ), // Padding inferior para evitar que el navbar tape el contenido
            child: Column(
              children: [
                // Advertencia si hay productos sin negocio_id
                if (tieneProductosSinNegocio)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Productos sin información del negocio',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Algunos productos no se pueden procesar. Vacía el carrito y agrega productos nuevamente.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<CarritoProvider>().limpiarCarrito();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Carrito vaciado'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          child: const Text('Vaciar'),
                        ),
                      ],
                    ),
                  ),
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
                              duration: Duration(
                                milliseconds: 400 + index * 100,
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Imagen del producto
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          item['img']?.toString() ??
                                              'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
                                          width: 80,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['nombre']?.toString() ??
                                                  'Sin nombre',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['descripcion']?.toString() ??
                                                  'Delicioso y recién hecho',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Center(
                                              child: Text(
                                                '\$${() {
                                                  // Helper para convertir precio de forma segura
                                                  int parsePrecio(dynamic precio) {
                                                    if (precio is int) return precio;
                                                    if (precio is String) return int.tryParse(precio) ?? 0;
                                                    if (precio is double) return precio.toInt();
                                                    return 0;
                                                  }

                                                  return parsePrecio(item['precio']);
                                                }()}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  fontSize: 20,
                                                ),
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
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _eliminarProducto(index),
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
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.remove,
                                                    size: 18,
                                                  ),
                                                  onPressed:
                                                      () {
                                                        // Helper para convertir cantidad de forma segura
                                                        int parseCantidad(
                                                          dynamic cantidad,
                                                        ) {
                                                          if (cantidad is int)
                                                            return cantidad;
                                                          if (cantidad
                                                              is String)
                                                            return int.tryParse(
                                                                  cantidad,
                                                                ) ??
                                                                1;
                                                          if (cantidad
                                                              is double)
                                                            return cantidad
                                                                .toInt();
                                                          return 1;
                                                        }

                                                        return parseCantidad(
                                                              item['cantidad'],
                                                            ) >
                                                            1;
                                                      }()
                                                      ? () {
                                                          context
                                                              .read<
                                                                CarritoProvider
                                                              >()
                                                              .modificarCantidad(
                                                                index,
                                                                -1,
                                                              );
                                                        }
                                                      : null,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36,
                                                      ),
                                                ),
                                              ),
                                              // Cantidad
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                child: Text(
                                                  '${() {
                                                    // Helper para convertir cantidad de forma segura
                                                    int parseCantidad(dynamic cantidad) {
                                                      if (cantidad is int) return cantidad;
                                                      if (cantidad is String) return int.tryParse(cantidad) ?? 1;
                                                      if (cantidad is double) return cantidad.toInt();
                                                      return 1;
                                                    }

                                                    return parseCantidad(item['cantidad']);
                                                  }()}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              // Botón para aumentar cantidad
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    context
                                                        .read<CarritoProvider>()
                                                        .modificarCantidad(
                                                          index,
                                                          1,
                                                        );
                                                  },
                                                  constraints:
                                                      const BoxConstraints(
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
              ],
            ),
          ),
          bottomNavigationBar: carrito.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            ' \$$total',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: tieneProductosSinNegocio
                              ? null
                              : _realizarPedido,
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
                          child: Text(
                            tieneProductosSinNegocio
                                ? 'Productos incompletos'
                                : 'Realizar Pedido',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// Modal para seleccionar ubicación (actual o manual)
class UbicacionModal extends StatefulWidget {
  const UbicacionModal({super.key});

  @override
  State<UbicacionModal> createState() => _UbicacionModalState();
}

class _UbicacionModalState extends State<UbicacionModal> {
  String? direccionManual;
  String? ubicacionActual;
  bool buscando = false;
  final TextEditingController _direccionController = TextEditingController();

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  // Obtiene la ubicación actual usando geolocator y la convierte a dirección legible
  Future<void> _obtenerUbicacion() async {
    setState(() => buscando = true);
    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => buscando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => buscando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Los permisos de ubicación están permanentemente denegados',
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

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
        ubicacionActual =
            'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
      }

      setState(() => buscando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación obtenida correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => buscando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                '📍 Selecciona tu ubicación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Necesitamos tu ubicación para entregar tu pedido',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Botón para obtener ubicación actual
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: buscando ? null : _obtenerUbicacion,
                  icon: buscando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    buscando
                        ? 'Obteniendo ubicación...'
                        : 'Usar ubicación actual',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Mostrar ubicación actual si se obtuvo
              if (ubicacionActual != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ubicacionActual!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Campo para referencias adicionales
              const Text(
                '📝 Referencias adicionales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Color de casa, puntos de referencia, instrucciones especiales, etc.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _direccionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Ej: Casa azul, frente al parque, tocar timbre 2 veces...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => direccionManual = value,
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final ubic = ubicacionActual;
                        final referencias =
                            direccionManual ?? _direccionController.text;

                        if (ubic == null ||
                            ubic.isEmpty ||
                            referencias.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Center(
                                child: AlertDialog(
                                  title: const Text(
                                    'Ubicación no seleccionada',
                                  ),
                                  content: const Text(
                                    'Debes obtener tu ubicación actual e ingresar referencias adicionales.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Aceptar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                          return;
                        }

                        if (referencias.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Debes ingresar referencias adicionales',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // Devolver datos de ubicación
                        Navigator.pop(context, {
                          'ubicacion': ubic,
                          'referencias': referencias,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
