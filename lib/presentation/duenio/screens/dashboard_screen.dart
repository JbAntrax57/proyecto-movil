import 'package:flutter/material.dart';
import 'pedidos_screen.dart';
import 'menu_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _initNotifications();
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
    _pedidoSub = FirebaseFirestore.instance
      .collection('pedidos')
      .where('restauranteId', isEqualTo: restauranteId)
      .where('estado', isEqualTo: 'pendiente')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) async {
        for (final doc in snapshot.docs) {
          if (!_notificados.contains(doc.id)) {
            _notificados.add(doc.id);
            // Mostrar notificación visual
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Nuevo pedido recibido!')),
              );
            }
            // Notificación nativa con sonido del sistema
            await _notificarNuevoPedido();
          }
        }
      });
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
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final opcion = opciones[index];
          return Card(
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
          );
        },
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