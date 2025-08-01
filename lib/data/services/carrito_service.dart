import '../services/http_service.dart';

class CarritoService {
  // Obtener carrito de un usuario
  static Future<List<Map<String, dynamic>>> obtenerCarrito(String userEmail) async {
    try {
      final response = await HttpService.get('/carrito/$userEmail');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo carrito: $e');
      return [];
    }
  }

  // Agregar producto al carrito
  static Future<bool> agregarProducto({
    required String userEmail,
    required String productoId,
    required int cantidad,
    Map<String, dynamic>? opciones,
  }) async {
    try {
      final data = {
        'userEmail': userEmail,
        'productoId': productoId,
        'cantidad': cantidad,
        if (opciones != null) 'opciones': opciones,
      };

      final response = await HttpService.post('/carrito/agregar', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error agregando producto al carrito: $e');
      return false;
    }
  }

  // Actualizar cantidad de un producto
  static Future<bool> actualizarCantidad({
    required String userEmail,
    required String productoId,
    required int cantidad,
  }) async {
    try {
      final data = {
        'userEmail': userEmail,
        'productoId': productoId,
        'cantidad': cantidad,
      };

      final response = await HttpService.put('/carrito/actualizar-cantidad', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error actualizando cantidad: $e');
      return false;
    }
  }

  // Eliminar producto del carrito
  static Future<bool> eliminarProducto({
    required String userEmail,
    required String productoId,
  }) async {
    try {
      final data = {
        'userEmail': userEmail,
        'productoId': productoId,
      };

      final response = await HttpService.post('/carrito/eliminar', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error eliminando producto del carrito: $e');
      return false;
    }
  }

  // Limpiar carrito completo
  static Future<bool> limpiarCarrito(String userEmail) async {
    try {
      final data = {
        'userEmail': userEmail,
      };

      final response = await HttpService.post('/carrito/limpiar', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error limpiando carrito: $e');
      return false;
    }
  }

  // Obtener total del carrito
  static Future<double> obtenerTotal(String userEmail) async {
    try {
      final response = await HttpService.get('/carrito/$userEmail/total');
      return (response['total'] ?? 0.0).toDouble();
    } catch (e) {
      print('Error obteniendo total del carrito: $e');
      return 0.0;
    }
  }
} 