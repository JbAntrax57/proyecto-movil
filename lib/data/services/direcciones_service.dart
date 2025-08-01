import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/direccion_model.dart';

class DireccionesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todas las direcciones de un usuario
  Future<List<DireccionModel>> obtenerDirecciones(String usuarioId) async {
    try {
      final response = await _supabase
          .from('direcciones')
          .select()
          .eq('usuario_id', usuarioId)
          .order('es_predeterminada', ascending: false)
          .order('fecha_creacion', ascending: false);

      return (response as List)
          .map((json) => DireccionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener direcciones: $e');
    }
  }

  // Obtener una dirección específica
  Future<DireccionModel?> obtenerDireccion(String direccionId) async {
    try {
      final response = await _supabase
          .from('direcciones')
          .select()
          .eq('id', direccionId)
          .single();

      return DireccionModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('No rows returned')) {
        return null;
      }
      throw Exception('Error al obtener dirección: $e');
    }
  }

  // Crear una nueva dirección
  Future<DireccionModel> crearDireccion(DireccionModel direccion) async {
    try {
      // Si la nueva dirección es predeterminada, quitar predeterminada de otras
      if (direccion.esPredeterminada) {
        await _supabase
            .from('direcciones')
            .update({'es_predeterminada': false})
            .eq('usuario_id', direccion.usuarioId)
            .eq('es_predeterminada', true);
      }

      final response = await _supabase
          .from('direcciones')
          .insert(direccion.toJson())
          .select()
          .single();

      return DireccionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear dirección: $e');
    }
  }

  // Actualizar una dirección existente
  Future<DireccionModel> actualizarDireccion(DireccionModel direccion) async {
    try {
      // Si la dirección se marca como predeterminada, quitar predeterminada de otras
      if (direccion.esPredeterminada) {
        await _supabase
            .from('direcciones')
            .update({'es_predeterminada': false})
            .eq('usuario_id', direccion.usuarioId)
            .eq('es_predeterminada', true)
            .neq('id', direccion.id!);
      }

      final response = await _supabase
          .from('direcciones')
          .update({
            ...direccion.toJson(),
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', direccion.id!)
          .select()
          .single();

      return DireccionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar dirección: $e');
    }
  }

  // Eliminar una dirección
  Future<void> eliminarDireccion(String direccionId) async {
    try {
      await _supabase
          .from('direcciones')
          .delete()
          .eq('id', direccionId);
    } catch (e) {
      throw Exception('Error al eliminar dirección: $e');
    }
  }

  // Marcar una dirección como predeterminada
  Future<void> marcarComoPredeterminada(String direccionId, String usuarioId) async {
    try {
      // Quitar predeterminada de todas las direcciones del usuario
      await _supabase
          .from('direcciones')
          .update({'es_predeterminada': false})
          .eq('usuario_id', usuarioId);

      // Marcar la dirección específica como predeterminada
      await _supabase
          .from('direcciones')
          .update({
            'es_predeterminada': true,
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', direccionId);
    } catch (e) {
      throw Exception('Error al marcar dirección como predeterminada: $e');
    }
  }

  // Obtener la dirección predeterminada de un usuario
  Future<DireccionModel?> obtenerDireccionPredeterminada(String usuarioId) async {
    try {
      final response = await _supabase
          .from('direcciones')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('es_predeterminada', true)
          .maybeSingle();

      if (response == null) return null;
      return DireccionModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener dirección predeterminada: $e');
    }
  }
} 