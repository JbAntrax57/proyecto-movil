import '../services/http_service.dart';

class DireccionesService {
  // Obtener direcciones de un usuario
  static Future<List<Map<String, dynamic>>> obtenerDirecciones(String userId) async {
    try {
      print('🔍 DireccionesService.obtenerDirecciones() - User ID: $userId');
      final response = await HttpService.get('/direcciones/$userId');
      print('🔍 DireccionesService.obtenerDirecciones() - Respuesta recibida: ${response.toString()}');
      final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
      print('🔍 DireccionesService.obtenerDirecciones() - Direcciones procesadas: ${data.length}');
      return data;
    } catch (e) {
      print('❌ Error obteniendo direcciones: $e');
      return [];
    }
  }

  // Obtener dirección por ID
  static Future<Map<String, dynamic>?> obtenerDireccion(String direccionId) async {
    try {
      final response = await HttpService.get('/direcciones/detalle/$direccionId');
      return response['data'];
    } catch (e) {
      print('Error obteniendo dirección: $e');
      return null;
    }
  }

  // Crear nueva dirección
  static Future<Map<String, dynamic>?> crearDireccion({
    required String userEmail,
    required String nombre,
    required String direccion,
    required double latitud,
    required double longitud,
    String? telefono,
    String? instrucciones,
    bool esPredeterminada = false,
  }) async {
    try {
      final data = {
        'userEmail': userEmail,
        'nombre': nombre,
        'direccion': direccion,
        'latitud': latitud,
        'longitud': longitud,
        if (telefono != null) 'telefono': telefono,
        if (instrucciones != null) 'instrucciones': instrucciones,
        'esPredeterminada': esPredeterminada,
      };

      final response = await HttpService.post('/direcciones', data);
      return response['data'];
    } catch (e) {
      print('Error creando dirección: $e');
      return null;
    }
  }

  // Actualizar dirección
  static Future<bool> actualizarDireccion({
    required String direccionId,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    String? telefono,
    String? instrucciones,
    bool? esPredeterminada,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nombre != null) data['nombre'] = nombre;
      if (direccion != null) data['direccion'] = direccion;
      if (latitud != null) data['latitud'] = latitud;
      if (longitud != null) data['longitud'] = longitud;
      if (telefono != null) data['telefono'] = telefono;
      if (instrucciones != null) data['instrucciones'] = instrucciones;
      if (esPredeterminada != null) data['esPredeterminada'] = esPredeterminada;

      final response = await HttpService.put('/direcciones/$direccionId', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error actualizando dirección: $e');
      return false;
    }
  }

  // Eliminar dirección
  static Future<bool> eliminarDireccion(String direccionId) async {
    try {
      final response = await HttpService.delete('/direcciones/$direccionId');
      return response['success'] ?? false;
    } catch (e) {
      print('Error eliminando dirección: $e');
      return false;
    }
  }

  // Establecer dirección como predeterminada
  static Future<bool> establecerPredeterminada(String direccionId) async {
    try {
      final response = await HttpService.post('/direcciones/$direccionId/predeterminada', {});
      return response['success'] ?? false;
    } catch (e) {
      print('Error estableciendo dirección predeterminada: $e');
      return false;
    }
  }

  // Obtener dirección predeterminada
  static Future<Map<String, dynamic>?> obtenerDireccionPredeterminada(String userEmail) async {
    try {
      final response = await HttpService.get('/direcciones/$userEmail/predeterminada');
      return response['data'];
    } catch (e) {
      print('Error obteniendo dirección predeterminada: $e');
      return null;
    }
  }

  // Validar dirección
  static Future<Map<String, dynamic>?> validarDireccion(String direccion) async {
    try {
      final response = await HttpService.post('/direcciones/validar', {
        'direccion': direccion,
      });
      return response['data'];
    } catch (e) {
      print('Error validando dirección: $e');
      return null;
    }
  }

  // Obtener coordenadas desde dirección
  static Future<Map<String, dynamic>?> obtenerCoordenadas(String direccion) async {
    try {
      final response = await HttpService.post('/direcciones/geocodificar', {
        'direccion': direccion,
      });
      return response['data'];
    } catch (e) {
      print('Error obteniendo coordenadas: $e');
      return null;
    }
  }

  // Obtener dirección desde coordenadas
  static Future<Map<String, dynamic>?> obtenerDireccionDesdeCoordenadas({
    required double latitud,
    required double longitud,
  }) async {
    try {
      final response = await HttpService.post('/direcciones/reverse-geocoding', {
        'latitud': latitud,
        'longitud': longitud,
      });
      return response['data'];
    } catch (e) {
      print('Error obteniendo dirección desde coordenadas: $e');
      return null;
    }
  }

  // Calcular distancia entre dos puntos
  static Future<double?> calcularDistancia({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) async {
    try {
      final response = await HttpService.post('/direcciones/calcular-distancia', {
        'lat1': lat1,
        'lng1': lng1,
        'lat2': lat2,
        'lng2': lng2,
      });
      return response['distancia'];
    } catch (e) {
      print('Error calculando distancia: $e');
      return null;
    }
  }
} 