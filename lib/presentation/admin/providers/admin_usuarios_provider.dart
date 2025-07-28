import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/top_info_message.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../providers/admin_configuracion_provider.dart';
import '../providers/admin_reportes_provider.dart';

class AdminUsuariosProvider extends ChangeNotifier {
  // Estado
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _negocios = [];
  List<Map<String, dynamic>> _usuariosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _busqueda = '';
  String _filtroRol = 'Todos';

  // Función para encriptar la contraseña con SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Getters
  List<Map<String, dynamic>> get usuarios => _usuarios;
  List<Map<String, dynamic>> get negocios => _negocios;
  List<Map<String, dynamic>> get usuariosFiltrados => _usuariosFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get busqueda => _busqueda;
  String get filtroRol => _filtroRol;

  // Inicializar el provider
  Future<void> inicializarUsuarios(BuildContext context) async {
    await cargarDatos();
  }

  // Cargar datos
  Future<void> cargarDatos() async {
    try {
      _setLoading(true);
      _setError(null);

      // Cargar usuarios
      final usuarios = await Supabase.instance.client
          .from('usuarios')
          .select()
          .order('created_at', ascending: false);

      // Cargar negocios para mostrar el nombre del restaurante
      final negocios = await Supabase.instance.client
          .from('negocios')
          .select('id, nombre');

      _usuarios = List<Map<String, dynamic>>.from(usuarios);
      _negocios = List<Map<String, dynamic>>.from(negocios);
      _setLoading(false);

      aplicarFiltros();
    } catch (e) {
      _setError('Error al cargar usuarios: $e');
      _setLoading(false);
    }
  }

  // Aplicar filtros
  void aplicarFiltros() {
    _usuariosFiltrados = _usuarios.where((usuario) {
      // Excluir usuarios con rol 'cliente'
      if ((usuario['rol'] ?? '').toString().toLowerCase() == 'cliente') {
        return false;
      }

      // Filtrar por rol
      if (_filtroRol != 'Todos' && (usuario['rol'] ?? '').toString().toLowerCase() != _filtroRol.toLowerCase()) {
        return false;
      }

      // Filtrar por búsqueda
      if (_busqueda.isNotEmpty) {
        final nombre = (usuario['name'] ?? usuario['nombre'] ?? '').toString().toLowerCase();
        final email = (usuario['email'] ?? '').toString().toLowerCase();
        final busqueda = _busqueda.toLowerCase();
        return nombre.contains(busqueda) || email.contains(busqueda);
      }

      return true;
    }).toList();
    
    // Ordenar por rol y luego por nombre
    _usuariosFiltrados.sort((a, b) {
      final rolA = (a['rol'] ?? '').toString().toLowerCase();
      final rolB = (b['rol'] ?? '').toString().toLowerCase();
      
      // Orden de prioridad de roles
      final ordenRoles = ['admin', 'duenio', 'repartidor'];
      final indexA = ordenRoles.indexOf(rolA);
      final indexB = ordenRoles.indexOf(rolB);
      
      if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
      
      // Si tienen el mismo rol, ordenar por nombre
      final nombreA = (a['name'] ?? a['nombre'] ?? '').toString().toLowerCase();
      final nombreB = (b['name'] ?? b['nombre'] ?? '').toString().toLowerCase();
      return nombreA.compareTo(nombreB);
    });
    
    notifyListeners();
  }

  // Obtener nombre del restaurante
  String obtenerNombreRestaurante(String? restauranteId) {
    if (restauranteId == null) return '';
    final negocio = _negocios.firstWhere(
      (n) => n['id'] == restauranteId,
      orElse: () => <String, dynamic>{},
    );
    return negocio['nombre'] ?? '';
  }

