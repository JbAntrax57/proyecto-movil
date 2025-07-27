import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../cliente/providers/carrito_provider.dart';
import '../../../services/puntos_service.dart';
import '../../../shared/widgets/custom_alert.dart';

class DashboardProvider extends ChangeNotifier {
  // Estado del dashboard
  bool _cargandoDatos = true;
  bool _cargandoNegocio = true;
  String? _negocioNombre;
  String? _negocioImgUrl;
  String? _ultimoRestauranteId;
  
  // Getters para el estado
  bool get cargandoDatos => _cargandoDatos;
  bool get cargandoNegocio => _cargandoNegocio;
  String? get negocioNombre => _negocioNombre;
  String? get negocioImgUrl => _negocioImgUrl;

  // Inicialización del dashboard
  Future<void> inicializarDashboard(BuildContext context) async {
    await _restaurarUserIdYEmail(context);
    await _restaurarRestauranteId(context);
    await _cargarDatosNegocio(context);
    _setCargandoDatos(false);
  }

  // Restaurar datos del usuario desde SharedPreferences
  Future<void> _restaurarUserIdYEmail(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userEmail = prefs.getString('userEmail');
    
    if (userId != null && userId.isNotEmpty) {
      Provider.of<CarritoProvider>(context, listen: false).setUserId(userId);
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      Provider.of<CarritoProvider>(context, listen: false).setUserEmail(userEmail);
    }
  }

  // Restaurar ID del restaurante desde la base de datos
  Future<void> _restaurarRestauranteId(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    if (userId != null) {
      final userData = await Supabase.instance.client
          .from('usuarios')
          .select('restaurante_id')
          .eq('id', userId)
          .maybeSingle();
          
      if (userData != null && userData['restaurante_id'] != null) {
        Provider.of<CarritoProvider>(context, listen: false)
            .setRestauranteId(userData['restaurante_id'] as String);
      }
    }
  }

  // Cargar datos del negocio desde Supabase
  Future<void> _cargarDatosNegocio(BuildContext context) async {
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    
    try {
      final data = await Supabase.instance.client
          .from('negocios')
          .select()
          .eq('id', restauranteId)
          .maybeSingle();
          
      _negocioNombre = data?['nombre']?.toString() ?? 'Mi Negocio';
      _negocioImgUrl = data?['img']?.toString();
      _cargandoNegocio = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando datos del negocio: $e');
      _cargandoNegocio = false;
      notifyListeners();
    }
  }

  // Cargar datos del negocio de forma reactiva
  Future<Map<String, dynamic>?> cargarDatosNegocioReactivo(String? restauranteId) async {
    if (restauranteId == null || restauranteId.isEmpty) return null;
    
    try {
      final data = await Supabase.instance.client
          .from('negocios')
          .select()
          .eq('id', restauranteId)
          .maybeSingle();
      return data;
    } catch (e) {
      print('❌ Error cargando datos reactivos del negocio: $e');
      return null;
    }
  }

  // Editar foto del negocio
  Future<void> editarFotoNegocio(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;
    
    try {
      final file = File(picked.path);
      final fileName = 'negocio_$restauranteId.jpg';
      
      // Subir a Supabase Storage
      final storage = Supabase.instance.client.storage.from('images');
      await storage.upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      final publicUrl = storage.getPublicUrl(fileName);
      
      // Actualizar la URL en la base de datos
      await Supabase.instance.client.from('negocios').update({'img': publicUrl}).eq('id', restauranteId);
      
      _negocioImgUrl = publicUrl;
      notifyListeners();
      
      showSuccessAlert(context, 'Foto actualizada');
    } catch (e) {
      print('❌ Error actualizando foto del negocio: $e');
      showErrorAlert(context, 'Error al actualizar la foto');
    }
  }

  // Métricas del dashboard
  Future<int> contarUsuarios() async {
    try {
      final data = await Supabase.instance.client.from('usuarios').select();
      return data.length;
    } catch (e) {
      print('❌ Error contando usuarios: $e');
      return 0;
    }
  }

  Future<int> contarNegocios() async {
    try {
      final data = await Supabase.instance.client.from('negocios').select();
      return data.length;
    } catch (e) {
      print('❌ Error contando negocios: $e');
      return 0;
    }
  }

  Future<int> contarPedidos() async {
    try {
      final data = await Supabase.instance.client.from('pedidos').select();
      return data.length;
    } catch (e) {
      print('❌ Error contando pedidos: $e');
      return 0;
    }
  }

  // Agregar negocio demo
  Future<void> agregarNegocioDemo(Map<String, dynamic> negocio) async {
    try {
      await Supabase.instance.client.from('negocios').insert(negocio);
    } catch (e) {
      print('❌ Error agregando negocio demo: $e');
    }
  }

