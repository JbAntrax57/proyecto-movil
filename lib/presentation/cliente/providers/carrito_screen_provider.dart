import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../../data/services/detalles_pedidos_service.dart';
import '../../../data/services/negocios_service.dart';
import '../../../data/services/pedidos_service.dart';
import '../../../data/services/http_service.dart';
import '../../../services/puntos_service.dart';

class CarritoScreenProvider extends ChangeNotifier {
  // Estado de la pantalla
  bool _isLoading = false;
  String? _error;
  bool _pedidoRealizado = false;
  String? _ubicacionSeleccionada;
  String? _referenciasSeleccionadas;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get pedidoRealizado => _pedidoRealizado;
  String? get ubicacionSeleccionada => _ubicacionSeleccionada;
  String? get referenciasSeleccionadas => _referenciasSeleccionadas;

  // Helper para convertir precio de forma segura
  double parsePrecio(dynamic precio) {
    if (precio is int) return precio.toDouble();
    if (precio is String) return double.tryParse(precio) ?? 0.0;
    if (precio is double) return precio;
    return 0.0;
  }

  // Helper para convertir cantidad de forma segura
  int parseCantidad(dynamic cantidad) {
    if (cantidad is int) return cantidad;
    if (cantidad is String) return int.tryParse(cantidad) ?? 1;
    if (cantidad is double) return cantidad.toInt();
    return 1;
  }

  // Calcular total del carrito
  double calcularTotal(List<Map<String, dynamic>> carrito) {
    return carrito.fold(0.0, (double sum, item) {
      final precio = parsePrecio(item['precio']);
      final cantidad = parseCantidad(item['cantidad']);
      return sum + (precio * cantidad);
    });
  }

  // Verificar si todos los productos tienen negocio_id
  bool tieneProductosSinNegocio(List<Map<String, dynamic>> carrito) {
    return carrito.any((item) => item['negocio_id'] == null);
  }

  // Obtener productos sin negocio_id
  List<Map<String, dynamic>> getProductosSinNegocio(List<Map<String, dynamic>> carrito) {
    return carrito.where((item) => item['negocio_id'] == null).toList();
  }

  // Obtener la mejor ubicación posible escuchando varias posiciones durante unos segundos
  Future<Position?> obtenerMejorUbicacion({int segundos = 5}) async {
    Position? mejorPosicion;
    double mejorPrecision = double.infinity;
    final completer = Completer<Position?>();
    
    final subscription = Geolocator.getPositionStream(
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

  // Obtener dirección desde coordenadas
  Future<String?> obtenerDireccionDesdeCoordenadas(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo dirección: $e');
      return null;
    }
  }

  // Agrupar productos por negocio
  Map<String, List<Map<String, dynamic>>> agruparProductosPorNegocio(List<Map<String, dynamic>> carrito) {
    final Map<String, List<Map<String, dynamic>>> productosPorNegocio = {};
    
    for (var item in carrito) {
      final negocioId = item['negocio_id'];
      if (negocioId == null) continue;
      productosPorNegocio.putIfAbsent(negocioId, () => []).add(item);
    }
    
    return productosPorNegocio;
  }

  // Obtener información del negocio desde el backend
  Future<Map<String, dynamic>?> obtenerInfoNegocio(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId');
      return response['data'];
    } catch (e) {
      print('❌ Error obteniendo información del negocio: $e');
      return null;
    }
  }

