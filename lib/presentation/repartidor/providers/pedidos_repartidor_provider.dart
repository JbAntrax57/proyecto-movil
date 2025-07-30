import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../shared/utils/pedidos_helper.dart';
import '../../../core/localization.dart';

class PedidosRepartidorProvider extends ChangeNotifier {
  // Estado de pedidos
  int _selectedIndex = 0; // 0: disponibles, 1: mis pedidos
  List<Map<String, dynamic>> _pedidosDisponibles = [];
  List<Map<String, dynamic>> _misPedidos = [];
  bool _isLoading = true;
  final List<String> _notificaciones = [];
  StreamSubscription? _pedidosSubscription;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int _ultimoTotalPedidosDisponibles = 0;

  // Getters para el estado
  int get selectedIndex => _selectedIndex;
  List<Map<String, dynamic>> get pedidosDisponibles => _pedidosDisponibles;
  List<Map<String, dynamic>> get misPedidos => _misPedidos;
  bool get isLoading => _isLoading;
  List<String> get notificaciones => _notificaciones;
  int get ultimoTotalPedidosDisponibles => _ultimoTotalPedidosDisponibles;

  // Inicializar el provider
  Future<void> inicializarPedidos(BuildContext context) async {
    await _restaurarUserIdYEmail(context);
    await _initNotificacionesLocales();
    await cargarAmbasListas(context);
    suscribirseAPedidos(context);
  }

