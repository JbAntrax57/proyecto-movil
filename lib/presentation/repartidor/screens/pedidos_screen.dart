import 'package:flutter/material.dart';
import 'notificaciones_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../cliente/screens/login_screen.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../providers/pedidos_repartidor_provider.dart';
import '../../../core/localization.dart';

// pedidos_screen.dart - Pantalla de pedidos asignados para el repartidor
// Rediseñada con patrón moderno de diseño
class RepartidorPedidosScreen extends StatefulWidget {
  const RepartidorPedidosScreen({super.key});
  @override
  State<RepartidorPedidosScreen> createState() => _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PedidosRepartidorProvider>().inicializarPedidos(context);
    });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidosRepartidorProvider>(
      builder: (context, pedidosProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              // AppBar moderno
              _buildAppBar(pedidosProvider),
              
              // Sección de notificaciones
              if (pedidosProvider.notificaciones.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildNotificationsSection(pedidosProvider),
                ),
              
              // Sección de estadísticas
              SliverToBoxAdapter(
                child: _buildStatsSection(pedidosProvider),
              ),
              
              // Sección de filtros
              SliverToBoxAdapter(
                child: _buildFiltersSection(pedidosProvider),
              ),
              
              // Contenido principal
              SliverToBoxAdapter(
                child: _buildContentSection(pedidosProvider),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(pedidosProvider),
        );
      },
    );
  }

  // AppBar moderno
  Widget _buildAppBar(PedidosRepartidorProvider pedidosProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => pedidosProvider.cargarAmbasListas(context),
          icon: Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Actualizar',
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RepartidorNotificacionesScreen(),
              ),
            );
          },
          icon: Icon(Icons.notifications, color: Colors.white),
          tooltip: 'Ver notificaciones',
        ),
        IconButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('isLoggedIn');
            await prefs.remove('userRol');
            await prefs.remove('userId');
            if (context.mounted) {
              Provider.of<CarritoProvider>(context, listen: false).setUserEmail('');
              Provider.of<CarritoProvider>(context, listen: false).setUserId('');
              Provider.of<CarritoProvider>(context, listen: false).setRestauranteId(null);
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ClienteLoginScreen()),
              (route) => false,
            );
          },
          icon: Icon(Icons.logout, color: Colors.white),
          tooltip: 'Cerrar sesión',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange[600]!,
                Colors.orange[700]!,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pedidosProvider.selectedIndex == 0 
                            ? 'Pedidos Disponibles' 
                            : 'Mis Pedidos',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          pedidosProvider.selectedIndex == 0 
                            ? 'Toma pedidos para entregar' 
                            : 'Gestiona tus entregas',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sección de notificaciones
  Widget _buildNotificationsSection(PedidosRepartidorProvider pedidosProvider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Notificaciones',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pedidosProvider.notificaciones.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '🔔 $n',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
          )),
        ],
      ),
    );
  }

  // Sección de estadísticas
  Widget _buildStatsSection(PedidosRepartidorProvider pedidosProvider) {
    final pedidosDisponibles = pedidosProvider.pedidosDisponibles.length;
    final misPedidos = pedidosProvider.misPedidos.length;
    final pedidosEnCamino = pedidosProvider.misPedidos
        .where((p) => p['estado']?.toString().toLowerCase() == 'en camino')
        .length;

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
                  'Disponibles',
                  '$pedidosDisponibles',
                  Icons.assignment_turned_in,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Mis Pedidos',
                  '$misPedidos',
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En Camino',
                  '$pedidosEnCamino',
                  Icons.delivery_dining,
                  Colors.purple,
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

  // Sección de filtros
  Widget _buildFiltersSection(PedidosRepartidorProvider pedidosProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Disponibles',
              pedidosProvider.selectedIndex == 0,
              Icons.assignment_turned_in,
              Colors.orange,
              () => pedidosProvider.setSelectedIndex(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterChip(
              'Mis Pedidos',
              pedidosProvider.selectedIndex == 1,
              Icons.list_alt,
              Colors.blue,
              () => pedidosProvider.setSelectedIndex(1),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para chips de filtro
  Widget _buildFilterChip(String title, bool isSelected, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sección de contenido principal
  Widget _buildContentSection(PedidosRepartidorProvider pedidosProvider) {
    if (pedidosProvider.isLoading) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
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
        ),
      );
    }

    final pedidos = pedidosProvider.selectedIndex == 0 
        ? pedidosProvider.pedidosDisponibles 
        : pedidosProvider.misPedidos;
    final mostrarTomar = pedidosProvider.selectedIndex == 0;

    if (pedidos.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mostrarTomar ? Icons.assignment_turned_in : Icons.list_alt,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                mostrarTomar ? 'No hay pedidos disponibles' : 'No tienes pedidos asignados',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mostrarTomar ? 'Los pedidos aparecerán aquí cuando estén listos' : 'Los pedidos que tomes aparecerán aquí',
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

    final pedidosOrdenados = pedidosProvider.getPedidosOrdenados(pedidos);

    return Column(
      children: pedidosOrdenados.map((pedido) {
        final productos = List<Map<String, dynamic>>.from(
          pedido['productos'] ?? [],
        );
        final total = pedidosProvider.calcularTotalPedido(productos);

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
                // Header con estado y fecha
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
                    // Fecha
                    Text(
                      _formatearFecha(pedido['created_at']?.toString() ?? ''),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información del cliente
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cliente: ${pedido['cliente_nombre'] ?? 'Sin nombre'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Dirección de entrega
                if (pedido['direccion_entrega'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
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
                  const SizedBox(height: 12),
                ],

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

                // Total y botones de acción
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
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mostrarTomar)
                      ElevatedButton(
                        onPressed: () => pedidosProvider.tomarPedido(context, pedido),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
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
                            Icon(Icons.delivery_dining, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Tomar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _mostrarOpcionesPedido(pedido, pedidosProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
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
                            Icon(Icons.more_vert, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Opciones',
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

  // Bottom Navigation Bar moderno
  Widget _buildBottomNavigationBar(PedidosRepartidorProvider pedidosProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: pedidosProvider.selectedIndex,
        onTap: (index) => pedidosProvider.setSelectedIndex(index),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange[600],
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assignment_turned_in),
                if (pedidosProvider.pedidosDisponibles.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        pedidosProvider.pedidosDisponibles.length.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Disponibles',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis pedidos',
          ),
        ],
      ),
    );
  }

  // Mostrar opciones del pedido
  void _mostrarOpcionesPedido(Map<String, dynamic> pedido, PedidosRepartidorProvider pedidosProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.6,
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delivery_dining,
                        color: Colors.orange[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opciones del Pedido',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Gestiona la entrega',
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
              
              // Opciones
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildOptionTile(
                      'Ver detalles',
                      Icons.info_outline,
                      Colors.blue,
                      () {
                        Navigator.pop(context);
                        // Implementar ver detalles
                      },
                    ),
                    _buildOptionTile(
                      'Actualizar estado',
                      Icons.update,
                      Colors.orange,
                      () {
                        Navigator.pop(context);
                        // Implementar actualizar estado
                      },
                    ),
                    _buildOptionTile(
                      'Ver mapa',
                      Icons.map,
                      Colors.green,
                      () {
                        Navigator.pop(context);
                        // Implementar ver mapa
                      },
                    ),
                    _buildOptionTile(
                      'Marcar como entregado',
                      Icons.check_circle,
                      Colors.green,
                      () {
                        Navigator.pop(context);
                        pedidosProvider.marcarEntregado(context, pedido);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper para opciones del modal
  Widget _buildOptionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
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
} 