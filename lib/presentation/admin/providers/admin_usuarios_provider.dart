import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario actualizado correctamente')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e')),
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario eliminado correctamente')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar: $e')),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El nombre es requerido')),
                      );
                      return;
                    }
                    
                    if (emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El email es requerido')),
                      );
                      return;
                    }
                    
                    if (passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La contraseña es requerida')),
                      );
                      return;
                    }
                    
                    if (passwordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                      );
                      return;
                    }
                    
                    // Validar formato de email
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(emailController.text.trim())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El formato del email no es válido')),
                      );
                      return;
                    }
                    
                    // Verificar que el email no esté duplicado
                    final emailExistente = _usuarios.any((usuario) => 
                      usuario['email']?.toString().toLowerCase() == emailController.text.trim().toLowerCase()
                    );
                    if (emailExistente) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El email ya está registrado')),
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

                      await Supabase.instance.client
                          .from('usuarios')
                          .insert(userData);

                      Navigator.of(context).pop();
                      await cargarDatos();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Usuario ${nombreController.text} creado correctamente'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      setStateDialog(() {
                        _error = 'Error al crear usuario: $e';
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al crear usuario: $e')),
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