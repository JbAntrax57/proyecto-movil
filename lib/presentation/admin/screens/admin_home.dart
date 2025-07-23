import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _AdminSectionUsuarios(),
    _AdminSectionPlaceholder(title: 'Negocios', icon: Icons.store),
    _AdminSectionPlaceholder(title: 'Reportes', icon: Icons.bar_chart),
    _AdminSectionPlaceholder(title: 'Pedidos', icon: Icons.receipt_long),
    _AdminSectionPlaceholder(title: 'Productos', icon: Icons.restaurant_menu),
    _AdminSectionPlaceholder(title: 'Configuración', icon: Icons.settings),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex] is _AdminSectionPlaceholder
            ? (_pages[_selectedIndex] as _AdminSectionPlaceholder).title
            : 'Admin'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Negocios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}

class _AdminSectionPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const _AdminSectionPlaceholder({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.blueGrey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Próximamente...'),
        ],
      ),
    );
  }
}

class _AdminSectionUsuarios extends StatefulWidget {
  const _AdminSectionUsuarios();

  @override
  State<_AdminSectionUsuarios> createState() => _AdminSectionUsuariosState();
}

class _AdminSectionUsuariosState extends State<_AdminSectionUsuarios> {
  late Future<List<Map<String, dynamic>>> _usuariosFuture;
  String _searchQuery = '';
  String _selectedRole = 'todos';

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _obtenerUsuarios();
  }

  Future<List<Map<String, dynamic>>> _obtenerUsuarios() async {
    final usuarios = await Supabase.instance.client.from('usuarios').select();
    final negocios = await Supabase.instance.client.from('negocios').select('id, nombre');
    final negociosMap = {for (var n in negocios) n['id']: n['nombre']};
    // Agrega el nombre del restaurante a cada usuario si es duenio
    for (var usuario in usuarios) {
      if ((usuario['rol'] ?? '') == 'duenio' && usuario['restaurante_id'] != null) {
        usuario['restaurante_nombre'] = negociosMap[usuario['restaurante_id']];
      }
    }
    return List<Map<String, dynamic>>.from(usuarios);
  }

  void _refrescar() {
    setState(() {
      _usuariosFuture = _obtenerUsuarios();
    });
  }

  List<Map<String, dynamic>> _filtrarUsuarios(List<Map<String, dynamic>> usuarios) {
    return usuarios.where((usuario) {
      final nombre = (usuario['name'] ?? usuario['nombre'] ?? '').toString().toLowerCase();
      final correo = (usuario['email'] ?? '').toString().toLowerCase();
      final rol = (usuario['rol'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchQuery = nombre.contains(query) || correo.contains(query);
      final matchRol = _selectedRole == 'todos' || rol == _selectedRole;
      return matchQuery && matchRol;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre o correo',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                      DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                      DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _usuariosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final usuarios = _filtrarUsuarios(snapshot.data ?? []);
                  if (usuarios.isEmpty) {
                    return const Center(child: Text('No hay usuarios registrados.'));
                  }
                  final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;
                  return isDesktop
                      ? _buildDataTable(usuarios)
                      : _buildListView(usuarios);
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: _mostrarDialogoCrearUsuario,
            tooltip: 'Agregar usuario',
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> usuarios) {
    final tieneDuenios = usuarios.any((u) => (u['rol'] ?? '') == 'duenio');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Nombre')),
          const DataColumn(label: Text('Rol')),
          if (tieneDuenios) const DataColumn(label: Text('Restaurante')),
          const DataColumn(label: Text('Acciones')),
        ],
        rows: usuarios.map((usuario) {
          final cells = [
            DataCell(Text(usuario['name'] ?? usuario['nombre'] ?? '')),
            DataCell(Text(usuario['rol'] ?? '')),
          ];
          if ((usuario['rol'] ?? '') == 'duenio') {
            cells.add(DataCell(Text(usuario['restaurante_nombre'] ?? '')));
          } else if (tieneDuenios) {
            cells.add(const DataCell(Text('')));
          }
          cells.add(DataCell(Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  _mostrarDialogoEditarUsuario(usuario);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _confirmarEliminarUsuario(usuario);
                },
              ),
            ],
          )));
          return DataRow(cells: cells);
        }).toList(),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> usuarios) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final esDuenio = (usuario['rol'] ?? '') == 'duenio';
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(usuario['name'] ?? usuario['nombre'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rol: ${usuario['rol'] ?? ''}'),
                if (esDuenio)
                  Text('Restaurante: ${usuario['restaurante_nombre'] ?? ''}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _mostrarDialogoEditarUsuario(usuario);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
                    _confirmarEliminarUsuario(usuario);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditarUsuario(Map<String, dynamic> usuario) {
    final nombreController = TextEditingController(text: usuario['name'] ?? usuario['nombre'] ?? '');
    String rol = usuario['rol'] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                  DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                  DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) rol = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoNombre = nombreController.text.trim().toUpperCase();
                if (nuevoNombre.isEmpty) return;
                try {
                  await Supabase.instance.client
                      .from('usuarios')
                      .update({'name': nuevoNombre, 'rol': rol})
                      .eq('id', usuario['id']);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario actualizado')),
                    );
                    _refrescar();
                  }
                } catch (e) {
                  if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
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

  void _confirmarEliminarUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Estás seguro de que deseas eliminar a "${usuario['name'] ?? usuario['nombre'] ?? ''}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('usuarios')
                    .delete()
                    .eq('id', usuario['id']);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario eliminado')),
                  );
                  _refrescar();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearUsuario() async {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    String rol = 'cliente';
    String? restauranteId;
    List<Map<String, dynamic>> restaurantes = [];
    bool isLoading = true;
    String? error;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (isLoading && restaurantes.isEmpty && error == null) {
              Future.microtask(() async {
                try {
                  final data = await Supabase.instance.client.from('negocios').select('id, nombre');
                  setStateDialog(() {
                    restaurantes = List<Map<String, dynamic>>.from(data);
                    isLoading = false;
                  });
                } catch (e) {
                  setStateDialog(() {
                    error = 'Error al cargar restaurantes: $e';
                    isLoading = false;
                  });
                }
              });
            }
            return AlertDialog(
              title: const Text('Agregar usuario'),
              content: isLoading
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                  : error != null
                      ? Text(error!, style: const TextStyle(color: Colors.red))
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                                ),
                              TextField(
                                controller: nombreController,
                                decoration: const InputDecoration(labelText: 'Nombre'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passwordController,
                                decoration: const InputDecoration(labelText: 'Contraseña'),
                                obscureText: true,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: telefonoController,
                                decoration: const InputDecoration(labelText: 'Teléfono'),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: direccionController,
                                decoration: const InputDecoration(labelText: 'Dirección'),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: rol,
                                decoration: const InputDecoration(labelText: 'Rol'),
                                items: const [
                                  DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                                  DropdownMenuItem(value: 'duenio', child: Text('Dueño')),
                                  DropdownMenuItem(value: 'repartidor', child: Text('Repartidor')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (value) {
                                  if (value != null) setStateDialog(() => rol = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: restauranteId,
                                decoration: const InputDecoration(labelText: 'Restaurante'),
                                items: restaurantes
                                    .map((rest) => DropdownMenuItem(
                                          value: rest['id'].toString(),
                                          child: Text(rest['nombre'] ?? ''),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setStateDialog(() => restauranteId = value);
                                },
                              ),
                            ],
                          ),
                        ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final nombre = nombreController.text.trim().toUpperCase();
                          final email = emailController.text.trim();
                          final password = passwordController.text;
                          final telefono = telefonoController.text.trim();
                          final direccion = direccionController.text.trim();
                          if (nombre.isEmpty || email.isEmpty || password.isEmpty || telefono.isEmpty) {
                            setStateDialog(() {
                              error = 'Completa todos los campos obligatorios.';
                            });
                            return;
                          }
                          try {
                            await Supabase.instance.client.from('usuarios').insert({
                              'name': nombre,
                              'email': email,
                              'password': password,
                              'rol': rol,
                              'telephone': telefono,
                              'direccion': direccion,
                              if (restauranteId != null) 'restaurante_id': restauranteId,
                            });
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Usuario creado')),
                              );
                              _refrescar();
                            }
                          } catch (e) {
                            setStateDialog(() {
                              error = 'Error: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 