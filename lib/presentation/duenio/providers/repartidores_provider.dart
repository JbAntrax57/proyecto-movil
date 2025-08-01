import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../core/localization.dart';

class RepartidoresProvider extends ChangeNotifier {
  // Estado de repartidores
  List<Map<String, dynamic>> _repartidoresDisponibles = [];
  List<Map<String, dynamic>> _notificacionesRepartidor = [];
  bool _isLoading = false;
  String _search = '';
  String? _error;
  bool _mostrarNotificaciones = false;
  TextEditingController telefonoController = TextEditingController();

  // Getters para el estado
  List<Map<String, dynamic>> get repartidoresDisponibles => _repartidoresDisponibles;
  List<Map<String, dynamic>> get notificacionesRepartidor => _notificacionesRepartidor;
  bool get isLoading => _isLoading;
  String get search => _search;
  String? get error => _error;
  bool get mostrarNotificaciones => _mostrarNotificaciones;

  // Inicializar el provider
  Future<void> inicializarRepartidores(BuildContext context) async {
    if (!context.mounted) return;
    await cargarRepartidoresDisponibles(context);
    if (!context.mounted) return;
    await cargarNotificacionesRepartidor(context);
  }

  // Cargar repartidores disponibles
  Future<void> cargarRepartidoresDisponibles(BuildContext context) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (!context.mounted) return;
      final userProvider = context.read<CarritoProvider>();
      final negocioId = userProvider.restauranteId;
      
      if (negocioId == null) {
        _setError('No se encontró el ID del negocio.');
        _setLoading(false);
        return;
      }
      
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
      
