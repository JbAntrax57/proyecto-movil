import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuProvider extends ChangeNotifier {
  // Estado de carga
  bool _isLoading = true;
  String? _error;

  // Datos
  List<Map<String, dynamic>> _productos = [];
  String _searchText = '';
  String? _restauranteId;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get productos => List.unmodifiable(_productos);
  String get searchText => _searchText;
  String? get restauranteId => _restauranteId;

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

  // Determina si el producto es nuevo (menos de 1 mes desde created_at)
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

  // Obtiene el menú del restaurante desde Supabase
  Future<List<Map<String, dynamic>>> obtenerMenu(String restauranteId) async {
    try {
      final data = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('restaurante_id', restauranteId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error al obtener menú: $e');
      return [];
    }
  }

  // Cargar productos del restaurante
  Future<void> cargarProductos(String restauranteId) async {
    if (_restauranteId == restauranteId && _productos.isNotEmpty) {
      return; // Ya están cargados para este restaurante
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _restauranteId = restauranteId;
    });

    try {
      final productosData = await obtenerMenu(restauranteId);
      setState(() {
        _productos = productosData;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar productos: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Aplicar filtro de búsqueda a los productos
  List<Map<String, dynamic>> getProductosFiltrados() {
    if (_searchText.trim().isEmpty) return _productos;
    
    final busqueda = _searchText.toLowerCase();
    return _productos.where((producto) {
      final nombre = (producto['nombre']?.toString() ?? '').toLowerCase();
      final descripcion = (producto['descripcion']?.toString() ?? '').toLowerCase();
      return nombre.contains(busqueda) || descripcion.contains(busqueda);
    }).toList();
  }

  // Actualizar texto de búsqueda
  void setSearchText(String text) {
    if (_searchText != text) {
      _searchText = text;
      notifyListeners();
    }
  }

  // Limpiar búsqueda
  void limpiarBusqueda() {
    _searchText = '';
    notifyListeners();
  }

  // Refrescar productos
  Future<void> refrescarProductos() async {
    if (_restauranteId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    await cargarProductos(_restauranteId!);
  }

  // Método helper para actualizar el estado
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Limpiar datos (útil para cambiar de restaurante o logout)
  void limpiarDatos() {
    _productos = [];
    _searchText = '';
    _restauranteId = null;
    _isLoading = true;
    _error = null;
    notifyListeners();
  }
} 