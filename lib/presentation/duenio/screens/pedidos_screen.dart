// pedidos_screen.dart - Pantalla de pedidos recibidos para el dueño de negocio
// Rediseñada con el mismo estilo visual moderno que el dashboard
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedidos_duenio_provider.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../core/localization.dart';
import 'package:google_fonts/google_fonts.dart';

class DuenioPedidosScreen extends StatefulWidget {
  const DuenioPedidosScreen({super.key});
  @override
  State<DuenioPedidosScreen> createState() => _DuenioPedidosScreenState();
}

class _DuenioPedidosScreenState extends State<DuenioPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PedidosDuenioProvider>().inicializarPedidos(context);
    });
  }

  // Helper para obtener folio del pedido
  String _obtenerFolio(String? pedidoId) {
    if (pedidoId == null || pedidoId.isEmpty) return 'N/A';
    return pedidoId.length >= 8 ? pedidoId.substring(0, 8) : pedidoId;
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
  Widget build(BuildContext context) {
    return Consumer<PedidosDuenioProvider>(
      builder: (context, pedidosProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(pedidosProvider),
          body: pedidosProvider.isLoading
              ? _buildLoadingState()
              : pedidosProvider.error != null
                  ? _buildErrorState(pedidosProvider)
                  : pedidosProvider.pedidos.isEmpty
                      ? _buildEmptyState()
                      : _buildPedidosContent(pedidosProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(PedidosDuenioProvider pedidosProvider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        'Pedidos',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.grey[700]),
          onPressed: () => pedidosProvider.cargarPedidos(context),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando pedidos...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PedidosDuenioProvider pedidosProvider) {
    return Center(
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
            pedidosProvider.error!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => pedidosProvider.cargarPedidos(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
                            child: Text(AppLocalizations.of(context).get('reintentar')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay pedidos aún',
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando recibas pedidos aparecerán aquí',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosContent(PedidosDuenioProvider pedidosProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await pedidosProvider.cargarPedidos(context);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildStatsSection(pedidosProvider),
            _buildFiltersSection(pedidosProvider),
            _buildPedidosList(pedidosProvider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(PedidosDuenioProvider pedidosProvider) {
    final pedidos = pedidosProvider.pedidos;
    final totalPedidos = pedidos.length;
    final pedidosPendientes = pedidos.where((p) => p['estado'] == 'pendiente').length;
    final pedidosPreparando = pedidos.where((p) => p['estado'] == 'preparando').length;
    final pedidosEnCamino = pedidos.where((p) => p['estado'] == 'en camino').length;
    final pedidosEntregados = pedidos.where((p) => p['estado'] == 'entregado').length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de pedidos',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.receipt_long,
                  title: 'Total',
                  value: '$totalPedidos',
                  color: Colors.blue,
                  subtitle: 'Pedidos recibidos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  title: 'Pendientes',
                  value: '$pedidosPendientes',
                  color: Colors.orange,
                  subtitle: 'Por procesar',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.restaurant,
                  title: 'Preparando',
                  value: '$pedidosPreparando',
                  color: Colors.purple,
                  subtitle: 'En cocina',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.delivery_dining,
                  title: 'En camino',
                  value: '$pedidosEnCamino',
                  color: Colors.green,
                  subtitle: 'En entrega',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(PedidosDuenioProvider pedidosProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar por estado',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pedidosProvider.getEstados(context).map((estado) {
                final selected = pedidosProvider.filtroEstado == estado['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      estado['label'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : estado['color'] as Color,
                      ),
                    ),
                    selected: selected,
                    selectedColor: estado['color'] as Color,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: selected ? Colors.transparent : (estado['color'] as Color),
                    ),
                    onSelected: (_) {
                      pedidosProvider.setFiltroEstado(
                        selected ? null : estado['label'] as String,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosList(PedidosDuenioProvider pedidosProvider) {
    final pedidosOrdenados = pedidosProvider.getPedidosOrdenados();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pedidos (${pedidosOrdenados.length})',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...pedidosOrdenados.map((pedido) => _buildPedidoCard(pedido, pedidosProvider)),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Map<String, dynamic> pedido, PedidosDuenioProvider pedidosProvider) {
    final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
    final total = pedidosProvider.calcularTotalPedido(pedido);
    final estado = pedido['estado']?.toString() ?? 'pendiente';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado y folio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: pedidosProvider.getEstadoColor(estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: pedidosProvider.getEstadoColor(estado),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pedidosProvider.getEstadoIcon(estado),
                        size: 16,
                        color: pedidosProvider.getEstadoColor(estado),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _traducirEstado(estado).toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pedidosProvider.getEstadoColor(estado),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      pedidosProvider.formatearFecha(pedido['created_at']?.toString() ?? ''),
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
              'Productos:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
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

            // Total y ubicación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue[600],
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
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.grey[600]),
                  onPressed: () {
                    pedidosProvider.mostrarDetallesPedido(context, pedido);
                  },
                  tooltip: 'Ver detalles',
                ),
              ],
            ),

            // Botón para cambiar estado
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(
                  'Cambiar estado',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final nuevoEstado = await pedidosProvider.mostrarModalCambiarEstado(
                    context,
                    estado,
                  );
                  if (nuevoEstado != null && nuevoEstado != estado && context.mounted) {
                    try {
                      await pedidosProvider.actualizarEstadoPedido(
                        pedido['id'].toString(),
                        nuevoEstado,
                        context,
                      );
                      if (context.mounted) {
                        showTopInfoMessage(
                          context,
                          'Estado actualizado a $nuevoEstado',
                          icon: Icons.check_circle,
                          backgroundColor: Colors.green[50],
                          textColor: Colors.green[700],
                          iconColor: Colors.green[700],
                          showDuration: const Duration(seconds: 2),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showTopInfoMessage(
                          context,
                          'Error al actualizar estado: $e',
                          icon: Icons.error,
                          backgroundColor: Colors.red[50],
                          textColor: Colors.red[700],
                          iconColor: Colors.red[700],
                          showDuration: const Duration(seconds: 2),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
