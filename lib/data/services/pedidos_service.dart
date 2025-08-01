import '../services/http_service.dart';

class PedidosService {
  // Crear un nuevo pedido
  static Future<Map<String, dynamic>?> crearPedido({
    required String userEmail,
    required String negocioId,
    required List<Map<String, dynamic>> productos,
    required Map<String, dynamic> direccion,
    required double total,
    String? notas,
  }) async {
    try {
      final data = {
        'userEmail': userEmail,
        'negocioId': negocioId,
        'productos': productos,
        'direccion': direccion,
        'total': total,
        if (notas != null) 'notas': notas,
      };

      final response = await HttpService.post('/pedidos', data);
      return response['data'];
    } catch (e) {
      print('Error creando pedido: $e');
      return null;
    }
  }

  // Obtener pedidos de un usuario
  static Future<List<Map<String, dynamic>>> obtenerPedidosUsuario(String userEmail) async {
    try {
      final response = await HttpService.get('/pedidos/usuario/$userEmail');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo pedidos del usuario: $e');
      return [];
    }
  }

  // Obtener pedido por ID
  static Future<Map<String, dynamic>?> obtenerPedido(String pedidoId) async {
    try {
      final response = await HttpService.get('/pedidos/$pedidoId');
      return response['data'];
    } catch (e) {
      print('Error obteniendo pedido: $e');
      return null;
    }
  }

  // Obtener pedidos por estado
  static Future<List<Map<String, dynamic>>> obtenerPedidosPorEstado(String estado) async {
    try {
      final response = await HttpService.get('/pedidos/estado/$estado');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo pedidos por estado: $e');
      return [];
    }
  }

  // Actualizar estado de un pedido
  static Future<bool> actualizarEstadoPedido({
    required String pedidoId,
    required String nuevoEstado,
    String? comentario,
  }) async {
    try {
      final data = {
        'estado': nuevoEstado,
        if (comentario != null) 'comentario': comentario,
      };

      final response = await HttpService.put('/pedidos/$pedidoId/estado', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error actualizando estado del pedido: $e');
      return false;
    }
  }

  // Cancelar pedido
  static Future<bool> cancelarPedido({
    required String pedidoId,
    String? motivo,
  }) async {
    try {
      final data = {
        'motivo': motivo ?? 'Cancelado por el usuario',
      };

      final response = await HttpService.post('/pedidos/$pedidoId/cancelar', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error cancelando pedido: $e');
      return false;
    }
  }

  // Obtener historial de pedidos
  static Future<List<Map<String, dynamic>>> obtenerHistorialPedidos(String userEmail) async {
    try {
      final response = await HttpService.get('/pedidos/historial/$userEmail');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo historial de pedidos: $e');
      return [];
    }
  }

  // Obtener pedidos activos
  static Future<List<Map<String, dynamic>>> obtenerPedidosActivos(String userEmail) async {
    try {
      final response = await HttpService.get('/pedidos/activos/$userEmail');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error obteniendo pedidos activos: $e');
      return [];
    }
  }

  // Calificar pedido
  static Future<bool> calificarPedido({
    required String pedidoId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      final data = {
        'calificacion': calificacion,
        if (comentario != null) 'comentario': comentario,
      };

      final response = await HttpService.post('/pedidos/$pedidoId/calificar', data);
      return response['success'] ?? false;
    } catch (e) {
      print('Error calificando pedido: $e');
      return false;
    }
  }

  // Obtener detalles de un pedido
  static Future<Map<String, dynamic>?> obtenerDetallesPedido(String pedidoId) async {
    try {
      final response = await HttpService.get('/pedidos/$pedidoId/detalles');
      return response['data'];
    } catch (e) {
      print('Error obteniendo detalles del pedido: $e');
      return null;
    }
  }

  // Obtener tiempo estimado de entrega
  static Future<int?> obtenerTiempoEstimado(String pedidoId) async {
    try {
      final response = await HttpService.get('/pedidos/$pedidoId/tiempo-estimado');
      return response['tiempoEstimado'];
    } catch (e) {
      print('Error obteniendo tiempo estimado: $e');
      return null;
    }
  }

  // Confirmar recepción del pedido
  static Future<bool> confirmarRecepcion(String pedidoId) async {
    try {
      final response = await HttpService.post('/pedidos/$pedidoId/confirmar-recepcion', {});
      return response['success'] ?? false;
    } catch (e) {
      print('Error confirmando recepción: $e');
      return false;
    }
  }
} 