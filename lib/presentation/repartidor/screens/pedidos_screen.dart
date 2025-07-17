import 'package:flutter/material.dart';
import 'mapa_screen.dart';
import 'actualizar_estado_screen.dart';

class RepartidorPedidosScreen extends StatefulWidget {
  const RepartidorPedidosScreen({super.key});
  @override
  State<RepartidorPedidosScreen> createState() => _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  List<Map<String, dynamic>> pedidos = [
    {'id': 1, 'direccion': 'Calle 1 #123', 'estado': 'En camino'},
    {'id': 2, 'direccion': 'Av. Central 45', 'estado': 'Pendiente'},
  ];
  final List<String> notificaciones = [];

  void _agregarPedidoPreparado() {
    setState(() {
      final nuevoId = (pedidos.isNotEmpty ? pedidos.last['id'] as int : 0) + 1;
      pedidos.add({'id': nuevoId, 'direccion': 'Dirección simulada', 'estado': 'Listo para entregar'});
      notificaciones.add('Nuevo pedido #$nuevoId listo para entregar');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos asignados'), centerTitle: true),
      body: Column(
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + index * 100),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(pedido['id'].toString()),
                      ),
                      title: Text('Pedido #${pedido['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Dirección: ${pedido['direccion'] as String}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(pedido['estado'] as String, style: const TextStyle(color: Colors.blue)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const ActualizarEstadoScreen(),
                              ));
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                            child: const Icon(Icons.check, size: 18),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const MapaScreen(),
                        ));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPedidoPreparado,
        icon: const Icon(Icons.notifications_active),
        label: const Text('Simular pedido preparado'),
      ),
    );
  }
} 