import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../cliente/providers/carrito_provider.dart';

class MenuDuenioProvider extends ChangeNotifier {
  // Estado del menú
  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = true;
  String? _error;
  String _searchText = '';
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  // Getters para el estado
  List<Map<String, dynamic>> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchText => _searchText;

  // Inicializar el provider
  Future<void> inicializarMenu(BuildContext context) async {
    await cargarProductos(context);
  }

  // Cargar productos del menú desde Supabase
  Future<void> cargarProductos(BuildContext context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (!context.mounted) return;
      final userProvider = context.read<CarritoProvider>();
      final negocioId = userProvider.restauranteId;
      
      if (negocioId == null || negocioId.isEmpty) {
        _setError('No se encontró el ID del negocio.');
        _setLoading(false);
        return;
      }
      
      final data = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('restaurante_id', negocioId);
      
      _productos = List<Map<String, dynamic>>.from(data);
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar productos: $e');
      _setLoading(false);
    }
  }

  // Agregar producto al menú
  Future<void> agregarProducto(Map<String, dynamic> producto) async {
    try {
      await Supabase.instance.client.from('productos').insert(producto);
      // No recargar productos aquí, se hará desde la UI
    } catch (e) {
      throw Exception('Error al agregar producto: $e');
    }
  }

  // Actualizar producto del menú
  Future<void> actualizarProducto(String productoId, Map<String, dynamic> producto) async {
    try {
      await Supabase.instance.client
          .from('productos')
          .update(producto)
          .eq('id', productoId);
      // No recargar productos aquí, se hará desde la UI
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  // Eliminar producto del menú
  Future<void> eliminarProducto(String productoId) async {
    try {
      await Supabase.instance.client
          .from('productos')
          .delete()
          .eq('id', productoId);
      // No recargar productos aquí, se hará desde la UI
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // Subir imagen a Supabase Storage
  Future<String?> subirImagen(File imagen) async {
    try {
      final fileName = 'producto_${DateTime.now().millisecondsSinceEpoch}_${imagen.path.split('/').last}';
      final storageResponse = await Supabase.instance.client.storage
          .from('images')
          .upload(
            fileName,
            imagen,
            fileOptions: const FileOptions(upsert: true),
          );
      
      if (storageResponse.isNotEmpty) {
        final url = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(fileName);
        return url;
      }
      return null;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Mostrar formulario de agregar/editar producto
  Future<bool?> mostrarFormularioProducto(
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
    String? urlSubida = imgController.text.isNotEmpty ? imgController.text : null;
    final picker = ImagePicker();
    bool subiendoImagen = false;

    Future<void> seleccionarYSubirImagen(Function setStateDialog) async {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      
      imagenLocal = File(picked.path);
      setStateDialog(() {
        subiendoImagen = true;
      });
      
      try {
        final url = await subirImagen(imagenLocal!);
        if (url != null) {
          urlSubida = url;
          imgController.text = url;
        }
      } catch (e) {
        // Manejar error de subida
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
              onPressed: () => Navigator.of(context).pop(false),
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
                      
                      if (nombre.isEmpty || precio <= 0) {
                        return;
                      }
                      
                      final data = {
                        'nombre': nombre,
                        'precio': precio,
                        'descripcion': descripcion,
                        'img': img,
                        'restaurante_id': negocioId,
                      };
                      
                                             try {
                         if (producto == null) {
                           await agregarProducto(data);
                         } else {
                           await actualizarProducto(producto['id'].toString(), data);
                         }
                         if (context.mounted) {
                           Navigator.of(context).pop(true);
                         }
                       } catch (e) {
                         // Manejar error
                         if (context.mounted) {
                           Navigator.of(context).pop(false);
                         }
                       }
                    },
              child: Text(producto == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para formatear precios como doubles
  String formatearPrecio(dynamic precio) {
    if (precio == null) return '0.00';
    if (precio is int) return precio.toDouble().toStringAsFixed(2);
    if (precio is double) return precio.toStringAsFixed(2);
    if (precio is String) {
      final doubleValue = double.tryParse(precio);
      return doubleValue?.toStringAsFixed(2) ?? '0.00';
    }
    return '0.00';
  }

  // Helper para calcular el precio total
  double calcularPrecioTotal(dynamic precio, int cantidad) {
    if (precio == null) return 0.0;
    if (precio is int) return (precio * cantidad).toDouble();
    if (precio is double) return precio * cantidad;
    if (precio is String) {
      final doubleValue = double.tryParse(precio);
      return (doubleValue ?? 0.0) * cantidad;
    }
    return 0.0;
  }

  // Determinar si el producto es nuevo (menos de 1 mes desde created_at)
  bool esNuevo(dynamic createdAt) {
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

  // Filtrar productos por búsqueda
  List<Map<String, dynamic>> getProductosFiltrados() {
    if (_searchText.isEmpty) {
      return _productos;
    }
    
    return _productos.where((producto) {
      final nombre = (producto['nombre']?.toString() ?? '').toLowerCase();
      final descripcion = (producto['descripcion']?.toString() ?? '').toLowerCase();
      final busqueda = _searchText.toLowerCase();
      return nombre.contains(busqueda) || descripcion.contains(busqueda);
    }).toList();
  }

  // Establecer texto de búsqueda
  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  // Limpiar búsqueda
  void limpiarBusqueda() {
    _searchText = '';
    searchController.clear();
    searchFocusNode.unfocus();
    notifyListeners();
  }

  // Obtener estadísticas del menú
  Map<String, int> obtenerEstadisticasMenu() {
    final estadisticas = <String, int>{};
    estadisticas['total'] = _productos.length;
    estadisticas['nuevos'] = _productos.where((p) => esNuevo(p['created_at'])).length;
    estadisticas['conImagen'] = _productos.where((p) => p['img'] != null && p['img'].toString().isNotEmpty).length;
    return estadisticas;
  }

  // Obtener productos por rango de precio
  List<Map<String, dynamic>> obtenerProductosPorPrecio(double minPrecio, double maxPrecio) {
    return _productos.where((producto) {
      final precio = double.tryParse(producto['precio']?.toString() ?? '0') ?? 0;
      return precio >= minPrecio && precio <= maxPrecio;
    }).toList();
  }

  // Obtener productos nuevos
  List<Map<String, dynamic>> obtenerProductosNuevos() {
    return _productos.where((producto) => esNuevo(producto['created_at'])).toList();
  }

  // Obtener productos sin imagen
  List<Map<String, dynamic>> obtenerProductosSinImagen() {
    return _productos.where((producto) {
      return producto['img'] == null || producto['img'].toString().isEmpty;
    }).toList();
  }

  // Calcular valor total del menú
  double calcularValorTotalMenu() {
    return _productos.fold<double>(0, (sum, producto) {
      final precio = double.tryParse(producto['precio']?.toString() ?? '0') ?? 0;
      return sum + precio;
    });
  }

  // Limpiar recursos
  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Setters para el estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 