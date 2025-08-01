import 'package:flutter/material.dart';
import '../../../data/services/negocios_service.dart';

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

  // Obtiene las categorías desde el backend
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      return await NegociosService.obtenerCategorias();
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      return [];
    }
  }

  // Obtiene los negocios desde el backend, filtrando por categoría si aplica
  Future<List<Map<String, dynamic>>> obtenerNegocios({
    String? categoriaId,
  }) async {
    try {
      if (categoriaId != null && categoriaId.isNotEmpty) {
        // Si hay filtro de categoría, obtener negocios por categoría
        return await NegociosService.obtenerNegociosPorCategoria(categoriaId);
      } else {
        // Si no hay filtro, obtener todos los negocios
        return await NegociosService.obtenerNegocios();
      }
    } catch (e) {
      print('❌ Error al obtener negocios: $e');
      return [];
    }
  }

  // Cargar categorías desde el backend
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

  // Cargar todos los negocios desde el backend
  Future<void> cargarNegocios() async {
    if (_todosLosNegocios.isNotEmpty) return; // Ya están cargados

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar todos los negocios desde el backend
      final data = await NegociosService.obtenerNegocios();
      
      print('📊 cargarNegocios - Datos obtenidos: ${data.length} negocios');
      if (data.isNotEmpty) {
        print('📊 cargarNegocios - Primer negocio: ${data.first}');
      }
      
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
    print('🔍 getRestantes - Total negocios: ${negocios.length}');
    print('🔍 getRestantes - Categoría seleccionada: $_categoriaSeleccionada');
    
    final noDestacados = negocios.where((n) => n['destacado'] != true).toList();
    print('🔍 getRestantes - No destacados: ${noDestacados.length}');
    
    if (_categoriaSeleccionada != null && _categoriaSeleccionada!.isNotEmpty) {
      final filtrados = noDestacados.where((n) {
        // Verificar si el negocio tiene categorías y si alguna coincide con la seleccionada
        final categorias = n['negocios_categorias'] as List<dynamic>?;
        print('🔍 Negocio ${n['nombre']} - Categorías: $categorias');
        
        if (categorias != null && categorias.isNotEmpty) {
          final tieneCategoria = categorias.any((cat) {
            final categoriaNombre = cat['categorias_principales']?['nombre']?.toString();
            print('🔍 Comparando: "$categoriaNombre" con "$_categoriaSeleccionada"');
            return categoriaNombre == _categoriaSeleccionada;
          });
          print('🔍 Negocio ${n['nombre']} - Tiene categoría: $tieneCategoria');
          return tieneCategoria;
        }
        return false;
      }).toList();
      
      print('🔍 getRestantes - Filtrados por categoría: ${filtrados.length}');
      return filtrados;
    }
    
    print('🔍 getRestantes - Sin filtro de categoría: ${noDestacados.length}');
    return noDestacados;
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
    print('📊 getRestantesFiltrados - Llamado');
    final restantes = getRestantes(_todosLosNegocios);
    print('📊 getRestantesFiltrados - Restantes sin búsqueda: ${restantes.length}');
    final conBusqueda = aplicarFiltroBusqueda(restantes);
    print('📊 getRestantesFiltrados - Con búsqueda: ${conBusqueda.length}');
    return conBusqueda;
  }

  // Actualizar categoría seleccionada
  void setCategoriaSeleccionada(String? categoria) {
    print('🔄 setCategoriaSeleccionada - Categoría anterior: $_categoriaSeleccionada');
    print('🔄 setCategoriaSeleccionada - Nueva categoría: $categoria');
    
    if (_categoriaSeleccionada != categoria) {
      _categoriaSeleccionada = categoria;
      print('🔄 setCategoriaSeleccionada - Categoría actualizada, notificando...');
      notifyListeners();
    } else {
      print('🔄 setCategoriaSeleccionada - No hay cambios, no se notifica');
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

    // NO limpiar filtros para mantener la categoría seleccionada
    // limpiarFiltros();
  }

  // Refrescar datos manteniendo filtros actuales
  Future<void> refrescarDatosConFiltros() async {
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