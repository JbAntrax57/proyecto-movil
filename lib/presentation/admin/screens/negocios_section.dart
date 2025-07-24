import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNegociosSection extends StatefulWidget {
  const AdminNegociosSection({super.key});

  @override
  State<AdminNegociosSection> createState() => _AdminNegociosSectionState();
}

class _AdminNegociosSectionState extends State<AdminNegociosSection> {
  late Future<List<Map<String, dynamic>>> _negociosFuture;

  @override
  void initState() {
    super.initState();
    _negociosFuture = _obtenerNegocios();
  }

  Future<List<Map<String, dynamic>>> _obtenerNegocios() async {
    final negocios = await Supabase.instance.client.from('negocios').select();
    // Obtener dueños (usuarios) para mostrar el nombre del dueño
    final usuarios = await Supabase.instance.client.from('usuarios').select('id, name');
    final usuariosMap = {for (var u in usuarios) u['id']: u['name']};
    for (var negocio in negocios) {
      if (negocio['usuarioid'] != null) {
        negocio['duenio_nombre'] = usuariosMap[negocio['usuarioid']];
      }
    }
    return List<Map<String, dynamic>>.from(negocios);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _negociosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final negocios = snapshot.data ?? [];
            if (negocios.isEmpty) {
              return const Center(child: Text('No hay negocios registrados.'));
            }
            final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;
            return isDesktop
                ? _buildDataTable(negocios)
                : _buildListView(negocios);
          },
        ),
        // Botón flotante
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _mostrarDialogoCrearNegocio,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> negocios) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Dueño')),
          DataColumn(label: Text('Dirección')),
          DataColumn(label: Text('Teléfono')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Destacado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: negocios.map((negocio) {
          return DataRow(cells: [
            DataCell(Text(negocio['nombre'] ?? '')),
            DataCell(Text(negocio['duenio_nombre'] ?? '')),
            DataCell(Text(negocio['direccion'] ?? '')),
            DataCell(Text(negocio['telefono'] ?? '')),
            DataCell(Text(negocio['categoria'] ?? '')),
            DataCell(Icon(
              negocio['destacado'] == true ? Icons.star : Icons.star_border,
              color: negocio['destacado'] == true ? Colors.amber : Colors.grey,
            )),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarDialogoEditarNegocio(negocio),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminarNegocio(negocio),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> negocios) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: negocios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final negocio = negocios[index];
        return Card(
          child: ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.store),
                if (negocio['destacado'] == true)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            title: Text(negocio['nombre'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dueño: ${negocio['duenio_nombre'] ?? ''}'),
                Text('Dirección: ${negocio['direccion'] ?? ''}'),
                Text('Teléfono: ${negocio['telefono'] ?? ''}'),
                Text('Categoría: ${negocio['categoria'] ?? ''}'),
                if (negocio['descripcion'] != null && negocio['descripcion'].toString().isNotEmpty)
                  Text('Descripción: ${negocio['descripcion']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarDialogoEditarNegocio(negocio),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminarNegocio(negocio),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refrescar() {
    setState(() {
      _negociosFuture = _obtenerNegocios();
    });
  }

  Future<void> _mostrarDialogoEditarNegocio(Map<String, dynamic> negocio) async {
    final nombreController = TextEditingController(text: negocio['nombre'] ?? '');
    final direccionController = TextEditingController(text: negocio['direccion'] ?? '');
    final telefonoController = TextEditingController(text: negocio['telefono'] ?? '');
    final categoriaController = TextEditingController(text: negocio['categoria'] ?? '');
    final descripcionController = TextEditingController(text: negocio['descripcion'] ?? '');
    bool destacado = negocio['destacado'] == true;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Negocio'),
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
                      controller: direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoriaController,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Destacado'),
                      value: destacado,
                      onChanged: (value) {
                        setStateDialog(() {
                          destacado = value ?? false;
                        });
                      },
                    ),
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
                      await Supabase.instance.client
                          .from('negocios')
                          .update({
                            'nombre': nombreController.text,
                            'direccion': direccionController.text,
                            'telefono': telefonoController.text,
                            'categoria': categoriaController.text,
                            'descripcion': descripcionController.text,
                            'destacado': destacado,
                          })
                          .eq('id', negocio['id']);

                      Navigator.of(context).pop();
                      _refrescar();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Negocio actualizado correctamente')),
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
      },
    );
  }

  Future<void> _confirmarEliminarNegocio(Map<String, dynamic> negocio) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar el negocio "${negocio['nombre']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('negocios')
                      .delete()
                      .eq('id', negocio['id']);

                  Navigator.of(context).pop();
                  _refrescar();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Negocio eliminado correctamente')),
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

  Future<void> _mostrarDialogoCrearNegocio() async {
    final nombreController = TextEditingController();
    final direccionController = TextEditingController();
    final telefonoController = TextEditingController();
    final categoriaController = TextEditingController();
    final descripcionController = TextEditingController();
    bool destacado = false;
    String? usuarioidSeleccionado;

    // Obtener usuarios para seleccionar dueño
    final usuarios = await Supabase.instance.client
        .from('usuarios')
        .select('id, name')
        .eq('rol', 'duenio')
        .not('id', 'is', null);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Crear Nuevo Negocio'),
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
                      controller: direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoriaController,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: usuarioidSeleccionado,
                      decoration: const InputDecoration(labelText: 'Dueño'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Seleccionar dueño')),
                        ...usuarios.map((usuario) => DropdownMenuItem(
                              value: usuario['id']?.toString(),
                              child: Text(usuario['name'] ?? ''),
                            )),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          usuarioidSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Destacado'),
                      value: destacado,
                      onChanged: (value) {
                        setStateDialog(() {
                          destacado = value ?? false;
                        });
                      },
                    ),
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
                    if (usuarioidSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debes seleccionar un dueño')),
                      );
                      return;
                    }

                    try {
                      await Supabase.instance.client
                          .from('negocios')
                          .insert({
                            'nombre': nombreController.text,
                            'direccion': direccionController.text,
                            'telefono': telefonoController.text,
                            'categoria': categoriaController.text,
                            'descripcion': descripcionController.text,
                            'destacado': destacado,
                            'usuarioid': usuarioidSeleccionado,
                          });

                      Navigator.of(context).pop();
                      _refrescar();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Negocio creado correctamente')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al crear negocio: $e')),
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
} 