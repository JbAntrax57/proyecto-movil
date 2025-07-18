import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _carritoStream = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userEmail)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null || data['carrito'] == null) return <Map<String, dynamic>>[];
      final raw = data['carrito'] as List<dynamic>;
      return raw.map((e) => Map<String, dynamic>.from(e)).toList();
    });
    _carritoStream!.listen((carritoDb) {
      _carrito
        ..clear()
        ..addAll(carritoDb);
      notifyListeners();
    });
  }

  Future<void> _updateCarritoDb() async {
    if (_userEmail == null) return;
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userEmail)
        .update({'carrito': _carrito});
  }

  void agregarProducto(Map<String, dynamic> producto) {
    final index = _carrito.indexWhere((item) => item['nombre'] == producto['nombre']);
    if (index != -1) {
      _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + (producto['cantidad'] ?? 1);
    } else {
      _carrito.add(Map<String, dynamic>.from(producto));
    }
    _updateCarritoDb();
    notifyListeners();
  }

  void eliminarProducto(int index) {
    _carrito.removeAt(index);
    _updateCarritoDb();
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    _updateCarritoDb();
    notifyListeners();
  }

  void modificarCantidad(int index, int delta) {
    if (index >= 0 && index < _carrito.length) {
      _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + delta;
      if (_carrito[index]['cantidad'] < 1) {
        _carrito[index]['cantidad'] = 1;
      }
      _updateCarritoDb();
      notifyListeners();
    }
  }
} 