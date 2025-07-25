import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/utils/pedidos_helper.dart';

// historial_pedidos_screen.dart - Pantalla de historial de pedidos para el cliente
// Muestra todos los pedidos realizados por el usuario con su estado actual
class HistorialPedidosScreen extends StatefulWidget {
  final bool? showAppBar;
  
  const HistorialPedidosScreen({
    super.key,
    this.showAppBar,
  });

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String? _error;
  bool _mostrarLeyenda = false;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
    
    // Mostrar la leyenda con un pequeño delay para una entrada más suave
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _mostrarLeyenda = true;
        });
      }
    });
    
    // Ocultar la leyenda después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _mostrarLeyenda = false;
        });
      }
    });
  }

  // Cargar pedidos del usuario desde Supabase
  Future<void> _cargarPedidos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail == null) {
        setState(() {
          _error = 'No se pudo identificar al usuario';
          _isLoading = false;
        });
        return;
      }

      final pedidosConDetalles = await PedidosHelper.obtenerPedidosConDetalles(
        usuarioEmail: userEmail,
      );

      // Ordenar pedidos por estado y fecha
      final pedidosOrdenados = _ordenarPedidosPorEstado(pedidosConDetalles);

      setState(() {
        _pedidos = pedidosOrdenados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar pedidos: $e';
        _isLoading = false;
      });
    }
  }

  // Ordenar pedidos por estado (prioridad) y fecha
  List<Map<String, dynamic>> _ordenarPedidosPorEstado(List<Map<String, dynamic>> pedidos) {
    // Definir prioridad de estados (menor número = mayor prioridad)
    final Map<String, int> prioridadEstados = {
      'pendiente': 1,
      'preparando': 2,
      'en camino': 3,
      'entregado': 4,
      'cancelado': 5,
    };

    pedidos.sort((a, b) {
      final estadoA = a['estado']?.toString().toLowerCase() ?? 'pendiente';
      final estadoB = b['estado']?.toString().toLowerCase() ?? 'pendiente';
      
      final prioridadA = prioridadEstados[estadoA] ?? 6;
      final prioridadB = prioridadEstados[estadoB] ?? 6;
      
      // Si tienen la misma prioridad, ordenar por fecha (más reciente primero)
      if (prioridadA == prioridadB) {
        final fechaA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1900);
        final fechaB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1900);
        return fechaB.compareTo(fechaA);
      }
      
      // Ordenar por prioridad de estado
      return prioridadA.compareTo(prioridadB);
    });

    return pedidos;
  }

  // Obtener color según el estado del pedido
  Color _getEstadoColor(String estado) {
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
  IconData _getEstadoIcon(String estado) {
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
  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar ?? true; // Asegurar que sea bool
    
    return Container(
      color: Colors.blue[50], // Fondo uniforme para toda la pantalla, incluyendo el área segura superior
      child: SafeArea(
        top: false, // Permite que el color de fondo cubra la parte superior (barra de estado)
        child: Scaffold(
          extendBody: true, // Permite que el contenido se extienda detrás de widgets flotantes
          backgroundColor: Colors.transparent, // El fondo lo pone el Container exterior
          appBar: showAppBar
            ? AppBar(
                backgroundColor: Colors.blue[50],
                title: const Text('Historial de Pedidos'),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _cargarPedidos,
                    tooltip: 'Actualizar',
                  ),
                ],
              )
            : null,
          body: Column(
            children: [
              // Título personalizado cuando no hay AppBar
              if (!showAppBar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Historial de Pedidos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.green),
                        onPressed: _cargarPedidos,
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                ),
              // Información sobre el ordenamiento (se oculta después de 5 segundos)
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                height: _mostrarLeyenda ? 60 : 0,
                margin: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: _mostrarLeyenda ? 8 : 0,
                ),
                child: AnimatedOpacity(
                  opacity: _mostrarLeyenda ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          child: Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            child: const Text(
                              'Los pedidos están ordenados por estado: Pendiente → Preparando → En camino → Entregado → Cancelado',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar pedidos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _cargarPedidos,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _pedidos.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tienes pedidos aún',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Realiza tu primer pedido para verlo aquí',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _cargarPedidos,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _pedidos.length,
                                  itemBuilder: (context, index) {
                                    final pedido = _pedidos[index];
                                    final productos = List<Map<String, dynamic>>.from(
                                      pedido['productos'] ?? [],
                                    );
                                    final total = productos.fold<double>(
                                      0,
                                      (sum, producto) {
                                        final precio = double.tryParse(
                                          producto['precio']?.toString() ?? '0',
                                        ) ?? 0;
                                        final cantidad = int.tryParse(
                                          producto['cantidad']?.toString() ?? '1',
                                        ) ?? 1;
                                        return sum + (precio * cantidad);
                                      },
                                    );

                                    return Card(
                                      elevation: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header con estado y fecha
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Indicador de prioridad
                                                    Container(
                                                      width: 4,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: _getEstadoColor(
                                                          pedido['estado']?.toString() ?? 'pendiente',
                                                        ),
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getEstadoColor(
                                                          pedido['estado']?.toString() ?? 'pendiente',
                                                        ).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(
                                                          color: _getEstadoColor(
                                                            pedido['estado']?.toString() ?? 'pendiente',
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            _getEstadoIcon(
                                                              pedido['estado']?.toString() ?? 'pendiente',
                                                            ),
                                                            size: 16,
                                                            color: _getEstadoColor(
                                                              pedido['estado']?.toString() ?? 'pendiente',
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            pedido['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: _getEstadoColor(
                                                                pedido['estado']?.toString() ?? 'pendiente',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  _formatearFecha(
                                                    pedido['created_at']?.toString() ?? '',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Productos
                                            Text(
                                              'Productos:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...productos.take(3).map((producto) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '• ${producto['nombre']?.toString() ?? 'Sin nombre'}',
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    'x${producto['cantidad']?.toString() ?? '1'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                            if (productos.length > 3)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '... y ${productos.length - 3} más',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),

                                            const SizedBox(height: 12),
                                            const Divider(),

                                            // Total y ubicación
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Total: \$${total.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    if (pedido['direccion_entrega'] != null)
                                                      SizedBox(
                                                        width: 200,
                                                        child: Text(
                                                          '📍 ${pedido['direccion_entrega']}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.info_outline),
                                                  onPressed: () {
                                                    _mostrarDetallesPedido(pedido);
                                                  },
                                                  tooltip: 'Ver detalles',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar detalles completos del pedido
  void _mostrarDetallesPedido(Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final productos = List<Map<String, dynamic>>.from(
          pedido['productos'] ?? [],
        );
        final total = productos.fold<double>(
          0,
          (sum, producto) {
            final precio = double.tryParse(
              producto['precio']?.toString() ?? '0',
            ) ?? 0;
            final cantidad = int.tryParse(
              producto['cantidad']?.toString() ?? '1',
            ) ?? 1;
            return sum + (precio * cantidad);
          },
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalles del Pedido',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(
                      pedido['estado']?.toString() ?? 'pendiente',
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getEstadoColor(
                        pedido['estado']?.toString() ?? 'pendiente',
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getEstadoIcon(
                          pedido['estado']?.toString() ?? 'pendiente',
                        ),
                        size: 16,
                        color: _getEstadoColor(
                          pedido['estado']?.toString() ?? 'pendiente',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pedido['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getEstadoColor(
                            pedido['estado']?.toString() ?? 'pendiente',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Fecha
                Text(
                  'Fecha: ${_formatearFecha(pedido['created_at']?.toString() ?? '')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Productos
                const Text(
                  'Productos:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...productos.map((producto) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${producto['nombre']?.toString() ?? 'Sin nombre'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'x${producto['cantidad']?.toString() ?? '1'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '\$${double.tryParse(producto['precio']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                const Divider(),

                // Total
                Row(
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
                const SizedBox(height: 16),

                // Ubicación
                if (pedido['direccion_entrega'] != null) ...[
                  const Text(
                    'Ubicación de entrega:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📍 ${pedido['direccion_entrega']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                // Referencias
                if (pedido['referencias'] != null && pedido['referencias'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Referencias:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📝 ${pedido['referencias']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
} 