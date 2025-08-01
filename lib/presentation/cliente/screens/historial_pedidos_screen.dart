import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/utils/pedidos_helper.dart';
import '../../../core/localization.dart';

// historial_pedidos_screen.dart - Pantalla de historial de pedidos para el cliente
// Rediseñada con patrón moderno de diseño
class HistorialPedidosScreen extends StatefulWidget {
  final bool? showAppBar;

  const HistorialPedidosScreen({super.key, this.showAppBar});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> 
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String? _error;
  bool _mostrarLeyenda = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  // Helper para obtener folio del pedido (primeros 8 dígitos del ID)
  String _obtenerFolio(String? pedidoId) {
    if (pedidoId == null || pedidoId.isEmpty) return 'N/A';
    return pedidoId.length >= 8 ? pedidoId.substring(0, 8) : pedidoId;
  }

  // Helper para formatear precios como doubles
  String _formatearPrecio(dynamic precio) {
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
  double _calcularPrecioTotal(dynamic precio, int cantidad) {
    if (precio == null) return 0.0;
    if (precio is int) return (precio * cantidad).toDouble();
    if (precio is double) return precio * cantidad;
    if (precio is String) {
      final doubleValue = double.tryParse(precio);
      return (doubleValue ?? 0.0) * cantidad;
    }
    return 0.0;
  }

  // Helper para traducir estados de pedidos
  String _traducirEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return AppLocalizations.of(context).get('estado_pendiente');
      case 'preparando':
        return AppLocalizations.of(context).get('estado_preparando');
      case 'en camino':
        return AppLocalizations.of(context).get('estado_en_camino');
      case 'entregado':
        return AppLocalizations.of(context).get('estado_entregado');
      case 'cancelado':
        return AppLocalizations.of(context).get('estado_cancelado');
      default:
        return AppLocalizations.of(context).get('estado_pendiente');
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Inicializar animación de slide
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _cargarPedidos();

    // Mostrar la leyenda con un delay más largo para una entrada más suave
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _mostrarLeyenda = true;
        });
        // Iniciar animación de slide
        _slideController.forward();
        // Iniciar animación de pulso después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _pulseController.repeat(reverse: true);
          }
        });
      }
    });

    // Ocultar la leyenda después de 8 segundos con animación más suave
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        // Detener animación de pulso primero
        _pulseController.stop();
        // Luego ocultar la leyenda con animación de salida
        _slideController.reverse();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _mostrarLeyenda = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
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
  List<Map<String, dynamic>> _ordenarPedidosPorEstado(
    List<Map<String, dynamic>> pedidos,
  ) {
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
        final fechaA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(1900);
        final fechaB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(1900);
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1976D2), // Colors.blue[600]
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            // AppBar moderno
            _buildAppBar(),
            
            // Sección de información
            if (_mostrarLeyenda) 
              SliverToBoxAdapter(
                child: _buildInfoSection(),
              ),
            
            // Estadísticas
            SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),
            
            // Contenido principal
            SliverToBoxAdapter(
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar moderno
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[600]!,
                Colors.blue[800]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                                     // Barra superior
                   Row(
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               AppLocalizations.of(context).get('historial_pedidos'),
                               style: GoogleFonts.poppins(
                                 fontSize: 24,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.white,
                               ),
                             ),
                             Text(
                               'Revisa tus pedidos anteriores',
                               style: GoogleFonts.poppins(
                                 fontSize: 14,
                                 color: Colors.white.withOpacity(0.8),
                               ),
                             ),
                           ],
                         ),
                       ),
                       IconButton(
                         onPressed: _cargarPedidos,
                         icon: Icon(
                           Icons.refresh,
                           color: Colors.white,
                           size: 24,
                         ),
                       ),
                     ],
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Sección de información
  Widget _buildInfoSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      height: _mostrarLeyenda ? 100 : 0,
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: _mostrarLeyenda ? 10 : 0,
      ),
      child: AnimatedOpacity(
        opacity: _mostrarLeyenda ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 100),
              child: Transform.scale(
                scale: _mostrarLeyenda ? 1.0 : 0.8,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.lightBlue[200]!,
                        Colors.blue[600]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icono animado
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        transform: Matrix4.identity()
                          ..scale(_mostrarLeyenda ? 1.0 : 0.3),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _mostrarLeyenda ? _pulseAnimation.value : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Texto animado
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          style: GoogleFonts.poppins(
                            fontSize: _mostrarLeyenda ? 15 : 0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          child: Text(
                            AppLocalizations.of(context).get('ordenamiento_pedidos'),
                          ),
                        ),
                      ),
                      // Indicador de cierre animado
                      AnimatedOpacity(
                        opacity: _mostrarLeyenda ? 0.6 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Sección de estadísticas
  Widget _buildStatsSection() {
    if (_isLoading || _error != null || _pedidos.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalPedidos = _pedidos.length;
    final pedidosActivos = _pedidos.where((p) => 
      ['pendiente', 'preparando', 'en camino'].contains(
        p['estado']?.toString().toLowerCase()
      )
    ).length;
    final pedidosEntregados = _pedidos.where((p) => 
      p['estado']?.toString().toLowerCase() == 'entregado'
    ).length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '$totalPedidos',
                  Icons.receipt_long,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Activos',
                  '$pedidosActivos',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Entregados',
                  '$pedidosEntregados',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget helper para tarjetas de estadísticas
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de contenido principal
  Widget _buildContentSection() {
    if (_isLoading) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando historial...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        child: Center(
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
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarPedidos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).get('reintentar'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pedidos.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).get('sin_pedidos'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).get('realizar_primer_pedido'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _pedidos.map((pedido) {
        final productos = List<Map<String, dynamic>>.from(
          pedido['productos'] ?? [],
        );
        final total = productos.fold<double>(0, (sum, producto) {
          final precio = _calcularPrecioTotal(
            producto['precio'],
            int.tryParse(producto['cantidad']?.toString() ?? '1') ?? 1,
          );
          return sum + precio;
        });

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[200]!,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estado y folio
                Row(
                  children: [
                    // Indicador de estado
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
                            _traducirEstado(
                              pedido['estado']?.toString() ?? 'pendiente',
                            ).toUpperCase(),
                            style: GoogleFonts.poppins(
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
                    const Spacer(),
                    // Folio y fecha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Folio: ${_obtenerFolio(pedido['id']?.toString())}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          _formatearFecha(
                            pedido['created_at']?.toString() ?? '',
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Productos
                Text(
                  '${AppLocalizations.of(context).get('productos')}:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...productos.take(3).map((producto) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '• ${producto['nombre']?.toString() ?? 'Sin nombre'}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        'x${producto['cantidad']?.toString() ?? '1'}',
                        style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),

                // Total y botón de detalles
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).get('total')}: \$${total.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[600],
                            ),
                          ),
                          if (pedido['direccion_entrega'] != null)
                            SizedBox(
                              width: 200,
                              child: Text(
                                '📍 ${pedido['direccion_entrega']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _mostrarDetallesPedido(pedido),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Detalles',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Mostrar detalles completos del pedido
  void _mostrarDetallesPedido(Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).get('detalles_pedido'),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Folio: ${_obtenerFolio(pedido['id']?.toString())}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              _traducirEstado(
                                pedido['estado']?.toString() ?? 'pendiente',
                              ).toUpperCase(),
                              style: GoogleFonts.poppins(
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
                        '${AppLocalizations.of(context).get('fecha')}: ${_formatearFecha(pedido['created_at']?.toString() ?? '')}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Productos
                      Text(
                        'Productos:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List<Map<String, dynamic>>.from(pedido['productos'] ?? []).map(
                        (producto) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${producto['nombre']?.toString() ?? AppLocalizations.of(context).get('sin_nombre')}',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                              Text(
                                'x${producto['cantidad']?.toString() ?? '1'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '\$${_formatearPrecio(producto['precio'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${List<Map<String, dynamic>>.from(pedido['productos'] ?? []).fold<double>(0, (sum, producto) {
                              final precio = _calcularPrecioTotal(
                                producto['precio'],
                                int.tryParse(producto['cantidad']?.toString() ?? '1') ?? 1,
                              );
                              return sum + precio;
                            }).toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Ubicación
                      if (pedido['direccion_entrega'] != null) ...[
                        Text(
                          '${AppLocalizations.of(context).get('ubicacion_entrega')}:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '📍 ${pedido['direccion_entrega']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Referencias
                      if (pedido['referencias'] != null &&
                          pedido['referencias'].toString().isNotEmpty) ...[
                        Text(
                          '${AppLocalizations.of(context).get('referencias')}:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.note, color: Colors.orange[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '📝 ${pedido['referencias']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40), // Espacio para el scroll
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
