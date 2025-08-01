import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/admin_usuarios_provider.dart';
import '../../../core/localization.dart';

// usuarios_section.dart - Pantalla de gestión de usuarios para el admin
// Refactorizada para usar AdminUsuariosProvider y separar lógica de negocio
class AdminUsuariosSection extends StatefulWidget {
  const AdminUsuariosSection({super.key});

  @override
  State<AdminUsuariosSection> createState() => _AdminUsuariosSectionState();
}

class _AdminUsuariosSectionState extends State<AdminUsuariosSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminUsuariosProvider>().inicializarUsuarios(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUsuariosProvider>(
      builder: (context, usuariosProvider, child) {
        if (usuariosProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (usuariosProvider.error != null) {
          return Center(child: Text(usuariosProvider.error!));
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
                          usuariosProvider.setBusqueda(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: usuariosProvider.filtroRol,
                        decoration: const InputDecoration(labelText: 'Filtrar por rol'),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'Todos', child: Text(AppLocalizations.of(context).get('todos'))),
                          DropdownMenuItem(value: 'admin', child: Text(AppLocalizations.of(context).get('admin'))),
                          DropdownMenuItem(value: 'duenio', child: Text(AppLocalizations.of(context).get('duenio'))),
                          DropdownMenuItem(value: 'repartidor', child: Text(AppLocalizations.of(context).get('repartidor'))),
                        ],
                        onChanged: (value) {
                          usuariosProvider.setFiltroRol(value ?? 'Todos');
                        },
                      ),
                    ],
                  ),
                ),
                // Contenido
                Expanded(
                  child: isDesktop
                      ? _buildDataTable(usuariosProvider)
                      : _buildListView(usuariosProvider),
                ),
              ],
            ),
            // Botón flotante
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => usuariosProvider.mostrarDialogoCrearUsuario(context),
                backgroundColor: Colors.green,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable(AdminUsuariosProvider usuariosProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(AppLocalizations.of(context).get('nombre'))),
          DataColumn(label: Text(AppLocalizations.of(context).get('email'))),
          DataColumn(label: Text(AppLocalizations.of(context).get('rol'))),
          DataColumn(label: Text(AppLocalizations.of(context).get('restaurante'))),
          DataColumn(label: Text(AppLocalizations.of(context).get('acciones'))),
        ],
        rows: usuariosProvider.usuariosFiltrados.map((usuario) {
          return DataRow(cells: [
            DataCell(Text(usuario['name'] ?? usuario['nombre'] ?? '')),
            DataCell(Text(usuario['email'] ?? '')),
            DataCell(Text(usuario['rol'] ?? '')),
            DataCell(Text(usuariosProvider.obtenerNombreRestaurante(usuario['restaurante_id']))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => usuariosProvider.mostrarDialogoEditarUsuario(context, usuario),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => usuariosProvider.confirmarEliminarUsuario(context, usuario),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildListView(AdminUsuariosProvider usuariosProvider) {
    // Agrupar usuarios por rol
    final usuariosPorRol = <String, List<Map<String, dynamic>>>{};
    for (final usuario in usuariosProvider.usuariosFiltrados) {
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
                color: usuariosProvider.obtenerColorPorRol(rol).withValues(alpha: 0.3),
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
              color: usuariosProvider.obtenerColorPorRol(usuario['rol'] ?? ''),
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
                      Text('Restaurante: ${usuariosProvider.obtenerNombreRestaurante(usuario['restaurante_id'])}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => usuariosProvider.mostrarDialogoEditarUsuario(context, usuario),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => usuariosProvider.confirmarEliminarUsuario(context, usuario),
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