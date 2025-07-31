import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../cliente/providers/carrito_provider.dart';
import '../../../shared/utils/pedidos_helper.dart';
import '../../../core/localization.dart';

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
  List<Map<String, dynamic>> getEstados(BuildContext context) {
    return [
      {'label': AppLocalizations.of(context).get('estado_pendiente'), 'color': Colors.orange},
      {'label': AppLocalizations.of(context).get('estado_preparando'), 'color': Colors.blue},
      {'label': AppLocalizations.of(context).get('estado_en_camino'), 'color': Colors.purple},
      {'label': AppLocalizations.of(context).get('estado_entregado'), 'color': Colors.teal},
      {'label': AppLocalizations.of(context).get('estado_cancelado'), 'color': Colors.red},
    ];
  }

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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
        final total = calcularTotalPedido(pedido);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle del modal
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            getEstadoIcon(pedido['estado']?.toString() ?? 'pendiente'),
                            color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente'),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detalles del Pedido',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                'Pedido #${pedido['id']?.toString().substring(0, 8) ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido scrolleable
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          // Estado del pedido
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente'),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    getEstadoIcon(pedido['estado']?.toString() ?? 'pendiente'),
                                    color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente'),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    pedido['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: getEstadoColor(pedido['estado']?.toString() ?? 'pendiente'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Información del pedido
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // Fecha
                                _buildInfoRow(
                                  icon: Icons.calendar_today,
                                  iconColor: Colors.blue,
                                  title: 'Fecha del Pedido',
                                  value: formatearFecha(pedido['created_at']?.toString() ?? ''),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Cliente
                                _buildInfoRow(
                                  icon: Icons.person,
                                  iconColor: Colors.green,
                                  title: 'Cliente',
                                  value: pedido['nombre_cliente']?.toString() ?? 'Cliente',
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Teléfono
                                if (pedido['telefono_cliente'] != null && pedido['telefono_cliente'].toString().isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.phone,
                                    iconColor: Colors.orange,
                                    title: 'Teléfono',
                                    value: pedido['telefono_cliente'].toString(),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Productos
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...productos.map((producto) => _buildProductoCard(producto)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Total
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total del Pedido',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  Text(
                                    '\$${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Información de entrega
                          if (pedido['direccion_entrega'] != null && pedido['direccion_entrega'].toString().isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Información de Entrega',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    icon: Icons.location_on,
                                    iconColor: Colors.red,
                                    title: 'Dirección',
                                    value: pedido['direccion_entrega'].toString(),
                                  ),
                                  if (pedido['referencias'] != null && pedido['referencias'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      icon: Icons.info_outline,
                                      iconColor: Colors.orange,
                                      title: 'Referencias',
                                      value: pedido['referencias'].toString(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget helper para información
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para productos
  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final precio = formatearPrecio(producto['precio']);
    final cantidad = producto['cantidad']?.toString() ?? '1';
    final subtotal = calcularPrecioTotal(producto['precio'], int.tryParse(cantidad) ?? 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen del producto
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: producto['img'] != null && producto['img'].toString().isNotEmpty
                ? Image.network(
                    producto['img'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto['nombre']?.toString() ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Cantidad: $cantidad',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Precio: \$$precio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Subtotal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mostrar modal para cambiar estado
  Future<String?> mostrarModalCambiarEstado(BuildContext context, String estadoActual) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final estados = [
          {
            'valor': 'pendiente',
            'icono': Icons.schedule,
            'color': Colors.orange,
            'titulo': 'Pendiente',
            'descripcion': 'Pedido recibido, esperando procesamiento',
            'traduccion': AppLocalizations.of(context).get('estado_pendiente'),
          },
          {
            'valor': 'preparando',
            'icono': Icons.restaurant,
            'color': Colors.blue,
            'titulo': 'Preparando',
            'descripcion': 'Pedido en cocina, preparando alimentos',
            'traduccion': AppLocalizations.of(context).get('estado_preparando'),
          },
          {
            'valor': 'en camino',
            'icono': Icons.delivery_dining,
            'color': Colors.purple,
            'titulo': 'En Camino',
            'descripcion': 'Pedido en ruta hacia el cliente',
            'traduccion': AppLocalizations.of(context).get('estado_en_camino'),
          },
          {
            'valor': 'listo',
            'icono': Icons.check_circle,
            'color': Colors.green,
            'titulo': 'Listo',
            'descripcion': 'Pedido preparado, listo para entrega',
            'traduccion': 'Listo',
          },
          {
            'valor': 'entregado',
            'icono': Icons.done_all,
            'color': Colors.teal,
            'titulo': 'Entregado',
            'descripcion': 'Pedido entregado al cliente',
            'traduccion': AppLocalizations.of(context).get('estado_entregado'),
          },
          {
            'valor': 'cancelado',
            'icono': Icons.cancel,
            'color': Colors.red,
            'titulo': 'Cancelado',
            'descripcion': 'Pedido cancelado',
            'traduccion': AppLocalizations.of(context).get('estado_cancelado'),
          },
        ];
        
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle del modal
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cambiar Estado',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Estado actual: ${estadoActual.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de estados
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: estados.length,
                  itemBuilder: (context, index) {
                    final estado = estados[index];
                    final isSelected = estado['valor'] == estadoActual;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (estado['color'] as Color).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? estado['color'] as Color
                              : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (estado['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            estado['icono'] as IconData,
                            color: estado['color'] as Color,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              estado['traduccion'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? estado['color'] as Color
                                    : Colors.grey[800],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: estado['color'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ACTUAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          estado['descripcion'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: estado['color'] as Color,
                                size: 20,
                              )
                            : Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                        onTap: () {
                          if (!isSelected) {
                            Navigator.pop(context, estado['valor'] as String);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Botón cancelar
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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