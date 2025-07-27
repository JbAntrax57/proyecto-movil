import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNegociosProvider extends ChangeNotifier {
  // Estado
  List<Map<String, dynamic>> _negocios = [];
  List<Map<String, dynamic>> _negociosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _filtroNombre = '';
  int? _filtroCategoriaId;

  // Getters
  List<Map<String, dynamic>> get negocios => _negocios;
  List<Map<String, dynamic>> get negociosFiltrados => _negociosFiltrados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filtroNombre => _filtroNombre;
  int? get filtroCategoriaId => _filtroCategoriaId;

  // Inicializar el provider
  Future<void> inicializarNegocios(BuildContext context) async {
    await cargarNegocios();
  }

  // Cargar negocios
  Future<void> cargarNegocios() async {
    try {
      _setLoading(true);
      _setError(null);

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
        negocio['categorias'] = await obtenerCategoriasNegocio(negocio['id']);
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

      _negocios = List<Map<String, dynamic>>.from(negocios);
      _setLoading(false);
      aplicarFiltros();
    } catch (e) {
      _setError('Error al cargar negocios: $e');
      _setLoading(false);
    }
  }

  // Obtener categorías de un negocio
  Future<List<String>> obtenerCategoriasNegocio(String negocioId) async {
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
    } catch (e) {
      // Error silencioso
    }
    return [];
  }

  // Aplicar filtros
  void aplicarFiltros() {
    _negociosFiltrados = _negocios.where((negocio) {
      final nombre = (negocio['nombre'] ?? '').toString().toLowerCase();
      final coincideNombre = nombre.contains(_filtroNombre.toLowerCase());
      final coincideCategoria = _filtroCategoriaId == null ||
        (negocio['categorias'] as List<String>?)?.any((cat) => cat.hashCode == _filtroCategoriaId) == true;
      return coincideNombre && coincideCategoria;
    }).toList();
    
    notifyListeners();
  }

  // Obtener categorías únicas para filtros
  Map<int, String> obtenerCategoriasUnicas() {
    final categoriasUnicas = <int, String>{};
    for (final negocio in _negocios) {
      if (negocio['categorias'] != null) {
        for (final cat in (negocio['categorias'] as List<String>)) {
          categoriasUnicas[cat.hashCode] = cat;
        }
      }
    }
    return categoriasUnicas;
  }

  // Mostrar bottom sheet crear negocio
  Future<void> mostrarBottomSheetCrearNegocio(BuildContext context) async {
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
          child: NegocioForm(
            onSuccess: () {
              Navigator.of(context).pop();
              cargarNegocios();
            },
          ),
        );
      },
    );
  }

  // Mostrar bottom sheet editar negocio
  Future<void> mostrarBottomSheetEditarNegocio(BuildContext context, Map<String, dynamic> negocio) async {
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
          child: NegocioForm(
            negocio: negocio,
            onSuccess: () {
              Navigator.of(context).pop();
              cargarNegocios();
            },
          ),
        );
      },
    );
  }

  // Confirmar eliminar negocio
  Future<void> confirmarEliminarNegocio(BuildContext context, Map<String, dynamic> negocio) async {
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
                  await cargarNegocios();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Negocio eliminado correctamente')),
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

  // Setters
  void setFiltroNombre(String filtroNombre) {
    _filtroNombre = filtroNombre;
    aplicarFiltros();
  }

  void setFiltroCategoriaId(int? filtroCategoriaId) {
    _filtroCategoriaId = filtroCategoriaId;
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

// Widget para el formulario de negocio
class NegocioForm extends StatefulWidget {
  final Map<String, dynamic>? negocio;
  final VoidCallback onSuccess;
  const NegocioForm({this.negocio, required this.onSuccess});

  @override
  State<NegocioForm> createState() => _NegocioFormState();
}

class _NegocioFormState extends State<NegocioForm> {
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
    cargarDatos();
  }

  Future<void> cargarDatos() async {
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
                onPressed: guardarNegocio,
                child: Text(widget.negocio == null ? 'Crear' : 'Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> guardarNegocio() async {
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
      if (widget.negocio == null) {
        // Crear
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
        
        final negocioId = insertNegocio[0]['id'];
        
        // Insertar categorías
        for (final catId in categoriasSeleccionadas) {
          await Supabase.instance.client
              .from('negocios_categorias')
              .insert({
                'negocio_id': negocioId,
                'categoria_id': catId,
              });
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Negocio creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        widget.onSuccess();
        
      } else {
        // Editar
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
        
        // Eliminar categorías anteriores
        await Supabase.instance.client
            .from('negocios_categorias')
            .delete()
            .eq('negocio_id', widget.negocio!['id']);
        
        // Insertar nuevas categorías
        for (final catId in categoriasSeleccionadas) {
          await Supabase.instance.client
              .from('negocios_categorias')
              .insert({
                'negocio_id': widget.negocio!['id'],
                'categoria_id': catId,
              });
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Negocio actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        widget.onSuccess();
      }
      
    } catch (e) {
      if (context.mounted) {
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