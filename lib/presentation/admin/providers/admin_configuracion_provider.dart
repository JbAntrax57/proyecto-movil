import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminConfiguracionProvider extends ChangeNotifier {
  // Estado de carga
  bool _isLoading = false;
  String? _error;
  
  // Datos de estadísticas
  Map<String, dynamic> _estadisticas = {};
  
  // Lista de dueños con puntos
  List<Map<String, dynamic>> _duenosPuntos = [];
  
  // Lista de notificaciones
  List<Map<String, dynamic>> _notificaciones = [];
  
  // Configuración de puntos
  int _puntosPorPedido = 2;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get estadisticas => _estadisticas;
  List<Map<String, dynamic>> get duenosPuntos => _duenosPuntos;
  List<Map<String, dynamic>> get notificaciones => _notificaciones;
  int get puntosPorPedido => _puntosPorPedido;

  // Inicializar datos
  Future<void> inicializarDatos() async {
    await cargarEstadisticas();
    await cargarDuenosPuntos();
    await cargarNotificaciones();
  }

  // Cargar estadísticas
  Future<void> cargarEstadisticas() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await Supabase.instance.client
          .rpc('obtener_estadisticas_puntos');
      
      if (result != null && result.isNotEmpty) {
        _estadisticas = result[0];
      } else {
        _estadisticas = {
          'total_duenos': 0,
          'duenos_con_puntos': 0,
          'duenos_sin_puntos': 0,
          'total_puntos_asignados': 0,
          'total_puntos_consumidos': 0,
          'total_puntos_disponibles': 0,
        };
      }
    } catch (e) {
      _setError('Error al cargar estadísticas: $e');
      _estadisticas = {
        'total_duenos': 0,
        'duenos_con_puntos': 0,
        'duenos_sin_puntos': 0,
        'total_puntos_asignados': 0,
        'total_puntos_consumidos': 0,
        'total_puntos_disponibles': 0,
      };
    } finally {
      _setLoading(false);
    }
  }

  // Cargar dueños con puntos
  Future<void> cargarDuenosPuntos() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await Supabase.instance.client
          .from('dashboard_puntos')
          .select('*')
          .order('puntos_disponibles', ascending: false);
      
      _duenosPuntos = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      _setError('Error al cargar dueños con puntos: $e');
      _duenosPuntos = [];
    } finally {
      _setLoading(false);
    }
  }

  // Cargar notificaciones
  Future<void> cargarNotificaciones() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await Supabase.instance.client
          .from('notificaciones_sistema')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);
      
      _notificaciones = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      _setError('Error al cargar notificaciones: $e');
      _notificaciones = [];
    } finally {
      _setLoading(false);
    }
  }

  // Asignar puntos a un dueño
  Future<void> asignarPuntos(String duenoId, int puntos, String tipo, String motivo) async {
    _setLoading(true);
    _setError(null);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _setError('Usuario no autenticado');
        return;
      }

      await Supabase.instance.client
          .rpc('asignar_puntos_dueno', params: {
        'p_dueno_id': duenoId,
        'p_puntos': puntos,
        'p_tipo_asignacion': tipo,
        'p_motivo': motivo,
        'p_admin_id': currentUser.id,
      });

      // Refrescar datos
      await cargarEstadisticas();
      await cargarDuenosPuntos();
      await cargarNotificaciones();
    } catch (e) {
      _setError('Error al asignar puntos: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar puntos por pedido
  Future<void> actualizarPuntosPorPedido(int puntos) async {
    _setLoading(true);
    _setError(null);

    try {
      // TODO: Implementar actualización en BD
      _puntosPorPedido = puntos;
      notifyListeners();
    } catch (e) {
      _setError('Error al actualizar puntos por pedido: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refrescar todos los datos
  Future<void> refrescarDatos() async {
    await cargarEstadisticas();
    await cargarDuenosPuntos();
    await cargarNotificaciones();
  }

  // Setters
  void setPuntosPorPedido(int puntos) {
    _puntosPorPedido = puntos;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 