  // Obtener dueño del negocio desde el backend
  Future<String?> obtenerDuenoNegocio(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId/dueno');
      return response['data']?['id'];
    } catch (e) {
      print('❌ Error obteniendo dueño del negocio: $e');
      return null;
    }
  }

  // Obtener puntos del dueño
  Future<Map<String, dynamic>?> obtenerPuntosDueno(String duenoId) async {
    try {
      return await PuntosService.obtenerPuntosDueno(duenoId);
    } catch (e) {
      print('❌ Error obteniendo puntos del dueño: $e');
      return null;
    }
  }

  // Crear pedido usando el backend
  Future<Map<String, dynamic>?> crearPedido({
    required String userEmail,
    required String negocioId,
    required double total,
    required String direccionEntrega,
    required String referencias,
    required List<Map<String, dynamic>> productos,
  }) async {
    try {
      final data = {
        'usuario_email': userEmail,
        'restaurante_id': negocioId,
        'total': total,
        'direccion_entrega': direccionEntrega,
        'referencias': referencias,
        'productos': productos,
      };

      final response = await HttpService.post('/pedidos', data);
      return response['data'];
    } catch (e) {
      print('❌ Error creando pedido: $e');
      return null;
    }
  }

  // Crear detalles del pedido
  Future<bool> crearDetallesPedido({
    required String pedidoId,
    required List<Map<String, dynamic>> productos,
  }) async {
    try {
      final detallesService = DetallesPedidosService();
      await detallesService.crearDetallesPedido(
        pedidoId: pedidoId,
        productos: productos,
      );
      return true;
    } catch (e) {
      print('❌ Error creando detalles del pedido: $e');
      return false;
    }
  }

  // Obtener puntos por pedido del sistema desde el backend
  Future<int> obtenerPuntosPorPedido(String duenoId) async {
    try {
      final response = await HttpService.get('/sistema-puntos/$duenoId');
      return response['data']?['puntos_por_pedido'] ?? 2;
    } catch (e) {
      print('❌ Error obteniendo puntos por pedido: $e');
      return 2; // Valor por defecto
    }
  }

  // Consumir puntos del dueño
  Future<bool> consumirPuntosDueno(String duenoId, int puntosConsumir) async {
    try {
      return await PuntosService.consumirPuntosEnPedido(
        duenoId,
        puntosConsumir: puntosConsumir,
      );
    } catch (e) {
      print('❌ Error consumiendo puntos: $e');
      return false;
    }
  }

  // Realizar pedido completo
  Future<bool> realizarPedido({
    required List<Map<String, dynamic>> carrito,
    required String userEmail,
    required String ubicacion,
    required String referencias,
  }) async {
    if (carrito.isEmpty) {
      setError('El carrito está vacío');
      return false;
    }

    setLoading(true);

    try {
      // Agrupar productos por negocio
      final productosPorNegocio = agruparProductosPorNegocio(carrito);

      // Mostrar puntos totales de los dueños
      print('🏪 === PUNTOS TOTALES DE LOS DUEÑOS DE NEGOCIOS INVOLUCRADOS ===');
      final Set<String> duenosProcesados = {};
      
      for (final entry in productosPorNegocio.entries) {
        final negocioId = entry.key;
        final productos = entry.value;
        
        final negocioInfo = await obtenerInfoNegocio(negocioId);
        final nombreNegocio = negocioInfo?['nombre'] ?? 'Negocio sin nombre';
        
        final duenoId = await obtenerDuenoNegocio(negocioId);
        
        if (duenoId != null && !duenosProcesados.contains(duenoId)) {
          duenosProcesados.add(duenoId);
          
          final puntosData = await obtenerPuntosDueno(duenoId);
          
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
      }
      
      print('🏪 === FIN DE PUNTOS TOTALES ===');

      // Crear un pedido por cada negocio
      for (final entry in productosPorNegocio.entries) {
        final negocioId = entry.key;
        final productos = entry.value;
        final total = calcularTotal(productos);

        // Crear el pedido
        final pedidoResult = await crearPedido(
          userEmail: userEmail,
          negocioId: negocioId,
          total: total,
          direccionEntrega: ubicacion,
          referencias: referencias,
          productos: productos,
        );

        if (pedidoResult == null) {
          throw Exception('Error creando pedido para negocio $negocioId');
        }

        // Crear los detalles del pedido
        final detallesCreados = await crearDetallesPedido(
          pedidoId: pedidoResult['id'],
          productos: productos,
        );

        if (!detallesCreados) {
          throw Exception('Error creando detalles del pedido');
        }

        // Procesar puntos del dueño
        final duenoId = await obtenerDuenoNegocio(negocioId);
        if (duenoId != null) {
          final puntosPorPedido = await obtenerPuntosPorPedido(duenoId);
          final puntosDescontados = await consumirPuntosDueno(duenoId, puntosPorPedido);
          
          if (!puntosDescontados) {
            print('⚠️ No se pudieron descontar puntos del dueño $duenoId');
          } else {
            print('✅ Puntos descontados exitosamente: $puntosPorPedido puntos');
          }
        }
      }

      setLoading(false);
      _pedidoRealizado = true;
      notifyListeners();
      return true;

    } catch (e) {
      setLoading(false);
      setError('Error al realizar el pedido: $e');
      return false;
    }
  }

  // Actualizar ubicación seleccionada
  void setUbicacion(String ubicacion, String referencias) {
    _ubicacionSeleccionada = ubicacion;
    _referenciasSeleccionadas = referencias;
    notifyListeners();
  }

  // Limpiar ubicación
  void limpiarUbicacion() {
    _ubicacionSeleccionada = null;
    _referenciasSeleccionadas = null;
    notifyListeners();
  }

  // Métodos helper para estado
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void resetPedidoRealizado() {
    _pedidoRealizado = false;
    notifyListeners();
  }
} 