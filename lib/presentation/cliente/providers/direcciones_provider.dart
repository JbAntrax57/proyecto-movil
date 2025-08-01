import 'package:flutter/material.dart';
import '../../../data/models/direccion_model.dart';
import '../../../data/services/direcciones_service.dart';

class DireccionesProvider extends ChangeNotifier {
  final DireccionesService _direccionesService = DireccionesService();
  
  List<DireccionModel> _direcciones = [];
  DireccionModel? _direccionSeleccionada;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DireccionModel> get direcciones => _direcciones;
  DireccionModel? get direccionSeleccionada => _direccionSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener todas las direcciones de un usuario
  Future<void> cargarDirecciones(String usuarioId) async {
    _setLoading(true);
    _error = null;

    try {
      _direcciones = await _direccionesService.obtenerDirecciones(usuarioId);
      
      // Si no hay dirección seleccionada, seleccionar la predeterminada
      if (_direccionSeleccionada == null && _direcciones.isNotEmpty) {
        final predeterminada = _direcciones.firstWhere(
          (d) => d.esPredeterminada,
          orElse: () => _direcciones.first,
        );
        _direccionSeleccionada = predeterminada;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Crear una nueva dirección
  Future<bool> crearDireccion(DireccionModel direccion) async {
    _setLoading(true);
    _error = null;

    try {
      final nuevaDireccion = await _direccionesService.crearDireccion(direccion);
      _direcciones.add(nuevaDireccion);
      
      // Si es la primera dirección, seleccionarla
      if (_direcciones.length == 1) {
        _direccionSeleccionada = nuevaDireccion;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar una dirección existente
  Future<bool> actualizarDireccion(DireccionModel direccion) async {
    _setLoading(true);
    _error = null;

    try {
      final direccionActualizada = await _direccionesService.actualizarDireccion(direccion);
      
      final index = _direcciones.indexWhere((d) => d.id == direccion.id);
      if (index != -1) {
        _direcciones[index] = direccionActualizada;
        
        // Si es la dirección seleccionada, actualizarla también
        if (_direccionSeleccionada?.id == direccion.id) {
          _direccionSeleccionada = direccionActualizada;
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar una dirección
  Future<bool> eliminarDireccion(String direccionId) async {
    _setLoading(true);
    _error = null;

    try {
      await _direccionesService.eliminarDireccion(direccionId);
      
      _direcciones.removeWhere((d) => d.id == direccionId);
      
      // Si se eliminó la dirección seleccionada, seleccionar otra
      if (_direccionSeleccionada?.id == direccionId) {
        _direccionSeleccionada = _direcciones.isNotEmpty ? _direcciones.first : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Marcar una dirección como predeterminada
  Future<bool> marcarComoPredeterminada(String direccionId, String usuarioId) async {
    _setLoading(true);
    _error = null;

    try {
      await _direccionesService.marcarComoPredeterminada(direccionId, usuarioId);
      
      // Actualizar el estado local
      for (int i = 0; i < _direcciones.length; i++) {
        _direcciones[i] = _direcciones[i].copyWith(
          esPredeterminada: _direcciones[i].id == direccionId,
        );
      }
      
      // Reordenar la lista (predeterminada primero)
      _direcciones.sort((a, b) {
        if (a.esPredeterminada && !b.esPredeterminada) return -1;
        if (!a.esPredeterminada && b.esPredeterminada) return 1;
        return b.fechaCreacion.compareTo(a.fechaCreacion);
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar una dirección
  void seleccionarDireccion(DireccionModel direccion) {
    _direccionSeleccionada = direccion;
    notifyListeners();
  }

  // Obtener la dirección predeterminada
  DireccionModel? get direccionPredeterminada {
    try {
      return _direcciones.firstWhere((d) => d.esPredeterminada);
    } catch (e) {
      return _direcciones.isNotEmpty ? _direcciones.first : null;
    }
  }

  // Limpiar el estado
  void limpiarEstado() {
    _direcciones = [];
    _direccionSeleccionada = null;
    _error = null;
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
} 