import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import '../../cliente/providers/carrito_provider.dart'; // Importa CarritoProvider correctamente
import 'package:permission_handler/permission_handler.dart'; // Para pedir permisos
import '../../../shared/widgets/custom_alert.dart';

class NotificacionesPedidosProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _pedidoSub;
  Set<String> _notificados = {};
  String? _restauranteId;
  BuildContext? _contextoGlobal;
  bool _inicializado = false;
  RealtimeChannel? _realtimeChannel; // Canal para Realtime

  // Inicializar el sistema de notificaciones al arrancar la app
  Future<void> inicializarSistema() async {
    if (_inicializado) return;
    
    await _initNotifications();
    _escucharTodosLosPedidos();
    _inicializado = true;
  }

  // Configurar el restaurante específico cuando el dueño hace login
  void configurarRestaurante(String restauranteId, BuildContext context) {
    _restauranteId = restauranteId;
    _contextoGlobal = context;
    _notificados.clear();
    _pedidoSub?.cancel();
    _suscribirsePedidosRealtime(restauranteId); // Suscribirse a Realtime
    print('🔔 Notificaciones configuradas para restaurante: $restauranteId');
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
    
    // Pedir permisos de notificación en Android/iOS
    await _pedirPermisosNotificacion();

    // Crear canal de notificaciones para Android
    const androidChannel = AndroidNotificationChannel(
      'pedidos_channel',
      'Pedidos',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Pedir permisos de notificación en Android/iOS
  Future<void> _pedirPermisosNotificacion() async {
    // Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // iOS: handled by flutter_local_notifications
  }

  void _escucharTodosLosPedidos() {
    print('🔔 Iniciando escucha de todos los pedidos...');
    _pedidoSub?.cancel();
    
    // Por ahora, usar una implementación simple sin Realtime
    // TODO: Implementar Supabase Realtime cuando esté disponible
    print('🔔 Escucha de pedidos configurada');
  }

  // Suscribirse a cambios en la tabla de pedidos usando Supabase Realtime
  void _suscribirsePedidosRealtime(String restauranteId) {
    _realtimeChannel?.unsubscribe();
    print('🔔 Suscribiéndose a pedidos Realtime para restaurante: $restauranteId');
    _realtimeChannel = Supabase.instance.client
      .channel('public:pedidos')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'pedidos',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'restaurante_id',
          value: restauranteId,
        ),
        callback: (payload) {
          print('🔔 Nuevo pedido detectado por Realtime: ${payload.newRecord}');
          _mostrarNotificacionNativa();
          _mostrarSnackBar(); // Refuerzo visual arriba
        },
      )
      .subscribe();
  }

  void _escucharPedidosNuevos() {
    final restauranteId = Provider.of<CarritoProvider>(_contextoGlobal!, listen: false).restauranteId;
    if (restauranteId == null) return;
    
    // Por ahora, usar una implementación simple sin Realtime
    // TODO: Implementar Supabase Realtime cuando esté disponible
    print('🔔 Escuchando pedidos nuevos para restaurante: $restauranteId');
  }

  Future<void> _mostrarNotificacionNativa() async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '¡Nuevo pedido recibido!',
        'Tienes un nuevo pedido pendiente.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pedidos_channel',
            'Pedidos',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
      );
      print('🔔 Notificación nativa mostrada');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }

  void _mostrarSnackBar() {
    if (_contextoGlobal != null) {
      try {
        showSuccessAlert(_contextoGlobal!, '¡Nuevo pedido recibido!');
        print('🔔 Alerta personalizada mostrada');
      } catch (e) {
        print('❌ Error mostrando alerta personalizada: $e');
      }
    }
  }

  // Limpiar notificaciones cuando se cierre la app
  void limpiarNotificaciones() {
    _localNotifications.cancelAll();
  }

  @override
  void dispose() {
    _pedidoSub?.cancel();
    _realtimeChannel?.unsubscribe(); // Cancelar la suscripción Realtime
    super.dispose();
  }
} 