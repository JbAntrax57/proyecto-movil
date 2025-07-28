import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/admin_negocios_provider.dart';

// negocios_section.dart - Pantalla de gestión de negocios para el admin
// Refactorizada para usar AdminNegociosProvider y separar lógica de negocio
class AdminNegociosSection extends StatefulWidget {
  const AdminNegociosSection({super.key});

  @override
  State<AdminNegociosSection> createState() => _AdminNegociosSectionState();
}

class _AdminNegociosSectionState extends State<AdminNegociosSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminNegociosProvider>().inicializarNegocios(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminNegociosProvider>(
      builder: (context, negociosProvider, child) {
        if (negociosProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (negociosProvider.error != null) {
          return Center(child: Text('Error: ${negociosProvider.error}'));
        }

        final negocios = negociosProvider.negociosFiltrados;
        if (negocios.isEmpty) {
          return const Center(child: Text('No hay negocios registrados.'));
        }

        // Obtener todas las categorías únicas para el filtro
        final categoriasUnicas = negociosProvider.obtenerCategoriasUnicas();

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
                          negociosProvider.setFiltroNombre(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filtro por categoría
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        value: negociosProvider.filtroCategoriaId,
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
                          negociosProvider.setFiltroCategoriaId(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: isDesktop
                  ? _buildDataTable(negocios, negociosProvider)
                  : _buildListView(negocios, negociosProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> negocios, AdminNegociosProvider negociosProvider) {
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
                  onPressed: () => negociosProvider.mostrarBottomSheetEditarNegocio(context, negocio),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => negociosProvider.confirmarEliminarNegocio(context, negocio),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> negocios, AdminNegociosProvider negociosProvider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: negocios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final negocio = negocios[index];
        return _buildNegocioCard(negocio, negociosProvider);
      },
    );
  }

  Widget _buildNegocioCard(Map<String, dynamic> negocio, AdminNegociosProvider negociosProvider) {
    final categorias = (negocio['categorias'] as List<String>?) ?? [];
    final isDestacado = negocio['destacado'] == true;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDestacado ? Colors.amber.shade300 : Colors.grey.shade200,
          width: isDestacado ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isDestacado 
            ? LinearGradient(
                colors: [Colors.amber.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y badge destacado
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                negocio['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isDestacado)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Destacado',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botones de acción
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          negociosProvider.mostrarBottomSheetEditarNegocio(context, negocio);
                          break;
                        case 'delete':
                          negociosProvider.confirmarEliminarNegocio(context, negocio);
                          break;
                        case 'toggle_destacado':
                          negociosProvider.toggleDestacado(negocio);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_destacado',
                        child: Row(
                          children: [
                            Icon(
                              isDestacado ? Icons.star_border : Icons.star,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Text(isDestacado ? 'Quitar destacado' : 'Marcar destacado'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información del dueño
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dueño: ${negocio['duenio_nombre'] ?? 'No asignado'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Dirección
              if (negocio['direccion'] != null && negocio['direccion'].toString().isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        negocio['direccion'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              
              if (negocio['direccion'] != null && negocio['direccion'].toString().isNotEmpty)
                const SizedBox(height: 8),
              
              // Teléfono
              if (negocio['telefono'] != null && negocio['telefono'].toString().isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      negocio['telefono'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              
              if (negocio['telefono'] != null && negocio['telefono'].toString().isNotEmpty)
                const SizedBox(height: 12),
              
              // Categorías
              if (categorias.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: categorias.map((categoria) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        categoria,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Descripción
              if (negocio['descripcion'] != null && negocio['descripcion'].toString().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        negocio['descripcion'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 