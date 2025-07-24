 import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsuariosSection extends StatefulWidget {
  const AdminUsuariosSection({super.key});

  @override
  State<AdminUsuariosSection> createState() => _AdminUsuariosSectionState();
}

class _AdminUsuariosSectionState extends State<AdminUsuariosSection> {
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _negocios = [];
  List<Map<String, dynamic>> _usuariosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _busqueda = '';
  String _filtroRol = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar usuarios
      final usuarios = await Supabase.instance.client
          .from('usuarios')
          .select()
          .order('created_at', ascending: false);

      // Cargar negocios para mostrar el nombre del restaurante
      final negocios = await Supabase.instance.client
          .from('negocios')
          .select('id, nombre');

      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(usuarios);
        _negocios = List<Map<String, dynamic>>.from(negocios);
        _isLoading = false;
      });

      _aplicarFiltros();
    } catch (e) {
      setState(() {
        _error = 'Error al cargar usuarios: $e';
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    setState(() {
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
    });
  }

  String _obtenerNombreRestaurante(String? restauranteId) {
    if (restauranteId == null) return '';
    final negocio = _negocios.firstWhere(
      (n) => n['id'] == restauranteId,
      orElse: () => <String, dynamic>{},
    );
    return negocio['nombre'] ?? '';
  }

  Color _obtenerColorPorRol(String rol) {
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

  Future<void> _mostrarDialogoEditarUsuario(Map<String, dynamic> usuario) async {
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
                  _cargarDatos();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario actualizado correctamente')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
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

  Future<void> _confirmarEliminarUsuario(Map<String, dynamic> usuario) async {
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
                  _cargarDatos();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario eliminado correctamente')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
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

  Future<void> _mostrarDialogoCrearUsuario() async {
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
                    try {
                      setStateDialog(() {
                        _isLoading = true;
                      });

                      final userData = {
                        'name': nombreController.text.toUpperCase(),
                        'email': emailController.text,
                        'password': passwordController.text,
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
                      _cargarDatos();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario creado correctamente')),
                        );
                      }
                    } catch (e) {
                      setStateDialog(() {
                        _error = 'Error al crear usuario: $e';
                      });
                      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;

    return Stack(
      children: [
        Column(
          children: [
            // Filtros
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nombre o email',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _busqueda = value;
                      });
                      _aplicarFiltros();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _filtroRol,
                    decoration: const InputDecoration(labelText: 'Filtrar por rol'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      const DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                      const DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroRol = value ?? 'Todos';
                      });
                      _aplicarFiltros();
                    },
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: isDesktop
                  ? _buildDataTable()
                  : _buildListView(),
            ),
          ],
        ),
        // Botón flotante
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _mostrarDialogoCrearUsuario,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Restaurante')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: _usuariosFiltrados.map((usuario) {
          return DataRow(cells: [
            DataCell(Text(usuario['name'] ?? usuario['nombre'] ?? '')),
            DataCell(Text(usuario['email'] ?? '')),
            DataCell(Text(usuario['rol'] ?? '')),
            DataCell(Text(_obtenerNombreRestaurante(usuario['restaurante_id']))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarDialogoEditarUsuario(usuario),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminarUsuario(usuario),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildListView() {
    // Agrupar usuarios por rol
    final usuariosPorRol = <String, List<Map<String, dynamic>>>{};
    for (final usuario in _usuariosFiltrados) {
      final rol = (usuario['rol'] ?? '').toString();
      usuariosPorRol.putIfAbsent(rol, () => []).add(usuario);
    }

    // Orden de roles para mostrar
    final ordenRoles = ['admin', 'duenio', 'repartidor'];
    
    // Filtrar solo los roles que tienen usuarios
    final rolesConUsuarios = ordenRoles.where((rol) => 
        usuariosPorRol.containsKey(rol) && usuariosPorRol[rol]!.isNotEmpty).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rolesConUsuarios.length,
      itemBuilder: (context, index) {
        final rol = rolesConUsuarios[index];
        final usuariosDelRol = usuariosPorRol[rol] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del grupo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _obtenerColorPorRol(rol).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${rol.toUpperCase()} (${usuariosDelRol.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // Usuarios del grupo
            ...usuariosDelRol.map((usuario) => Card(
              color: _obtenerColorPorRol(usuario['rol'] ?? ''),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(((usuario['name'] ?? usuario['nombre'] ?? '')).isNotEmpty 
                      ? (usuario['name'] ?? usuario['nombre'] ?? '')[0].toUpperCase()
                      : '?'),
                ),
                title: Text(usuario['name'] ?? usuario['nombre'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${usuario['email'] ?? ''}'),
                    Text('Rol: ${usuario['rol'] ?? ''}'),
                    if (usuario['rol'] == 'duenio' && usuario['restaurante_id'] != null)
                      Text('Restaurante: ${_obtenerNombreRestaurante(usuario['restaurante_id'])}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialogoEditarUsuario(usuario),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarEliminarUsuario(usuario),
                    ),
                  ],
                ),
              ),
            )).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
} 