import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../cliente/providers/carrito_provider.dart';
import '../../../shared/utils/pedidos_helper.dart';

class PedidosDuenioProvider extends ChangeNotifier {
  // Estado de los pedidos
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String? _error;
  String? _filtroEstado;
  StreamSubscription? _pedidosSubscription;

  // Getters para el estado
  List<Map<String, dynamic>> get pedidos => _pedidos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filtroEstado => _filtroEstado;

  // Lista de estados para los badges
  final List<Map<String, dynamic>> estados = [
    {'label': 'Pendiente', 'color': Colors.orange},
    {'label': 'Preparando', 'color': Colors.blue},
    {'label': 'En camino', 'color': Colors.purple},
    {'label': 'Listo', 'color': Colors.green},
    {'label': 'Entregado', 'color': Colors.teal},
    {'label': 'Cancelado', 'color': Colors.red},
  ];

  // Orden personalizado de estados
  final List<String> ordenEstados = [
    'pendiente',
    'preparando',
    'en camino',
    'listo',
    'entregado',
    'cancelado',
  ];

  // Inicializar el provider
  Future<void> inicializarPedidos(BuildContext context) async {
    await cargarPedidos(context);
    suscribirseAPedidosRealtime(context);
  }

  // Suscribirse a la tabla de pedidos para actualizar la lista en tiempo real
  void suscribirseAPedidosRealtime(BuildContext context) {
    _pedidosSubscription?.cancel();
    _pedidosSubscription = Supabase.instance.client
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .listen((data) async {
        final userProvider = context.read<CarritoProvider>();
        final negocioId = userProvider.restauranteId;
        final pedidosNegocio = List<Map<String, dynamic>>.from(data)
            .where((p) => p['restaurante_id'] == negocioId)
            .toList();
        
        // Obtener detalles para los pedidos filtrados
        if (pedidosNegocio.isNotEmpty) {
          final pedidosIds = pedidosNegocio.map((p) => p['id'] as String).toList();
          final detallesPorPedido = await PedidosHelper.obtenerDetallesMultiplesPedidos(pedidosIds);
          
          // Combinar pedidos con sus detalles
          final pedidosConDetalles = pedidosNegocio.map((pedido) {
            final pedidoId = pedido['id'] as String;
            final detalles = detallesPorPedido[pedidoId] ?? [];
            
            return {
              ...pedido,
              'productos': detalles, // Mantener compatibilidad
            };
          }).toList();
          
          _pedidos = pedidosConDetalles;
          notifyListeners();
        } else {
          _pedidos = pedidosNegocio;
          notifyListeners();
        }
      });
  }