  // Restaurar userId y email del usuario
  Future<void> _restaurarUserIdYEmail(BuildContext context) async {
    if (!context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userEmail = prefs.getString('userEmail');
    if (userId != null && userId.isNotEmpty) {
      context.read<CarritoProvider>().setUserId(userId);
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      context.read<CarritoProvider>().setUserEmail(userEmail);
    }
  }

  // Inicializa las notificaciones locales para Android
  Future<void> _initNotificacionesLocales() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Suscribirse a la tabla de pedidos usando stream para recibir cambios en tiempo real
  void suscribirseAPedidos(BuildContext context) {
    _pedidosSubscription = Supabase.instance.client
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .listen((data) async {
        if (!context.mounted) return;
        
        // Obtener el ID del repartidor
        final userProvider = context.read<CarritoProvider>();
        final email = userProvider.userEmail;
        if (email == null) return;

        final repartidor = await Supabase.instance.client
          .from('usuarios')
          .select('id')
          .eq('email', email)
          .maybeSingle();
        final repartidorId = repartidor?['id'];
        if (repartidorId == null) return;

        // Obtener los restaurantes donde está asignado el repartidor
        final asignacionesRestaurantes = await Supabase.instance.client
          .from('negocios_repartidores')
          .select('negocio_id')
          .eq('repartidor_id', repartidorId)
          .eq('estado', 'activo');
        
        final restaurantesIds = asignacionesRestaurantes.map((a) => a['negocio_id'] as String).toSet();
        
        if (restaurantesIds.isEmpty) {
          _pedidosDisponibles = [];
          notifyListeners();
          return;
        }

        // Filtrar solo los pedidos en estado 'listo' de restaurantes asignados
        final pedidosListo = List<Map<String, dynamic>>.from(data)
            .where((p) => p['estado'] == 'listo' && restaurantesIds.contains(p['restaurante_id']))
            .toList();

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
          await _flutterLocalNotificationsPlugin.show(
            0,
            AppLocalizations.of(context).get('nuevo_pedido_disponible'),
            AppLocalizations.of(context).get('pedidos_listos_para_tomar').replaceAll('{count}', totalActual.toString()),
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

        if (context.mounted) {
          await cargarMisPedidos(context);
        }

        _pedidosDisponibles = disponibles;
        notifyListeners();
      });
  }

  // Cargar ambas listas de pedidos
  Future<void> cargarAmbasListas(BuildContext context) async {
    _setLoading(true);
    await Future.wait([
      cargarPedidosDisponibles(context),
      cargarMisPedidos(context),
    ]);
    _setLoading(false);
  }

  // Pedidos en estado 'listo' no asignados
  Future<void> cargarPedidosDisponibles(BuildContext context) async {
    try {
      final userProvider = context.read<CarritoProvider>();
      final email = userProvider.userEmail;
      if (email == null) {
        _pedidosDisponibles = [];
        notifyListeners();
        return;
      }

      // Obtener el ID del repartidor
      final repartidor = await Supabase.instance.client
        .from('usuarios')
        .select('id')
        .eq('email', email)
        .maybeSingle();
      final repartidorId = repartidor?['id'];
      if (repartidorId == null) {
        _pedidosDisponibles = [];
        notifyListeners();
        return;
      }

      // Obtener los restaurantes donde está asignado el repartidor
      final asignacionesRestaurantes = await Supabase.instance.client
        .from('negocios_repartidores')
        .select('negocio_id')
        .eq('repartidor_id', repartidorId)
        .eq('estado', 'activo');
      
      final restaurantesIds = asignacionesRestaurantes.map((a) => a['negocio_id'] as String).toList();
      
      if (restaurantesIds.isEmpty) {
        _pedidosDisponibles = [];
        notifyListeners();
        return;
      }

      // Obtener pedidos en estado 'listo' solo de los restaurantes asignados
      final pedidosListo = await PedidosHelper.obtenerPedidosConDetalles(
        estado: 'listo',
        restaurantesIds: restaurantesIds,
      );

      // Obtener los pedidos ya asignados a cualquier repartidor
      final asignados = await Supabase.instance.client
        .from('pedidos_repartidores')
        .select('pedido_id');
      final idsAsignados = asignados.map((a) => a['pedido_id']).toSet();

      // Filtrar pedidos disponibles (no asignados)
      final disponibles = pedidosListo
          .where((p) => !idsAsignados.contains(p['id']))
          .toList();

      _pedidosDisponibles = disponibles;
      notifyListeners();
    } catch (e) {
      print('Error cargando pedidos disponibles: $e');
      _pedidosDisponibles = [];
      notifyListeners();
    }
  }

  // Pedidos asignados a este repartidor
  Future<void> cargarMisPedidos(BuildContext context) async {
    try {
      final userProvider = context.read<CarritoProvider>();
      final email = userProvider.userEmail;
      if (email == null) {
        _misPedidos = [];
        notifyListeners();
        return;
      }
      final repartidor = await Supabase.instance.client
        .from('usuarios')
        .select('id')
        .eq('email', email)
        .maybeSingle();
      final repartidorId = repartidor?['id'];
      if (repartidorId == null) {
        _misPedidos = [];
        notifyListeners();
        return;
      }
      final asignaciones = await Supabase.instance.client
        .from('pedidos_repartidores')
        .select('pedido_id')
        .eq('repartidor_id', repartidorId);
      final pedidoIds = asignaciones.map((a) => a['pedido_id'] as String).toList();
      if (pedidoIds.isEmpty) {
        _misPedidos = [];
        notifyListeners();
        return;
      }
      
      // Obtener pedidos con detalles usando el helper
      final pedidosConDetalles = await PedidosHelper.obtenerDetallesMultiplesPedidos(pedidoIds);
      
      // Obtener los pedidos base y combinarlos con detalles
      final pedidosDb = await Supabase.instance.client
        .from('pedidos')
        .select()
        .filter('id', 'in', '(${pedidoIds.join(',')})');
      
      _misPedidos = pedidosDb.map((pedido) {
        final pedidoId = pedido['id'] as String;
        final detalles = pedidosConDetalles[pedidoId] ?? [];
        
        return {
          ...pedido,
          'productos': detalles, // Mantener compatibilidad
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      _misPedidos = [];
      notifyListeners();
    }
  }

  // Tomar (autoasignar) un pedido
  Future<void> tomarPedido(BuildContext context, Map<String, dynamic> pedido) async {
    _setLoading(true);
    final userProvider = context.read<CarritoProvider>();
    final email = userProvider.userEmail;
    if (email == null) {
      _setLoading(false);
      return;
    }
          final repartidor = await Supabase.instance.client
        .from('usuarios')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    final repartidorId = repartidor?['id'];
    if (repartidorId == null) {
      _setLoading(false);
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
    
    if (context.mounted) {
      showTopInfoMessage(
        context,
        '¡Pedido tomado!',
        icon: Icons.check_circle,
        backgroundColor: Colors.green[50],
        textColor: Colors.green[700],
        iconColor: Colors.green[700],
      );
    }
    
    await cargarAmbasListas(context); // Refresca la lista y el badge
    _setLoading(false);
  }

  // Marcar pedido como entregado
  Future<void> marcarEntregado(BuildContext context, Map<String, dynamic> pedido) async {
    _setLoading(true);
    await Supabase.instance.client
      .from('pedidos')
      .update({'estado': 'entregado'})
      .eq('id', pedido['id']);
    
    if (context.mounted) {
      showTopInfoMessage(
        context,
        AppLocalizations.of(context).get('pedido_entregado'),
        icon: Icons.delivery_dining,
        backgroundColor: Colors.blue[50],
        textColor: Colors.blue[700],
        iconColor: Colors.blue[700],
      );
    }
    
    await cargarAmbasListas(context); // Refresca la lista y el badge
    _setLoading(false);
  }

  // Obtener nombre del restaurante
  Future<String> obtenerNombreRestaurante(String restauranteId) async {
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

  // Helper para obtener folio del pedido (primeros 8 dígitos del ID)
  String obtenerFolio(String? pedidoId) {
    if (pedidoId == null || pedidoId.isEmpty) return 'N/A';
    return pedidoId.length >= 8 ? pedidoId.substring(0, 8) : pedidoId;
  }

  // Helper para formatear precios como doubles
  String formatearPrecio(dynamic precio) {
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
  double calcularPrecioTotal(dynamic precio, int cantidad) {
    if (precio == null) return 0.0;
    if (precio is int) return (precio * cantidad).toDouble();
    if (precio is double) return precio * cantidad;
    if (precio is String) {
      final doubleValue = double.tryParse(precio);
      return (doubleValue ?? 0.0) * cantidad;
    }
    return 0.0;
  }

  // Obtener pedidos ordenados
  List<Map<String, dynamic>> getPedidosOrdenados(List<Map<String, dynamic>> pedidos) {
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
    return pedidosOrdenados;
  }

  // Calcular total de un pedido
  double calcularTotalPedido(List<Map<String, dynamic>> productos) {
    return productos.fold<double>(0, (sum, producto) {
      final precio = double.tryParse(producto['precio']?.toString() ?? '0') ?? 0;
      final cantidad = int.tryParse(producto['cantidad']?.toString() ?? '1') ?? 1;
      return sum + (precio * cantidad);
    });
  }

  // Cambiar índice seleccionado
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Limpiar recursos
  @override
  void dispose() {
    _pedidosSubscription?.cancel();
    super.dispose();
  }

  // Setters para el estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 