  // Agregar usuario demo
  Future<void> agregarUsuarioDemo(Map<String, dynamic> usuario) async {
    try {
      await Supabase.instance.client.from('usuarios').insert(usuario);
    } catch (e) {
      print('❌ Error agregando usuario demo: $e');
    }
  }

  // Cargar notificaciones del dueño
  Future<List<Map<String, dynamic>>> cargarNotificacionesDuenio(BuildContext context) async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) return [];
      
      final data = await Supabase.instance.client
        .from('notificaciones')
        .select()
        .eq('usuario_id', userId)
        .order('fecha', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error cargando notificaciones: $e');
      return [];
    }
  }

  // Marcar notificación como leída
  Future<void> marcarNotificacionComoLeida(String notificacionId) async {
    try {
      await Supabase.instance.client
        .from('notificaciones')
        .update({'leida': true})
        .eq('id', notificacionId);
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  // Formatear fecha
  String formatearFecha(dynamic fecha) {
    try {
      final date = DateTime.parse(fecha.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha.toString();
    }
  }

  // Cargar repartidores disponibles
  Future<List<Map<String, dynamic>>> cargarRepartidoresDisponibles(BuildContext context) async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final negocioId = userProvider.restauranteId;
      if (negocioId == null) return [];
      
      // Obtener todos los repartidores
      final repartidores = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('rol', 'repartidor');
      
      // Obtener los ya asignados a este restaurante
      final asignados = await Supabase.instance.client
        .from('negocios_repartidores')
        .select('repartidor_id')
        .eq('negocio_id', negocioId);
      
      final idsAsignados = asignados.map((a) => a['repartidor_id']).toSet();
      
      // Filtrar los que no están asignados
      return List<Map<String, dynamic>>.from(repartidores)
          .where((r) => !idsAsignados.contains(r['id']))
          .toList();
    } catch (e) {
      print('❌ Error cargando repartidores disponibles: $e');
      return [];
    }
  }

  // Asignar repartidor al restaurante
  Future<void> asignarRepartidorAlRestaurante(BuildContext context, dynamic repartidorId) async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final negocioId = userProvider.restauranteId;
      if (negocioId == null) return;
      
      await Supabase.instance.client.from('negocios_repartidores').insert({
        'negocio_id': negocioId,
        'repartidor_id': repartidorId,
        'asociado_en': DateTime.now().toIso8601String(),
        'estado': 'activo',
      });
    } catch (e) {
      print('❌ Error asignando repartidor: $e');
    }
  }

  // Mostrar diálogo de puntos
  Future<void> mostrarDialogoPuntos(BuildContext context) async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final userId = userProvider.userId;
      
      if (userId == null) {
        showErrorAlert(context, 'No se pudo identificar al usuario');
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener datos de puntos
      final puntosData = await PuntosService.obtenerPuntosDueno(userId);
      
      // Cerrar loading
      Navigator.pop(context);

      if (puntosData == null) {
        showErrorAlert(context, 'No se encontraron datos de puntos para este usuario');
        return;
      }

      // Mostrar diálogo con información de puntos
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Mis Puntos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPuntoInfo('Puntos Disponibles', '${puntosData['puntos_disponibles'] ?? 0}', Colors.green),
              const SizedBox(height: 12),
              _buildPuntoInfo('Total Asignado', '${puntosData['total_asignado'] ?? 0}', Colors.blue),
              const SizedBox(height: 12),
              _buildPuntoInfo('Puntos por Pedido', '${puntosData['puntos_por_pedido'] ?? 2}', Colors.orange),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Negocio',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (puntosData['puntos_disponibles'] ?? 0) > 0 
                          ? '✅ Activo - Puedes recibir pedidos'
                          : '❌ Inactivo - Sin puntos disponibles',
                      style: TextStyle(
                        color: (puntosData['puntos_disponibles'] ?? 0) > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar loading si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showErrorAlert(context, 'Error al cargar información de puntos: $e');
    }
  }

  // Widget helper para mostrar información de puntos
  Widget _buildPuntoInfo(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Cerrar sesión
  Future<void> cerrarSesion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (context.mounted) {
        Provider.of<CarritoProvider>(context, listen: false).setUserEmail('');
        Provider.of<CarritoProvider>(context, listen: false).setUserId('');
        Provider.of<CarritoProvider>(context, listen: false).setRestauranteId(null);
      }
    } catch (e) {
      print('❌ Error cerrando sesión: $e');
    }
  }

  // Setters para el estado
  void _setCargandoDatos(bool value) {
    _cargandoDatos = value;
    notifyListeners();
  }

  void setCargandoNegocio(bool value) {
    _cargandoNegocio = value;
    notifyListeners();
  }
} 