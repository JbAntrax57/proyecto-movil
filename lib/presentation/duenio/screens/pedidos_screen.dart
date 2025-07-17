import 'package:flutter/material.dart';
import 'menu_screen.dart';

class DuenioPedidosScreen extends StatelessWidget {
  const DuenioPedidosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final pedidos = [
      {'id': 1, 'cliente': 'Juan', 'estado': 'Pendiente'},
      {'id': 2, 'cliente': 'Ana', 'estado': 'En preparación'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos recibidos'), centerTitle: true),
      body: ListView.builder(
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
                  backgroundColor: Colors.orange[100],
                  child: Text(pedido['id'].toString()),
                ),
                title: Text('Pedido #${pedido['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Cliente: ${pedido['cliente'] as String}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pedido['estado'] as String, style: const TextStyle(color: Colors.deepOrange)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final nuevoEstado = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Actualizar estado'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, 'En preparación'),
                                child: const Text('En preparación'),
                              ),
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, 'Listo para entregar'),
                                child: const Text('Listo para entregar'),
                              ),
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, 'Entregado'),
                                child: const Text('Entregado'),
                              ),
                            ],
                          ),
                        );
                        if (nuevoEstado != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Estado actualizado a "$nuevoEstado"')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ],
                ),
                onTap: () {},
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const DuenioMenuScreen(),
        )),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Ver menú'),
      ),
    );
  }
} 