  // Obtener color por rol
  Color obtenerColorPorRol(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.red.shade100;
      case 'duenio':
        return Colors.orange.shade100;
      case 'repartidor':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // Mostrar diálogo editar usuario
  Future<void> mostrarDialogoEditarUsuario(BuildContext context, Map<String, dynamic> usuario) async {
    final nombreController = TextEditingController(text: usuario['name'] ?? usuario['nombre'] ?? '');
    final rolController = TextEditingController(text: usuario['rol'] ?? '');

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: rolController.text,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                  DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                ],
                onChanged: (value) {
                  rolController.text = value ?? '';
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('usuarios')
                      .update({
                        'name': nombreController.text.toUpperCase(),
                        'rol': rolController.text,
                      })
                      .eq('id', usuario['id']);

                  Navigator.of(context).pop();
                  await cargarDatos();
                  
                  // Notificar a otros providers para que se actualicen
                  await _notificarOtrosProviders(context);
                  
                  if (context.mounted) {
                    showTopInfoMessage(
                      context,
                      'Usuario actualizado correctamente',
                      icon: Icons.check_circle,
                      backgroundColor: Colors.green[50],
                      textColor: Colors.green[700],
                      iconColor: Colors.green[700],
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showTopInfoMessage(
                      context,
                      'Error al actualizar: $e',
                      icon: Icons.error,
                      backgroundColor: Colors.red[50],
                      textColor: Colors.red[700],
                      iconColor: Colors.red[700],
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Confirmar eliminar usuario
  Future<void> confirmarEliminarUsuario(BuildContext context, Map<String, dynamic> usuario) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar a ${usuario['name'] ?? usuario['nombre']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('usuarios')
                      .delete()
                      .eq('id', usuario['id']);

                  Navigator.of(context).pop();
                  await cargarDatos();
                  
                  // Notificar a otros providers para que se actualicen
                  await _notificarOtrosProviders(context);
                  
                  if (context.mounted) {
                    showTopInfoMessage(
                      context,
                      'Usuario eliminado correctamente',
                      icon: Icons.check_circle,
                      backgroundColor: Colors.green[50],
                      textColor: Colors.green[700],
                      iconColor: Colors.green[700],
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showTopInfoMessage(
                      context,
                      'Error al eliminar: $e',
                      icon: Icons.error,
                      backgroundColor: Colors.red[50],
                      textColor: Colors.red[700],
                      iconColor: Colors.red[700],
                    );
                  }
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar diálogo crear usuario
  Future<void> mostrarDialogoCrearUsuario(BuildContext context) async {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    String rolSeleccionado = 'cliente';
    String? restauranteSeleccionado;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear Nuevo Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: rolSeleccionado,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                        DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                        DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          rolSeleccionado = value ?? 'cliente';
                          if (value != 'duenio') {
                            restauranteSeleccionado = null;
                          }
                        });
                      },
                    ),
                    if (rolSeleccionado == 'duenio') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: restauranteSeleccionado,
                        decoration: const InputDecoration(labelText: 'Restaurante'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Seleccionar restaurante')),
                          ..._negocios.map((negocio) => DropdownMenuItem(
                                value: negocio['id'].toString(),
                                child: Text(negocio['nombre']),
                              )),
                        ],
                        onChanged: (value) {
                          setStateDialog(() {
                            restauranteSeleccionado = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    // Validar campos requeridos
                    if (nombreController.text.trim().isEmpty) {
                      showTopInfoMessage(
                        context,
                        'El nombre es requerido',
                        icon: Icons.warning,
                        backgroundColor: Colors.orange[50],
                        textColor: Colors.orange[700],
                        iconColor: Colors.orange[700],
                      );
                      return;
                    }
                    
                    if (emailController.text.trim().isEmpty) {
                      showTopInfoMessage(
                        context,
                        'El email es requerido',
                        icon: Icons.warning,
                        backgroundColor: Colors.orange[50],
                        textColor: Colors.orange[700],
                        iconColor: Colors.orange[700],
                      );
                      return;
                    }
                    
                    if (passwordController.text.trim().isEmpty) {
                      showTopInfoMessage(
                        context,
                        'La contraseña es requerida',
                        icon: Icons.warning,
                        backgroundColor: Colors.orange[50],
                        textColor: Colors.orange[700],
                        iconColor: Colors.orange[700],
                      );
                      return;
                    }
                    
                    if (passwordController.text.length < 6) {
                      showTopInfoMessage(
                        context,
                        'La contraseña debe tener al menos 6 caracteres',
                        icon: Icons.warning,
                        backgroundColor: Colors.orange[50],
                        textColor: Colors.orange[700],
                        iconColor: Colors.orange[700],
                      );
                      return;
                    }
                    
                    // Validar formato de email
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(emailController.text.trim())) {
                      showTopInfoMessage(
                        context,
                        'El formato del email no es válido',
                        icon: Icons.warning,
                        backgroundColor: Colors.orange[50],
                        textColor: Colors.orange[700],
                        iconColor: Colors.orange[700],
                      );
                      return;
                    }
                    
                    // Verificar que el email no esté duplicado
                    final emailExistente = _usuarios.any((usuario) => 
                      usuario['email']?.toString().toLowerCase() == emailController.text.trim().toLowerCase()
                    );
                    if (emailExistente) {
                      showTopInfoMessage(
                        context,
                        'El email ya está registrado',
                        icon: Icons.warning,
                        backgroundColor: Colors.orange[50],
                        textColor: Colors.orange[700],
                        iconColor: Colors.orange[700],
                      );
                      return;
                    }
                    
                    try {
                      setStateDialog(() {
                        _isLoading = true;
                      });

                      final userData = {
                        'name': nombreController.text.toUpperCase(),
                        'email': emailController.text,
                        'password': hashPassword(passwordController.text), // Contraseña encriptada
                        'telephone': telefonoController.text,
                        'direccion': direccionController.text,
                        'rol': rolSeleccionado,
                      };

                      if (rolSeleccionado == 'duenio' && restauranteSeleccionado != null) {
                        userData['restaurante_id'] = restauranteSeleccionado!;
                      }

                                             // Insertar usuario en la tabla usuarios
                       print('🔄 Insertando usuario en tabla usuarios...');
                       final usuarioResult = await Supabase.instance.client
                           .from('usuarios')
                           .insert(userData)
                           .select()
                           .single();
                       print('✅ Usuario creado con ID: ${usuarioResult['id']}');

                                             // Si el usuario se creó exitosamente, insertar en dashboard_puntos
                       if (usuarioResult != null) {
                         final usuarioId = usuarioResult['id'];
                         
                         try {
                            print('🔄 Insertando en sistema_puntos...');
                            // Insertar en sistema_puntos con puntos iniciales de 0
                            final sistemaPuntosData = {
                              'dueno_id': usuarioId,
                              'puntos_disponibles': 0,
                              'total_asignado': 0,
                              'created_at': DateTime.now().toIso8601String(),
                            };
                            
                            print('📊 Datos a insertar en sistema_puntos: $sistemaPuntosData');
                            
                            await Supabase.instance.client
                                .from('sistema_puntos')
                                .insert(sistemaPuntosData);
                            
                            print('✅ Usuario insertado en sistema_puntos con ID: $usuarioId');
                          } catch (e) {
                            print('⚠️ Error al insertar en sistema_puntos: $e');
                            print('⚠️ Detalles del error: ${e.toString()}');
                            // Continuar aunque falle la inserción en sistema_puntos
                          }
                       }

                      Navigator.of(context).pop();
                      await cargarDatos();
                      
                      // Notificar a otros providers para que se actualicen
                      await _notificarOtrosProviders(context);
                      
                      if (context.mounted) {
                        showTopInfoMessage(
                          context,
                          'Usuario ${nombreController.text} creado correctamente',
                          icon: Icons.check_circle,
                          backgroundColor: Colors.green[50],
                          textColor: Colors.green[700],
                          iconColor: Colors.green[700],
                          showDuration: const Duration(seconds: 3),
                        );
                      }
                    } catch (e) {
                      setStateDialog(() {
                        _error = 'Error al crear usuario: $e';
                      });
                      if (context.mounted) {
                        showTopInfoMessage(
                          context,
                          'Error al crear usuario: $e',
                          icon: Icons.error,
                          backgroundColor: Colors.red[50],
                          textColor: Colors.red[700],
                          iconColor: Colors.red[700],
                        );
                      }
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Notificar a otros providers para que se actualicen
  Future<void> _notificarOtrosProviders(BuildContext context) async {
    try {
      // Notificar al provider de configuración
      if (context.mounted) {
        final configProvider = context.read<AdminConfiguracionProvider>();
        await configProvider.refrescarDatos();
      }
      
      // Notificar al provider de reportes
      if (context.mounted) {
        final reportesProvider = context.read<AdminReportesProvider>();
        await reportesProvider.cargarReportes();
      }
      
      print('✅ Otros providers actualizados después de crear usuario');
    } catch (e) {
      print('⚠️ Error al notificar otros providers: $e');
    }
  }

  // Setters
  void setBusqueda(String busqueda) {
    _busqueda = busqueda;
    aplicarFiltros();
  }

  void setFiltroRol(String filtroRol) {
    _filtroRol = filtroRol;
    aplicarFiltros();
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