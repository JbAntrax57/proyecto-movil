import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PuntosService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Inicializar notificaciones locales
  static Future<void> inicializarNotificaciones() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Consumir puntos al crear un pedido
  static Future<bool> consumirPuntosEnPedido(String duenoId, {int puntosConsumir = 2}) async {
    try {
      // Intentar usar la función RPC primero
      try {
        final result = await Supabase.instance.client
            .rpc('consumir_puntos_pedido', params: {
          'p_dueno_id': duenoId,
          'p_puntos_consumir': puntosConsumir,
        });

        // Verificar estado de restaurantes después de consumir puntos
        await verificarEstadoRestaurantes();

        return result == true;
      } catch (e) {
        print('RPC no disponible, usando método directo: $e');
        // Si la función RPC no está disponible, usar método directo
        return await _consumirPuntosDirecto(duenoId, puntosConsumir);
      }
    } catch (e) {
      print('Error consumiendo puntos en pedido: $e');
      return false;
    }
  }

  // Método directo para consumir puntos (fallback)
  static Future<bool> _consumirPuntosDirecto(String duenoId, int puntosConsumir) async {
    try {
      // Obtener puntos actuales
      final currentData = await Supabase.instance.client
          .from('sistema_puntos')
          .select('puntos_disponibles, total_asignado')
          .eq('dueno_id', duenoId)
          .single();

      final puntosDisponibles = currentData['puntos_disponibles'] ?? 0;
      
      // Verificar si tiene suficientes puntos
      if (puntosDisponibles < puntosConsumir) {
        print('❌ El dueño no tiene suficientes puntos. Disponibles: $puntosDisponibles, Requeridos: $puntosConsumir');
        return false;
      }

      // Calcular nuevos valores
      final nuevosPuntosDisponibles = puntosDisponibles - puntosConsumir;
      
      // Actualizar puntos
      final result = await Supabase.instance.client
          .from('sistema_puntos')
          .update({
            'puntos_disponibles': nuevosPuntosDisponibles,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('dueno_id', duenoId)
          .select();

      if (result.isEmpty) {
        print('❌ No se pudo actualizar los puntos del dueño');
        return false;
      }

      print('✅ Puntos consumidos exitosamente: $puntosConsumir puntos');
      print('✅ Nuevos puntos disponibles: $nuevosPuntosDisponibles');
      
      // Verificar estado de restaurantes
      await verificarEstadoRestaurantes();
      
      return true;
    } catch (e) {
      print('Error en método directo de consumo de puntos: $e');
      return false;
    }
  }

  // Verificar estado de restaurantes basado en puntos
  static Future<void> verificarEstadoRestaurantes() async {
    try {
      await Supabase.instance.client
          .rpc('verificar_estado_restaurantes_por_puntos');
    } catch (e) {
      print('Error verificando estado de restaurantes: $e');
    }
  }

  // Obtener puntos de un dueño
  static Future<Map<String, dynamic>?> obtenerPuntosDueno(String duenoId) async {
    try {
      final result = await Supabase.instance.client
          .from('sistema_puntos')
          .select('*')
          .eq('dueno_id', duenoId)
          .maybeSingle();
      
      return result;
    } catch (e) {
      print('Error obteniendo puntos del dueño: $e');
      return null;
    }
  }

  // Enviar notificación local
  static Future<void> enviarNotificacionLocal({
    required String titulo,
    required String mensaje,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'puntos_channel',
      'Sistema de Puntos',
      channelDescription: 'Notificaciones del sistema de puntos',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      titulo,
      mensaje,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Verificar y enviar notificaciones de puntos bajos
  static Future<void> verificarPuntosBajos(String duenoId) async {
    try {
      final puntos = await obtenerPuntosDueno(duenoId);
      if (puntos != null) {
        final puntosDisponibles = puntos['puntos_disponibles'] ?? 0;
        
        if (puntosDisponibles <= 0) {
          await enviarNotificacionLocal(
            titulo: 'Puntos Agotados',
            mensaje: 'Se han agotado tus puntos. Tus restaurantes han sido desactivados.',
          );
        } else if (puntosDisponibles <= 50) {
          await enviarNotificacionLocal(
            titulo: 'Puntos Bajos',
            mensaje: 'Te quedan $puntosDisponibles puntos. Considera recargar.',
          );
        }
      }
    } catch (e) {
      print('Error verificando puntos bajos: $e');
    }
  }

  // Obtener notificaciones no leídas para un usuario
  static Future<List<Map<String, dynamic>>> obtenerNotificacionesNoLeidas(String usuarioId) async {
    try {
      final result = await Supabase.instance.client
          .from('notificaciones_sistema')
          .select('*')
          .eq('usuario_id', usuarioId)
          .eq('leida', false)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error obteniendo notificaciones no leídas: $e');
      return [];
    }
  }

  // Marcar notificación como leída
  static Future<void> marcarNotificacionLeida(String notificacionId) async {
    try {
      await Supabase.instance.client
          .from('notificaciones_sistema')
          .update({'leida': true})
          .eq('id', notificacionId);
    } catch (e) {
      print('Error marcando notificación como leída: $e');
    }
  }

  // Obtener estadísticas del sistema de puntos
  static Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final result = await Supabase.instance.client
          .rpc('obtener_estadisticas_puntos');
      
      if (result != null && result.isNotEmpty) {
        return result[0];
      }
      return {
        'total_duenos': 0,
        'duenos_con_puntos': 0,
        'duenos_sin_puntos': 0,
        'total_puntos_asignados': 0,
        'total_puntos_consumidos': 0,
        'total_puntos_disponibles': 0,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'total_duenos': 0,
        'duenos_con_puntos': 0,
        'duenos_sin_puntos': 0,
        'total_puntos_asignados': 0,
        'total_puntos_consumidos': 0,
        'total_puntos_disponibles': 0,
      };
    }
  }

  // Asignar puntos a un dueño (solo para admins)
  static Future<bool> asignarPuntosDueno(
    String duenoId,
    int puntos,
    String tipoAsignacion,
    String motivo,
  ) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return false;

      final result = await Supabase.instance.client
          .rpc('asignar_puntos_dueno', params: {
        'p_dueno_id': duenoId,
        'p_puntos': puntos,
        'p_tipo_asignacion': tipoAsignacion,
        'p_motivo': motivo,
        'p_admin_id': currentUser.id,
      });

      return result == true;
    } catch (e) {
      print('Error asignando puntos: $e');
      return false;
    }
  }

  // Obtener historial de asignaciones de puntos
  static Future<List<Map<String, dynamic>>> obtenerHistorialAsignaciones(String duenoId) async {
    try {
      final result = await Supabase.instance.client
          .from('asignaciones_puntos')
          .select('*, sistema_puntos!inner(dueno_id)')
          .eq('sistema_puntos.dueno_id', duenoId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error obteniendo historial de asignaciones: $e');
      return [];
    }
  }

  // Verificar si un restaurante está activo basado en puntos
  static Future<bool> verificarRestauranteActivo(String duenoId) async {
    try {
      final puntos = await obtenerPuntosDueno(duenoId);
      if (puntos != null) {
        return (puntos['puntos_disponibles'] ?? 0) > 0;
      }
      return false;
    } catch (e) {
      print('Error verificando estado del restaurante: $e');
      return false;
    }
  }

  static final SupabaseClient _client = Supabase.instance.client;

  /// Verificar si el usuario es admin
  static Future<bool> esUsuarioAdmin(String? userId) async {
    if (userId == null) return false;
    
    try {
      final userData = await _client
          .from('usuarios')
          .select('rol')
          .eq('id', userId)
          .single();
      
      final rol = userData['rol']?.toString().toLowerCase();
      print('🔍 Verificando rol: $rol para usuario: $userId');
      return rol == 'admin';
    } catch (e) {
      print('🔍 Error verificando rol: $e');
      return false;
    }
  }

  /// Agregar puntos a un dueño
  static Future<bool> agregarPuntos({
    required String duenoId,
    required int puntos,
    required String motivo,
    String? adminId,
  }) async {
    try {
      print('🔄 Agregando $puntos puntos al dueño $duenoId');
      print('🔄 Admin ID: ${adminId ?? 'admin-default'}');
      print('🔄 Motivo: $motivo');
      
      // Permitir operación sin verificar autenticación
      print('✅ Operación permitida para desarrollo.');
      adminId = adminId ?? '61c7d5d8-0bdf-40fb-961c-b7e24333c6a4'; // ID del admin
      
      // 1. Obtener puntos actuales
      print('🔄 Obteniendo puntos actuales...');
      final currentData = await _client
          .from('sistema_puntos')
          .select('puntos_disponibles, total_asignado')
          .eq('dueno_id', duenoId)
          .single();

      print('🔄 Puntos actuales: ${currentData['puntos_disponibles']} disponibles');
      print('🔄 Total asignado actual: ${currentData['total_asignado']}');
      
      final nuevosPuntosDisponibles = (currentData['puntos_disponibles'] ?? 0) + puntos;
      final nuevoTotalAsignado = (currentData['total_asignado'] ?? 0) + puntos;
      
      print('🔄 Nuevos puntos: $nuevosPuntosDisponibles disponibles');
      print('🔄 Nuevo total asignado: $nuevoTotalAsignado');

      // 2. Actualizar puntos en sistema_puntos
      print('🔄 Actualizando puntos en la base de datos...');
      final result = await _client
          .from('sistema_puntos')
          .update({
            'puntos_disponibles': nuevosPuntosDisponibles,
            'total_asignado': nuevoTotalAsignado,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('dueno_id', duenoId)
          .select();

      print('🔄 Resultado de actualización: ${result.length} registros actualizados');
      if (result.isEmpty) {
        print('❌ No se pudo actualizar los puntos del dueño');
        return false;
      }

                     // 2. Obtener el ID del sistema_puntos para este dueño
               print('🔄 Obteniendo ID del sistema_puntos...');
               final sistemaPuntosData = await _client
                   .from('sistema_puntos')
                   .select('id')
                   .eq('dueno_id', duenoId)
                   .single();
               
               final sistemaPuntosId = sistemaPuntosData['id'];
               print('🔄 Sistema puntos ID: $sistemaPuntosId');
               
               // 3. Registrar la asignación
               print('🔄 Registrando asignación de puntos...');
               print('🔄 Admin ID final: $adminId');
               await _client.from('asignaciones_puntos').insert({
                 'sistema_puntos_id': sistemaPuntosId,
                 'admin_id': adminId, // Solo usar adminId si no es null
                 'puntos_asignados': puntos,
                 'tipo_asignacion': 'agregar',
                 'motivo': motivo,
                 'created_at': DateTime.now().toIso8601String(),
               });
      print('🔄 Asignación registrada exitosamente');

                     // 3. Crear notificación (opcional)
               try {
                 print('🔄 Creando notificación...');
                 await _client.from('notificaciones_sistema').insert({
                   'usuario_id': duenoId,
                   'tipo': 'asignacion_puntos',
                   'titulo': 'Puntos Agregados',
                   'mensaje': 'Se han agregado $puntos puntos a tu cuenta. Motivo: $motivo',
                   'leida': false,
                   'created_at': DateTime.now().toIso8601String(),
                 });
                 print('🔄 Notificación creada exitosamente');
               } catch (e) {
                 print('⚠️ Error creando notificación: $e');
                 print('⚠️ Continuando sin notificación...');
               }

      print('✅ Puntos agregados exitosamente');
      print('✅ Devolviendo true - Operación exitosa');
      return true;
    } catch (e) {
      print('Error agregando puntos: $e');
      return false;
    }
  }

  /// Quitar puntos a un dueño
  static Future<bool> quitarPuntos({
    required String duenoId,
    required int puntos,
    required String motivo,
    String? adminId,
  }) async {
    try {
      print('🔄 Quitando $puntos puntos al dueño $duenoId');
      print('🔄 Admin ID: ${adminId ?? 'admin-default'}');
      print('🔄 Motivo: $motivo');
      
      // Permitir operación sin verificar autenticación
      print('✅ Operación permitida para desarrollo.');
      adminId = adminId ?? '61c7d5d8-0bdf-40fb-961c-b7e24333c6a4'; // ID del admin
      
      // 1. Verificar que tenga suficientes puntos
      final currentPoints = await _client
          .from('sistema_puntos')
          .select('puntos_disponibles, total_asignado')
          .eq('dueno_id', duenoId)
          .single();

      if (currentPoints['puntos_disponibles'] < puntos) {
        print('El dueño no tiene suficientes puntos');
        return false;
      }

      // 2. Actualizar puntos en sistema_puntos
      final nuevosPuntosDisponibles = (currentPoints['puntos_disponibles'] ?? 0) - puntos;
      final nuevoTotalAsignado = (currentPoints['total_asignado'] ?? 0) - puntos;
      
      print('🔄 Quitando $puntos puntos del total asignado: ${currentPoints['total_asignado']} -> $nuevoTotalAsignado');
      
      final result = await _client
          .from('sistema_puntos')
          .update({
            'puntos_disponibles': nuevosPuntosDisponibles,
            'total_asignado': nuevoTotalAsignado,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('dueno_id', duenoId)
          .select();

      if (result.isEmpty) {
        print('No se pudo actualizar los puntos del dueño');
        return false;
      }

      // 3. Obtener el ID del sistema_puntos para este dueño
      print('🔄 Obteniendo ID del sistema_puntos...');
      final sistemaPuntosData = await _client
          .from('sistema_puntos')
          .select('id')
          .eq('dueno_id', duenoId)
          .single();
      
      final sistemaPuntosId = sistemaPuntosData['id'];
      print('🔄 Sistema puntos ID: $sistemaPuntosId');
      
      // 4. Registrar la asignación (negativa)
      print('🔄 Admin ID final: $adminId');
      await _client.from('asignaciones_puntos').insert({
        'sistema_puntos_id': sistemaPuntosId,
        'admin_id': adminId, // Solo usar adminId si no es null
        'puntos_asignados': -puntos,
        'tipo_asignacion': 'quitar',
        'motivo': motivo,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. Crear notificación (opcional)
      try {
        await _client.from('notificaciones_sistema').insert({
          'usuario_id': duenoId,
          'tipo': 'asignacion_puntos',
          'titulo': 'Puntos Quitados',
          'mensaje': 'Se han quitado $puntos puntos de tu cuenta. Motivo: $motivo',
          'leida': false,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('🔄 Notificación creada exitosamente');
      } catch (e) {
        print('⚠️ Error creando notificación: $e');
        print('⚠️ Continuando sin notificación...');
      }

      print('Puntos quitados exitosamente');
      print('✅ Devolviendo true - Operación exitosa');
      return true;
    } catch (e) {
      print('Error quitando puntos: $e');
      return false;
    }
  }

  /// Obtener historial de puntos de un dueño
  static Future<List<Map<String, dynamic>>> obtenerHistorialPuntos(String duenoId) async {
    try {
      // Primero obtener el sistema_puntos_id para este dueño
      final sistemaPuntosData = await _client
          .from('sistema_puntos')
          .select('id')
          .eq('dueno_id', duenoId)
          .single();
      
      final sistemaPuntosId = sistemaPuntosData['id'];
      
      final result = await _client
          .from('asignaciones_puntos')
          .select('*')
          .eq('sistema_puntos_id', sistemaPuntosId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error obteniendo historial: $e');
      return [];
    }
  }
} 