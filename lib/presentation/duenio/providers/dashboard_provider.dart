import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../cliente/providers/carrito_provider.dart';
import '../../../services/puntos_service.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../core/localization.dart';

class DashboardProvider extends ChangeNotifier {
  // Estado del dashboard
  bool _cargandoDatos = true;
  bool _cargandoNegocio = true;
  String? _negocioNombre;
  String? _negocioImgUrl;
  String? _negocioDescripcion; // Added for new method
  String? _ultimoRestauranteId;
  
  // Estadísticas del dashboard
  Map<String, dynamic> _estadisticas = {};
  bool _cargandoEstadisticas = false;
  
  // Getters para el estado
  bool get cargandoDatos => _cargandoDatos;
  bool get cargandoNegocio => _cargandoNegocio;
  String? get negocioNombre => _negocioNombre;
  String? get negocioImgUrl => _negocioImgUrl;
  Map<String, dynamic> get estadisticas => _estadisticas;
  bool get cargandoEstadisticas => _cargandoEstadisticas;

  // Inicialización del dashboard
  Future<void> inicializarDashboard(BuildContext context) async {
    await _restaurarUserIdYEmail(context);
    await _restaurarRestauranteId(context);
    await _cargarDatosNegocio(context);
    await _cargarEstadisticas(context);
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
      _negocioDescripcion = data?['descripcion']?.toString(); // Load description
      _cargandoNegocio = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando datos del negocio: $e');
      _cargandoNegocio = false;
      notifyListeners();
    }
  }

  // Cargar estadísticas del dashboard
  Future<void> _cargarEstadisticas(BuildContext context) async {
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    if (restauranteId == null) return;

    _setCargandoEstadisticas(true);
    
    try {
      // Obtener fecha de hoy
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDia = inicioDia.add(const Duration(days: 1));

      // Pedidos del día
      final pedidosHoy = await Supabase.instance.client
          .from('pedidos')
          .select('*')
          .eq('restaurante_id', restauranteId)
          .gte('created_at', inicioDia.toIso8601String())
          .lt('created_at', finDia.toIso8601String());

      // Pedidos en camino
      final pedidosEnCamino = await Supabase.instance.client
          .from('pedidos')
          .select('*')
          .eq('restaurante_id', restauranteId)
          .eq('estado', 'en camino');

      // Calcular ventas del día
      double ventasHoy = 0;
      for (var pedido in pedidosHoy) {
        ventasHoy += (pedido['total'] ?? 0).toDouble();
      }

      // Obtener puntos del dueño
      final userId = Provider.of<CarritoProvider>(context, listen: false).userId;
      Map<String, dynamic> puntosData = {};
      if (userId != null) {
        try {
          puntosData = await PuntosService.obtenerPuntosDueno(userId) ?? {};
        } catch (e) {
          print('❌ Error obteniendo puntos: $e');
        }
      }

      // Obtener pedidos de ayer para comparación
      final ayer = hoy.subtract(const Duration(days: 1));
      final inicioAyer = DateTime(ayer.year, ayer.month, ayer.day);
      final finAyer = inicioAyer.add(const Duration(days: 1));
      
      final pedidosAyer = await Supabase.instance.client
          .from('pedidos')
          .select('*')
          .eq('restaurante_id', restauranteId)
          .gte('created_at', inicioAyer.toIso8601String())
          .lt('created_at', finAyer.toIso8601String());

      double ventasAyer = 0;
      for (var pedido in pedidosAyer) {
        ventasAyer += (pedido['total'] ?? 0).toDouble();
      }

      // Calcular porcentajes de cambio
      final cambioPedidos = pedidosAyer.isNotEmpty 
          ? ((pedidosHoy.length - pedidosAyer.length) / pedidosAyer.length * 100).round()
          : 0;
      
      final cambioVentas = ventasAyer > 0 
          ? ((ventasHoy - ventasAyer) / ventasAyer * 100).round()
          : 0;

      _estadisticas = {
        'pedidos_hoy': pedidosHoy.length,
        'ventas_hoy': ventasHoy,
        'pedidos_en_camino': pedidosEnCamino.length,
        'puntos_disponibles': puntosData['puntos_disponibles'] ?? 0,
        'cambio_pedidos': cambioPedidos,
        'cambio_ventas': cambioVentas,
        'tiempo_promedio': '25min', // TODO: Calcular tiempo real
      };

      _setCargandoEstadisticas(false);
    } catch (e) {
      print('❌ Error cargando estadísticas: $e');
      _setCargandoEstadisticas(false);
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
      print('❌ Error cargando datos del negocio reactivo: $e');
      return null;
    }
  }

  // Refrescar estadísticas
  Future<void> refrescarEstadisticas(BuildContext context) async {
    await _cargarEstadisticas(context);
  }

  // Editar foto del negocio
  Future<void> editarFotoNegocio(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      // TODO: Implementar subida de imagen a Supabase Storage
      // Por ahora solo mostrar mensaje
      if (context.mounted) {
        showTopInfoMessage(
          context,
          'Función de cambio de foto próximamente disponible',
          icon: Icons.info,
          backgroundColor: Colors.blue[50],
          textColor: Colors.blue[700],
          iconColor: Colors.blue[700],
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopInfoMessage(
          context,
          'Error al seleccionar imagen: $e',
          icon: Icons.error,
          backgroundColor: Colors.red[50],
          textColor: Colors.red[700],
          iconColor: Colors.red[700],
        );
      }
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
    final restauranteId = Provider.of<CarritoProvider>(context, listen: false).restauranteId;
    final userId = Provider.of<CarritoProvider>(context, listen: false).userId;
    
    if (restauranteId == null || userId == null) {
      if (context.mounted) {
        showTopInfoMessage(
          context,
          'Error: No se pudo obtener información del negocio',
          icon: Icons.error,
          backgroundColor: Colors.red[50],
          textColor: Colors.red[700],
          iconColor: Colors.red[700],
        );
      }
      return;
    }

    try {
      final puntosData = await PuntosService.obtenerPuntosDueno(userId);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber[600]),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).get('mis_puntos')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPuntoInfo('Puntos Disponibles', '${puntosData?['puntos_disponibles'] ?? 0}', Colors.green),
                  const SizedBox(height: 12),
                  _buildPuntoInfo('Total Asignado', '${puntosData?['total_asignado'] ?? 0}', Colors.blue),
                  const SizedBox(height: 12),
                  _buildPuntoInfo('Puntos por Pedido', '${puntosData?['puntos_por_pedido'] ?? 0}', Colors.orange),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Los puntos se consumen automáticamente con cada pedido',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).get('cerrar')),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopInfoMessage(
          context,
          'Error al cargar puntos: $e',
          icon: Icons.error,
          backgroundColor: Colors.red[50],
          textColor: Colors.red[700],
          iconColor: Colors.red[700],
        );
      }
    }
  }

  Widget _buildPuntoInfo(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Cerrar sesión
  Future<void> cerrarSesion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRol');
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      
      if (context.mounted) {
        Provider.of<CarritoProvider>(context, listen: false).limpiarSesion();
      }
    } catch (e) {
      print('❌ Error cerrando sesión: $e');
    }
  }

  // Setters
  void _setCargandoDatos(bool cargando) {
    _cargandoDatos = cargando;
    notifyListeners();
  }

  void _setCargandoEstadisticas(bool cargando) {
    _cargandoEstadisticas = cargando;
    notifyListeners();
  }

  // Mostrar modal de configuración del negocio
  Future<void> mostrarDialogoConfiguracionNegocio(BuildContext context, String restauranteId) async {
    final nombreController = TextEditingController(text: _negocioNombre ?? '');
    final descripcionController = TextEditingController(text: _negocioDescripcion ?? '');
    String? imagenUrl = _negocioImgUrl;
    File? imagenLocal;
    final picker = ImagePicker();
    bool subiendoImagen = false;

    Future<void> seleccionarYSubirImagen(Function setStateDialog) async {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      
      imagenLocal = File(picked.path);
      setStateDialog(() {
        subiendoImagen = true;
      });
      
      try {
        final fileName = 'negocio_${DateTime.now().millisecondsSinceEpoch}_${imagenLocal!.path.split('/').last}';
        final storageResponse = await Supabase.instance.client.storage
            .from('images')
            .upload(fileName, imagenLocal!);
        
        if (storageResponse.isNotEmpty) {
          imagenUrl = Supabase.instance.client.storage
              .from('images')
              .getPublicUrl(fileName);
        }
      } catch (e) {
        print('Error subiendo imagen: $e');
      }
      
      setStateDialog(() {
        subiendoImagen = false;
      });
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle del modal
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.store,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuración del Negocio',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Edita la información de tu negocio',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                
                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección de imagen
                        _buildImageSection(
                          imagenUrl,
                          imagenLocal,
                          subiendoImagen,
                          () => seleccionarYSubirImagen(setStateDialog),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sección de información básica
                        _buildBasicInfoSection(
                          nombreController,
                          descripcionController,
                        ),
                        
                        const SizedBox(height: 80), // Espacio para botones
                      ],
                    ),
                  ),
                ),
                
                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[200]!,
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: subiendoImagen
                              ? null
                              : () async {
                                  final nombre = nombreController.text.trim();
                                  final descripcion = descripcionController.text.trim();
                                  final img = imagenUrl ?? '';
                                  
                                  if (nombre.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Por favor ingresa el nombre del negocio',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  try {
                                    await Supabase.instance.client
                                        .from('negocios')
                                        .update({
                                          'nombre': nombre,
                                          'descripcion': descripcion,
                                          'img': img,
                                        })
                                        .eq('id', restauranteId);
                                    
                                    // Actualizar datos locales
                                    _negocioNombre = nombre;
                                    _negocioDescripcion = descripcion;
                                    _negocioImgUrl = img;
                                    notifyListeners();
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Información actualizada correctamente',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: $e',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Guardar Cambios',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper para la sección de imagen
  Widget _buildImageSection(
    String? imagenUrl,
    File? imagenLocal,
    bool subiendoImagen,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen del Negocio',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
            ),
            child: imagenUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.network(
                          imagenUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.store,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : imagenLocal != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.file(
                          imagenLocal!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para agregar imagen',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (subiendoImagen) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Subiendo imagen...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Widget helper para la sección de información básica
  Widget _buildBasicInfoSection(
    TextEditingController nombreController,
    TextEditingController descripcionController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Negocio',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        // Campo Nombre
        _buildTextField(
          controller: nombreController,
          label: 'Nombre del negocio',
          hint: 'Ej: Mi Restaurante',
          icon: Icons.store,
          isRequired: true,
        ),
        
        const SizedBox(height: 16),
        
        // Campo Descripción
        _buildTextField(
          controller: descripcionController,
          label: 'Descripción',
          hint: 'Describe tu negocio...',
          icon: Icons.description,
          maxLines: 3,
        ),
      ],
    );
  }

  // Widget helper para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 