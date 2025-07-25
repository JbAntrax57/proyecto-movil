import 'package:flutter/material.dart';
import 'mapa_screen.dart';
import 'actualizar_estado_screen.dart';
import 'notificaciones_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cliente/screens/login_screen.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/utils/pedidos_helper.dart';

// pedidos_screen.dart - Pantalla de pedidos asignados para el repartidor
// Permite ver pedidos asignados, simular nuevos pedidos preparados, navegar al mapa y actualizar estado de entrega.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class RepartidorPedidosScreen extends StatefulWidget {
  // Pantalla de pedidos asignados para el repartidor
  const RepartidorPedidosScreen({super.key});
  @override
  State<RepartidorPedidosScreen> createState() => _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  int _selectedIndex = 0; // 0: disponibles, 1: mis pedidos
  List<Map<String, dynamic>> pedidosDisponibles = [];
  List<Map<String, dynamic>> misPedidos = [];
  bool _isLoading = true;
  final List<String> notificaciones = [];
  RealtimeChannel? _pedidosChannel;
  StreamSubscription? _pedidosSubscription;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int _ultimoTotalPedidosDisponibles = 0;

  @override
  void initState() {
    super.initState();
    _restaurarUserIdYEmail();
    _initNotificacionesLocales();
    _cargarAmbasListas();
    _suscribirseAPedidos();
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

  // Inicializa las notificaciones locales para Android
  Future<void> _initNotificacionesLocales() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Suscribirse a la tabla de pedidos usando stream para recibir cambios en tiempo real
  void _suscribirseAPedidos() {
    _pedidosSubscription = Supabase.instance.client
      .from('pedidos')
      .stream(primaryKey: ['id']) // Asegúrate que 'id' es la PK real
      .listen((data) async {
        print('DEBUG: Stream de pedidos ejecutado. Total registros: \'${data.length}\'');
        // Filtrar solo los pedidos en estado 'listo'
        final pedidosListo = List<Map<String, dynamic>>.from(data)
            .where((p) => p['estado'] == 'listo')
            .toList();
        print('DEBUG: Pedidos en estado listo detectados por stream: \'${pedidosListo.length}\'');

        // Obtener los pedidos ya asignados
        final asignados = await Supabase.instance.client
            .from('pedidos_repartidores')
            .select('pedido_id');
        final idsAsignados = asignados.map((a) => a['pedido_id']).toSet();

        final disponibles = pedidosListo
            .where((p) => !idsAsignados.contains(p['id']))
            .toList();

        // Notificación local si hay nuevos pedidos disponibles
        final totalActual = disponibles.length;
        if (totalActual > _ultimoTotalPedidosDisponibles) {
          await flutterLocalNotificationsPlugin.show(
            0,
            '¡Nuevo pedido disponible!',
            'Hay $totalActual pedidos listos para tomar.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'pedidos_channel',
                'Pedidos',
                channelDescription: 'Notificaciones de nuevos pedidos disponibles',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
        _ultimoTotalPedidosDisponibles = totalActual;

        await _cargarMisPedidos();

        setState(() {
          pedidosDisponibles = disponibles;
        });
      });
  }

  @override
  void dispose() {
    _pedidosSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargarAmbasListas() async {
    setState(() { _isLoading = true; });
    await Future.wait([
      _cargarPedidosDisponibles(),
      _cargarMisPedidos(),
    ]);
    setState(() { _isLoading = false; });
  }

  // Pedidos en estado 'listo' no asignados
  Future<void> _cargarPedidosDisponibles() async {
    try {
      final pedidosListo = await PedidosHelper.obtenerPedidosConDetalles(
        estado: 'listo',
      );
      print('DEBUG: Pedidos en estado listo: ' + pedidosListo.toString());
      final asignados = await Supabase.instance.client
        .from('pedidos_repartidores')
        .select('pedido_id');
      final idsAsignados = asignados.map((a) => a['pedido_id']).toSet();
      print('DEBUG: Pedidos ya asignados: ' + idsAsignados.toString());
      final disponibles = pedidosListo
          .where((p) => !idsAsignados.contains(p['id']))
          .toList();
      print('DEBUG: Pedidos disponibles para tomar: ' + disponibles.toString());
      pedidosDisponibles = disponibles;
    } catch (e) {
      print('DEBUG: Error al cargar pedidos disponibles: $e');
      pedidosDisponibles = [];
    }
  }

  // Pedidos asignados a este repartidor
  Future<void> _cargarMisPedidos() async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final email = userProvider.userEmail;
      if (email == null) {
        misPedidos = [];
        return;
      }
      final repartidor = await Supabase.instance.client
        .from('usuarios')
        .select('id')
        .eq('email', email ?? '')
        .maybeSingle();
      final repartidorId = repartidor?['id'];
      if (repartidorId == null) {
        misPedidos = [];
        return;
      }
      final asignaciones = await Supabase.instance.client
        .from('pedidos_repartidores')
        .select('pedido_id')
        .eq('repartidor_id', repartidorId);
      final pedidoIds = asignaciones.map((a) => a['pedido_id'] as String).toList();
      if (pedidoIds.isEmpty) {
        misPedidos = [];
        return;
      }
      
      // Obtener pedidos con detalles usando el helper
      final pedidosConDetalles = await PedidosHelper.obtenerDetallesMultiplesPedidos(pedidoIds);
      
      // Obtener los pedidos base y combinarlos con detalles
      final pedidosDb = await Supabase.instance.client
        .from('pedidos')
        .select()
        .filter('id', 'in', '(${pedidoIds.join(',')})');
      
      misPedidos = pedidosDb.map((pedido) {
        final pedidoId = pedido['id'] as String;
        final detalles = pedidosConDetalles[pedidoId] ?? [];
        
        return {
          ...pedido,
          'productos': detalles, // Mantener compatibilidad
        };
      }).toList();
    } catch (e) {
      misPedidos = [];
    }
  }

  // Tomar (autoasignar) un pedido
  Future<void> _tomarPedido(Map<String, dynamic> pedido) async {
    setState(() { _isLoading = true; });
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final email = userProvider.userEmail;
    if (email == null) {
      setState(() { _isLoading = false; });
      return;
    }
    final repartidor = await Supabase.instance.client
      .from('usuarios')
      .select('id')
      .eq('email', email ?? '')
      .maybeSingle();
    final repartidorId = repartidor?['id'];
    if (repartidorId == null) {
      setState(() { _isLoading = false; });
      return;
    }
    // Insertar en pedidos_repartidores
    await Supabase.instance.client.from('pedidos_repartidores').insert({
      'pedido_id': pedido['id'],
      'repartidor_id': repartidorId,
      'asignado_en': DateTime.now().toIso8601String(),
      'estado': 'asignado',
    });
    // Cambiar el estado del pedido a 'en camino'
    await Supabase.instance.client
      .from('pedidos')
      .update({'estado': 'en camino'})
      .eq('id', pedido['id']);
    showSuccessAlert(context, '¡Pedido tomado!');
    await _cargarAmbasListas(); // Refresca la lista y el badge
    setState(() { _isLoading = false; });
  }

  // Agregar función auxiliar para obtener el nombre del restaurante:
  Future<String> _obtenerNombreRestaurante(String restauranteId) async {
    try {
      final data = await Supabase.instance.client
          .from('negocios')
          .select('nombre')
          .eq('id', restauranteId)
          .maybeSingle();
      return data != null && data['nombre'] != null ? data['nombre'] as String : 'Restaurante desconocido';
    } catch (e) {
      return 'Restaurante desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Pedidos disponibles' : 'Mis pedidos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              await prefs.remove('userRol');
              await prefs.remove('userId');
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
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Ver notificaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RepartidorNotificacionesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarAmbasListas,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (notificaciones.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.green[50],
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: notificaciones.map((n) => Text('🔔 $n', style: const TextStyle(color: Colors.green))).toList(),
                  ),
                ),
              Expanded(
                child: _selectedIndex == 0
                  ? _buildPedidosList(pedidosDisponibles, true)
                  : _buildPedidosList(misPedidos, false),
              ),
            ],
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assignment_turned_in),
                if (pedidosDisponibles.isNotEmpty)
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
                        pedidosDisponibles.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
      floatingActionButton: null,
    );
  }

  Widget _buildPedidosList(List<Map<String, dynamic>> pedidos, bool mostrarTomar) {
    if (pedidos.isEmpty) {
      return const Center(child: Text('No hay pedidos para mostrar.', style: TextStyle(color: Colors.grey)));
    }
    // Ordenar: primero 'en camino', luego otros, al final 'entregado'
    final pedidosOrdenados = List<Map<String, dynamic>>.from(pedidos);
    pedidosOrdenados.sort((a, b) {
      final estadoA = (a['estado'] ?? '').toString().toLowerCase();
      final estadoB = (b['estado'] ?? '').toString().toLowerCase();
      if (estadoA == 'en camino' && estadoB != 'en camino') return -1;
      if (estadoA != 'en camino' && estadoB == 'en camino') return 1;
      if (estadoA == 'entregado' && estadoB != 'entregado') return 1;
      if (estadoA != 'entregado' && estadoB == 'entregado') return -1;
      return 0;
    });
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pedidosOrdenados.length,
      itemBuilder: (context, index) {
        final pedido = pedidosOrdenados[index];
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pedido['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    Text(
                      pedido['created_at']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                ...productos.take(3).map(
                  (producto) => Padding(
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
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(),
                // Total y ubicación
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                    ),
                    // Mostrar dirección de entrega si existe en cualquier campo común
                    () {
                      final direccion = pedido['direccion_entrega'] ?? pedido['direccion'] ?? pedido['direccionEntrega'];
                      if (direccion != null && direccion.toString().isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  direccion,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }(),
                    // Mostrar referencias si existen (solo en 'Mis pedidos')
                    if (!mostrarTomar) ...[
                      if (pedido['referencias'] != null && pedido['referencias'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  pedido['referencias'],
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    // Botón para marcar como entregado debajo de la dirección en 'Mis pedidos'
                    if (!mostrarTomar && (pedido['estado']?.toString().toLowerCase() == 'en camino'))
                      Padding(
                        padding: const EdgeInsets.only(top: 14.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _marcarEntregado(pedido),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('Marcar como entregado'),
                          ),
                        ),
                      ),
                  ],
                ),
                // Botón para tomar pedido directamente debajo de la dirección
                if (mostrarTomar)
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          await _tomarPedido(pedido);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tomar pedido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Marcar pedido como entregado
  Future<void> _marcarEntregado(Map<String, dynamic> pedido) async {
    setState(() { _isLoading = true; });
    await Supabase.instance.client
      .from('pedidos')
      .update({'estado': 'entregado'})
      .eq('id', pedido['id']);
    showInfoAlert(context, '¡Pedido marcado como entregado!');
    await _cargarAmbasListas(); // Refresca la lista y el badge
    setState(() { _isLoading = false; });
  }
}
// Fin de pedidos_screen.dart (repartidor)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 