import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../../../shared/widgets/custom_alert.dart';

/// asignar_repartidores_screen.dart - Vista para que el dueño asigne repartidores a su restaurante
class AsignarRepartidoresScreen extends StatefulWidget {
  const AsignarRepartidoresScreen({super.key});

  @override
  State<AsignarRepartidoresScreen> createState() => _AsignarRepartidoresScreenState();
}

class _AsignarRepartidoresScreenState extends State<AsignarRepartidoresScreen> {
  bool _isLoading = false;
  String _search = '';
  final TextEditingController _telefonoController = TextEditingController();

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
      return List<Map<String, dynamic>>.from(repartidores).where((r) => !idsAsignados.contains(r['id'])).toList();
    } catch (e) {
      return [];
    }
  }

  // Asignar repartidor al restaurante (insertar en negocios_repartidores)
  Future<void> _asignarRepartidorAlRestaurante(dynamic repartidorId) async {
    setState(() { _isLoading = true; });
    final userProvider = Provider.of<CarritoProvider>(context, listen: false);
    final negocioId = userProvider.restauranteId;
    if (negocioId == null) return;
    await Supabase.instance.client.from('negocios_repartidores').insert({
      'negocio_id': negocioId,
      'repartidor_id': repartidorId,
      'asociado_en': DateTime.now().toIso8601String(),
      'estado': 'activo',
    });
    setState(() { _isLoading = false; });
  }

  // Asignar repartidor por teléfono (sin importar si ya está asignado a otro restaurante)
  Future<void> _asignarPorTelefono() async {
    setState(() { _isLoading = true; });
    final telefono = _telefonoController.text.trim();
    if (telefono.isEmpty) {
      showWarningAlert(context, 'Ingresa un número de teléfono');
      setState(() { _isLoading = false; });
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
      setState(() { _isLoading = false; });
      return;
    }
    await Supabase.instance.client.from('negocios_repartidores').insert({
      'negocio_id': negocioId,
      'repartidor_id': resultado['id'],
      'asociado_en': DateTime.now().toIso8601String(),
      'estado': 'activo',
    });
    showSuccessAlert(context, 'Repartidor asignado por teléfono correctamente.');
    setState(() { _isLoading = false; });
    _telefonoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar repartidores'),
        centerTitle: true,
      ),
      body: Column(
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
                setState(() { _search = value.trim().toLowerCase(); });
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
                if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final repartidores = snapshot.data ?? [];
                // Filtrar por búsqueda
                final filtrados = repartidores.where((r) {
                  final nombre = (r['nombre'] ?? '').toString().toLowerCase();
                  final email = (r['email'] ?? '').toString().toLowerCase();
                  final telefono = (r['telefono'] ?? '').toString().toLowerCase();
                  return nombre.contains(_search) || email.contains(_search) || telefono.contains(_search);
                }).toList();
                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text('No hay repartidores disponibles para asignar.', style: TextStyle(color: Colors.orange)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.delivery_dining, color: Colors.orange),
                        title: Text(repartidor['nombre'] ?? repartidor['email'] ?? 'Repartidor'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tel: ${repartidor['telephone'] ?? '-'}'),
                            Text('Dirección: ${repartidor['direccion'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            await _asignarRepartidorAlRestaurante(repartidor['id']);
                            showSuccessAlert(context, 'Repartidor asignado correctamente.');
                            setState(() {}); // Refrescar la lista
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
    );
  }
} 