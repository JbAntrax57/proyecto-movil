import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../providers/menu_duenio_provider.dart';
import 'package:flutter/services.dart'; // Para personalizar la status bar

// menu_screen.dart - Pantalla de menú del dueño de negocio
// Refactorizada para usar MenuDuenioProvider y separar lógica de negocio
class DuenioMenuScreen extends StatefulWidget {
  const DuenioMenuScreen({super.key});

  @override
  State<DuenioMenuScreen> createState() => _DuenioMenuScreenState();
}

class _DuenioMenuScreenState extends State<DuenioMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MenuDuenioProvider>().inicializarMenu(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuDuenioProvider>(
      builder: (context, menuProvider, child) {
        // Obtenemos el negocioId del dueño logueado
        final userProvider = Provider.of<CarritoProvider>(context, listen: false);
        final negocioId = userProvider.restauranteId;
        
        if (negocioId == null || negocioId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Menú del negocio'),
              centerTitle: true,
            ),
            body: const Center(
              child: Text(
                'No se encontró el ID del negocio. Por favor, vuelve a iniciar sesión o contacta al administrador.',
                style: TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Envolvemos con AnnotatedRegion para personalizar la status bar
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.white, // Fondo blanco para la status bar
            statusBarIconBrightness: Brightness.dark, // Iconos oscuros
            statusBarBrightness: Brightness.light, // Para iOS
          ),
          child: SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Menú del negocio'),
                centerTitle: true,
              ),
              body: Column(
                children: [
                  // Barra de búsqueda
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: menuProvider.searchController,
                      focusNode: menuProvider.searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: menuProvider.searchText.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  menuProvider.limpiarBusqueda();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onChanged: (value) {
                        menuProvider.setSearchText(value);
                      },
                      autofocus: false,
                    ),
                  ),
                  // Lista de productos
                  Expanded(
                    child: menuProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : menuProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error al cargar productos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  menuProvider.error!,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => menuProvider.cargarProductos(context),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : menuProvider.getProductosFiltrados().isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron productos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Intenta con otro término de búsqueda',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: menuProvider.getProductosFiltrados().length + 1,
                            itemBuilder: (context, index) {
                              if (index == menuProvider.getProductosFiltrados().length) {
                                // Espacio extra al final para que el FAB no tape el último card
                                return const SizedBox(height: 40);
                              }
                              final producto = menuProvider.getProductosFiltrados()[index];
                              return Card(
                                elevation: 5,
                                margin: const EdgeInsets.only(bottom: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: SizedBox(
                                  height: 120, // Altura fija para el card
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Imagen del producto con badge 'Nuevo' encima si aplica
                                      Stack(
                                        children: [
                                          // Imagen del producto con altura suficiente para el badge
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                            ),
                                            child: producto['img'] != null && producto['img'].toString().isNotEmpty
                                                ? Image.network(
                                                    producto['img'],
                                                    width: 110,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 110,
                                                      height: 120,
                                                      color: Colors.grey[100],
                                                      child: const Icon(
                                                        Icons.fastfood,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 110,
                                                    height: 120,
                                                    color: Colors.grey[100],
                                                    child: const Icon(
                                                      Icons.fastfood,
                                                      color: Colors.grey,
                                                      size: 40,
                                                    ),
                                                  ),
                                          ),
                                          // Badge 'Nuevo' en la esquina superior izquierda de la imagen
                                          if (menuProvider.esNuevo(producto['created_at']))
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withValues(alpha: 0.85),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.08),
                                                      blurRadius: 4,
                                                      offset: const Offset(1, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Text(
                                                  'Nuevo',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 18),
                                      // Info principal
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              producto['nombre'] ?? 'Sin nombre',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              producto['descripcion'] ?? 'Sin descripción',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Center(
                                              child: Text(
                                                '\$${menuProvider.formatearPrecio(producto['precio'])}',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botones de editar y eliminar
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Editar',
                                            onPressed: () async {
                                              final result = await menuProvider.mostrarFormularioProducto(
                                                context,
                                                negocioId,
                                                producto: producto,
                                              );
                                              if (result == true && context.mounted) {
                                                // Refrescar la lista si se editó
                                                await menuProvider.cargarProductos(context);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Eliminar',
                                            onPressed: () async {
                                              try {
                                                await menuProvider.eliminarProducto(producto['id'].toString());
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Producto eliminado'),
                                                      behavior: SnackBarBehavior.floating,
                                                      margin: EdgeInsets.only(
                                                        top: 60,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error al eliminar producto: $e'),
                                                      backgroundColor: Colors.red,
                                                      behavior: SnackBarBehavior.floating,
                                                      margin: const EdgeInsets.only(
                                                        top: 60,
                                                        left: 16,
                                                        right: 16,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await menuProvider.mostrarFormularioProducto(
                    context,
                    negocioId,
                  );
                  if (result == true && context.mounted) {
                    // Refrescar la lista si se agregó
                    await menuProvider.cargarProductos(context);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar producto'),
              ),
            ),
          ),
        );
      },
    );
  }
} 