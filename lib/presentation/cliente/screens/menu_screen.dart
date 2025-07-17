import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// menu_screen.dart - Pantalla de menú de un negocio para el cliente
// Muestra los productos del menú obtenidos en tiempo real desde Firestore.
// Permite agregar productos al carrito y ver detalles de cada producto.
class MenuScreen extends StatelessWidget {
  // Recibe el ID y nombre del restaurante, y un callback para agregar al carrito
  final String restauranteId;
  final String restaurante;
  final void Function(Map<String, dynamic> producto)? onAddToCart;

  const MenuScreen({
    super.key,
    required this.restauranteId,
    required this.restaurante,
    this.onAddToCart,
  });

  // Obtiene el menú del restaurante en tiempo real desde Firestore
  Stream<List<Map<String, dynamic>>> getMenuStream() {
    return FirebaseFirestore.instance
      .collection('negocios')
      .doc(restauranteId)
      .collection('menu')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList());
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold principal con AppBar y StreamBuilder para menú
    return Scaffold(
      appBar: AppBar(title: Text('Menú - $restaurante'), centerTitle: true),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getMenuStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar menú'));
          }
          final productos = snapshot.data ?? [];
          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos en el menú'));
          }
          // Lista animada de productos
          return ListView.builder(
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
                  elevation: 8,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: Colors.white,
                  shadowColor: Colors.blue.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: Colors.blue.withOpacity(0.08),
                    highlightColor: Colors.blue.withOpacity(0.04),
                    onTap: () {
                      // Al tocar un producto, muestra modal para elegir cantidad y agregar al carrito
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) {
                          int cantidad = 1;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 24, right: 24,
                                  top: 24,
                                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Imagen del producto
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Image.network(
                                        producto['img'] as String,
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 180,
                                          height: 180,
                                          color: Colors.blue[50],
                                          child: const Icon(Icons.fastfood, color: Colors.blueGrey, size: 70),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    // Nombre del producto
                                    Text(
                                      producto['nombre'] as String,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    // Descripción
                                    Text(
                                      producto['descripcion'] as String? ?? 'Delicioso y recién hecho',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blueGrey[700]),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    // Precio
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '\$${producto['precio']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    // Selector de cantidad
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: cantidad > 1 ? () => setState(() => cantidad--) : null,
                                        ),
                                        Text('$cantidad', style: const TextStyle(fontSize: 20)),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => setState(() => cantidad++),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    // Botón para agregar al carrito
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.add_shopping_cart),
                                        label: const Text('Agregar al carrito'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        onPressed: () {
                                          final productoConCantidad = Map<String, dynamic>.from(producto);
                                          productoConCantidad['cantidad'] = cantidad;
                                          if (onAddToCart != null) {
                                            onAddToCart!(productoConCantidad);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${producto['nombre']} x$cantidad añadido al carrito')),
                                            );
                                          }
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen miniatura
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              producto['img'] as String,
                              width: 62,
                              height: 62,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 62,
                                height: 62,
                                color: Colors.blue[50],
                                child: const Icon(Icons.fastfood, color: Colors.blueGrey, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Detalles del producto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto['nombre'] as String,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  producto['descripcion'] as String? ?? 'Delicioso y recién hecho',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Precio
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '\$${producto['precio']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Botón alternativo para agregar al carrito (opcional)
                              ElevatedButton(
                                onPressed: () async {
                                  int cantidad = 1;
                                  final result = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('¿Cuántos ${producto['nombre']} quieres agregar?'),
                                        content: StatefulBuilder(
                                          builder: (context, setState) {
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove),
                                                  onPressed: cantidad > 1 ? () => setState(() => cantidad--) : null,
                                                ),
                                                Text('$cantidad', style: const TextStyle(fontSize: 20)),
                                                IconButton(
                                                  icon: const Icon(Icons.add),
                                                  onPressed: () => setState(() => cantidad++),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, cantidad),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                            child: const Text('Agregar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (result != null && result > 0) {
                                    final productoConCantidad = Map<String, dynamic>.from(producto);
                                    productoConCantidad['cantidad'] = result;
                                    if (onAddToCart != null) {
                                      onAddToCart!(productoConCantidad);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${producto['nombre']} x$result añadido al carrito')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(32, 32),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 