import 'package:flutter/material.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = [
      {'nombre': 'Pizza Margarita', 'precio': 120, 'cantidad': 1},
      {'nombre': 'Refresco', 'precio': 30, 'cantidad': 2},
    ];
    final int total = carrito.fold(0, (int sum, item) => sum + (item['precio'] as int) * (item['cantidad'] as int));
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de compras'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: carrito.length,
              itemBuilder: (context, index) {
                final item = carrito[index];
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
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(item['nombre'].toString()[0]),
                      ),
                      title: Text(item['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cantidad: ${(item['cantidad'] as int)}'),
                      trailing: Text(' 24 24${(item['precio'] as int) * (item['cantidad'] as int)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleMedium),
                Text(' 24 24$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payment),
                  label: const Text('Pagar'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 