import 'package:flutter/material.dart';
import 'pedidos_screen.dart';
import 'menu_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import '../providers/notificaciones_pedidos_provider.dart'; // Importa el provider de notificaciones
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'asignar_repartidores_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences
import '../../cliente/screens/login_screen.dart'; // Importa el login del cliente
import '../../../shared/widgets/custom_alert.dart';
import '../../../services/puntos_service.dart';

/// dashboard_screen.dart - Pantalla principal (dashboard) para el dueño
/// Muestra un menú con las opciones principales para la gestión del restaurante.
class DuenioDashboardScreen extends StatefulWidget {
  const DuenioDashboardScreen({super.key});

  @override
  State<DuenioDashboardScreen> createState() => _DuenioDashboardScreenState();
}

class _DuenioDashboardScreenState extends State<DuenioDashboardScreen> {
  StreamSubscription? _pedidoSub;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  Set<String> _notificados = {}; // Para evitar notificar el mismo pedido varias veces
  String? _negocioNombre;
  String? _negocioImgUrl;
  bool _cargandoNegocio = true;
  bool _cargandoDatos = true; // Nuevo flag
  String? _ultimoRestauranteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restaurarUserIdYEmail();
      await _restaurarRestauranteId();
      setState(() {
        _cargandoDatos = false;
      });
    });
    _initNotifications();
    _configurarNotificaciones();
    WidgetsBinding.instance.addPostFrameCallback((_) => _escucharPedidosNuevos());
  }

  Future<void> _initNotifications() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  Future<void> _notificarNuevoPedido() async {
    await _localNotifications.show(
      0,
      '¡Nuevo pedido recibido!',
      'Tienes un nuevo pedido pendiente.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pedidos_channel',
          'Pedidos',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true, // Sonido nativo
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
    );
  }

  void _escucharPedidosNuevos() {
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    
    // Por ahora, usar una implementación simple sin streams
    // TODO: Implementar Supabase Realtime cuando esté disponible
    print('🔔 Escuchando pedidos nuevos para restaurante: $restauranteId');
  }

  void _configurarNotificaciones() {
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    
    // Configurar notificaciones para el restaurante específico
    context.read<NotificacionesPedidosProvider>().configurarRestaurante(restauranteId, context);
  }

  // Cargar datos del negocio del dueño desde Supabase
  Future<void> _cargarDatosNegocio() async {
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    final data = await Supabase.instance.client
        .from('negocios')
        .select()
        .eq('id', restauranteId)
        .maybeSingle();
    setState(() {
      _negocioNombre = data?['nombre']?.toString() ?? 'Mi Negocio';
      _negocioImgUrl = data?['img']?.toString();
      _cargandoNegocio = false;
    });
  }

  // Permite seleccionar y subir una nueva foto del negocio
  Future<void> _editarFotoNegocio() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    final file = File(picked.path);
    final fileName = 'negocio_$restauranteId.jpg';
    // Subir a Supabase Storage (bucket: images)
    final storage = Supabase.instance.client.storage.from('images');
    await storage.upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    final publicUrl = storage.getPublicUrl(fileName);
    // Actualizar la URL en la base de datos
    await Supabase.instance.client.from('negocios').update({'img': publicUrl}).eq('id', restauranteId);
    setState(() {
      _negocioImgUrl = publicUrl;
    });
    showSuccessAlert(context, 'Foto actualizada');
  }

  // Obtiene métricas y datos de Supabase para el dashboard
  Future<int> contarUsuarios() async {
    final data = await Supabase.instance.client.from('usuarios').select();
    return data.length;
  }
  Future<int> contarNegocios() async {
    final data = await Supabase.instance.client.from('negocios').select();
    return data.length;
  }
  Future<int> contarPedidos() async {
    final data = await Supabase.instance.client.from('pedidos').select();
    return data.length;
  }

  // Agrega un negocio demo usando Supabase
  Future<void> agregarNegocioDemo(Map<String, dynamic> negocio) async {
    await Supabase.instance.client.from('negocios').insert(negocio);
  }
  // Agrega un usuario demo usando Supabase
  Future<void> agregarUsuarioDemo(Map<String, dynamic> usuario) async {
    await Supabase.instance.client.from('usuarios').insert(usuario);
  }

  // Cargar notificaciones locales del dueño desde Supabase
  Future<List<Map<String, dynamic>>> _cargarNotificacionesDuenio() async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) return [];
      final data = await Supabase.instance.client
        .from('notificaciones')
        .select()
        .eq('usuario_id', userId)
        .order('fecha', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error cargando notificaciones: $e');
      return [];
    }
  }

  // Marcar notificación como leída
  Future<void> _marcarNotificacionComoLeida(String notificacionId) async {
    try {
      await Supabase.instance.client
        .from('notificaciones')
        .update({'leida': true})
        .eq('id', notificacionId);
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  // Formatea la fecha para mostrarla de forma amigable
  String _formatearFecha(dynamic fecha) {
    try {
      final date = DateTime.parse(fecha.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' ;
    } catch (e) {
      return fecha.toString();
    }
  }

  // Cargar repartidores disponibles (usuarios con rol repartidor que no estén ya asignados a este restaurante)
  Future<List<Map<String, dynamic>>> _cargarRepartidoresDisponibles() async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final negocioId = userProvider.restauranteId;
      if (negocioId == null) return [];
      // Obtener todos los repartidores
      final repartidores = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('rol', 'repartidor');
      // Obtener los ya asignados a este restaurante
      final asignados = await Supabase.instance.client
        .from('negocios_repartidores')
        .select('repartidor_id')
        .eq('negocio_id', negocioId);
      final idsAsignados = asignados.map((a) => a['repartidor_id']).toSet();
      // Filtrar los que no están asignados
      return List<Map<String, dynamic>>.from(repartidores).where((r) => !idsAsignados.contains(r['id'])).toList();
    } catch (e) {
      return [];
    }
  }

  // Asignar repartidor al restaurante (insertar en negocios_repartidores)
  Future<void> _asignarRepartidorAlRestaurante(dynamic repartidorId) async {
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final negocioId = userProvider.restauranteId;
    if (negocioId == null) return;
    await Supabase.instance.client.from('negocios_repartidores').insert({
      'negocio_id': negocioId,
      'repartidor_id': repartidorId,
      'asociado_en': DateTime.now().toIso8601String(),
      'estado': 'activo',
    });
  }

  Future<void> _restaurarRestauranteId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    print('DEBUG: _restaurarRestauranteId userId: $userId');
    if (userId != null) {
      final userData = await Supabase.instance.client
          .from('usuarios')
          .select('restaurante_id')
          .eq('id', userId)
          .maybeSingle();
      print('DEBUG: _restaurarRestauranteId userData: $userData');
      if (userData != null && userData['restaurante_id'] != null) {
        if (mounted) {
          Provider.of<CarritoProvider>(context, listen: false)
              .setRestauranteId(userData['restaurante_id'] as String);
          print('DEBUG: restauranteId restaurado: ${userData['restaurante_id']}');
        }
      }
    }
  }

  Future<void> _restaurarUserIdYEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userEmail = prefs.getString('userEmail');
    if (userId != null && userId.isNotEmpty) {
      Provider.of<CarritoProvider>(context, listen: false).setUserId(userId);
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      Provider.of<CarritoProvider>(context, listen: false).setUserEmail(userEmail);
    }
  }

  // Mostrar diálogo con información de puntos del dueño
  Future<void> _mostrarDialogoPuntos() async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final userId = userProvider.userId;
      
      if (userId == null) {
        showErrorAlert(context, 'No se pudo identificar al usuario');
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener datos de puntos
      final puntosData = await PuntosService.obtenerPuntosDueno(userId);
      
      // Cerrar loading
      Navigator.pop(context);

      if (puntosData == null) {
        showErrorAlert(context, 'No se encontraron datos de puntos para este usuario');
        return;
      }

      // Mostrar diálogo con información de puntos
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Mis Puntos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPuntoInfo('Puntos Disponibles', '${puntosData['puntos_disponibles'] ?? 0}', Colors.green),
              const SizedBox(height: 12),
              _buildPuntoInfo('Total Asignado', '${puntosData['total_asignado'] ?? 0}', Colors.blue),
              const SizedBox(height: 12),
              _buildPuntoInfo('Puntos por Pedido', '${puntosData['puntos_por_pedido'] ?? 2}', Colors.orange),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Negocio',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (puntosData['puntos_disponibles'] ?? 0) > 0 
                          ? '✅ Activo - Puedes recibir pedidos'
                          : '❌ Inactivo - Sin puntos disponibles',
                      style: TextStyle(
                        color: (puntosData['puntos_disponibles'] ?? 0) > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar loading si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showErrorAlert(context, 'Error al cargar información de puntos: $e');
    }
  }

  // Widget helper para mostrar información de puntos
  Widget _buildPuntoInfo(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pedidoSub?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _cargarDatosNegocioReactivo(String? restauranteId) async {
    print('DEBUG: _cargarDatosNegocioReactivo restauranteId: $restauranteId');
    if (restauranteId == null || restauranteId.isEmpty) return null;
    final data = await Supabase.instance.client
        .from('negocios')
        .select()
        .eq('id', restauranteId)
        .maybeSingle();
    print('DEBUG: _cargarDatosNegocioReactivo negocio data: $data');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) {
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
          _mostrarDialogoPuntos();
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
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
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- Sección de información del negocio ---
          // --- Foto y nombre del negocio ---
          FutureBuilder<Map<String, dynamic>?>(
            future: _cargarDatosNegocioReactivo(restauranteId),
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
                    onTap: _editarFotoNegocio,
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