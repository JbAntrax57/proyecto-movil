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

  // Filtros
  String _filtroNombre = '';
  int? _filtroCategoriaId;

  @override
  void initState() {
    super.initState();
    _negociosFuture = _obtenerNegocios();
  }

  Future<List<Map<String, dynamic>>> _obtenerNegocios() async {
    final negocios = await Supabase.instance.client
        .from('negocios')
        .select()
        .order('nombre', ascending: true);
    // Obtener dueños (usuarios) para mostrar el nombre del dueño
    final usuarios = await Supabase.instance.client.from('usuarios').select('id, name');
    final usuariosMap = {for (var u in usuarios) u['id']: u['name']};
    
    // Obtener categorías para cada negocio
    for (var negocio in negocios) {
      if (negocio['usuarioid'] != null) {
        negocio['duenio_nombre'] = usuariosMap[negocio['usuarioid']];
      }
      // Obtener categorías del negocio (nueva estructura)
      negocio['categorias'] = await _obtenerCategoriasNegocio(negocio['id']);
    }
    // Ordenar por nombre y luego por la primera categoría (en memoria)
    negocios.sort((a, b) {
      final nombreA = (a['nombre'] ?? '').toString();
      final nombreB = (b['nombre'] ?? '').toString();
      final cmpNombre = nombreA.compareTo(nombreB);
      if (cmpNombre != 0) return cmpNombre;
      final catA = ((a['categorias'] as List<String>?)?.isNotEmpty ?? false) ? (a['categorias'] as List<String>)[0] : '';
      final catB = ((b['categorias'] as List<String>?)?.isNotEmpty ?? false) ? (b['categorias'] as List<String>)[0] : '';
      return catA.compareTo(catB);
    });
    return List<Map<String, dynamic>>.from(negocios);
  }

  Future<List<String>> _obtenerCategoriasNegocio(String negocioId) async {
    try {
      final categoriasData = await Supabase.instance.client
          .from('negocios_categorias')
          .select('categorias_principales(nombre)')
          .eq('negocio_id', negocioId);
      if (categoriasData.isNotEmpty) {
        return categoriasData
            .map((item) => item['categorias_principales']['nombre'] as String)
            .toList();
      }
    } catch (e) {}
    return [];
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
              return Center(child: Text('Error:  [31m [1m${snapshot.error} [0m'));
            }
            final negocios = snapshot.data ?? [];
            if (negocios.isEmpty) {
              return const Center(child: Text('No hay negocios registrados.'));
            }

            // Obtener todas las categorías únicas para el filtro
            final categoriasUnicas = <int, String>{};
            for (final negocio in negocios) {
              if (negocio['categorias'] != null) {
                for (final cat in (negocio['categorias'] as List<String>)) {
                  categoriasUnicas[cat.hashCode] = cat;
                }
              }
            }

            // Aplicar filtros
            List<Map<String, dynamic>> negociosFiltrados = negocios.where((negocio) {
              final nombre = (negocio['nombre'] ?? '').toString().toLowerCase();
              final coincideNombre = nombre.contains(_filtroNombre.toLowerCase());
              final coincideCategoria = _filtroCategoriaId == null ||
                (negocio['categorias'] as List<String>?)?.any((cat) => cat.hashCode == _filtroCategoriaId) == true;
              return coincideNombre && coincideCategoria;
            }).toList();

            final isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Filtro por nombre
                        SizedBox(
                          width: 220,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Buscar restaurante',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _filtroNombre = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Filtro por categoría
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<int>(
                            value: _filtroCategoriaId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Todas'),
                              ),
                              ...categoriasUnicas.entries.map((e) => DropdownMenuItem<int>(
                                value: e.key,
                                child: Text(e.value),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filtroCategoriaId = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: isDesktop
                      ? _buildDataTable(negociosFiltrados)
                      : _buildListView(negociosFiltrados),
                ),
              ],
            );
          },
        ),
        // Botón flotante
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _mostrarBottomSheetCrearNegocio(context),
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
            DataCell(Text((negocio['categorias'] as List<String>?)?.join(', ') ?? '')),
            DataCell(Icon(
              negocio['destacado'] == true ? Icons.star : Icons.star_border,
              color: negocio['destacado'] == true ? Colors.amber : Colors.grey,
            )),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarBottomSheetEditarNegocio(context, negocio),
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
                Text('Categorías: ${(negocio['categorias'] as List<String>?)?.join(', ') ?? ''}'),
                if (negocio['descripcion'] != null && negocio['descripcion'].toString().isNotEmpty)
                  Text('Descripción: ${negocio['descripcion']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarBottomSheetEditarNegocio(context, negocio),
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

  Future<void> _mostrarBottomSheetCrearNegocio(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: _NegocioForm(
            onSuccess: () {
              Navigator.of(context).pop();
              _refrescar();
            },
          ),
        );
      },
    );
  }

  Future<void> _mostrarBottomSheetEditarNegocio(BuildContext context, Map<String, dynamic> negocio) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: _NegocioForm(
            negocio: negocio,
            onSuccess: () {
              Navigator.of(context).pop();
              _refrescar();
            },
          ),
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
}

