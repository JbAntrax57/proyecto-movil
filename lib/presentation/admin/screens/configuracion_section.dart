import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/puntos_dialog.dart';
import 'package:intl/intl.dart';

class AdminConfiguracionSection extends StatefulWidget {
  const AdminConfiguracionSection({super.key});

  @override
  State<AdminConfiguracionSection> createState() => _AdminConfiguracionSectionState();
}

class _AdminConfiguracionSectionState extends State<AdminConfiguracionSection> {
  late Future<Map<String, dynamic>> _estadisticasFuture;
  late Future<List<Map<String, dynamic>>> _duenosPuntosFuture;
  late Future<List<Map<String, dynamic>>> _notificacionesFuture;
  
  int _puntosPorPedido = 2;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
    _estadisticasFuture = _obtenerEstadisticas();
    _duenosPuntosFuture = _obtenerDuenosPuntos();
    _notificacionesFuture = _obtenerNotificaciones();
  }

  void _verificarAutenticacion() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      print('⚠️ ADVERTENCIA: Usuario no autenticado en Configuración');
      // Mostrar mensaje al usuario
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Usuario no autenticado. Algunas funciones pueden no estar disponibles.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      print('✅ Usuario autenticado: ${currentUser.email}');
      print('✅ User ID: ${currentUser.id}');
      print('✅ App Metadata: ${currentUser.appMetadata}');
      print('✅ User Metadata: ${currentUser.userMetadata}');
    }
  }

  Future<Map<String, dynamic>> _obtenerEstadisticas() async {
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

  Future<List<Map<String, dynamic>>> _obtenerDuenosPuntos() async {
    try {
      print('Obteniendo dueños con puntos...');
      
      // Verificar autenticación
      final currentUser = Supabase.instance.client.auth.currentUser;
      print('Usuario actual: ${currentUser?.id ?? 'No autenticado'}');
      print('Email del usuario: ${currentUser?.email ?? 'No email'}');
      
      if (currentUser == null) {
        print('⚠️ ADVERTENCIA: Usuario no autenticado');
        // Intentar obtener datos sin autenticación para desarrollo
      }
      
      // Probar primero con consulta directa
      print('Probando consulta directa...');
      final directResult = await Supabase.instance.client
          .from('sistema_puntos')
          .select('*')
          .limit(5);
      print('Consulta directa: ${directResult.length} registros');
      
      final result = await Supabase.instance.client
          .from('dashboard_puntos')
          .select('*')
          .order('puntos_disponibles', ascending: false);
      
      print('Resultado obtenido: ${result.length} dueños');
      print('Primer dueño: ${result.isNotEmpty ? result.first : 'No hay datos'}');
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error obteniendo dueños con puntos: $e');
      print('Error completo: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerNotificaciones() async {
    try {
      final result = await Supabase.instance.client
          .from('notificaciones_sistema')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  Future<void> _asignarPuntos(String duenoId, int puntos, String tipo, String motivo) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      await Supabase.instance.client
          .rpc('asignar_puntos_dueno', params: {
        'p_dueno_id': duenoId,
        'p_puntos': puntos,
        'p_tipo_asignacion': tipo,
        'p_motivo': motivo,
        'p_admin_id': currentUser.id,
      });

      // Refrescar datos
      setState(() {
        _estadisticasFuture = _obtenerEstadisticas();
        _duenosPuntosFuture = _obtenerDuenosPuntos();
        _notificacionesFuture = _obtenerNotificaciones();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Puntos ${tipo == 'agregar' ? 'asignados' : 'quitados'} correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error asignando puntos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar puntos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _mostrarDialogoPuntos(Map<String, dynamic> dueno, String tipoOperacion) async {
    print('🔄 Mostrando diálogo de puntos para: ${dueno['dueno_email']}');
    print('🔄 Tipo de operación: $tipoOperacion');

    await showDialog(
      context: context,
      builder: (context) => PuntosDialog(
        dueno: dueno,
        onPuntosUpdated: () {
          setState(() {
            _duenosPuntosFuture = _obtenerDuenosPuntos();
          });
        },
      ),
    );
  }

  Future<void> _mostrarDialogoAsignarPuntos(Map<String, dynamic> dueno) async {
    final puntosController = TextEditingController();
    final motivoController = TextEditingController();
    String tipoAsignacion = 'agregar';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Asignar Puntos - ${dueno['dueno_nombre']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Puntos actuales: ${dueno['puntos_disponibles']}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipoAsignacion,
                decoration: const InputDecoration(labelText: 'Tipo de operación'),
                items: const [
                  DropdownMenuItem(value: 'agregar', child: Text('Agregar puntos')),
                  DropdownMenuItem(value: 'quitar', child: Text('Quitar puntos')),
                ],
                onChanged: (value) {
                  tipoAsignacion = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: puntosController,
                decoration: const InputDecoration(labelText: 'Cantidad de puntos'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(labelText: 'Motivo'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final puntos = int.tryParse(puntosController.text);
                final motivo = motivoController.text.trim();
                
                if (puntos == null || puntos <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa una cantidad válida de puntos')),
                  );
                  return;
                }
                
                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un motivo')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _asignarPuntos(dueno['dueno_id'], puntos, tipoAsignacion, motivo);
              },
              child: const Text('Asignar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración del Sistema'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refrescar datos
                setState(() {
                  _duenosPuntosFuture = _obtenerDuenosPuntos();
                });
                print('🔄 Datos refrescados');
              },
              tooltip: 'Refrescar',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.people), text: 'Dueños'),
              Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(),
            _buildDuenosTab(),
            _buildNotificacionesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _estadisticasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final estadisticas = snapshot.data ?? {};
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard de Puntos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // KPIs
              SizedBox(
                height: 220,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _buildKPICard(
                      'Total Dueños',
                      '${estadisticas['total_duenos'] ?? 0}',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildKPICard(
                      'Con Puntos',
                      '${estadisticas['duenos_con_puntos'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildKPICard(
                      'Sin Puntos',
                      '${estadisticas['duenos_sin_puntos'] ?? 0}',
                      Icons.cancel,
                      Colors.red,
                    ),
                    _buildKPICard(
                      'Puntos Disponibles',
                      '${estadisticas['total_puntos_disponibles'] ?? 0}',
                      Icons.stars,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Configuración global
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración Global',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Puntos por pedido: '),
                          DropdownButton<int>(
                            value: _puntosPorPedido,
                            items: [2, 3, 4, 5].map((puntos) {
                              return DropdownMenuItem(
                                value: puntos,
                                child: Text('$puntos puntos'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _puntosPorPedido = value!;
                              });
                              // TODO: Implementar actualización en BD
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDuenosTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _duenosPuntosFuture,
      builder: (context, snapshot) {
        print('Estado del FutureBuilder: ${snapshot.connectionState}');
        print('Error: ${snapshot.error}');
        print('Datos: ${snapshot.data?.length ?? 0} dueños');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final duenos = snapshot.data ?? [];
        print('Dueños a mostrar: ${duenos.length}');
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: duenos.length,
          itemBuilder: (context, index) {
            final dueno = duenos[index];
            final estadoPuntos = dueno['estado_puntos'] ?? 'Con puntos';
            
            Color colorEstado;
            IconData iconEstado;
            
            switch (estadoPuntos) {
              case 'Sin puntos':
                colorEstado = Colors.red;
                iconEstado = Icons.cancel;
                break;
              case 'Puntos bajos':
                colorEstado = Colors.orange;
                iconEstado = Icons.warning;
                break;
              default:
                colorEstado = Colors.green;
                iconEstado = Icons.check_circle;
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorEstado,
                  child: Icon(iconEstado, color: Colors.white),
                ),
                title: Text(dueno['dueno_nombre'] ?? 'Dueño sin nombre'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${dueno['dueno_email'] ?? ''}'),
                    Text('Puntos disponibles: ${dueno['puntos_disponibles']}'),
                    Text('Total asignado: ${dueno['total_asignado']}'),
                    Text('Estado: $estadoPuntos'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.green),
                      onPressed: () => _mostrarDialogoPuntos(dueno, 'agregar'),
                      tooltip: 'Agregar puntos',
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.red),
                      onPressed: () => _mostrarDialogoPuntos(dueno, 'quitar'),
                      tooltip: 'Quitar puntos',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificacionesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _notificacionesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notificaciones = snapshot.data ?? [];
        
        if (notificaciones.isEmpty) {
          return const Center(
            child: Text('No hay notificaciones recientes'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notificaciones.length,
          itemBuilder: (context, index) {
            final notificacion = notificaciones[index];
            final fecha = DateTime.parse(notificacion['created_at']);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: notificacion['leida'] == true ? Colors.grey : Colors.blue,
                  child: Icon(
                    notificacion['leida'] == true ? Icons.check : Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                title: Text(notificacion['titulo'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notificacion['mensaje'] ?? ''),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Text(
                  notificacion['tipo'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKPICard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 6,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
} 