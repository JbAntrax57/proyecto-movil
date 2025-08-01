import 'package:flutter/material.dart';
import '../../../data/services/pedidos_service.dart';
import '../../../shared/utils/pedidos_helper.dart';

class PedidosProvider extends ChangeNotifier {
  // Estado de la pantalla
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _pedidos = [];
  String? _userEmail;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get pedidos => List.unmodifiable(_pedidos);
  String? get userEmail => _userEmail;

  // Verificar si hay pedidos
  bool get tienePedidos => _pedidos.isNotEmpty;

  // Establecer email del usuario
  void setUserEmail(String email) {
    _userEmail = email;
    if (email.isNotEmpty) {
      cargarPedidos();
    }
  }

  // Cargar pedidos del usuario
  Future<void> cargarPedidos() async {
    if (_userEmail == null || _userEmail!.isEmpty) return;

    setLoading(true);
    limpiarError();

    try {
      final pedidosData = await PedidosService.obtenerPedidosUsuario(_userEmail!);
      
      _pedidos = pedidosData;
      notifyListeners();
    } catch (e) {
      setError('Error al cargar los pedidos: $e');
    } finally {
      setLoading(false);
    }
  }

  // Recargar pedidos (para pull-to-refresh)
  Future<void> recargarPedidos() async {
    await cargarPedidos();
  }

  // Obtener color del estado del pedido
  Color getEstadoColor(String estado) {
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

  // Obtener ícono del estado del pedido
  IconData getEstadoIcon(String estado) {
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

  // Calcular progreso del pedido basado en el estado
  double getEstadoProgress(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 0.25;
      case 'preparando':
        return 0.5;
      case 'en camino':
        return 0.75;
      case 'entregado':
        return 1.0;
      case 'cancelado':
        return 0.0;
      default:
        return 0.0;
    }
  }

  // Verificar si el pedido está activo (no entregado ni cancelado)
  bool isPedidoActivo(String estado) {
    return estado.toLowerCase() != 'entregado' && 
           estado.toLowerCase() != 'cancelado';
  }

  // Obtener pedidos por estado
  List<Map<String, dynamic>> getPedidosPorEstado(String estado) {
    return _pedidos.where((pedido) => 
      pedido['estado'].toString().toLowerCase() == estado.toLowerCase()
    ).toList();
  }

  // Obtener pedidos activos
  List<Map<String, dynamic>> getPedidosActivos() {
    return _pedidos.where((pedido) => 
      isPedidoActivo(pedido['estado'].toString())
    ).toList();
  }

  // Obtener pedidos completados
  List<Map<String, dynamic>> getPedidosCompletados() {
    return _pedidos.where((pedido) => 
      pedido['estado'].toString().toLowerCase() == 'entregado'
    ).toList();
  }

  // Obtener pedidos cancelados
  List<Map<String, dynamic>> getPedidosCancelados() {
    return _pedidos.where((pedido) => 
      pedido['estado'].toString().toLowerCase() == 'cancelado'
    ).toList();
  }

  // Obtener estadísticas de pedidos
  Map<String, int> getEstadisticasPedidos() {
    final total = _pedidos.length;
    final activos = getPedidosActivos().length;
    final completados = getPedidosCompletados().length;
    final cancelados = getPedidosCancelados().length;

    return {
      'total': total,
      'activos': activos,
      'completados': completados,
      'cancelados': cancelados,
    };
  }

  // Obtener pedido por ID
  Map<String, dynamic>? getPedidoPorId(String pedidoId) {
    try {
      return _pedidos.firstWhere((pedido) => pedido['id'] == pedidoId);
    } catch (e) {
      return null;
    }
  }

  // Formatear fecha del pedido
  String formatearFechaPedido(Map<String, dynamic> pedido) {
    try {
      final timestamp = DateTime.parse(pedido['created_at'].toString());
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  // Obtener productos de un pedido
  List<Map<String, dynamic>> getProductosPedido(Map<String, dynamic> pedido) {
    try {
      final productos = pedido['productos'] as List?;
      if (productos == null) return [];
      
      return productos.map((producto) => 
        Map<String, dynamic>.from(producto)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Calcular total de un pedido
  double calcularTotalPedido(Map<String, dynamic> pedido) {
    try {
      final productos = getProductosPedido(pedido);
      return productos.fold(0.0, (total, producto) {
        final precio = _parsePrecio(producto['precio']);
        final cantidad = _parseCantidad(producto['cantidad']);
        return total + (precio * cantidad);
      });
    } catch (e) {
      return 0.0;
    }
  }

  // Helper para convertir precio de forma segura
  double _parsePrecio(dynamic precio) {
    if (precio is int) return precio.toDouble();
    if (precio is String) return double.tryParse(precio) ?? 0.0;
    if (precio is double) return precio;
    return 0.0;
  }

  // Helper para convertir cantidad de forma segura
  int _parseCantidad(dynamic cantidad) {
    if (cantidad is int) return cantidad;
    if (cantidad is String) return int.tryParse(cantidad) ?? 1;
    if (cantidad is double) return cantidad.toInt();
    return 1;
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

  // Limpiar sesión
  void limpiarSesion() {
    _pedidos.clear();
    _userEmail = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
} 