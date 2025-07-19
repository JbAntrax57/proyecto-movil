import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase

class CarritoProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _carrito = [];
  String? _userEmail;
  String? _restauranteId; // ID del restaurante asociado al usuario dueño
  Stream<List<Map<String, dynamic>>>? _carritoStream;
  Stream<List<Map<String, dynamic>>>? get carritoStream => _carritoStream;

  List<Map<String, dynamic>> get carrito => List.unmodifiable(_carrito);

  String? get userEmail => _userEmail;
  String? get restauranteId => _restauranteId;

  void setUserEmail(String email) {
    if (_userEmail != email) {
      _userEmail = email;
      _listenToCarrito();
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
      _carrito.clear();
      _carrito.addAll(carritoDb);
      notifyListeners();
    });
  }

  // Obtiene el carrito del usuario desde Supabase
  Future<List<Map<String, dynamic>>> obtenerCarrito(String email) async {
    final data = await Supabase.instance.client
        .from('carritos')
        .select()
        .eq('email', email);
    if (data.isEmpty) return [];
    return List<Map<String, dynamic>>.from(data);
  }
  
  // Actualiza el carrito en Supabase
  Future<void> actualizarCarrito(String email, List<Map<String, dynamic>> carrito) async {
    await Supabase.instance.client
        .from('carritos')
        .upsert({'email': email, 'carrito': carrito});
  }

  void agregarProducto(Map<String, dynamic> producto) {
    final index = _carrito.indexWhere((item) => item['nombre'] == producto['nombre']);
    if (index != -1) {
      _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + (producto['cantidad'] ?? 1);
    } else {
      _carrito.add(Map<String, dynamic>.from(producto));
    }
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
      _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + delta;
      if (_carrito[index]['cantidad'] < 1) {
        _carrito[index]['cantidad'] = 1;
      }
      actualizarCarrito(_userEmail!, _carrito);
      notifyListeners();
    }
  }
} 