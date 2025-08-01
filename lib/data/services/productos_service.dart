import '../services/http_service.dart';

class ProductosService {
  // Obtener todos los productos
  static Future<List<Map<String, dynamic>>> obtenerProductos() async {
    try {
      final response = await HttpService.get('/productos');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos: $e');
      return [];
    }
  }

  // Obtener producto por ID
  static Future<Map<String, dynamic>?> obtenerProducto(String productoId) async {
    try {
      final response = await HttpService.get('/productos/$productoId');
      return response['data'];
    } catch (e) {
      print('Error obteniendo producto: $e');
      return null;
    }
  }

  // Obtener productos por categoría
  static Future<List<Map<String, dynamic>>> obtenerProductosPorCategoria(String categoria) async {
    try {
      final response = await HttpService.get('/productos/categoria/$categoria');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos por categoría: $e');
      return [];
    }
  }

  // Obtener productos de un negocio
  static Future<List<Map<String, dynamic>>> obtenerProductosNegocio(String negocioId) async {
    try {
      print('🔍 ProductosService.obtenerProductosNegocio() - Negocio ID: $negocioId');
      // Solicitar explícitamente solo productos activos
      final response = await HttpService.get('/negocios/$negocioId/productos?activo=true');
      print('🔍 ProductosService.obtenerProductosNegocio() - Respuesta recibida: ${response.toString()}');
      final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
      print('🔍 ProductosService.obtenerProductosNegocio() - Datos procesados: ${data.length} productos');
      return data;
    } catch (e) {
      print('❌ Error obteniendo productos del negocio: $e');
      return [];
    }
  }

  // Buscar productos
  static Future<List<Map<String, dynamic>>> buscarProductos(String query) async {
    try {
      final response = await HttpService.get('/productos/buscar?q=${Uri.encodeComponent(query)}');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error buscando productos: $e');
      return [];
    }
  }

  // Obtener productos destacados
  static Future<List<Map<String, dynamic>>> obtenerProductosDestacados() async {
    try {
      final response = await HttpService.get('/productos/destacados');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos destacados: $e');
      return [];
    }
  }

  // Obtener productos populares
  static Future<List<Map<String, dynamic>>> obtenerProductosPopulares() async {
    try {
      final response = await HttpService.get('/productos/populares');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos populares: $e');
      return [];
    }
  }

  // Obtener categorías de productos
  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      final response = await HttpService.get('/productos/categorias');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return [];
    }
  }

  // Obtener opciones de un producto
  static Future<List<Map<String, dynamic>>> obtenerOpcionesProducto(String productoId) async {
    try {
      final response = await HttpService.get('/productos/$productoId/opciones');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo opciones del producto: $e');
      return [];
    }
  }

  // Obtener variantes de un producto
  static Future<List<Map<String, dynamic>>> obtenerVariantesProducto(String productoId) async {
    try {
      final response = await HttpService.get('/productos/$productoId/variantes');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo variantes del producto: $e');
      return [];
    }
  }

  // Verificar disponibilidad de un producto
  static Future<bool> verificarDisponibilidad(String productoId) async {
    try {
      final response = await HttpService.get('/productos/$productoId/disponibilidad');
      return response['disponible'] ?? false;
    } catch (e) {
      print('Error verificando disponibilidad: $e');
      return false;
    }
  }

  // Obtener productos similares
  static Future<List<Map<String, dynamic>>> obtenerProductosSimilares(String productoId) async {
    try {
      final response = await HttpService.get('/productos/$productoId/similares');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos similares: $e');
      return [];
    }
  }

  // Obtener productos por rango de precio
  static Future<List<Map<String, dynamic>>> obtenerProductosPorPrecio({
    required double precioMin,
    required double precioMax,
  }) async {
    try {
      final response = await HttpService.get('/productos/precio?min=$precioMin&max=$precioMax');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos por precio: $e');
      return [];
    }
  }

  // Obtener productos con descuento
  static Future<List<Map<String, dynamic>>> obtenerProductosConDescuento() async {
    try {
      final response = await HttpService.get('/productos/descuentos');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos con descuento: $e');
      return [];
    }
  }

  // Calificar un producto
  static Future<bool> calificarProducto({
    required String productoId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      final data = {
        'calificacion': calificacion,
        if (comentario != null) 'comentario': comentario,
      };

      final response = await HttpService.post('/productos/$productoId/calificar', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error calificando producto: $e');
      return false;
    }
  }

  // Obtener calificaciones de un producto
  static Future<List<Map<String, dynamic>>> obtenerCalificacionesProducto(String productoId) async {
    try {
      final response = await HttpService.get('/productos/$productoId/calificaciones');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo calificaciones del producto: $e');
      return [];
    }
  }
} 