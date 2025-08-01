import 'package:flutter/material.dart';
import '../../../data/models/direccion_model.dart';
import '../../../data/services/direcciones_service.dart';

class DireccionesProvider extends ChangeNotifier {
  
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
  Future<void> cargarDirecciones(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      print('🔍 DireccionesProvider.cargarDirecciones() - User ID: $userId');
      final direccionesData = await DireccionesService.obtenerDirecciones(userId);
      _direcciones = direccionesData.map((data) => DireccionModel.fromMap(data)).toList();
      
      print('🔍 DireccionesProvider.cargarDirecciones() - Direcciones cargadas: ${_direcciones.length}');
      
      // Si no hay dirección seleccionada, seleccionar la predeterminada
      if (_direccionSeleccionada == null && _direcciones.isNotEmpty) {
        final predeterminada = _direcciones.firstWhere(
          (d) => d.esPredeterminada,
          orElse: () => _direcciones.first,
        );
        _direccionSeleccionada = predeterminada;
      }
    } catch (e) {
      print('❌ Error cargando direcciones: $e');
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
      final nuevaDireccionData = await DireccionesService.crearDireccion(
        userEmail: direccion.usuarioId,
        nombre: direccion.nombre,
        direccion: direccion.direccion,
        latitud: direccion.latitud ?? 0.0,
        longitud: direccion.longitud ?? 0.0,
        instrucciones: direccion.referencias,
        esPredeterminada: direccion.esPredeterminada,
      );
      if (nuevaDireccionData != null) {
        final nuevaDireccion = DireccionModel.fromMap(nuevaDireccionData);
        _direcciones.add(nuevaDireccion);
        
        // Si es la primera dirección, seleccionarla
        if (_direcciones.length == 1) {
          _direccionSeleccionada = nuevaDireccion;
        }
        
        notifyListeners();
        return true;
      } else {
        return false;
      }
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
      final success = await DireccionesService.actualizarDireccion(
        direccionId: direccion.id!,
        nombre: direccion.nombre,
        direccion: direccion.direccion,
        latitud: direccion.latitud,
        longitud: direccion.longitud,
        instrucciones: direccion.referencias,
        esPredeterminada: direccion.esPredeterminada,
      );
      
      if (success) {
        // Actualizar en la lista local
        final index = _direcciones.indexWhere((d) => d.id == direccion.id);
        if (index != -1) {
          _direcciones[index] = direccion;
          
          // Si es la dirección seleccionada, actualizarla también
          if (_direccionSeleccionada?.id == direccion.id) {
            _direccionSeleccionada = direccion;
          }
        }
      }
      
      notifyListeners();
      return success;
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
      await DireccionesService.eliminarDireccion(direccionId);
      
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
  Future<bool> marcarComoPredeterminada(String direccionId, String userEmail) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await DireccionesService.establecerPredeterminada(direccionId);
      
      if (success) {
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
      }
      
      notifyListeners();
      return success;
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