import 'package:flutter/material.dart';
import 'pedidos_screen.dart';
import 'menu_screen.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/notificaciones_pedidos_provider.dart';
import 'asignar_repartidores_screen.dart';
import '../../cliente/screens/login_screen.dart';

/// dashboard_screen.dart - Pantalla principal (dashboard) para el dueño
/// Muestra un menú con las opciones principales para la gestión del restaurante.
class DuenioDashboardScreen extends StatefulWidget {
  const DuenioDashboardScreen({super.key});

  @override
  State<DuenioDashboardScreen> createState() => _DuenioDashboardScreenState();
}

class _DuenioDashboardScreenState extends State<DuenioDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<DashboardProvider>().inicializarDashboard(context);
    });
    _configurarNotificaciones();
  }



  void _configurarNotificaciones() {
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    
    // Configurar notificaciones para el restaurante específico
    context.read<NotificacionesPedidosProvider>().configurarRestaurante(restauranteId, context);
  }





  



  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.cargandoDatos) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final restauranteId = Provider.of<CarritoProvider>(context).restauranteId;
        final List<_MenuOption> opciones = [
          _MenuOption(
            icon: Icons.receipt_long,
            title: 'Pedidos',
            subtitle: 'Ver y gestionar pedidos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuenioPedidosScreen()),
              );
            },
          ),
          _MenuOption(
            icon: Icons.restaurant_menu,
            title: 'Menú',
            subtitle: 'Gestionar productos y categorías',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DuenioMenuScreen()),
              );
            },
          ),
          _MenuOption(
            icon: Icons.bar_chart,
            title: 'Estadísticas',
            subtitle: 'Ver ventas y métricas',
            onTap: () {
              // Navegar a la pantalla de estadísticas
              // Navigator.pushNamed(context, '/duenio/estadisticas');
            },
          ),
          _MenuOption(
            icon: Icons.stars,
            title: 'Mis Puntos',
            subtitle: 'Ver puntos disponibles y estado',
            onTap: () {
              dashboardProvider.mostrarDialogoPuntos(context);
            },
          ),
          // Puedes agregar más opciones aquí
        ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dueño'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await dashboardProvider.cerrarSesion(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ClienteLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- Sección de información del negocio ---
          // --- Foto y nombre del negocio ---
          FutureBuilder<Map<String, dynamic>?>(
            future: dashboardProvider.cargarDatosNegocioReactivo(restauranteId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data;
              final nombre = data?['nombre']?.toString() ?? 'Mi Negocio';
              final imgUrl = data?['img']?.toString();
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => dashboardProvider.editarFotoNegocio(context),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: imgUrl != null && imgUrl.isNotEmpty
                              ? NetworkImage(imgUrl)
                              : null,
                          child: imgUrl == null || imgUrl.isEmpty
                              ? const Icon(Icons.store, size: 48, color: Colors.blueGrey)
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // --- Botón para ir a la vista de asignar repartidores ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delivery_dining, color: Colors.white),
                      label: const Text(
                        'Asignar repartidores',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AsignarRepartidoresScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
          // --- Menú de opciones ---
          ...List.generate(opciones.length, (index) {
            final opcion = opciones[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(opcion.icon, size: 36, color: Colors.blueAccent),
                  title: Text(opcion.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(opcion.subtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: opcion.onTap,
                ),
              ),
            );
          }),
        ],
      ),
    );
      },
    );
  }
}

/// Clase interna para definir las opciones del menú
class _MenuOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
} 