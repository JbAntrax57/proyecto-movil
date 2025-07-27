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
                  onPressed: () => negociosProvider.mostrarBottomSheetEditarNegocio(context, negocio),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => negociosProvider.confirmarEliminarNegocio(context, negocio),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 