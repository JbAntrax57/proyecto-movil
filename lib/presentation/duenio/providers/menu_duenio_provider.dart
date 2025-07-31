import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../cliente/providers/carrito_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Cambiar estado activo/inactivo de un producto
  Future<void> cambiarEstadoProducto(String productoId, bool activo) async {
    try {
      await Supabase.instance.client
          .from('productos')
          .update({'activo': activo})
          .eq('id', productoId);
      
      // Actualizar el producto en la lista local
      final index = _productos.indexWhere((p) => p['id'].toString() == productoId);
      if (index != -1) {
        _productos[index]['activo'] = activo;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error al cambiar estado del producto: $e');
    }
  }

  // Obtener productos activos
  List<Map<String, dynamic>> getProductosActivos() {
    return _productos.where((producto) => producto['activo'] == true).toList();
  }

  // Obtener productos inactivos
  List<Map<String, dynamic>> getProductosInactivos() {
    return _productos.where((producto) => producto['activo'] == false).toList();
  }

  // Verificar si un producto está activo
  bool isProductoActivo(Map<String, dynamic> producto) {
    return producto['activo'] == true;
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
    bool isEditing = producto != null;

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

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle del modal
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Editar Producto' : 'Agregar Producto',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              isEditing ? 'Modifica los datos del producto' : 'Crea un nuevo producto para tu menú',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                
                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección de imagen
                        _buildImageSection(
                          urlSubida,
                          imagenLocal,
                          subiendoImagen,
                          () => seleccionarYSubirImagen(setStateDialog),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sección de información básica
                        _buildBasicInfoSection(
                          nombreController,
                          precioController,
                          descripcionController,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sección de estado (solo para edición)
                        if (isEditing) ...[
                          _buildStatusSection(producto!),
                          const SizedBox(height: 24),
                        ],
                        
                        const SizedBox(height: 80), // Espacio para botones
                      ],
                    ),
                  ),
                ),
                
                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: subiendoImagen
                              ? null
                              : () async {
                                  final nombre = nombreController.text.trim();
                                  final precio = double.tryParse(precioController.text.trim()) ?? 0;
                                  final descripcion = descripcionController.text.trim();
                                  final img = imgController.text.trim();
                                  
                                  if (nombre.isEmpty || precio <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Por favor completa todos los campos requeridos',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
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
                                      Navigator.pop(context, true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isEditing ? 'Producto actualizado correctamente' : 'Producto agregado correctamente',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: $e',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEditing ? Icons.save : Icons.add,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEditing ? 'Guardar Cambios' : 'Agregar Producto',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper para la sección de imagen
  Widget _buildImageSection(
    String? urlSubida,
    File? imagenLocal,
    bool subiendoImagen,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen del Producto',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
            ),
            child: urlSubida?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.network(
                          urlSubida!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : imagenLocal != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.file(
                          imagenLocal!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para agregar imagen',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (subiendoImagen) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Subiendo imagen...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Widget helper para la sección de información básica
  Widget _buildBasicInfoSection(
    TextEditingController nombreController,
    TextEditingController precioController,
    TextEditingController descripcionController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Producto',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        // Campo Nombre
        _buildTextField(
          controller: nombreController,
          label: 'Nombre del producto',
          hint: 'Ej: Hamburguesa Clásica',
          icon: Icons.restaurant,
          isRequired: true,
        ),
        
        const SizedBox(height: 16),
        
        // Campo Precio
        _buildTextField(
          controller: precioController,
          label: 'Precio',
          hint: '0.00',
          icon: Icons.attach_money,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          isRequired: true,
        ),
        
        const SizedBox(height: 16),
        
        // Campo Descripción
        _buildTextField(
          controller: descripcionController,
          label: 'Descripción',
          hint: 'Describe tu producto...',
          icon: Icons.description,
          maxLines: 3,
        ),
      ],
    );
  }

  // Widget helper para la sección de estado
  Widget _buildStatusSection(Map<String, dynamic> producto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del Producto',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                producto['activo'] == true ? Icons.check_circle : Icons.cancel,
                color: producto['activo'] == true ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto['activo'] == true ? 'Producto Activo' : 'Producto Inactivo',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: producto['activo'] == true ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      producto['activo'] == true 
                          ? 'Los clientes pueden ver y ordenar este producto'
                          : 'Los clientes no pueden ver este producto',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget helper para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
      ],
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