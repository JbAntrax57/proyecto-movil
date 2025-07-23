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

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _configurarNotificaciones();
    WidgetsBinding.instance.addPostFrameCallback((_) => _escucharPedidosNuevos());
    _cargarDatosNegocio(); // Cargar datos del negocio al iniciar
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
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

  @override
  void dispose() {
    _pedidoSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lista de opciones del menú del dueño
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
      // Puedes agregar más opciones aquí
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Dueño'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- Foto y nombre del negocio ---
          if (_cargandoNegocio)
            const Center(child: CircularProgressIndicator()),
          if (!_cargandoNegocio)
            Column(
              children: [
                GestureDetector(
                  onTap: _editarFotoNegocio,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.blue[50],
                        backgroundImage: _negocioImgUrl != null && _negocioImgUrl!.isNotEmpty
                            ? NetworkImage(_negocioImgUrl!)
                            : null,
                        child: _negocioImgUrl == null || _negocioImgUrl!.isEmpty
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
                  _negocioNombre ?? 'Mi Negocio',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
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