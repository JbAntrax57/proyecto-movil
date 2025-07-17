import 'package:flutter/material.dart';

// menu_screen.dart - Pantalla de menú del dueño de negocio
// Permite ver los productos del menú, simular eliminación y agregar productos (simulado).
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class DuenioMenuScreen extends StatelessWidget {
  // Pantalla de menú para el dueño de negocio
  const DuenioMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista simulada de productos
    final productos = [
      {'nombre': 'Pizza Margarita', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80'},
      {'nombre': 'Pizza Pepperoni', 'precio': 140, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80'},
      {'nombre': 'Refresco', 'precio': 30, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80'},
    ];
    // Scaffold principal con lista de productos
    return Scaffold(
      appBar: AppBar(title: const Text('Menú del negocio'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          // Animación de aparición para cada producto
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
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    producto['img'] as String,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
                title: Text(
                  producto['nombre'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Precio:  24 24${producto['precio']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Simula la eliminación de un producto
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto eliminado (simulado)')),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      // Botón para agregar producto (simulado)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto agregado (simulado)')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
      ),
    );
  }
}
// Fin de menu_screen.dart (dueño)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 