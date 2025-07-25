import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'dart:async';
import '../../../data/services/detalles_pedidos_service.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../services/puntos_service.dart';

// carrito_screen.dart - Pantalla de carrito de compras para el cliente
// Permite ver, modificar y eliminar productos del carrito, calcular el total y realizar el pedido.
// Incluye selección de ubicación (actual o manual) antes de enviar el pedido.
class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _mostrarAlerta = false;
  String _mensajeAlerta = '';
  Color _colorAlerta = Colors.green;
  IconData _iconoAlerta = Icons.check_circle;

  // Función para mostrar alertas personalizadas
  void _mostrarAlertaPersonalizada(String mensaje, Color color, IconData icono) {
    setState(() {
      _mensajeAlerta = mensaje;
      _colorAlerta = color;
      _iconoAlerta = icono;
      _mostrarAlerta = true;
    });

    // Ocultar la alerta después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mostrarAlerta = false;
        });
      }
    });
  }

  // Obtiene la mejor ubicación posible escuchando varias posiciones durante unos segundos
  Future<Position?> obtenerMejorUbicacion({int segundos = 5}) async {
    Position? mejorPosicion;
    double mejorPrecision = double.infinity;
    final completer = Completer<Position?>();
    final subscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((Position position) {
          if (position.accuracy < mejorPrecision) {
            mejorPrecision = position.accuracy;
            mejorPosicion = position;
          }
        });
    // Espera unos segundos y luego cancela el stream
    await Future.delayed(Duration(seconds: segundos));
    await subscription.cancel();
    completer.complete(mejorPosicion);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>().carrito;
    print('Carrito en screen: $carrito'); // Debug
    print('Longitud del carrito: ${carrito.length}'); // Debug

    // Función para refrescar el carrito
    void _refrescarCarrito() async {
      try {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Limpiar duplicados y cargar carrito
        await context.read<CarritoProvider>().limpiarCarritosDuplicados();
        await context.read<CarritoProvider>().cargarCarrito();

        // Cerrar loading
        Navigator.pop(context);

        _mostrarAlertaPersonalizada(
          'Carrito refrescado y duplicados limpiados',
          Colors.green,
          Icons.check_circle,
        );
      } catch (e) {
        // Cerrar loading si está abierto
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        _mostrarAlertaPersonalizada(
          'Error al refrescar carrito: $e',
          Colors.red,
          Icons.error,
        );
      }
    }

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
        _mostrarAlertaPersonalizada(
          'Producto eliminado del carrito',
          Colors.orange,
          Icons.delete,
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
        _mostrarAlertaPersonalizada(
          'Carrito vaciado',
          Colors.blue,
          Icons.clear_all,
        );
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
        _mostrarAlertaPersonalizada(
          'El carrito está vacío',
          Colors.orange,
          Icons.shopping_cart_outlined,
        );
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
        final userEmail = context.read<CarritoProvider>().userEmail;
        if (userEmail == null || userEmail.isEmpty) {
          Navigator.pop(context); // Cerrar loading
          _mostrarAlertaPersonalizada(
            'Error: No se pudo identificar al usuario. Por favor, inicia sesión nuevamente.',
            Colors.red,
            Icons.error,
          );
          return;
        }

        // Agrupar productos por negocio_id
        final Map<String, List<Map<String, dynamic>>> productosPorNegocio = {};
        for (var item in carrito) {
          final negocioId = item['negocio_id'];
          if (negocioId == null) continue;
          productosPorNegocio.putIfAbsent(negocioId, () => []).add(item);
        }

        // Mostrar puntos totales de los dueños de los negocios involucrados
        print('🏪 === PUNTOS TOTALES DE LOS DUEÑOS DE NEGOCIOS INVOLUCRADOS ===');
        final Set<String> duenosProcesados = {};
        
        for (final entry in productosPorNegocio.entries) {
          final negocioId = entry.key;
          final productos = entry.value;
          
          try {
            // Obtener información del negocio
            final negocioData = await Supabase.instance.client
                .from('negocios')
                .select('nombre')
                .eq('id', negocioId)
                .single();
            
            final nombreNegocio = negocioData['nombre'] ?? 'Negocio sin nombre';
            
                                    // Obtener el dueño del negocio desde la tabla usuarios
                        final duenoData = await Supabase.instance.client
                            .from('usuarios')
                            .select('id')
                            .eq('restaurante_id', negocioId)
                            .eq('rol', 'duenio')
                            .limit(1)
                            .maybeSingle();
            
            final duenoId = duenoData?['id'];
            
            if (duenoId != null && !duenosProcesados.contains(duenoId)) {
              duenosProcesados.add(duenoId);
              
              // Obtener puntos del dueño
              final puntosData = await PuntosService.obtenerPuntosDueno(duenoId);
              
              if (puntosData != null) {
                final puntosDisponibles = puntosData['puntos_disponibles'] ?? 0;
                final totalAsignado = puntosData['total_asignado'] ?? 0;
                final puntosConsumidos = totalAsignado - puntosDisponibles;
                
                print('📊 NEGOCIO: $nombreNegocio');
                print('👤 DUEÑO ID: $duenoId');
                print('💰 PUNTOS DISPONIBLES: $puntosDisponibles');
                print('📈 TOTAL ASIGNADO: $totalAsignado');
                print('📉 PUNTOS CONSUMIDOS: $puntosConsumidos');
                print('📦 PRODUCTOS EN PEDIDO: ${productos.length}');
                print('---');
              } else {
                print('❌ NEGOCIO: $nombreNegocio');
                print('❌ DUEÑO ID: $duenoId');
                print('❌ NO SE PUDIERON OBTENER LOS PUNTOS');
                print('---');
              }
            }
          } catch (e) {
            print('❌ Error obteniendo información del negocio $negocioId: $e');
          }
        }
        
        print('🏪 === FIN DE PUNTOS TOTALES ===');

        // Crear un pedido por cada negocio
        for (final entry in productosPorNegocio.entries) {
          final negocioId = entry.key;
          final productos = entry.value;
          final total = productos.fold(0, (int sum, item) {
            int parsePrecio(dynamic precio) {
              if (precio is int) return precio;
              if (precio is String) return int.tryParse(precio) ?? 0;
              if (precio is double) return precio.toInt();
              return 0;
            }

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

          // Crear el pedido sin el campo productos
          final pedidoResult = await Supabase.instance.client.from('pedidos').insert({
            'usuario_email': userEmail,
            'restaurante_id': negocioId,
            'total': total,
            'estado': 'pendiente',
            'direccion_entrega': ubicacionData['ubicacion'],
            'referencias': ubicacionData['referencias'],
            'created_at': DateTime.now().toIso8601String(),
          }).select().single();

          // Crear los detalles del pedido usando la nueva tabla
          final detallesService = DetallesPedidosService();
          await detallesService.crearDetallesPedido(
            pedidoId: pedidoResult['id'],
            productos: productos,
          );

          // Obtener el dueño del negocio para descuentar puntos
          try {
            final duenoData = await Supabase.instance.client
                .from('usuarios')
                .select('id')
                .eq('restaurante_id', negocioId)
                .eq('rol', 'duenio')
                .limit(1)
                .maybeSingle();
            
            final duenoId = duenoData?['id'];
            if (duenoId != null) {
              // Obtener los puntos por pedido del sistema de puntos
              final puntosData = await Supabase.instance.client
                  .from('sistema_puntos')
                  .select('puntos_por_pedido')
                  .eq('dueno_id', duenoId)
                  .single();
              
              final puntosPorPedido = puntosData['puntos_por_pedido'] ?? 2;
              
              // Descontar puntos del dueño
              final puntosDescontados = await PuntosService.consumirPuntosEnPedido(
                duenoId,
                puntosConsumir: puntosPorPedido,
              );
              
              if (!puntosDescontados) {
                print('⚠️ No se pudieron descontar puntos del dueño $duenoId');
              } else {
                print('✅ Puntos descontados exitosamente: $puntosPorPedido puntos');
              }
            }
          } catch (e) {
            print('⚠️ Error al procesar puntos del dueño: $e');
            // Continuar con el pedido aunque falle el descuento de puntos
          }
        }

        // Cerrar loading
        Navigator.pop(context);

        // Limpiar el carrito
        context.read<CarritoProvider>().limpiarCarrito();

        // Mostrar éxito
        showSuccessAlert(
          context,
          '¡Pedidos realizados con éxito! 🎉\nTu pedido está siendo procesado.',
        );

        // Esperar 2 segundos para que el usuario vea el mensaje de éxito
        await Future.delayed(const Duration(seconds: 2));

        // Regresar a la pantalla anterior
        Navigator.pop(context);
      } catch (e) {
        // Cerrar loading
        Navigator.pop(context);

        _mostrarAlertaPersonalizada(
          'Error al realizar el pedido: $e',
          Colors.red,
          Icons.error,
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
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.green[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mi Carrito',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            centerTitle: false,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                  size: 18,
                ),
              ),
              onPressed: () {
                Navigator.pop(context, carrito);
              },
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.blue[700],
                    size: 18,
                  ),
                ),
                onPressed: _refrescarCarrito,
                tooltip: 'Refrescar carrito',
              ),
              if (carrito.isNotEmpty)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[700],
                      size: 18,
                    ),
                  ),
                  onPressed: _limpiarCarrito,
                  tooltip: 'Vaciar carrito',
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              bottom: 0,
            ), // Removemos el padding inferior ya que usaremos SizedBox
            child: Column(
              children: [
                // Advertencia si hay productos sin negocio_id
                if (tieneProductosSinNegocio)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[50]!, Colors.orange[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Productos incompletos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Algunos productos no tienen la información completa del negocio y no se pueden procesar.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context
                                      .read<CarritoProvider>()
                                      .limpiarCarrito();
                                  _mostrarAlertaPersonalizada(
                                    'Carrito vaciado',
                                    Colors.blue,
                                    Icons.clear_all,
                                  );
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Vaciar carrito'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[700],
                                  side: BorderSide(color: Colors.orange[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.store, size: 18),
                                label: const Text('Explorar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: carrito.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Tu carrito está vacío',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Agrega algunos productos deliciosos\nde los restaurantes disponibles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.store),
                                  label: const Text('Explorar restaurantes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: carrito.length,
                                itemBuilder: (context, index) {
                                  final item = carrito[index];

                                  // Helper functions
                                  int parsePrecio(dynamic precio) {
                                    if (precio is int) return precio;
                                    if (precio is String)
                                      return int.tryParse(precio) ?? 0;
                                    if (precio is double) return precio.toInt();
                                    return 0;
                                  }

                                  int parseCantidad(dynamic cantidad) {
                                    if (cantidad is int) return cantidad;
                                    if (cantidad is String)
                                      return int.tryParse(cantidad) ?? 1;
                                    if (cantidad is double)
                                      return cantidad.toInt();
                                    return 1;
                                  }

                                  final precio = parsePrecio(item['precio']);
                                  final cantidad = parseCantidad(
                                    item['cantidad'],
                                  );
                                  final subtotal = precio * cantidad;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          // Opcional: mostrar detalles del producto
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Header con nombre, precio unitario y botón eliminar
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Imagen del producto
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Image.network(
                                                        item['img']
                                                                ?.toString() ??
                                                            'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .grey[100],
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons.fastfood,
                                                                size: 32,
                                                                color: Colors
                                                                    .grey[400],
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 16),

                                                  // Información principal
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Nombre del producto
                                                        Text(
                                                          item['nombre']
                                                                  ?.toString() ??
                                                              'Sin nombre',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),

                                                        const SizedBox(
                                                          height: 4,
                                                        ),

                                                        // Descripción
                                                        if (item['descripcion'] !=
                                                                null &&
                                                            item['descripcion']
                                                                .toString()
                                                                .isNotEmpty)
                                                          Text(
                                                            item['descripcion']
                                                                .toString(),
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 14,
                                                              height: 1.3,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),

                                                        const SizedBox(
                                                          height: 8,
                                                        ),

                                                        // Precio unitario
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .green[50],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .green[200]!,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            '\$$precio c/u',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .green[700],
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Botón eliminar
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        color: Colors.red[600],
                                                        size: 20,
                                                      ),
                                                      onPressed: () =>
                                                          _eliminarProducto(
                                                            index,
                                                          ),
                                                      tooltip:
                                                          'Eliminar producto',
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 36,
                                                            minHeight: 36,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 16),

                                              // Controles de cantidad y subtotal
                                              Row(
                                                children: [
                                                  // Controles de cantidad
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey[200]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Botón disminuir
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                const BorderRadius.only(
                                                                  topLeft:
                                                                      Radius.circular(
                                                                        12,
                                                                      ),
                                                                  bottomLeft:
                                                                      Radius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                            onTap: cantidad > 1
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
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              child: Icon(
                                                                Icons
                                                                    .remove_rounded,
                                                                size: 18,
                                                                color:
                                                                    cantidad > 1
                                                                    ? Colors
                                                                          .grey[700]
                                                                    : Colors
                                                                          .grey[400],
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        // Cantidad
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 12,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            border: Border.symmetric(
                                                              horizontal: BorderSide(
                                                                color: Colors
                                                                    .grey[200]!,
                                                                width: 1,
                                                              ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            '$cantidad',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                          ),
                                                        ),

                                                        // Botón aumentar
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                const BorderRadius.only(
                                                                  topRight:
                                                                      Radius.circular(
                                                                        12,
                                                                      ),
                                                                  bottomRight:
                                                                      Radius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                            onTap: () {
                                                              context
                                                                  .read<
                                                                    CarritoProvider
                                                                  >()
                                                                  .modificarCantidad(
                                                                    index,
                                                                    1,
                                                                  );
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              child: Icon(
                                                                Icons
                                                                    .add_rounded,
                                                                size: 18,
                                                                color: Colors
                                                                    .green[700],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  const Spacer(),

                                                  // Subtotal
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'Subtotal',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.blue[400]!,
                                                              Colors.blue[600]!,
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.blue
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Text(
                                                          '\$$subtotal',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
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
                                    ),
                                  );
                                },
                              ),
                            ),
                            // SizedBox para evitar que el bottom navigation bar tape el último elemento
                            const SizedBox(height: 190),
                          ],
                        ),
                ),
              ],
            ),
          ),
          // Alerta personalizada
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _mostrarAlerta
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  height: _mostrarAlerta ? 60 : 0,
                  margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: _mostrarAlerta ? 120 : 0,
                  ),
                  child: AnimatedOpacity(
                    opacity: _mostrarAlerta ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _colorAlerta.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _colorAlerta),
                        boxShadow: [
                          BoxShadow(
                            color: _colorAlerta.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _iconoAlerta,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              child: Text(_mensajeAlerta),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: carrito.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicador visual
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Información del total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '\$$total',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    size: 16,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${carrito.length} ${carrito.length == 1 ? 'producto' : 'productos'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Botón de realizar pedido
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: tieneProductosSinNegocio
                                ? null
                                : _realizarPedido,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tieneProductosSinNegocio
                                  ? Colors.grey[300]
                                  : Colors.green,
                              foregroundColor: tieneProductosSinNegocio
                                  ? Colors.grey[600]
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: tieneProductosSinNegocio ? 0 : 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!tieneProductosSinNegocio) ...[
                                  const Icon(
                                    Icons.shopping_cart_checkout,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  tieneProductosSinNegocio
                                      ? 'Productos incompletos'
                                      : 'Realizar Pedido',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

  // Obtiene la mejor ubicación posible escuchando varias posiciones durante unos segundos
  Future<Position?> obtenerMejorUbicacion({int segundos = 5}) async {
    Position? mejorPosicion;
    double mejorPrecision = double.infinity;
    final completer = Completer<Position?>();
    final subscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen((Position position) {
          if (position.accuracy < mejorPrecision) {
            mejorPrecision = position.accuracy;
            mejorPosicion = position;
          }
        });
    // Espera unos segundos y luego cancela el stream
    await Future.delayed(Duration(seconds: segundos));
    await subscription.cancel();
    completer.complete(mejorPosicion);
    return completer.future;
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
                  onPressed: buscando
                      ? null
                      : () async {
                          setState(() => buscando = true);
                          try {
                            final posicion = await obtenerMejorUbicacion();
                            if (!mounted) return;
                            if (posicion != null) {
                              try {
                                final placemarks =
                                    await placemarkFromCoordinates(
                                      posicion.latitude,
                                      posicion.longitude,
                                    );
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  ubicacionActual =
                                      '${p.street ?? ''} ${p.subThoroughfare ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}';
                                } else {
                                  ubicacionActual =
                                      'Lat: ${posicion.latitude.toStringAsFixed(6)}, Lng: ${posicion.longitude.toStringAsFixed(6)} (±${posicion.accuracy}m)';
                                }
                              } catch (e) {
                                ubicacionActual =
                                    'Lat: ${posicion.latitude.toStringAsFixed(6)}, Lng: ${posicion.longitude.toStringAsFixed(6)} (±${posicion.accuracy}m)';
                              }
                            } else {
                              ubicacionActual = null;
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ubicacionActual = null;
                          }
                          setState(() => buscando = false);
                        },
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
              if (buscando)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (ubicacionActual != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    ubicacionActual!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

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
                          // Como este está dentro de un modal, usamos un showDialog en lugar de la alerta personalizada
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Referencias requeridas'),
                                content: const Text(
                                  'Debes ingresar referencias adicionales para la entrega.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              );
                            },
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
