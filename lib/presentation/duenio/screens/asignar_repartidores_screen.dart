import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/repartidores_provider.dart';

/// asignar_repartidores_screen.dart - Vista para que el dueño asigne repartidores a su restaurante
/// Refactorizada para usar RepartidoresProvider y separar lógica de negocio
class AsignarRepartidoresScreen extends StatefulWidget {
  const AsignarRepartidoresScreen({super.key});

  @override
  State<AsignarRepartidoresScreen> createState() =>
      _AsignarRepartidoresScreenState();
}

class _AsignarRepartidoresScreenState extends State<AsignarRepartidoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<RepartidoresProvider>().inicializarRepartidores(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RepartidoresProvider>(
      builder: (context, repartidoresProvider, child) {
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
                        repartidoresProvider.setSearchText(value);
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
                            controller: repartidoresProvider.telefonoController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono del repartidor',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: repartidoresProvider.isLoading 
                              ? null 
                              : () => repartidoresProvider.asignarPorTelefono(context),
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
                    child: repartidoresProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : repartidoresProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar repartidores',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  repartidoresProvider.error!,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => repartidoresProvider.cargarRepartidoresDisponibles(context),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : repartidoresProvider.getRepartidoresFiltrados().isEmpty
                        ? const Center(
                            child: Text(
                              'No hay repartidores disponibles para asignar.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(18),
                            itemCount: repartidoresProvider.getRepartidoresFiltrados().length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final repartidor = repartidoresProvider.getRepartidoresFiltrados()[index];
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
                                    onPressed: repartidoresProvider.isLoading
                                        ? null
                                        : () async {
                                            await repartidoresProvider.asignarRepartidorAlRestaurante(
                                              context,
                                              repartidor['id'],
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Repartidor asignado correctamente.'),
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: EdgeInsets.only(
                                                    top: 60,
                                                    left: 16,
                                                    right: 16,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text('Asignar'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Panel de notificaciones desplegable
              if (repartidoresProvider.mostrarNotificaciones)
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
                          color: Colors.black.withValues(alpha: 0.2),
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
                              const Expanded(
                                child: Text(
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
                                  repartidoresProvider.ocultarNotificaciones();
                                },
                              ),
                            ],
                          ),
                        ),
                        // Lista de notificaciones
                        Flexible(
                          child: repartidoresProvider.notificacionesRepartidor.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No hay solicitudes de repartidores',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: repartidoresProvider.notificacionesRepartidor.length,
                                  itemBuilder: (context, index) {
                                    final notif = repartidoresProvider.notificacionesRepartidor[index];
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
                                          repartidoresProvider.formatearFecha(notif['fecha']),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: esNoLeida
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                ),
                                                onPressed: () async {
                                                  await repartidoresProvider.marcarNotificacionComoLeida(
                                                    context,
                                                    notif['id'].toString(),
                                                  );
                                                },
                                                tooltip: 'Marcar como leída',
                                              )
                                            : null,
                                        onTap: () {
                                          // Mostrar detalles del cliente
                                          repartidoresProvider.mostrarDetallesCliente(context, notif);
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
                    repartidoresProvider.toggleMostrarNotificaciones();
                  },
                  backgroundColor: repartidoresProvider.contarNotificacionesNoLeidas > 0
                      ? Colors.red
                      : Colors.orange,
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  label: Text(
                    repartidoresProvider.contarNotificacionesNoLeidas > 0
                        ? '${repartidoresProvider.contarNotificacionesNoLeidas}'
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
      },
    );
  }
}