  // Cargar pedidos del negocio desde Supabase
  Future<void> cargarPedidos(BuildContext context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (!context.mounted) return;
      final userProvider = context.read<CarritoProvider>();
      final negocioId = userProvider.restauranteId;
      
      if (negocioId == null || negocioId.isEmpty) {
        _setError('No se encontró el ID del negocio.');
        _setLoading(false);
        return;
      }
      
      // Usar el helper para obtener pedidos con detalles
      final pedidosConDetalles = await PedidosHelper.obtenerPedidosConDetalles(
        restauranteId: negocioId,
      );
      
      _pedidos = pedidosConDetalles;
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar pedidos: $e');
      _setLoading(false);
    }
  }

  // Actualizar estado de un pedido
  Future<void> actualizarEstadoPedido(String pedidoId, String nuevoEstado, BuildContext? context) async {
    try {
      await Supabase.instance.client
          .from('pedidos')
          .update({'estado': nuevoEstado})
          .eq('id', pedidoId);
      
      // Refrescar la lista después de actualizar si tenemos contexto
      if (context != null) {
        await cargarPedidos(context);
      }
    } catch (e) {
      // Error actualizando estado del pedido
      throw Exception('Error al actualizar el estado del pedido');
    }
  }

  // Obtener color según el estado del pedido
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

  // Obtener icono según el estado del pedido
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

  // Formatear fecha
  String formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }

  // Helper para formatear precios como doubles
  String formatearPrecio(dynamic precio) {
    if (precio == null) return '0.00';
    if (precio is int) return precio.toDouble().toStringAsFixed(2);
    if (precio is double) return precio.toStringAsFixed(2);
    if (precio is String) {
      final doubleValue = double.tryParse(precio);
      return doubleValue?.toStringAsFixed(2) ?? '0.00';
    }
    return '0.00';
  }

  // Helper para calcular el precio total
  double calcularPrecioTotal(dynamic precio, int cantidad) {
    if (precio == null) return 0.0;
    if (precio is int) return (precio * cantidad).toDouble();
    if (precio is double) return precio * cantidad;
    if (precio is String) {
      final doubleValue = double.tryParse(precio);
      return (doubleValue ?? 0.0) * cantidad;
    }
    return 0.0;
  }

  // Calcular total de un pedido
  double calcularTotalPedido(Map<String, dynamic> pedido) {
    final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
    return productos.fold<double>(0, (sum, producto) {
      final precio = calcularPrecioTotal(
        producto['precio'],
        int.tryParse(producto['cantidad']?.toString() ?? '1') ?? 1,
      );
      return sum + precio;
    });
  }

  // Filtrar pedidos por estado
  List<Map<String, dynamic>> getPedidosFiltrados() {
    if (_filtroEstado == null) {
      return _pedidos;
    }
    
    return _pedidos
        .where((p) => (p['estado'] ?? '').toLowerCase() == _filtroEstado!.toLowerCase())
        .toList();
  }

  // Obtener pedidos ordenados
  List<Map<String, dynamic>> getPedidosOrdenados() {
    final pedidosFiltrados = getPedidosFiltrados();
    
    pedidosFiltrados.sort((a, b) {
      final estadoA = (a['estado'] ?? '').toString().toLowerCase();
      final estadoB = (b['estado'] ?? '').toString().toLowerCase();
      final idxA = ordenEstados.indexOf(estadoA);
      final idxB = ordenEstados.indexOf(estadoB);
      
      if (idxA == idxB) {
        // Si el estado es igual, ordenar por fecha descendente
        return (b['created_at'] ?? '').compareTo(a['created_at'] ?? '');
      }
      return idxA.compareTo(idxB);
    });
    
    return pedidosFiltrados;
  }

  // Establecer filtro de estado
  void setFiltroEstado(String? estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  // Limpiar filtro
  void limpiarFiltro() {
    _filtroEstado = null;
    notifyListeners();
  }

  // Obtener estadísticas de pedidos
  Map<String, int> obtenerEstadisticasPedidos() {
    final estadisticas = <String, int>{};
    
    for (final pedido in _pedidos) {
      final estado = (pedido['estado'] ?? 'pendiente').toString().toLowerCase();
      estadisticas[estado] = (estadisticas[estado] ?? 0) + 1;
    }
    
    return estadisticas;
  }

  // Obtener pedidos por estado
  List<Map<String, dynamic>> obtenerPedidosPorEstado(String estado) {
    return _pedidos
        .where((p) => (p['estado'] ?? '').toString().toLowerCase() == estado.toLowerCase())
        .toList();
  }

  // Obtener pedidos recientes (últimas 24 horas)
  List<Map<String, dynamic>> obtenerPedidosRecientes() {
    final ahora = DateTime.now();
    final hace24Horas = ahora.subtract(const Duration(hours: 24));
    
    return _pedidos.where((pedido) {
      try {
        final fechaPedido = DateTime.parse(pedido['created_at']?.toString() ?? '');
        return fechaPedido.isAfter(hace24Horas);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Obtener pedidos pendientes
  List<Map<String, dynamic>> obtenerPedidosPendientes() {
    return _pedidos.where((pedido) {
      final estado = (pedido['estado'] ?? '').toString().toLowerCase();
      return estado == 'pendiente' || estado == 'preparando';
    }).toList();
  }

  // Verificar si hay pedidos nuevos
  bool hayPedidosNuevos() {
    return _pedidos.any((pedido) {
      final estado = (pedido['estado'] ?? '').toString().toLowerCase();
      return estado == 'pendiente';
    });
  }

  // Obtener total de ventas del día
  double obtenerTotalVentasDelDia() {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    
    return _pedidos.where((pedido) {
      try {
        final fechaPedido = DateTime.parse(pedido['created_at']?.toString() ?? '');
        return fechaPedido.isAfter(inicioDia);
      } catch (e) {
        return false;
      }
    }).fold<double>(0, (sum, pedido) => sum + calcularTotalPedido(pedido));
  }

  // Mostrar detalles del pedido
  void mostrarDetallesPedido(BuildContext context, Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
        final total = calcularTotalPedido(pedido);

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getEstadoIcon(pedido['estado']?.toString() ?? 'pendiente'),
                          color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente'),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Detalles del Pedido',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Estado visual
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: getEstadoColor(
                      pedido['estado']?.toString() ?? 'pendiente',
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getEstadoColor(
                        pedido['estado']?.toString() ?? 'pendiente',
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getEstadoIcon(
                          pedido['estado']?.toString() ?? 'pendiente',
                        ),
                        size: 18,
                        color: getEstadoColor(
                          pedido['estado']?.toString() ?? 'pendiente',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pedido['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getEstadoColor(
                            pedido['estado']?.toString() ?? 'pendiente',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Fecha
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fecha: ${formatearFecha(pedido['created_at']?.toString() ?? '')}',
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Productos
                const Text(
                  'Productos:',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...productos.map(
                  (producto) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Imagen del producto si hay
                        if (producto['img'] != null && producto['img'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              producto['img'],
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 38,
                                height: 38,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            producto['nombre']?.toString() ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'x${producto['cantidad']?.toString() ?? '1'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '\$${formatearPrecio(producto['precio'])}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Total destacado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 18,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ubicación
                if (pedido['direccion_entrega'] != null && pedido['direccion_entrega'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pedido['direccion_entrega'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Referencias
                if (pedido['referencias'] != null && pedido['referencias'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pedido['referencias'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mostrar modal para cambiar estado
  Future<String?> mostrarModalCambiarEstado(BuildContext context, String estadoActual) async {
    return await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final estados = [
          'pendiente',
          'preparando',
          'en camino',
          'listo',
          'entregado',
          'cancelado',
        ];
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Selecciona el nuevo estado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...estados.map(
              (estado) => ListTile(
                leading: Icon(
                  getEstadoIcon(estado),
                  color: getEstadoColor(estado),
                ),
                title: Text(estado.toUpperCase()),
                onTap: () => Navigator.pop(context, estado),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // Limpiar recursos
  @override
  void dispose() {
    _pedidosSubscription?.cancel();
    super.dispose();
  }

  // Setters para el estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 