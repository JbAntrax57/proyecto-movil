import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'dart:convert'; // Para jsonDecode

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
  int _parsePrecio(dynamic precio) {
    if (precio is int) return precio;
    if (precio is String) return int.tryParse(precio) ?? 0;
    if (precio is double) return precio.toInt();
    return 0; // Valor por defecto
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
        // Obtener el carrito desde Supabase (incluye limpieza de duplicados)
        final carritoDb = await obtenerCarrito(_userEmail!);
        print('Carrito obtenido de DB: $carritoDb'); // Debug
        
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
      final carritoDb = await obtenerCarrito(_userEmail!);
      _carrito.clear();
      _carrito.addAll(carritoDb);
      notifyListeners();
      print('Carrito cargado manualmente: $_carrito'); // Debug
    } catch (error) {
      print('Error cargando carrito manualmente: $error'); // Debug
    }
  }

  // Limpia carritos duplicados para un usuario
  Future<void> _limpiarCarritosDuplicados() async {
    if (_userEmail == null || _userEmail!.isEmpty) return;
    
    try {
      // Obtener todos los carritos del usuario
      final carritos = await Supabase.instance.client
          .from('carritos')
          .select('id, updated_at')
          .eq('email', _userEmail!)
          .order('updated_at', ascending: false);
      
      if (carritos.length > 1) {
        print('Encontrados ${carritos.length} carritos para $_userEmail, limpiando duplicados...'); // Debug
        
        // Mantener solo el más reciente
        final carritoMasReciente = carritos.first;
        final carritosAEliminar = carritos.skip(1).map((c) => c['id']).toList();
        
        // Eliminar carritos duplicados
        for (final id in carritosAEliminar) {
          await Supabase.instance.client
              .from('carritos')
              .delete()
              .eq('id', id);
        }
        
        print('Carritos duplicados eliminados, manteniendo ID: ${carritoMasReciente['id']}'); // Debug
      }
    } catch (e) {
      print('Error limpiando carritos duplicados: $e');
    }
  }

  // Método público para limpiar carritos duplicados manualmente
  Future<void> limpiarCarritosDuplicados() async {
    await _limpiarCarritosDuplicados();
  }

  // Obtiene el carrito del usuario desde Supabase
  Future<List<Map<String, dynamic>>> obtenerCarrito(String email) async {
    try {
      // Primero obtener todos los carritos del usuario
      final carritos = await Supabase.instance.client
          .from('carritos')
          .select('id, carrito, updated_at')
          .eq('email', email)
          .order('updated_at', ascending: false);
      
      if (carritos.isEmpty) {
        print('No se encontró carrito para: $email'); // Debug
        return [];
      }
      
      // Si hay múltiples carritos, limpiar duplicados
      if (carritos.length > 1) {
        print('Encontrados ${carritos.length} carritos para $email, limpiando duplicados...'); // Debug
        await _limpiarCarritosDuplicados();
        // Después de limpiar, obtener el carrito más reciente
        final carritoLimpio = await Supabase.instance.client
            .from('carritos')
            .select('carrito')
            .eq('email', email)
            .single();
        return _parsearCarrito(carritoLimpio['carrito']);
      }
      
      // Si solo hay un carrito, usarlo directamente
      final data = carritos.first;
      return _parsearCarrito(data['carrito']);
      
    } catch (e) {
      print('Error obteniendo carrito: $e');
      return [];
    }
  }

  // Función auxiliar para parsear el carrito
  List<Map<String, dynamic>> _parsearCarrito(dynamic carritoData) {
    if (carritoData == null) return [];
    
    // Si carrito es una lista, la devolvemos directamente
    if (carritoData is List) {
      return List<Map<String, dynamic>>.from(carritoData);
    }
    // Si es un string JSON, lo parseamos
    if (carritoData is String) {
      try {
        final List<dynamic> parsed = jsonDecode(carritoData);
        return parsed
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (e) {
        print('Error parsing carrito JSON: $e');
        return [];
      }
    }
    return [];
  }

  // Actualiza el carrito en Supabase
  Future<void> actualizarCarrito(
    String email,
    List<Map<String, dynamic>> carrito,
  ) async {
    if (email.isEmpty) {
      print('Error: No se puede actualizar carrito sin email');
      return;
    }
    try {
      print('Actualizando carrito en DB para: $email'); // Debug
      
      // Primero limpiar carritos duplicados si existen
      await _limpiarCarritosDuplicados();
      
      // Verificar si existe un carrito para este usuario
      final carritos = await Supabase.instance.client
          .from('carritos')
          .select('id')
          .eq('email', email);
      
      if (carritos.isNotEmpty) {
        // Actualizar el carrito existente (el más reciente después de limpiar)
        await Supabase.instance.client
            .from('carritos')
            .update({
              'carrito': carrito,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('email', email);
        print('Carrito existente actualizado en DB'); // Debug
      } else {
        // Crear un nuevo carrito
        await Supabase.instance.client
            .from('carritos')
            .insert({
              'email': email,
              'carrito': carrito,
              'updated_at': DateTime.now().toIso8601String(),
            });
        print('Nuevo carrito creado en DB'); // Debug
      }
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
    actualizarCarrito(_userEmail!, _carrito);
    notifyListeners();
  }

  void eliminarProducto(int index) {
    if (_userEmail == null || _userEmail!.isEmpty) {
      print('Error: No se puede eliminar producto sin email de usuario');
      return;
    }
    _carrito.removeAt(index);
    actualizarCarrito(_userEmail!, _carrito);
    notifyListeners();
  }

  void limpiarCarrito() {
    if (_userEmail == null || _userEmail!.isEmpty) {
      print('Error: No se puede limpiar carrito sin email de usuario');
      return;
    }
    _carrito.clear();
    actualizarCarrito(_userEmail!, _carrito);
    notifyListeners();
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

      actualizarCarrito(_userEmail!, _carrito);
      notifyListeners();
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
