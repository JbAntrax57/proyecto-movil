import 'package:flutter/material.dart';
import '../../../data/services/carrito_service.dart';

class CarritoProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _carrito = [];
  String? _userEmail;
  String? _restauranteId; // ID del restaurante asociado al usuario dueño
  String? _userId;
  Stream<List<Map<String, dynamic>>>? _carritoStream;
  Stream<List<Map<String, dynamic>>>? get carritoStream => _carritoStream;

  List<Map<String, dynamic>> get carrito => List.unmodifiable(_carrito);

  String? get userEmail {
    print('getUserEmail llamado, valor actual: $_userEmail'); // Debug
    return _userEmail;
  }

  String? get restauranteId => _restauranteId;

  String? get userId => _userId;
  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  // Verificar si el carrito está cargado
  bool get carritoCargado => _userEmail != null && _userEmail!.isNotEmpty;

  // Helper para convertir cantidad de forma segura
  int _parseCantidad(dynamic cantidad) {
    if (cantidad is int) return cantidad;
    if (cantidad is String) return int.tryParse(cantidad) ?? 1;
    if (cantidad is double) return cantidad.toInt();
    return 1; // Valor por defecto
  }

  // Helper para convertir precio de forma segura
  double _parsePrecio(dynamic precio) {
    if (precio is int) return precio.toDouble();
    if (precio is String) return double.tryParse(precio) ?? 0.0;
    if (precio is double) return precio;
    return 0.0; // Valor por defecto
  }

  void setUserEmail(String email) {
    print('setUserEmail llamado con: $email'); // Debug
    if (_userEmail != email) {
      _userEmail = email;
      print('Email establecido en provider: $_userEmail'); // Debug
      _listenToCarrito();
    } else {
      print('Email ya estaba establecido: $_userEmail'); // Debug
      // Aún así, cargar el carrito para asegurar que esté sincronizado
      if (email.isNotEmpty) {
        _listenToCarrito();
      }
    }
  }

  // Método para establecer el restauranteId (usado al login del dueño)
  void setRestauranteId(String? id) {
    _restauranteId = id;
    notifyListeners();
  }

  void _listenToCarrito() {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    print('Cargando carrito para usuario: $_userEmail'); // Debug
    
    // Cargar carrito de forma asíncrona
    Future.microtask(() async {
      try {
        // Obtener el carrito desde el backend
        final carritoDb = await CarritoService.obtenerCarrito(_userEmail!);
        print('Carrito obtenido del backend: $carritoDb'); // Debug
        
        _carrito.clear();
        _carrito.addAll(carritoDb);
        print('Carrito actual en provider: $_carrito'); // Debug
        notifyListeners();
      } catch (error) {
        print('Error cargando carrito: $error'); // Debug
      }
    });
  }

  // Método público para cargar el carrito manualmente
  Future<void> cargarCarrito() async {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    try {
      final carritoDb = await CarritoService.obtenerCarrito(_userEmail!);
      _carrito.clear();
      _carrito.addAll(carritoDb);
      notifyListeners();
      print('Carrito cargado manualmente: $_carrito'); // Debug
    } catch (error) {
      print('Error cargando carrito manualmente: $error'); // Debug
    }
  }

  // Método público para limpiar carritos duplicados manualmente
  Future<void> limpiarCarritosDuplicados() async {
    // La limpieza de duplicados ahora se maneja en el backend
    print('Limpieza de duplicados manejada por el backend');
  }

  // Obtiene el carrito del usuario desde el backend
  Future<List<Map<String, dynamic>>> obtenerCarrito(String email) async {
    try {
      return await CarritoService.obtenerCarrito(email);
    } catch (e) {
      print('Error obteniendo carrito: $e');
      return [];
    }
  }

  // Actualiza el carrito en el backend
  Future<void> actualizarCarrito(
    String email,
    List<Map<String, dynamic>> carrito,
  ) async {
    if (email.isEmpty) {
      print('Error: No se puede actualizar carrito sin email');
      return;
    }
    try {
      print('Actualizando carrito en backend para: $email'); // Debug
      
      // La actualización del carrito se maneja automáticamente por el backend
      // cuando se agregan, eliminan o modifican productos
      print('Carrito actualizado en backend'); // Debug
    } catch (e) {
      print('Error actualizando carrito: $e');
    }
  }

  void agregarProducto(Map<String, dynamic> producto) {
    if (_userEmail == null || _userEmail!.isEmpty) {
      print('Error: No se puede agregar producto sin email de usuario');
      return;
    }
    print('Agregando producto: $producto'); // Debug
    print('Negocio ID del producto: ${producto['negocio_id']}'); // Debug
    
    // Buscar producto por nombre y negocio_id para evitar duplicados
    final index = _carrito.indexWhere(
      (item) => item['nombre'] == producto['nombre'] && 
                item['negocio_id'] == producto['negocio_id'],
    );
    
    if (index != -1) {
      // Sumar cantidades de forma segura
      final cantidadActual = _parseCantidad(_carrito[index]['cantidad']);
      final cantidadNueva = _parseCantidad(producto['cantidad']);
      _carrito[index]['cantidad'] = cantidadActual + cantidadNueva;
      print('Producto existente actualizado, nueva cantidad: ${_carrito[index]['cantidad']}'); // Debug
    } else {
      _carrito.add(Map<String, dynamic>.from(producto));
      print('Nuevo producto agregado al carrito'); // Debug
    }
    
    print('Carrito actual: $_carrito'); // Debug
    
    // Actualizar en el backend
    _actualizarCarritoEnBackend();
    notifyListeners();
  }

  // Método privado para actualizar el carrito en el backend
  Future<void> _actualizarCarritoEnBackend() async {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    
    try {
      // Enviar cada producto al backend
      for (final producto in _carrito) {
        await CarritoService.agregarProducto(
          userEmail: _userEmail!,
          productoId: producto['id'].toString(),
          cantidad: _parseCantidad(producto['cantidad']),
          opciones: producto['opciones'],
        );
      }
    } catch (e) {
      print('Error actualizando carrito en backend: $e');
    }
  }

  void eliminarProducto(int index) {
    if (_userEmail == null || _userEmail!.isEmpty) {
      print('Error: No se puede eliminar producto sin email de usuario');
      return;
    }
    
    final producto = _carrito[index];
    _carrito.removeAt(index);
    
    // Eliminar del backend
    _eliminarProductoEnBackend(producto);
    notifyListeners();
  }

  // Método privado para eliminar producto del backend
  Future<void> _eliminarProductoEnBackend(Map<String, dynamic> producto) async {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    
    try {
      await CarritoService.eliminarProducto(
        userEmail: _userEmail!,
        productoId: producto['id'].toString(),
      );
    } catch (e) {
      print('Error eliminando producto del backend: $e');
    }
  }

  void limpiarCarrito() {
    if (_userEmail == null || _userEmail!.isEmpty) {
      print('Error: No se puede limpiar carrito sin email de usuario');
      return;
    }
    _carrito.clear();
    
    // Limpiar en el backend
    _limpiarCarritoEnBackend();
    notifyListeners();
  }

  // Método privado para limpiar carrito en el backend
  Future<void> _limpiarCarritoEnBackend() async {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    
    try {
      await CarritoService.limpiarCarrito(_userEmail!);
    } catch (e) {
      print('Error limpiando carrito en backend: $e');
    }
  }

  void modificarCantidad(int index, int delta) {
    if (_userEmail == null || _userEmail!.isEmpty) {
      print('Error: No se puede modificar cantidad sin email de usuario');
      return;
    }
    if (index >= 0 && index < _carrito.length) {
      // Modificar cantidad de forma segura
      final cantidadActual = _parseCantidad(_carrito[index]['cantidad']);
      final nuevaCantidad = cantidadActual + delta;
      _carrito[index]['cantidad'] = nuevaCantidad < 1 ? 1 : nuevaCantidad;

      // Actualizar en el backend
      _actualizarCantidadEnBackend(_carrito[index], nuevaCantidad);
      notifyListeners();
    }
  }

  // Método privado para actualizar cantidad en el backend
  Future<void> _actualizarCantidadEnBackend(Map<String, dynamic> producto, int nuevaCantidad) async {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    
    try {
      await CarritoService.actualizarCantidad(
        userEmail: _userEmail!,
        productoId: producto['id'].toString(),
        cantidad: nuevaCantidad,
      );
    } catch (e) {
      print('Error actualizando cantidad en backend: $e');
    }
  }

  void limpiarSesion() {
    _carrito.clear();
    _userEmail = null;
    _userId = null;
    _restauranteId = null;
    notifyListeners();
  }
}