      // Filtrar los que no están asignados a este restaurante
      _repartidoresDisponibles = List<Map<String, dynamic>>.from(repartidores)
          .where((r) => !idsAsignados.contains(r['id']))
          .toList();
      
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar repartidores: $e');
      _setLoading(false);
    }
  }

  // Asignar repartidor al restaurante
  Future<void> asignarRepartidorAlRestaurante(BuildContext context, dynamic repartidorId) async {
    _setLoading(true);
    
    try {
      if (!context.mounted) return;
      final userProvider = context.read<CarritoProvider>();
      final negocioId = userProvider.restauranteId;
      
      if (negocioId == null) {
        _setError('No se encontró el ID del negocio.');
        _setLoading(false);
        return;
      }
      
      await Supabase.instance.client.from('negocios_repartidores').insert({
        'negocio_id': negocioId,
        'repartidor_id': repartidorId,
        'asociado_en': DateTime.now().toIso8601String(),
        'estado': 'activo',
      });
      
      // Recargar repartidores disponibles
      if (context.mounted) {
        await cargarRepartidoresDisponibles(context);
      }
      _setLoading(false);
    } catch (e) {
      _setError('Error al asignar repartidor: $e');
      _setLoading(false);
    }
  }

  // Asignar repartidor por teléfono
  Future<void> asignarPorTelefono(BuildContext context) async {
    _setLoading(true);
    
    try {
      if (!context.mounted) return;
      final telefono = telefonoController.text.trim();
      
      if (telefono.isEmpty) {
        if (context.mounted) {
          showWarningAlert(context, 'Ingresa un número de teléfono');
        }
        _setLoading(false);
        return;
      }
      
      final userProvider = context.read<CarritoProvider>();
      final negocioId = userProvider.restauranteId;
      
      if (negocioId == null) {
        _setError('No se encontró el ID del negocio.');
        _setLoading(false);
        return;
      }
      
      // Buscar repartidor por teléfono
      final resultado = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('rol', 'repartidor')
          .eq('telefono', telefono)
          .maybeSingle();
      
      if (resultado == null) {
        if (context.mounted) {
          showErrorAlert(context, 'No se encontró un repartidor con ese teléfono');
        }
        _setLoading(false);
        return;
      }
      
      await Supabase.instance.client.from('negocios_repartidores').insert({
        'negocio_id': negocioId,
        'repartidor_id': resultado['id'],
        'asociado_en': DateTime.now().toIso8601String(),
        'estado': 'activo',
      });
      
      if (context.mounted) {
        showTopInfoMessage(
          context,
          'Repartidor asignado por teléfono correctamente.',
          icon: Icons.check_circle,
          backgroundColor: Colors.green[50],
          textColor: Colors.green[700],
          iconColor: Colors.green[700],
        );
      }
      
      telefonoController.clear();
      _setLoading(false);
    } catch (e) {
      _setError('Error al asignar repartidor por teléfono: $e');
      _setLoading(false);
    }
  }

  // Cargar notificaciones de "quiero ser repartidor"
  Future<void> cargarNotificacionesRepartidor(BuildContext context) async {
    try {
      if (!context.mounted) return;
      final userProvider = context.read<CarritoProvider>();
      final userId = userProvider.userId;
      
      if (userId == null) {
        _setError('No se encontró el ID del usuario.');
        return;
      }
      
      final data = await Supabase.instance.client
          .from('notificaciones')
          .select()
          .eq('usuario_id', userId)
          .eq('tipo', 'repartidor_disponible')
          .order('fecha', ascending: false);
      
      _notificacionesRepartidor = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar notificaciones: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> marcarNotificacionComoLeida(BuildContext context, String notificacionId) async {
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', notificacionId);
      
      // Recargar notificaciones
      if (context.mounted) {
        await cargarNotificacionesRepartidor(context);
      }
    } catch (e) {
      _setError('Error al marcar notificación como leída: $e');
    }
  }

  // Formatear fecha para mostrar de forma amigable
  String formatearFecha(dynamic fecha) {
    try {
      final date = DateTime.parse(fecha.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha.toString();
    }
  }

  // Mostrar detalles del cliente
  void mostrarDetallesCliente(BuildContext context, Map<String, dynamic> notificacion) {
    final mensaje = notificacion['mensaje'] ?? '';

    // Extraer información del mensaje
    final regex = RegExp(
      r'El cliente (.+?) \((.+?)\) quiere ser repartidor\. Dirección: (.+?), Teléfono: (.+)',
    );
    final match = regex.firstMatch(mensaje);

    String nombre = 'Cliente';
    String email = '';
    String direccion = '';
    String telefono = '';

    if (match != null) {
      nombre = match.group(1) ?? 'Cliente';
      email = match.group(2) ?? '';
      direccion = match.group(3) ?? '';
      telefono = match.group(4) ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).get('detalles_cliente')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(context, 'Nombre', nombre),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Email', email),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Dirección', direccion),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Teléfono', telefono),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este cliente quiere trabajar como repartidor para tu restaurante',
                      style: TextStyle(color: Colors.orange[800], fontSize: 12),
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
            child: Text(AppLocalizations.of(context).get('cerrar')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showSuccessAlert(
                context,
                'Información del cliente disponible para contacto',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(AppLocalizations.of(context).get('contactar')),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para mostrar información
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value.isEmpty ? AppLocalizations.of(context).get('no_disponible') : value)),
      ],
    );
  }

  // Filtrar repartidores por búsqueda
  List<Map<String, dynamic>> getRepartidoresFiltrados() {
    if (_search.isEmpty) {
      return _repartidoresDisponibles;
    }
    
    return _repartidoresDisponibles.where((r) {
      final nombre = (r['nombre'] ?? '').toString().toLowerCase();
      final email = (r['email'] ?? '').toString().toLowerCase();
      final telefono = (r['telefono'] ?? '').toString().toLowerCase();
      return nombre.contains(_search) ||
          email.contains(_search) ||
          telefono.contains(_search);
    }).toList();
  }

  // Obtener notificaciones no leídas
  List<Map<String, dynamic>> getNotificacionesNoLeidas() {
    return _notificacionesRepartidor.where((n) => n['leida'] != true).toList();
  }

  // Contar notificaciones no leídas
  int get contarNotificacionesNoLeidas => getNotificacionesNoLeidas().length;

  // Establecer texto de búsqueda
  void setSearchText(String text) {
    _search = text.trim().toLowerCase();
    notifyListeners();
  }

  // Cambiar estado de mostrar notificaciones
  void toggleMostrarNotificaciones() {
    _mostrarNotificaciones = !_mostrarNotificaciones;
    notifyListeners();
  }

  // Ocultar notificaciones
  void ocultarNotificaciones() {
    _mostrarNotificaciones = false;
    notifyListeners();
  }

  // Limpiar recursos
  @override
  void dispose() {
    telefonoController.dispose();
    super.dispose();
  }

  // Setters para el estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 