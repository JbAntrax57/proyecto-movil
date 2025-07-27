import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NegociosProvider extends ChangeNotifier {
  // Estado de carga
  bool _isLoading = true;
  bool _isLoadingCategorias = true;
  String? _error;

  // Datos
  List<Map<String, dynamic>> _todosLosNegocios = [];
  List<Map<String, dynamic>> _categorias = [];
  
  // Filtros y búsqueda
  String? _categoriaSeleccionada;
  String _searchText = '';

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingCategorias => _isLoadingCategorias;
  String? get error => _error;
  List<Map<String, dynamic>> get todosLosNegocios => List.unmodifiable(_todosLosNegocios);
  List<Map<String, dynamic>> get categorias => List.unmodifiable(_categorias);
  String? get categoriaSeleccionada => _categoriaSeleccionada;
  String get searchText => _searchText;

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

  // Obtiene las categorías desde Supabase
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      final data = await Supabase.instance.client
          .from('categorias_principales')
          .select()
          .eq('activo', true)
          .order('nombre');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      return [];
    }
  }

  // Obtiene los negocios desde Supabase, filtrando por categoría si aplica
  Future<List<Map<String, dynamic>>> obtenerNegocios({
    String? categoriaId,
  }) async {
    try {
      if (categoriaId != null && categoriaId.isNotEmpty) {
        // Si hay filtro de categoría, usar la relación inner con filtro
        final data = await Supabase.instance.client
          .from('negocios')
          .select('*, negocios_categorias!inner(categoria_id)')
          .eq('negocios_categorias.categoria_id', categoriaId)
          .order('nombre');
        return List<Map<String, dynamic>>.from(data);
      } else {
        // Si no hay filtro, obtener todos los negocios
        final data = await Supabase.instance.client
          .from('negocios')
          .select('*')
          .order('nombre');
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      print('❌ Error al obtener negocios: $e');
      return [];
    }
  }

  // Cargar categorías desde Supabase
  Future<void> cargarCategorias() async {
    if (_categorias.isNotEmpty) return; // Ya están cargadas

    setState(() {
      _isLoadingCategorias = true;
    });

    try {
      final categoriasData = await obtenerCategorias();
      setState(() {
        _categorias = categoriasData;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      print('❌ Error al cargar categorías: $e');
      setState(() {
        _isLoadingCategorias = false;
      });
    }
  }

  // Cargar todos los negocios una sola vez con sus categorías
  Future<void> cargarNegocios() async {
    if (_todosLosNegocios.isNotEmpty) return; // Ya están cargados

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar todos los negocios con sus categorías para poder filtrar correctamente
      final data = await Supabase.instance.client
          .from('negocios')
          .select('*, negocios_categorias(categoria_id, categorias_principales(nombre))')
          .order('nombre');
      setState(() {
        _todosLosNegocios = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar negocios: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Devuelve los negocios destacados (campo 'destacado' == true) para el slider
  List<Map<String, dynamic>> getDestacados(List<Map<String, dynamic>> negocios) {
    return negocios.where((n) => n['destacado'] == true).toList();
  }

  // Devuelve el resto de negocios para la lista principal, aplicando filtro de categoría
  List<Map<String, dynamic>> getRestantes(List<Map<String, dynamic>> negocios) {
    final noDestacados = negocios.where((n) => n['destacado'] != true);
    if (_categoriaSeleccionada != null) {
      return noDestacados
          .where((n) {
            // Verificar si el negocio tiene categorías y si alguna coincide con la seleccionada
            final categorias = n['negocios_categorias'] as List<dynamic>?;
            if (categorias != null && categorias.isNotEmpty) {
              return categorias.any((cat) {
                final categoriaNombre = cat['categorias_principales']?['nombre']?.toString();
                return categoriaNombre == _categoriaSeleccionada;
              });
            }
            return false;
          })
          .toList();
    }
    return noDestacados.toList();
  }

  // Aplicar filtro de búsqueda a una lista de negocios
  List<Map<String, dynamic>> aplicarFiltroBusqueda(List<Map<String, dynamic>> negocios) {
    final filtro = _searchText.trim().toLowerCase();
    if (filtro.isEmpty) return negocios;
    
    return negocios.where((n) =>
        (n['nombre']?.toString() ?? '').toLowerCase().contains(filtro)
    ).toList();
  }

  // Obtener negocios destacados con filtro de búsqueda aplicado
  List<Map<String, dynamic>> getDestacadosFiltrados() {
    final destacados = getDestacados(_todosLosNegocios);
    return aplicarFiltroBusqueda(destacados);
  }

  // Obtener negocios restantes con filtro de búsqueda aplicado
  List<Map<String, dynamic>> getRestantesFiltrados() {
    final restantes = getRestantes(_todosLosNegocios);
    return aplicarFiltroBusqueda(restantes);
  }

  // Actualizar categoría seleccionada
  void setCategoriaSeleccionada(String? categoria) {
    if (_categoriaSeleccionada != categoria) {
      _categoriaSeleccionada = categoria;
      notifyListeners();
    }
  }

  // Actualizar texto de búsqueda
  void setSearchText(String text) {
    if (_searchText != text) {
      _searchText = text;
      notifyListeners();
    }
  }

  // Limpiar filtros
  void limpiarFiltros() {
    _categoriaSeleccionada = null;
    _searchText = '';
    notifyListeners();
  }

  // Refrescar todos los datos
  Future<void> refrescarDatos() async {
    // Limpiar cache para forzar recarga
    _todosLosNegocios = [];
    _categorias = [];
    
    // Recargar negocios
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await cargarNegocios();

    // Recargar categorías
    setState(() {
      _isLoadingCategorias = true;
    });
    await cargarCategorias();

    // Limpiar filtros
    limpiarFiltros();
  }

  // Método helper para actualizar el estado
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Limpiar datos (útil para logout)
  void limpiarDatos() {
    _todosLosNegocios = [];
    _categorias = [];
    _categoriaSeleccionada = null;
    _searchText = '';
    _isLoading = true;
    _isLoadingCategorias = true;
    _error = null;
    notifyListeners();
  }
} 