import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Para personalizar la status bar

// menu_screen.dart - Pantalla de menú del dueño de negocio
// Permite ver los productos del menú, simular eliminación y agregar productos (simulado).
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
// Convertimos a StatefulWidget para poder refrescar la lista al agregar/editar producto
class DuenioMenuScreen extends StatefulWidget {
  const DuenioMenuScreen({super.key});

  @override
  State<DuenioMenuScreen> createState() => _DuenioMenuScreenState();
}

class _DuenioMenuScreenState extends State<DuenioMenuScreen> {
  // Controlador para la barra de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  final FocusNode _searchFocusNode =
      FocusNode(); // FocusNode para controlar el foco
  // Función para mostrar el formulario de agregar/editar producto
  // Ahora devuelve un Future<bool?> para saber si se agregó/editó un producto
  Future<bool?> _mostrarFormularioProducto(
    BuildContext context,
    String negocioId, {
    Map<String, dynamic>? producto,
  }) async {
    final nombreController = TextEditingController(
      text: producto != null ? producto['nombre'] : '',
    );
    final precioController = TextEditingController(
      text: producto != null ? producto['precio']?.toString() ?? '' : '',
    );
    final descripcionController = TextEditingController(
      text: producto != null ? producto['descripcion'] ?? '' : '',
    );
    final imgController = TextEditingController(
      text: producto != null ? producto['img'] ?? '' : '',
    );
    File? imagenLocal;
    String? urlSubida = imgController.text.isNotEmpty
        ? imgController.text
        : null;
    final picker = ImagePicker();
    bool subiendoImagen = false;

    Future<void> seleccionarYSubirImagen(Function setStateDialog) async {
      print('🟣 Seleccionando imagen...');
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) {
        print('🟣 No se seleccionó imagen');
        return;
      }
      imagenLocal = File(picked.path);
      setStateDialog(() {
        subiendoImagen = true;
      });
      print('🟣 Subiendo imagen a Supabase...');
      final fileName =
          'producto_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final storageResponse = await Supabase.instance.client.storage
          .from('images')
          .upload(
            fileName,
            imagenLocal!,
            fileOptions: const FileOptions(upsert: true),
          );
      print('🟣 Respuesta de storage: $storageResponse');
      if (storageResponse != null && storageResponse.isNotEmpty) {
        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(fileName);
        print('🟣 URL pública generada: $url');
        urlSubida = url;
        imgController.text = url;
      }
      setStateDialog(() {
        subiendoImagen = false;
      });
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(
            producto == null ? 'Agregar producto' : 'Editar producto',
          ),
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
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Permite decimales
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // No hubo cambio
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: subiendoImagen
                  ? null
                  : () async {
                      final nombre = nombreController.text.trim();
                      final precio =
                          double.tryParse(precioController.text.trim()) ?? 0;
                      final descripcion = descripcionController.text.trim();
                      final img = imgController.text.trim();
                      print(
                        '🟣 Guardando producto: nombre=$nombre, precio=$precio, descripcion=$descripcion, img=$img',
                      );
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
                      Navigator.of(
                        context,
                      ).pop(true); // Indicamos que hubo cambio
                    },
              child: Text(producto == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Obtiene los productos del menú desde Supabase
  Future<List<Map<String, dynamic>>> obtenerProductosMenu(
    String negocioId,
  ) async {
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

  // Determina si el producto es nuevo (menos de 1 mes desde created_at)
  bool _esNuevo(dynamic createdAt) {
    if (createdAt == null) return false;
    try {
      final fecha = DateTime.tryParse(createdAt.toString());
      if (fecha == null) return false;
      final ahora = DateTime.now();
      return ahora.difference(fecha).inDays < 30;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el negocioId del dueño logueado
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final negocioId = userProvider.restauranteId;
    if (negocioId == null || negocioId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Menú del negocio'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'No se encontró el ID del negocio. Por favor, vuelve a iniciar sesión o contacta al administrador.',
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Envolvemos con AnnotatedRegion para personalizar la status bar (blanca, iconos oscuros)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white, // Fondo blanco para la status bar
        statusBarIconBrightness: Brightness.dark, // Iconos oscuros
        statusBarBrightness: Brightness.light, // Para iOS
      ),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Menú del negocio'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Barra de búsqueda
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode, // Asociar el FocusNode
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
                              _searchFocusNode
                                  .unfocus(); // Quitar el foco al limpiar
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchText = value);
                  },
                  autofocus: false, // No enfocar automáticamente nunca
                ),
              ),
              // Lista de productos
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  // Usamos una key para forzar el refresco si es necesario
                  key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  future: obtenerProductosMenu(negocioId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: \n${snapshot.error}'));
                    }
                    final productos = snapshot.data ?? [];
                    // Filtrado por búsqueda
                    final productosFiltrados = productos.where((producto) {
                      final nombre = (producto['nombre']?.toString() ?? '')
                          .toLowerCase();
                      final descripcion =
                          (producto['descripcion']?.toString() ?? '')
                              .toLowerCase();
                      final busqueda = _searchText.toLowerCase();
                      return nombre.contains(busqueda) ||
                          descripcion.contains(busqueda);
                    }).toList();
                    if (productosFiltrados.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron productos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta con otro término de búsqueda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          productosFiltrados.length +
                          1, // +1 para el espacio extra
                      itemBuilder: (context, index) {
                        if (index == productosFiltrados.length) {
                          // Espacio extra al final para que el FAB no tape el último card
                          return const SizedBox(height: 40);
                        }
                        final producto = productosFiltrados[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SizedBox(
                            height: 120, // Altura fija para el card
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Imagen del producto con badge 'Nuevo' encima si aplica
                                Stack(
                                  children: [
                                    // Imagen del producto con altura suficiente para el badge
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomLeft: Radius.circular(20),
                                      ),
                                      child: producto['img'] != null && producto['img'].toString().isNotEmpty
                                          ? Image.network(
                                              producto['img'],
                                              width: 110,
                                              height: 120, // Altura suficiente para el badge
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 110,
                                                height: 120,
                                                color: Colors.grey[100],
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 110,
                                              height: 120,
                                              color: Colors.grey[100],
                                              child: const Icon(
                                                Icons.fastfood,
                                                color: Colors.grey,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    // Badge 'Nuevo' en la esquina superior izquierda de la imagen
                                    if (_esNuevo(producto['created_at']))
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.85), // Naranja con transparencia
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 4,
                                                offset: const Offset(1, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'Nuevo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 18),
                                // Info principal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        producto['nombre'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      // Badge 'Nuevo' si el producto fue creado hace menos de 1 mes
                                      const SizedBox(height: 6),
                                      Text(
                                        producto['descripcion'] ??
                                            'Sin descripción',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: Text(
                                          '\$${producto['precio']?.toStringAsFixed != null ? double.tryParse(producto['precio'].toString())?.toStringAsFixed(2) ?? producto['precio'].toString() : producto['precio'].toString()}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Botones de editar y eliminar
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Al editar, esperar el resultado del modal y refrescar si es necesario
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar',
                                      onPressed: () async {
                                        final result =
                                            await _mostrarFormularioProducto(
                                              context,
                                              negocioId,
                                              producto: producto,
                                            );
                                        if (result == true) {
                                          setState(
                                            () {},
                                          ); // Refresca la lista si se editó
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Eliminar',
                                      onPressed: () async {
                                        await Supabase.instance.client
                                            .from('productos')
                                            .delete()
                                            .eq('id', producto['id']);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Producto eliminado'),
                                            behavior: SnackBarBehavior.floating,
                                            margin: EdgeInsets.only(
                                              top: 60,
                                              left: 16,
                                              right: 16,
                                            ),
                                          ),
                                        );
                                        setState(
                                          () {},
                                        ); // Refresca la lista al eliminar
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
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              // Al cerrar el modal, si retorna true, refrescamos la lista
              final result = await _mostrarFormularioProducto(
                context,
                negocioId,
              );
              if (result == true) {
                setState(() {}); // Refresca la pantalla para ver el cambio
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar producto'),
          ),
        ),
      ),
    );
  }
}
// Fin de menu_screen.dart (dueño)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 