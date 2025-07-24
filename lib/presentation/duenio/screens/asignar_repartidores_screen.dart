import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../../../shared/widgets/custom_alert.dart';

/// asignar_repartidores_screen.dart - Vista para que el dueño asigne repartidores a su restaurante
class AsignarRepartidoresScreen extends StatefulWidget {
  const AsignarRepartidoresScreen({super.key});

  @override
  State<AsignarRepartidoresScreen> createState() =>
      _AsignarRepartidoresScreenState();
}

class _AsignarRepartidoresScreenState extends State<AsignarRepartidoresScreen> {
  bool _isLoading = false;
  String _search = '';
  final TextEditingController _telefonoController = TextEditingController();
  List<Map<String, dynamic>> _notificacionesRepartidor = [];
  bool _mostrarNotificaciones = false;

  @override
  void initState() {
    super.initState();
    _cargarNotificacionesRepartidor();
  }

  // Cargar repartidores disponibles (usuarios con rol repartidor)
  Future<List<Map<String, dynamic>>> _cargarRepartidoresDisponibles() async {
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
      // Filtrar los que no están asignados a este restaurante
      return List<Map<String, dynamic>>.from(
        repartidores,
      ).where((r) => !idsAsignados.contains(r['id'])).toList();
    } catch (e) {
      return [];
    }
  }

  // Asignar repartidor al restaurante (insertar en negocios_repartidores)
  Future<void> _asignarRepartidorAlRestaurante(dynamic repartidorId) async {
    setState(() {
      _isLoading = true;
    });
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final negocioId = userProvider.restauranteId;
    if (negocioId == null) return;
    await Supabase.instance.client.from('negocios_repartidores').insert({
      'negocio_id': negocioId,
      'repartidor_id': repartidorId,
      'asociado_en': DateTime.now().toIso8601String(),
      'estado': 'activo',
    });
    setState(() {
      _isLoading = false;
    });
  }

  // Cargar notificaciones de "quiero ser repartidor"
  Future<void> _cargarNotificacionesRepartidor() async {
    try {
      final userProvider = Provider.of<CarritoProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('notificaciones')
          .select()
          .eq('usuario_id', userId)
          .eq('tipo', 'repartidor_disponible')
          .order('fecha', ascending: false);

      setState(() {
        _notificacionesRepartidor = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print('❌ Error cargando notificaciones de repartidor: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> _marcarNotificacionComoLeida(String notificacionId) async {
    try {
      await Supabase.instance.client
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', notificacionId);
      // Recargar notificaciones
      await _cargarNotificacionesRepartidor();
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  // Formatea la fecha para mostrarla de forma amigable
  String _formatearFecha(dynamic fecha) {
    try {
      final date = DateTime.parse(fecha.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha.toString();
    }
  }

  // Mostrar detalles del cliente en un diálogo
  void _mostrarDetallesCliente(Map<String, dynamic> notificacion) {
    final mensaje = notificacion['mensaje'] ?? '';

    // Extraer información del mensaje (formato: "El cliente Nombre (email) quiere ser repartidor. Dirección: dir, Teléfono: tel")
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
            const Text('Detalles del Cliente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nombre', nombre),
            const SizedBox(height: 8),
            _buildInfoRow('Email', email),
            const SizedBox(height: 8),
            _buildInfoRow('Dirección', direccion),
            const SizedBox(height: 8),
            _buildInfoRow('Teléfono', telefono),
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
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí podrías agregar lógica para contactar al cliente
              showSuccessAlert(
                context,
                'Información del cliente disponible para contacto',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para mostrar información
  Widget _buildInfoRow(String label, String value) {
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
        Expanded(child: Text(value.isEmpty ? 'No disponible' : value)),
      ],
    );
  }

  // Asignar repartidor por teléfono (sin importar si ya está asignado a otro restaurante)
  Future<void> _asignarPorTelefono() async {
    setState(() {
      _isLoading = true;
    });
    final telefono = _telefonoController.text.trim();
    if (telefono.isEmpty) {
      showWarningAlert(context, 'Ingresa un número de teléfono');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final negocioId = userProvider.restauranteId;
    if (negocioId == null) return;
    // Buscar repartidor por teléfono
    final resultado = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('rol', 'repartidor')
        .eq('telefono', telefono)
        .maybeSingle();
    if (resultado == null) {
      showErrorAlert(context, 'No se encontró un repartidor con ese teléfono');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    await Supabase.instance.client.from('negocios_repartidores').insert({
      'negocio_id': negocioId,
      'repartidor_id': resultado['id'],
      'asociado_en': DateTime.now().toIso8601String(),
      'estado': 'activo',
    });
    showSuccessAlert(
      context,
      'Repartidor asignado por teléfono correctamente.',
    );
    setState(() {
      _isLoading = false;
    });
    _telefonoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final notificacionesNoLeidas = _notificacionesRepartidor
        .where((n) => n['leida'] != true)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar repartidores'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar repartidor',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              // Asignar por teléfono
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono del repartidor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _asignarPorTelefono,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Asignar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _cargarRepartidoresDisponibles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final repartidores = snapshot.data ?? [];
                    // Filtrar por búsqueda
                    final filtrados = repartidores.where((r) {
                      final nombre = (r['nombre'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email = (r['email'] ?? '').toString().toLowerCase();
                      final telefono = (r['telefono'] ?? '')
                          .toString()
                          .toLowerCase();
                      return nombre.contains(_search) ||
                          email.contains(_search) ||
                          telefono.contains(_search);
                    }).toList();
                    if (filtrados.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay repartidores disponibles para asignar.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: filtrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final repartidor = filtrados[index];
                        return Card(
                          color: Colors.orange[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.delivery_dining,
                              color: Colors.orange,
                            ),
                            title: Text(
                              repartidor['nombre'] ??
                                  repartidor['email'] ??
                                  'Repartidor',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tel: ${repartidor['telephone'] ?? '-'}'),
                                Text(
                                  'Dirección: ${repartidor['direccion'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      await _asignarRepartidorAlRestaurante(
                                        repartidor['id'],
                                      );
                                      showSuccessAlert(
                                        context,
                                        'Repartidor asignado correctamente.',
                                      );
                                      setState(() {}); // Refrescar la lista
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Asignar'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Panel de notificaciones desplegable
          if (_mostrarNotificaciones)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 300,
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header del panel
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                                             child: Row(
                         children: [
                           const Icon(Icons.notifications, color: Colors.orange),
                           const SizedBox(width: 8),
                           Expanded(
                             child: const Text(
                               'Solicitudes de repartidores',
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 16,
                               ),
                             ),
                           ),
                           IconButton(
                             icon: const Icon(Icons.close),
                             onPressed: () {
                               setState(() {
                                 _mostrarNotificaciones = false;
                               });
                             },
                           ),
                         ],
                       ),
                    ),
                    // Lista de notificaciones
                    Flexible(
                      child: _notificacionesRepartidor.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No hay solicitudes de repartidores',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _notificacionesRepartidor.length,
                              itemBuilder: (context, index) {
                                final notif = _notificacionesRepartidor[index];
                                final esNoLeida = notif['leida'] != true;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: esNoLeida
                                        ? Colors.orange[50]
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: esNoLeida
                                          ? Colors.orange[200]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delivery_dining,
                                      color: esNoLeida
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      notif['mensaje'] ?? '',
                                      style: TextStyle(
                                        fontWeight: esNoLeida
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: esNoLeida
                                            ? Colors.orange[800]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatearFecha(notif['fecha']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: esNoLeida
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            ),
                                            onPressed: () async {
                                              await _marcarNotificacionComoLeida(
                                                notif['id'].toString(),
                                              );
                                            },
                                            tooltip: 'Marcar como leída',
                                          )
                                        : null,
                                    onTap: () {
                                      // Mostrar detalles del cliente
                                      _mostrarDetallesCliente(notif);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          // Botón flotante para mostrar notificaciones
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _mostrarNotificaciones = !_mostrarNotificaciones;
                });
              },
              backgroundColor: notificacionesNoLeidas > 0
                  ? Colors.red
                  : Colors.orange,
              icon: const Icon(Icons.notifications, color: Colors.white),
              label: Text(
                notificacionesNoLeidas > 0
                    ? '$notificacionesNoLeidas'
                    : 'Solicitudes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
