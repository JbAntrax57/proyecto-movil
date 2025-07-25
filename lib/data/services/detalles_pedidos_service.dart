import 'package:supabase_flutter/supabase_flutter.dart';

class DetallesPedidosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Crear detalles de pedido
  Future<void> crearDetallesPedido({
    required String pedidoId,
    required List<Map<String, dynamic>> productos,
  }) async {
    try {
      // Preparar los datos para insertar
      final detalles = productos.map((producto) {
        return {
          'pedido_id': pedidoId,
          'producto_id': producto['id'] ?? producto['producto_id'],
          'nombre': producto['nombre'] ?? '',
          'descripcion': producto['descripcion'] ?? '',
          'precio': double.tryParse(producto['precio']?.toString() ?? '0') ?? 0.0,
          'cantidad': int.tryParse(producto['cantidad']?.toString() ?? '1') ?? 1,
          'img': producto['img'] ?? '',
        };
      }).toList();

      // Insertar todos los detalles
      await _supabase.from('detalles_pedidos').insert(detalles);
    } catch (e) {
      throw Exception('Error al crear detalles del pedido: $e');
    }
  }

  /// Obtener detalles de un pedido específico
  Future<List<Map<String, dynamic>>> obtenerDetallesPedido(String pedidoId) async {
    try {
      final data = await _supabase
          .from('detalles_pedidos')
          .select()
          .eq('pedido_id', pedidoId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error al obtener detalles del pedido: $e');
    }
  }

  /// Obtener detalles de múltiples pedidos
  Future<Map<String, List<Map<String, dynamic>>>> obtenerDetallesMultiplesPedidos(
    List<String> pedidosIds,
  ) async {
    try {
      final data = await _supabase
          .from('detalles_pedidos')
          .select()
          .inFilter('pedido_id', pedidosIds)
          .order('created_at', ascending: true);
      
      // Agrupar por pedido_id
      final Map<String, List<Map<String, dynamic>>> detallesPorPedido = {};
      for (final detalle in data) {
        final pedidoId = detalle['pedido_id'] as String;
        detallesPorPedido.putIfAbsent(pedidoId, () => []).add(detalle);
      }
      
      return detallesPorPedido;
    } catch (e) {
      throw Exception('Error al obtener detalles de múltiples pedidos: $e');
    }
  }

  /// Eliminar detalles de un pedido
  Future<void> eliminarDetallesPedido(String pedidoId) async {
    try {
      await _supabase
          .from('detalles_pedidos')
          .delete()
          .eq('pedido_id', pedidoId);
    } catch (e) {
      throw Exception('Error al eliminar detalles del pedido: $e');
    }
  }

  /// Actualizar un detalle específico
  Future<void> actualizarDetalle({
    required String detalleId,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _supabase
          .from('detalles_pedidos')
          .update(datos)
          .eq('id', detalleId);
    } catch (e) {
      throw Exception('Error al actualizar detalle: $e');
    }
  }

  /// Calcular total de un pedido basado en sus detalles
  Future<double> calcularTotalPedido(String pedidoId) async {
    try {
      final detalles = await obtenerDetallesPedido(pedidoId);
      
      return detalles.fold<double>(0, (total, detalle) {
        final precio = double.tryParse(detalle['precio']?.toString() ?? '0') ?? 0.0;
        final cantidad = int.tryParse(detalle['cantidad']?.toString() ?? '1') ?? 1;
        return total + (precio * cantidad);
      });
    } catch (e) {
      throw Exception('Error al calcular total del pedido: $e');
    }
  }
} 