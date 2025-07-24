import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cliente/providers/carrito_provider.dart';

/// notificaciones_screen.dart - Pantalla para que el repartidor vea sus notificaciones
/// Muestra una lista de notificaciones obtenidas de la tabla 'notificaciones' filtradas por el usuario actual (repartidor).
class RepartidorNotificacionesScreen extends StatelessWidget {
  const RepartidorNotificacionesScreen({super.key});

  // Cargar notificaciones del repartidor desde Supabase
  Future<List<Map<String, dynamic>>> _cargarNotificacionesRepartidor(BuildContext context) async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final userEmail = userProvider.userEmail;
      if (userEmail == null) return [];
      final data = await Supabase.instance.client
        .from('notificaciones')
        .select()
        .eq('usuario_id', userEmail)
        .order('fecha', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis notificaciones'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cargarNotificacionesRepartidor(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notificaciones = snapshot.data ?? [];
          if (notificaciones.isEmpty) {
            return Center(
              child: Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No tienes notificaciones recientes.', style: TextStyle(color: Colors.blueGrey)),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: notificaciones.length,
            itemBuilder: (context, index) {
              final notif = notificaciones[index];
              return Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.purple),
                  title: Text(notif['mensaje'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(_formatearFecha(notif['fecha'])),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 