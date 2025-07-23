// pedidos_screen.dart - Pantalla de pedidos recibidos para el dueño de negocio
// Rediseñada con el mismo estilo visual que el historial de pedidos del cliente
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart'; // Para personalizar la status bar

class DuenioPedidosScreen extends StatefulWidget {
  const DuenioPedidosScreen({super.key});
  @override
  State<DuenioPedidosScreen> createState() => _DuenioPedidosScreenState();
}

class _DuenioPedidosScreenState extends State<DuenioPedidosScreen> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String? _error;
  String? _filtroEstado; // Estado seleccionado para filtrar

  // Lista de estados para los badges
  final List<Map<String, dynamic>> _estados = [
    {'label': 'Pendiente', 'color': Colors.orange},
    {'label': 'Preparando', 'color': Colors.blue},
    {'label': 'En camino', 'color': Colors.purple},
    {'label': 'Listo', 'color': Colors.green},
    {'label': 'Entregado', 'color': Colors.teal},
    {'label': 'Cancelado', 'color': Colors.red},
  ];

  // Orden personalizado de estados
  final List<String> _ordenEstados = [
    'pendiente',
    'preparando',
    'en camino',
    'listo',
    'entregado',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  // Cargar pedidos del negocio desde Supabase
  Future<void> _cargarPedidos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userProvider = context.read<CarritoProvider>();
      final negocioId = userProvider.restauranteId;
      print('🟣 negocioId usado para pedidos: $negocioId');
      if (negocioId == null || negocioId.isEmpty) {
        setState(() {
          _error = 'No se encontró el ID del negocio.';
          _isLoading = false;
        });
        return;
      }
      final data = await Supabase.instance.client
          .from('pedidos')
          .select()
          .eq('restaurante_id', negocioId)
          .order('created_at', ascending: false);
      setState(() {
        _pedidos = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar pedidos: $e';
        _isLoading = false;
      });
    }
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

  // Actualiza el estado de un pedido en Supabase
  Future<void> _actualizarEstadoPedido(
    String pedidoId,
    String nuevoEstado,
  ) async {
    await Supabase.instance.client
        .from('pedidos')
        .update({'estado': nuevoEstado})
        .eq('id', pedidoId);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.blue[50], // Fondo azul claro para la status bar
        statusBarIconBrightness: Brightness.dark, // Iconos oscuros
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.blue[50],
          appBar: AppBar(
      backgroundColor: Colors.blue[50],
            title: const Text('Pedidos del negocio'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarPedidos,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          body: _isLoading
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                        'No hay pedidos aún',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cuando recibas pedidos aparecerán aquí',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Fila de badges para filtrar por estado
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _estados.map((estado) {
                          final selected = _filtroEstado == estado['label'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 10,
                            ),
                            child: ChoiceChip(
                              label: Text(estado['label']),
                              selected: selected,
                              selectedColor: (estado['color'] as Color)
                                  .withOpacity(0.18),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: selected
                                    ? estado['color'] as Color
                                    : Colors.black87,
                              fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _filtroEstado = selected
                                      ? null
                                      : estado['label'] as String;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Lista filtrada de pedidos
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            (_filtroEstado == null
                                    ? _pedidos
                                    : _pedidos
                                          .where(
                                            (p) =>
                                                (p['estado'] ?? '')
                                                    .toLowerCase() ==
                                                _filtroEstado!.toLowerCase(),
                                          )
                                          .toList())
                                .length,
                        itemBuilder: (context, index) {
                          // Filtrar y ordenar los pedidos por estado personalizado
                          List<Map<String, dynamic>> pedidosFiltrados = _filtroEstado == null
                              ? _pedidos
                              : _pedidos
                                    .where(
                                      (p) =>
                                          (p['estado'] ?? '').toLowerCase() ==
                                          _filtroEstado!.toLowerCase(),
                                    )
                                    .toList();
                          pedidosFiltrados.sort((a, b) {
                            final estadoA = (a['estado'] ?? '').toString().toLowerCase();
                            final estadoB = (b['estado'] ?? '').toString().toLowerCase();
                            final idxA = _ordenEstados.indexOf(estadoA);
                            final idxB = _ordenEstados.indexOf(estadoB);
                            if (idxA == idxB) {
                              // Si el estado es igual, ordenar por fecha descendente
                              return (b['created_at'] ?? '').compareTo(a['created_at'] ?? '');
                            }
                            return idxA.compareTo(idxB);
                          });
                          final pedido = pedidosFiltrados[index];
                          final productos = List<Map<String, dynamic>>.from(
                            pedido['productos'] ?? [],
                          );
                          final total = productos.fold<double>(0, (
                            sum,
                            producto,
                          ) {
                            final precio =
                                double.tryParse(
                                  producto['precio']?.toString() ?? '0',
                                ) ??
                                0;
                            final cantidad =
                                int.tryParse(
                                  producto['cantidad']?.toString() ?? '1',
                                ) ??
                                1;
                            return sum + (precio * cantidad);
                          });

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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEstadoColor(
                                            pedido['estado']?.toString() ??
                                                'pendiente',
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _getEstadoColor(
                                              pedido['estado']?.toString() ??
                                                  'pendiente',
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getEstadoIcon(
                                                pedido['estado']?.toString() ??
                                                    'pendiente',
                                              ),
                                              size: 16,
                                              color: _getEstadoColor(
                                                pedido['estado']?.toString() ??
                                                    'pendiente',
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              pedido['estado']
                                                      ?.toString()
                                                      .toUpperCase() ??
                                                  'PENDIENTE',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getEstadoColor(
                                                  pedido['estado']
                                                          ?.toString() ??
                                                      'pendiente',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatearFecha(
                                          pedido['created_at']?.toString() ??
                                              '',
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
                                  ...productos
                                      .take(3)
                                      .map(
                                        (producto) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                child: Row(
                                  children: [
                                              Text(
                                                '• ${producto['nombre']?.toString() ?? 'Sin nombre'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
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
                                        ),
                                      ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total: \$${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          if (pedido['direccion_entrega'] !=
                                              null)
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

                                  // Botón para cambiar estado debajo de la card
                                  const SizedBox(height: 16),
                                  Center(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Cambiar estado'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                          onPressed: () async {
                                        final nuevoEstado =
                                            await showModalBottomSheet<String>(
                                              context: context,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            24,
                                                          ),
                                                        ),
                                                  ),
                                              builder: (context) {
                                                final estados = [
                                                  'pendiente',
                                                  'preparando',
                                                  'en camino',
                                                  'entregado',
                                                  'cancelado',
                                                ];
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Selecciona el nuevo estado',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    ...estados.map(
                                                      (estado) => ListTile(
                                                        leading: Icon(
                                                          _getEstadoIcon(
                                                            estado,
                                                          ),
                                                          color:
                                                              _getEstadoColor(
                                                                estado,
                                                              ),
                                                        ),
                                                        title: Text(
                                                          estado.toUpperCase(),
                                                        ),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                              context,
                                                              estado,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                );
                                              },
                                            );
                                        if (nuevoEstado != null &&
                                            nuevoEstado != pedido['estado']) {
                                          await _actualizarEstadoPedido(
                                            pedido['id'].toString(),
                                            nuevoEstado,
                                          );
                                          _cargarPedidos(); // Refresca la lista
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Estado actualizado a $nuevoEstado',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                              margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ); // Paréntesis de cierre para AnnotatedRegion y método build
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
        final total = productos.fold<double>(0, (sum, producto) {
          final precio =
              double.tryParse(producto['precio']?.toString() ?? '0') ?? 0;
          final cantidad =
              int.tryParse(producto['cantidad']?.toString() ?? '1') ?? 1;
          return sum + (precio * cantidad);
        });

        return Padding(
          padding: EdgeInsets.only(
            left: 20, // Padding horizontal
            right: 20, // Padding horizontal
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
                          _getEstadoIcon(
                            pedido['estado']?.toString() ?? 'pendiente',
                          ),
                          color: _getEstadoColor(
                            pedido['estado']?.toString() ?? 'pendiente',
                          ),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Detalles del Pedido',
                          style: const TextStyle(
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
                    color: _getEstadoColor(
                      pedido['estado']?.toString() ?? 'pendiente',
                    ).withOpacity(0.12),
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
                        size: 18,
                        color: _getEstadoColor(
                          pedido['estado']?.toString() ?? 'pendiente',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pedido['estado']?.toString().toUpperCase() ??
                            'PENDIENTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getEstadoColor(
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
                      'Fecha: ${_formatearFecha(pedido['created_at']?.toString() ?? '')}',
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
                        if (producto['img'] != null &&
                            producto['img'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              producto['img'],
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
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
                          '\$${double.tryParse(producto['precio']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
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
                if (pedido['direccion_entrega'] != null &&
                    pedido['direccion_entrega'].toString().isNotEmpty) ...[
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
                if (pedido['referencias'] != null &&
                    pedido['referencias'].toString().isNotEmpty) ...[
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
}
