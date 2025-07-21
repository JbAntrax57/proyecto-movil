import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'package:image_picker/image_picker.dart';

// menu_screen.dart - Pantalla de menú del dueño de negocio
// Permite ver los productos del menú, simular eliminación y agregar productos (simulado).
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
class DuenioMenuScreen extends StatelessWidget {
  // Pantalla de menú para el dueño de negocio
  const DuenioMenuScreen({super.key});

  // Función para mostrar el formulario de agregar/editar producto
  void _mostrarFormularioProducto(BuildContext context, String negocioId, {Map<String, dynamic>? producto}) {
    final nombreController = TextEditingController(text: producto != null ? producto['nombre'] : '');
    final precioController = TextEditingController(text: producto != null ? producto['precio']?.toString() ?? '' : '');
    final descripcionController = TextEditingController(text: producto != null ? producto['descripcion'] ?? '' : '');
    final imgController = TextEditingController(text: producto != null ? producto['img'] ?? '' : '');
    File? imagenLocal;
    String? urlSubida = imgController.text.isNotEmpty ? imgController.text : null;
    final picker = ImagePicker();
    bool subiendoImagen = false;

    Future<void> seleccionarYSubirImagen(Function setStateDialog) async {
      print('🟣 Seleccionando imagen...');
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) {
        print('🟣 No se seleccionó imagen');
        return;
      }
      imagenLocal = File(picked.path);
      setStateDialog(() { subiendoImagen = true; });
      print('🟣 Subiendo imagen a Supabase...');
      final fileName = 'producto_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final storageResponse = await Supabase.instance.client.storage
          .from('images')
          .upload(fileName, imagenLocal!, fileOptions: const FileOptions(upsert: true));
      print('🟣 Respuesta de storage: $storageResponse');
      if (storageResponse != null && storageResponse.isNotEmpty) {
        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(fileName);
        print('🟣 URL pública generada: $url');
        urlSubida = url;
        imgController.text = url;
      }
      setStateDialog(() { subiendoImagen = false; });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(producto == null ? 'Agregar producto' : 'Editar producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    await seleccionarYSubirImagen(setStateDialog);
                  },
                  child: urlSubida?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            urlSubida!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : imagenLocal != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imagenLocal!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            ),
                ),
                if (subiendoImagen) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // Permite decimales
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: imgController,
                  decoration: const InputDecoration(labelText: 'URL de imagen'),
                  readOnly: true,
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
              onPressed: subiendoImagen
                  ? null
                  : () async {
                      final nombre = nombreController.text.trim();
                      final precio = double.tryParse(precioController.text.trim()) ?? 0;
                      final descripcion = descripcionController.text.trim();
                      final img = imgController.text.trim();
                      print('🟣 Guardando producto: nombre=$nombre, precio=$precio, descripcion=$descripcion, img=$img');
                      if (nombre.isEmpty || precio <= 0) {
                        print('🟣 Validación fallida: nombre o precio vacío');
                        return;
                      }
                      final data = {
                        'nombre': nombre,
                        'precio': precio,
                        'descripcion': descripcion,
                        'img': img,
                        'restaurante_id': negocioId,
                      };
                      print('🟣 Data enviada a Supabase: $data');
                      if (producto == null) {
                        await Supabase.instance.client
                            .from('productos')
                            .insert(data);
                        print('🟣 Producto insertado');
                      } else {
                        await Supabase.instance.client
                            .from('productos')
                            .update(data)
                            .eq('id', producto['id']);
                        print('🟣 Producto actualizado');
                      }
                      Navigator.of(context).pop();
                      (context as Element).markNeedsBuild();
                    },
              child: Text(producto == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Obtiene los productos del menú desde Supabase
  Future<List<Map<String, dynamic>>> obtenerProductosMenu(String negocioId) async {
    print('🟣 negocioId usado para productos: $negocioId');
    final data = await Supabase.instance.client
        .from('productos')
        .select()
        .eq('restaurante_id', negocioId); // columna correcta
    return List<Map<String, dynamic>>.from(data);
  }

  // Agrega un producto al menú usando Supabase
  Future<void> agregarProductoMenu(Map<String, dynamic> producto) async {
    await Supabase.instance.client.from('productos').insert(producto);
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el negocioId del dueño logueado
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final negocioId = userProvider.restauranteId;
    if (negocioId == null || negocioId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menú del negocio'), centerTitle: true),
        body: const Center(
          child: Text(
            'No se encontró el ID del negocio. Por favor, vuelve a iniciar sesión o contacta al administrador.',
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menú del negocio'), centerTitle: true),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: obtenerProductosMenu(negocioId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: \n${snapshot.error}'));
            }
            final productos = snapshot.data ?? [];
            if (productos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fastfood, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay productos en el menú',
                      style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Agrega tu primer producto usando el botón +',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen del producto
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: producto['img'] != null && producto['img'].toString().isNotEmpty
                              ? Image.network(
                                  producto['img'],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.fastfood, color: Colors.grey, size: 40),
                                  ),
                                )
                              : Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.fastfood, color: Colors.grey, size: 40),
                                ),
                        ),
                        const SizedBox(width: 18),
                        // Info principal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                producto['descripcion'] ?? 'Sin descripción',
                                style: const TextStyle(fontSize: 15, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '\$${producto['precio']?.toStringAsFixed != null ? double.tryParse(producto['precio'].toString())?.toStringAsFixed(2) ?? producto['precio'].toString() : producto['precio'].toString()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botones de editar y eliminar
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Editar',
                              onPressed: () {
                                _mostrarFormularioProducto(context, negocioId, producto: producto);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar',
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
            _mostrarFormularioProducto(context, negocioId);
          },
          icon: const Icon(Icons.add),
          label: const Text('Agregar producto'),
        ),
      ),
    );
  }
}
// Fin de menu_screen.dart (dueño)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 