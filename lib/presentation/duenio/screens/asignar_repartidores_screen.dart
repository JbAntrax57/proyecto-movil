import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/repartidores_provider.dart';

/// asignar_repartidores_screen.dart - Vista para que el dueño asigne repartidores a su restaurante
/// Rediseñada con patrón moderno de diseño
class AsignarRepartidoresScreen extends StatefulWidget {
  const AsignarRepartidoresScreen({super.key});

  @override
  State<AsignarRepartidoresScreen> createState() =>
      _AsignarRepartidoresScreenState();
}

class _AsignarRepartidoresScreenState extends State<AsignarRepartidoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<RepartidoresProvider>().inicializarRepartidores(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RepartidoresProvider>(
      builder: (context, repartidoresProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // AppBar moderno
                  _buildAppBar(),
                  
                  // Sección de búsqueda
                  SliverToBoxAdapter(
                    child: _buildSearchSection(repartidoresProvider),
                  ),
                  
                  // Sección de asignación por teléfono
                  SliverToBoxAdapter(
                    child: _buildPhoneAssignmentSection(repartidoresProvider),
                  ),
                  
                  // Estadísticas
                  SliverToBoxAdapter(
                    child: _buildStatsSection(repartidoresProvider),
                  ),
                  
                  // Contenido principal
                  SliverToBoxAdapter(
                    child: _buildContentSection(repartidoresProvider),
                  ),
                ],
              ),
              
              // Panel de notificaciones
              if (repartidoresProvider.mostrarNotificaciones)
                _buildNotificationsPanel(repartidoresProvider),
            ],
          ),
          
          // Botón flotante para notificaciones
          floatingActionButton: _buildFloatingActionButton(repartidoresProvider),
        );
      },
    );
  }

  // AppBar moderno
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
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
                Colors.orange[600]!,
                Colors.orange[400]!,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Asignar Repartidores',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Gestiona tu equipo de entrega',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sección de búsqueda
  Widget _buildSearchSection(RepartidoresProvider repartidoresProvider) {
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
          Row(
            children: [
              Icon(Icons.search, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Buscar Repartidor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, teléfono o email...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              repartidoresProvider.setSearchText(value);
            },
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Sección de asignación por teléfono
  Widget _buildPhoneAssignmentSection(RepartidoresProvider repartidoresProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          Row(
            children: [
              Icon(Icons.phone, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Asignar por Teléfono',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: repartidoresProvider.telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Teléfono del repartidor',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: repartidoresProvider.isLoading 
                    ? null 
                    : () => repartidoresProvider.asignarPorTelefono(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Asignar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sección de estadísticas
  Widget _buildStatsSection(RepartidoresProvider repartidoresProvider) {
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
                  '${repartidoresProvider.getRepartidoresFiltrados().length}',
                  Icons.people,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Solicitudes',
                  '${repartidoresProvider.contarNotificacionesNoLeidas}',
                  Icons.notifications,
                  Colors.orange,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de contenido principal
  Widget _buildContentSection(RepartidoresProvider repartidoresProvider) {
    if (repartidoresProvider.isLoading) {
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
                'Cargando repartidores...',
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

    if (repartidoresProvider.error != null) {
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
                'Error al cargar repartidores',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                repartidoresProvider.error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => repartidoresProvider.cargarRepartidoresDisponibles(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reintentar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (repartidoresProvider.getRepartidoresFiltrados().isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delivery_dining,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay repartidores disponibles',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Todos los repartidores ya están asignados o no hay ninguno registrado.',
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

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repartidores Disponibles',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...repartidoresProvider.getRepartidoresFiltrados().map((repartidor) => 
            _buildRepartidorCard(repartidor, repartidoresProvider)
          ),
        ],
      ),
    );
  }

  // Widget helper para tarjetas de repartidor
  Widget _buildRepartidorCard(Map<String, dynamic> repartidor, RepartidoresProvider repartidoresProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            // Avatar del repartidor
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delivery_dining,
                color: Colors.orange[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Información del repartidor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repartidor['nombre'] ?? repartidor['email'] ?? 'Repartidor',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        repartidor['telephone'] ?? 'Sin teléfono',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (repartidor['direccion'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            repartidor['direccion'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Botón de asignar
            ElevatedButton(
              onPressed: repartidoresProvider.isLoading
                  ? null
                  : () async {
                      await repartidoresProvider.asignarRepartidorAlRestaurante(
                        context,
                        repartidor['id'],
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Repartidor asignado correctamente',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Asignar',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón flotante para notificaciones
  Widget _buildFloatingActionButton(RepartidoresProvider repartidoresProvider) {
    return FloatingActionButton.extended(
      onPressed: () {
        repartidoresProvider.toggleMostrarNotificaciones();
      },
      backgroundColor: repartidoresProvider.contarNotificacionesNoLeidas > 0
          ? Colors.red[600]
          : Colors.orange[600],
      icon: Stack(
        children: [
          Icon(Icons.notifications, color: Colors.white),
          if (repartidoresProvider.contarNotificacionesNoLeidas > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '${repartidoresProvider.contarNotificacionesNoLeidas}',
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
      label: Text(
        repartidoresProvider.contarNotificacionesNoLeidas > 0
            ? 'Solicitudes'
            : 'Notificaciones',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Panel de notificaciones
  Widget _buildNotificationsPanel(RepartidoresProvider repartidoresProvider) {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solicitudes de Repartidores',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () {
                      repartidoresProvider.ocultarNotificaciones();
                    },
                  ),
                ],
              ),
            ),
            
            // Lista de notificaciones
            Flexible(
              child: repartidoresProvider.notificacionesRepartidor.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay solicitudes',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Los repartidores aparecerán aquí cuando soliciten unirse',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: repartidoresProvider.notificacionesRepartidor.length,
                      itemBuilder: (context, index) {
                        final notif = repartidoresProvider.notificacionesRepartidor[index];
                        final esNoLeida = notif['leida'] != true;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: esNoLeida
                                ? Colors.orange[50]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: esNoLeida
                                  ? Colors.orange[200]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: esNoLeida
                                    ? Colors.orange[100]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.delivery_dining,
                                color: esNoLeida
                                    ? Colors.orange[600]
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notif['mensaje'] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: esNoLeida
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: esNoLeida
                                    ? Colors.orange[800]
                                    : Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              repartidoresProvider.formatearFecha(notif['fecha']),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            trailing: esNoLeida
                                ? IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green[600],
                                    ),
                                    onPressed: () async {
                                      await repartidoresProvider.marcarNotificacionComoLeida(
                                        context,
                                        notif['id'].toString(),
                                      );
                                    },
                                    tooltip: 'Marcar como leída',
                                  )
                                : null,
                            onTap: () {
                              repartidoresProvider.mostrarDetallesCliente(context, notif);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
