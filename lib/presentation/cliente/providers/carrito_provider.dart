import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'dart:convert'; // Para jsonDecode

class CarritoProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _carrito = [];
  String? _userEmail;
  String? _restauranteId; // ID del restaurante asociado al usuario dueño
  Stream<List<Map<String, dynamic>>>? _carritoStream;
  Stream<List<Map<String, dynamic>>>? get carritoStream => _carritoStream;

  List<Map<String, dynamic>> get carrito => List.unmodifiable(_carrito);

  String? get userEmail {
    print('getUserEmail llamado, valor actual: $_userEmail'); // Debug
    return _userEmail;
  }
  String? get restauranteId => _restauranteId;

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
    }
  }

  // Método para establecer el restauranteId (usado al login del dueño)
  void setRestauranteId(String? id) {
    _restauranteId = id;
    notifyListeners();
  }

  void _listenToCarrito() {
    if (_userEmail == null) return;
    // Obtener el carrito inicial desde Supabase
    obtenerCarrito(_userEmail!).then((carritoDb) {
      print('Carrito obtenido de DB: $carritoDb'); // Debug
      _carrito.clear();
      _carrito.addAll(carritoDb);
      print('Carrito actual en provider: $_carrito'); // Debug
      notifyListeners();
    }).catchError((error) {
      print('Error cargando carrito: $error'); // Debug
    });
  }

  // Obtiene el carrito del usuario desde Supabase
  Future<List<Map<String, dynamic>>> obtenerCarrito(String email) async {
    try {
      final data = await Supabase.instance.client
          .from('carritos')
          .select('carrito')
          .eq('email', email)
          .single();
      
      if (data != null && data['carrito'] != null) {
        // Si carrito es una lista, la devolvemos directamente
        if (data['carrito'] is List) {
          return List<Map<String, dynamic>>.from(data['carrito']);
        }
        // Si es un string JSON, lo parseamos
        if (data['carrito'] is String) {
          try {
            final List<dynamic> parsed = jsonDecode(data['carrito']);
            return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
          } catch (e) {
            print('Error parsing carrito JSON: $e');
            return [];
          }
        }
      }
      return [];
    } catch (e) {
      print('Error obteniendo carrito: $e');
      return [];
    }
  }
  
  // Actualiza el carrito en Supabase
  Future<void> actualizarCarrito(String email, List<Map<String, dynamic>> carrito) async {
    try {
      await Supabase.instance.client
          .from('carritos')
          .upsert({
            'email': email, 
            'carrito': carrito,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error actualizando carrito: $e');
    }
  }

  void agregarProducto(Map<String, dynamic> producto) {
    print('Agregando producto: $producto'); // Debug
    print('Negocio ID del producto: ${producto['negocio_id']}'); // Debug
    final index = _carrito.indexWhere((item) => item['nombre'] == producto['nombre']);
    if (index != -1) {
      // Sumar cantidades de forma segura
      final cantidadActual = _parseCantidad(_carrito[index]['cantidad']);
      final cantidadNueva = _parseCantidad(producto['cantidad']);
      _carrito[index]['cantidad'] = cantidadActual + cantidadNueva;
      print('Producto existente, nueva cantidad: ${_carrito[index]['cantidad']}'); // Debug
    } else {
      _carrito.add(Map<String, dynamic>.from(producto));
      print('Producto nuevo agregado'); // Debug
    }
    print('Carrito después de agregar: $_carrito'); // Debug
    actualizarCarrito(_userEmail!, _carrito);
    notifyListeners();
  }

  void eliminarProducto(int index) {
    _carrito.removeAt(index);
    actualizarCarrito(_userEmail!, _carrito);
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    actualizarCarrito(_userEmail!, _carrito);
    notifyListeners();
  }

  void modificarCantidad(int index, int delta) {
    if (index >= 0 && index < _carrito.length) {
      // Modificar cantidad de forma segura
      final cantidadActual = _parseCantidad(_carrito[index]['cantidad']);
      final nuevaCantidad = cantidadActual + delta;
      _carrito[index]['cantidad'] = nuevaCantidad < 1 ? 1 : nuevaCantidad;
      
      actualizarCarrito(_userEmail!, _carrito);
      notifyListeners();
    }
  }
} 