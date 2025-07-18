import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class NotificacionesPedidosProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _pedidoSub;
  Set<String> _notificados = {};
  String? _restauranteId;
  BuildContext? _contextoGlobal;
  bool _inicializado = false;

  // Inicializar el sistema de notificaciones al arrancar la app
  Future<void> inicializarSistema() async {
    if (_inicializado) return;
    
    await _initNotifications();
    _escucharTodosLosPedidos();
    _inicializado = true;
  }

  // Configurar el restaurante específico cuando el dueño hace login
  void configurarRestaurante(String restauranteId, BuildContext contextoGlobal) {
    _restauranteId = restauranteId;
    _contextoGlobal = contextoGlobal;
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

  void _escucharTodosLosPedidos() {
    print('🔔 Iniciando escucha de todos los pedidos...');
    _pedidoSub?.cancel();
    
    _pedidoSub = FirebaseFirestore.instance
      .collection('pedidos')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final pedido = change.doc.data();
            if (pedido != null) {
              final restauranteId = pedido['restauranteId'] as String?;
              final estado = pedido['estado'] as String?;
              
              // Solo notificar si es un pedido pendiente y coincide con el restaurante configurado
              if (estado == 'pendiente' && 
                  restauranteId != null && 
                  _restauranteId != null && 
                  restauranteId == _restauranteId &&
                  !_notificados.contains(change.doc.id)) {
                
                print('🔔 Nuevo pedido detectado: ${change.doc.id}');
                _notificados.add(change.doc.id);
                
                // Mostrar notificación nativa
                await _mostrarNotificacionNativa();
                
                // Mostrar SnackBar si hay contexto
                _mostrarSnackBar();
              }
            }
          }
        }
      }, onError: (error) {
        print('❌ Error en escucha de pedidos: $error');
      });
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
        ScaffoldMessenger.of(_contextoGlobal!).showSnackBar(
          const SnackBar(
            content: Text('¡Nuevo pedido recibido!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        print('🔔 SnackBar mostrado');
      } catch (e) {
        print('❌ Error mostrando SnackBar: $e');
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
    super.dispose();
  }
} 