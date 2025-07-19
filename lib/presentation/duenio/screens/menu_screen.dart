import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase

// menu_screen.dart - Pantalla de menú del dueño de negocio
// Permite ver los productos del menú, simular eliminación y agregar productos (simulado).
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class DuenioMenuScreen extends StatelessWidget {
  // Pantalla de menú para el dueño de negocio
  const DuenioMenuScreen({super.key});

  // Función para mostrar el formulario de agregar/editar producto
  void _mostrarFormularioProducto(BuildContext context, String restauranteId, {Map<String, dynamic>? producto}) {
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
                await Supabase.instance.client
                  .from('productos')
                  .insert(data);
              } else {
                // Editar producto existente
                await Supabase.instance.client
                  .from('productos')
                  .update(data)
                  .eq('id', producto['id']);
              }
              Navigator.of(context).pop();
            },
            child: Text(producto == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  // Obtiene los productos del menú desde Supabase
  Future<List<Map<String, dynamic>>> obtenerProductosMenu(String negocioId) async {
    final data = await Supabase.instance.client
        .from('productos')
        .select()
        .eq('negocioId', negocioId);
    return List<Map<String, dynamic>>.from(data);
  }

  // Agrega un producto al menú usando Supabase
  Future<void> agregarProductoMenu(Map<String, dynamic> producto) async {
    await Supabase.instance.client.from('productos').insert(producto);
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el restauranteId del dueño logueado
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final restauranteId = userProvider.restauranteId;
    return Scaffold(
      appBar: AppBar(title: const Text('Menú del negocio'), centerTitle: true),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: obtenerProductosMenu(restauranteId ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final productos = snapshot.data ?? [];
          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos en el menú'));
          }
          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(producto['nombre'] ?? 'Sin nombre'),
                  subtitle: Text(producto['descripcion'] ?? 'Sin descripción'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${producto['precio'] ?? 0}'),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('productos')
                              .delete()
                              .eq('id', producto['id']);
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
          _mostrarFormularioProducto(context, restauranteId ?? '');
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
      ),
    );
  }
}
// Fin de menu_screen.dart (dueño)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 