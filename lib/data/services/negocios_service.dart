import '../services/http_service.dart';

class NegociosService {
  // Obtener todos los negocios
  static Future<List<Map<String, dynamic>>> obtenerNegocios() async {
    try {
      print('🔍 NegociosService.obtenerNegocios() - Iniciando llamada al backend');
      final response = await HttpService.get('/negocios');
      print('🔍 NegociosService.obtenerNegocios() - Respuesta recibida: ${response.toString()}');
      final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
      print('🔍 NegociosService.obtenerNegocios() - Datos procesados: ${data.length} negocios');
      return data;
    } catch (e) {
      print('❌ Error obteniendo negocios: $e');
      return [];
    }
  }

  // Obtener negocio por ID
  static Future<Map<String, dynamic>?> obtenerNegocio(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId');
      return response['data'];
    } catch (e) {
      print('Error obteniendo negocio: $e');
      return null;
    }
  }

  // Obtener negocios por categoría
  static Future<List<Map<String, dynamic>>> obtenerNegociosPorCategoria(String categoria) async {
    try {
      final response = await HttpService.get('/negocios/categoria/$categoria');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo negocios por categoría: $e');
      return [];
    }
  }

  // Obtener negocios destacados
  static Future<List<Map<String, dynamic>>> obtenerNegociosDestacados() async {
    try {
      final response = await HttpService.get('/negocios/destacados');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo negocios destacados: $e');
      return [];
    }
  }

  // Buscar negocios
  static Future<List<Map<String, dynamic>>> buscarNegocios(String query) async {
    try {
      final response = await HttpService.get('/negocios/buscar?q=${Uri.encodeComponent(query)}');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error buscando negocios: $e');
      return [];
    }
  }

  // Obtener negocios cercanos
  static Future<List<Map<String, dynamic>>> obtenerNegociosCercanos({
    required double latitud,
    required double longitud,
    double? radioKm,
  }) async {
    try {
      final queryParams = {
        'lat': latitud.toString(),
        'lng': longitud.toString(),
        if (radioKm != null) 'radio': radioKm.toString(),
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final response = await HttpService.get('/negocios/cercanos?$queryString');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo negocios cercanos: $e');
      return [];
    }
  }

  // Obtener productos de un negocio
  static Future<List<Map<String, dynamic>>> obtenerProductosNegocio(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId/productos');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo productos del negocio: $e');
      return [];
    }
  }

  // Obtener categorías de productos de un negocio
  static Future<List<Map<String, dynamic>>> obtenerCategoriasNegocio(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId/categorias');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo categorías del negocio: $e');
      return [];
    }
  }

  // Obtener todas las categorías
  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      print('🔍 NegociosService.obtenerCategorias() - Iniciando llamada al backend');
      final response = await HttpService.get('/negocios/categorias');
      print('🔍 NegociosService.obtenerCategorias() - Respuesta recibida: ${response.toString()}');
      final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
      print('🔍 NegociosService.obtenerCategorias() - Datos procesados: ${data.length} categorías');
      return data;
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  // Obtener horarios de un negocio
  static Future<Map<String, dynamic>?> obtenerHorariosNegocio(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId/horarios');
      return response['data'];
    } catch (e) {
      print('Error obteniendo horarios del negocio: $e');
      return null;
    }
  }

  // Verificar si un negocio está abierto
  static Future<bool> verificarNegocioAbierto(String negocioId) async {
    try {
      final response = await HttpService.get('/negocios/$negocioId/abierto');
      return response['abierto'] ?? false;
    } catch (e) {
      print('Error verificando si el negocio está abierto: $e');
      return false;
    }
  }
} 