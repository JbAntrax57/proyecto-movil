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

  void inicializar(String restauranteId, BuildContext contextoGlobal) async {
    _restauranteId = restauranteId;
    _contextoGlobal = contextoGlobal;
    await _initNotifications();
    _escucharPedidosNuevos();
  }

  Future<void> _initNotifications() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  void _escucharPedidosNuevos() {
    if (_restauranteId == null) return;
    _pedidoSub?.cancel();
    _pedidoSub = FirebaseFirestore.instance
      .collection('pedidos')
      .where('restauranteId', isEqualTo: _restauranteId)
      .where('estado', isEqualTo: 'pendiente')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) async {
        for (final doc in snapshot.docs) {
          if (!_notificados.contains(doc.id)) {
            _notificados.add(doc.id);
            // Notificación nativa
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
                  playSound: true,
                ),
                iOS: DarwinNotificationDetails(presentSound: true),
              ),
            );
            // SnackBar global (si hay contexto)
            if (_contextoGlobal != null) {
              ScaffoldMessenger.of(_contextoGlobal!).showSnackBar(
                const SnackBar(content: Text('¡Nuevo pedido recibido!')),
              );
            }
          }
        }
      });
  }

  @override
  void dispose() {
    _pedidoSub?.cancel();
    super.dispose();
  }
} 