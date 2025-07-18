import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';

// menu_screen.dart - Pantalla de menú del dueño de negocio
// Permite ver los productos del menú, simular eliminación y agregar productos (simulado).
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class DuenioMenuScreen extends StatelessWidget {
  // Pantalla de menú para el dueño de negocio
  const DuenioMenuScreen({super.key});

  // Función para mostrar el formulario de agregar/editar producto
  void _mostrarFormularioProducto(BuildContext context, String restauranteId, {DocumentSnapshot? producto}) {
    final nombreController = TextEditingController(text: producto != null ? producto['nombre'] : '');
    final precioController = TextEditingController(text: producto != null ? producto['precio'].toString() : '');
    final descripcionController = TextEditingController(text: producto != null ? producto['descripcion'] ?? '' : '');
    final imgController = TextEditingController(text: producto != null ? producto['img'] ?? '' : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producto == null ? 'Agregar producto' : 'Editar producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: imgController,
                decoration: const InputDecoration(labelText: 'URL de imagen'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final precio = int.tryParse(precioController.text.trim()) ?? 0;
              final descripcion = descripcionController.text.trim();
              final img = imgController.text.trim();
              if (nombre.isEmpty || precio <= 0) return;
              final data = {
                'nombre': nombre,
                'precio': precio,
                'descripcion': descripcion,
                'img': img,
              };
              if (producto == null) {
                // Agregar nuevo producto
                await FirebaseFirestore.instance
                  .collection('negocios')
                  .doc(restauranteId)
                  .collection('menu')
                  .add(data);
              } else {
                // Editar producto existente
                await FirebaseFirestore.instance
                  .collection('negocios')
                  .doc(restauranteId)
                  .collection('menu')
                  .doc(producto.id)
                  .update(data);
              }
              Navigator.of(context).pop();
            },
            child: Text(producto == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el restauranteId del dueño logueado
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final restauranteId = userProvider.restauranteId;
    return Scaffold(
      appBar: AppBar(title: const Text('Menú del negocio'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('negocios')
            .doc(restauranteId)
            .collection('menu')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar menú'));
          }
          final productos = snapshot.data?.docs ?? [];
          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos en el menú.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              final data = producto.data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['img'] ?? '',
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
                    data['nombre'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Precio: ${data['precio'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _mostrarFormularioProducto(context, restauranteId!, producto: producto);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('negocios')
                              .doc(restauranteId)
                              .collection('menu')
                              .doc(producto.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Producto eliminado')), 
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarFormularioProducto(context, restauranteId!);
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
      ),
    );
  }
}
// Fin de menu_screen.dart (dueño)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 