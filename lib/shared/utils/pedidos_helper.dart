import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/detalles_pedidos_service.dart';

class PedidosHelper {
  static final DetallesPedidosService _detallesService = DetallesPedidosService();

  /// Obtener detalles de un pedido específico
  static Future<List<Map<String, dynamic>>> obtenerDetallesPedido(String pedidoId) async {
    try {
      return await _detallesService.obtenerDetallesPedido(pedidoId);
    } catch (e) {
      print('Error obteniendo detalles del pedido $pedidoId: $e');
      return [];
    }
  }

  /// Obtener detalles de múltiples pedidos de manera eficiente
  static Future<Map<String, List<Map<String, dynamic>>>> obtenerDetallesMultiplesPedidos(
    List<String> pedidosIds,
  ) async {
    try {
      return await _detallesService.obtenerDetallesMultiplesPedidos(pedidosIds);
    } catch (e) {
      print('Error obteniendo detalles de múltiples pedidos: $e');
      return {};
    }
  }

  /// Calcular total de un pedido basado en sus detalles
  static Future<double> calcularTotalPedido(String pedidoId) async {
    try {
      return await _detallesService.calcularTotalPedido(pedidoId);
    } catch (e) {
      print('Error calculando total del pedido $pedidoId: $e');
      return 0.0;
    }
  }

  /// Obtener pedidos con sus detalles incluidos
  static Future<List<Map<String, dynamic>>> obtenerPedidosConDetalles({
    String? usuarioEmail,
    String? restauranteId,
    String? estado,
  }) async {
    try {
      // Construir la consulta base
      var query = Supabase.instance.client.from('pedidos').select();
      
      if (usuarioEmail != null) {
        query = query.eq('usuario_email', usuarioEmail);
      }
      
      if (restauranteId != null) {
        query = query.eq('restaurante_id', restauranteId);
      }
      
      if (estado != null) {
        query = query.eq('estado', estado);
      }
      
      final pedidos = await query.order('created_at', ascending: false);
      
      if (pedidos.isEmpty) return [];
      
      // Obtener los IDs de los pedidos
      final pedidosIds = pedidos.map((p) => p['id'] as String).toList();
      
      // Obtener todos los detalles de una vez
      final detallesPorPedido = await obtenerDetallesMultiplesPedidos(pedidosIds);
      
      // Combinar pedidos con sus detalles
      final pedidosConDetalles = pedidos.map((pedido) {
        final pedidoId = pedido['id'] as String;
        final detalles = detallesPorPedido[pedidoId] ?? [];
        
        return {
          ...pedido,
          'productos': detalles, // Mantener compatibilidad con el código existente
        };
      }).toList();
      
      return pedidosConDetalles;
    } catch (e) {
      print('Error obteniendo pedidos con detalles: $e');
      return [];
    }
  }

  /// Formatear fecha de manera consistente
  static String formatearFecha(dynamic fecha) {
    try {
      final date = DateTime.parse(fecha.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha.toString();
    }
  }

  /// Obtener color del estado del pedido
  static Color getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtener icono del estado del pedido
  static IconData getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.schedule;
      case 'preparando':
        return Icons.restaurant;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
} 