class _NegocioForm extends StatefulWidget {
  final Map<String, dynamic>? negocio;
  final VoidCallback onSuccess;
  const _NegocioForm({this.negocio, required this.onSuccess});

  @override
  State<_NegocioForm> createState() => _NegocioFormState();
}

class _NegocioFormState extends State<_NegocioForm> {
  late TextEditingController nombreController;
  late TextEditingController direccionController;
  late TextEditingController telefonoController;
  late TextEditingController descripcionController;
  bool destacado = false;
  String? usuarioidSeleccionado;
  List<int> categoriasSeleccionadas = [];
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> categorias = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.negocio?['nombre'] ?? '');
    direccionController = TextEditingController(text: widget.negocio?['direccion'] ?? '');
    telefonoController = TextEditingController(text: widget.negocio?['telefono'] ?? '');
    descripcionController = TextEditingController(text: widget.negocio?['descripcion'] ?? '');
    destacado = widget.negocio?['destacado'] == true;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final usuariosData = await Supabase.instance.client
        .from('usuarios')
        .select('id, name')
        .eq('rol', 'duenio')
        .not('id', 'is', null);
    final categoriasData = await Supabase.instance.client
        .from('categorias_principales')
        .select('id, nombre, icono, color')
        .eq('activo', true)
        .order('nombre');
    usuarios = List<Map<String, dynamic>>.from(usuariosData);
    categorias = List<Map<String, dynamic>>.from(categoriasData);
    if (widget.negocio != null) {
      // Editar: cargar categorías actuales
      final categoriasActuales = await Supabase.instance.client
          .from('negocios_categorias')
          .select('categoria_id')
          .eq('negocio_id', widget.negocio!['id']);
      categoriasSeleccionadas = categoriasActuales
          .map((item) => item['categoria_id'] as int)
          .toList();
      usuarioidSeleccionado = widget.negocio!['usuarioid']?.toString();
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
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
            controller: descripcionController,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text('Categorías:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: () async {
                  final nuevaCategoria = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) {
                      final nombreCtrl = TextEditingController();
                      final descCtrl = TextEditingController();
                      return AlertDialog(
                        title: const Text('Nueva categoría'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nombreCtrl,
                              decoration: const InputDecoration(labelText: 'Nombre'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descCtrl,
                              decoration: const InputDecoration(labelText: 'Descripción'),
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
                              final nombre = nombreCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              if (nombre.isEmpty) return;
                              // Insertar en la BD
                              final res = await Supabase.instance.client
                                  .from('categorias_principales')
                                  .insert({
                                    'nombre': nombre,
                                    'descripcion': desc,
                                    'activo': true,
                                  })
                                  .select()
                                  .single();
                              Navigator.of(context).pop(res);
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      );
                    },
                  );
                  if (nuevaCategoria != null) {
                    setState(() {
                      categorias.add(nuevaCategoria);
                      categoriasSeleccionadas.add(nuevaCategoria['id'] as int);
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              child: ListView.builder(
                itemCount: categorias.length,
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  final categoriaId = categoria['id'] as int;
                  final isSelected = categoriasSeleccionadas.contains(categoriaId);
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Text(categoria['icono'] ?? ''),
                        const SizedBox(width: 8),
                        Expanded(child: Text(categoria['nombre'])),
                      ],
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          categoriasSeleccionadas.add(categoriaId);
                        } else {
                          categoriasSeleccionadas.remove(categoriaId);
                        }
                      });
                    },
                    activeColor: Color(int.parse(categoria['color']?.replaceAll('#', '0xFF') ?? '0xFFFF6B6B')),
                  );
                },
              ),
            ),
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
              setState(() {
                usuarioidSeleccionado = value;
              });
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Destacado'),
            value: destacado,
            onChanged: (value) {
              setState(() {
                destacado = value ?? false;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _guardarNegocio,
                child: Text(widget.negocio == null ? 'Crear' : 'Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _guardarNegocio() async {
    print('🔍 Iniciando creación/edición de negocio...');
    
    if (usuarioidSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un dueño')),
      );
      return;
    }
    if (categoriasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos una categoría')),
      );
      return;
    }
    
    try {
      print('📝 Datos a guardar:');
      print('  - Nombre: ${nombreController.text}');
      print('  - Dirección: ${direccionController.text}');
      print('  - Teléfono: ${telefonoController.text}');
      print('  - Descripción: ${descripcionController.text}');
      print('  - Destacado: $destacado');
      print('  - Usuario ID: $usuarioidSeleccionado');
      print('  - Categorías seleccionadas: $categoriasSeleccionadas');
      
      if (widget.negocio == null) {
        // Crear
        print('🆕 Creando nuevo negocio...');
        final insertNegocio = await Supabase.instance.client
            .from('negocios')
            .insert({
              'nombre': nombreController.text,
              'direccion': direccionController.text,
              'telefono': telefonoController.text,
              'descripcion': descripcionController.text,
              'destacado': destacado,
              'usuarioid': usuarioidSeleccionado,
            })
            .select();
        
        print('✅ Negocio creado con ID: ${insertNegocio[0]['id']}');
        final negocioId = insertNegocio[0]['id'];
        
        print('📋 Insertando categorías...');
        for (final catId in categoriasSeleccionadas) {
          await Supabase.instance.client
              .from('negocios_categorias')
              .insert({
                'negocio_id': negocioId,
                'categoria_id': catId,
              });
          print('  ✅ Categoría $catId insertada');
        }
        
        print('🎉 Negocio creado exitosamente');
        
        // Mostrar SnackBar ANTES de cerrar el modal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Negocio creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Esperar un momento para que se vea el SnackBar
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Luego cerrar el modal
        widget.onSuccess();
        
      } else {
        // Editar
        print('✏️ Editando negocio existente...');
        await Supabase.instance.client
            .from('negocios')
            .update({
              'nombre': nombreController.text,
              'direccion': direccionController.text,
              'telefono': telefonoController.text,
              'descripcion': descripcionController.text,
              'destacado': destacado,
            })
            .eq('id', widget.negocio!['id']);
        
        print('🗑️ Eliminando categorías anteriores...');
        await Supabase.instance.client
            .from('negocios_categorias')
            .delete()
            .eq('negocio_id', widget.negocio!['id']);
        
        print('📋 Insertando nuevas categorías...');
        for (final catId in categoriasSeleccionadas) {
          await Supabase.instance.client
              .from('negocios_categorias')
              .insert({
                'negocio_id': widget.negocio!['id'],
                'categoria_id': catId,
              });
          print('  ✅ Categoría $catId insertada');
        }
        
        print('🎉 Negocio actualizado exitosamente');
        
        // Mostrar SnackBar ANTES de cerrar el modal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Negocio actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Esperar un momento para que se vea el SnackBar
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Luego cerrar el modal
        widget.onSuccess();
      }
      
    } catch (e) {
      print('❌ Error al guardar negocio: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar negocio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
} 