import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cliente/providers/carrito_provider.dart';
import '../providers/menu_duenio_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
        final userProvider = Provider.of<CarritoProvider>(context, listen: false);
        final negocioId = userProvider.restauranteId;
        
        if (negocioId == null || negocioId.isEmpty) {
          return _buildErrorScreen('No se encontró el ID del negocio. Por favor, vuelve a iniciar sesión.');
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => menuProvider.cargarProductos(context),
                child: CustomScrollView(
                  slivers: [
                    // AppBar fijo
                    SliverToBoxAdapter(
                      child: _buildAppBar(),
                    ),
                    // Barra de búsqueda fija
                    SliverToBoxAdapter(
                      child: _buildSearchSection(menuProvider),
                    ),
                    // Estadísticas que se ocultan
                    SliverToBoxAdapter(
                      child: _buildStatsSection(menuProvider),
                    ),
                    // Contenido scrolleable
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildContentSection(menuProvider, negocioId),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(menuProvider, negocioId),
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de retroceso
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: Colors.blue[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menú del Negocio',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Gestiona tus productos',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(MenuDuenioProvider menuProvider) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: menuProvider.searchController,
        focusNode: menuProvider.searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: menuProvider.searchText.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () => menuProvider.limpiarBusqueda(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) => menuProvider.setSearchText(value),
        style: GoogleFonts.poppins(fontSize: 16),
      ),
    );
  }

  Widget _buildStatsSection(MenuDuenioProvider menuProvider) {
    final productos = menuProvider.getProductosFiltrados();
    final totalProductos = productos.length;
    final productosNuevos = productos.where((p) => menuProvider.esNuevo(p['created_at'])).length;
    final productosActivos = productos.where((p) => p['activo'] == true).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.inventory,
              title: 'Total',
              value: totalProductos.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.new_releases,
              title: 'Nuevos',
              value: productosNuevos.toString(),
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              title: 'Activos',
              value: productosActivos.toString(),
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(MenuDuenioProvider menuProvider, String negocioId) {
    return menuProvider.isLoading
        ? _buildLoadingState()
        : menuProvider.error != null
            ? _buildErrorState(menuProvider)
            : menuProvider.getProductosFiltrados().isEmpty
                ? _buildEmptyState(menuProvider)
                : _buildProductosList(menuProvider, negocioId);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando productos...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(MenuDuenioProvider menuProvider) {
    return Container(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar productos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                menuProvider.error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => menuProvider.cargarProductos(context),
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(MenuDuenioProvider menuProvider) {
    return Container(
      height: 300,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Icon(
                  Icons.search_off,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                menuProvider.searchText.isNotEmpty
                    ? 'Intenta con otro término de búsqueda'
                    : 'Agrega tu primer producto',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductosList(MenuDuenioProvider menuProvider, String negocioId) {
    return Column(
      children: [
        ...menuProvider.getProductosFiltrados().map((producto) => 
          _buildProductoCard(producto, menuProvider, negocioId)
        ),
        const SizedBox(height: 100), // Espacio para el FAB
      ],
    );
  }

  Widget _buildProductoCard(
    Map<String, dynamic> producto,
    MenuDuenioProvider menuProvider,
    String negocioId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Imagen del producto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: producto['img'] != null && producto['img'].toString().isNotEmpty
                      ? Image.network(
                          producto['img'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.fastfood,
                            color: Colors.grey[400],
                            size: 48,
                          ),
                        ),
                ),
                // Badge Nuevo
                if (menuProvider.esNuevo(producto['created_at']))
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'NUEVO',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Botones de acción
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        color: Colors.blue,
                        onPressed: () async {
                          final result = await menuProvider.mostrarFormularioProducto(
                            context,
                            negocioId,
                            producto: producto,
                          );
                          if (result == true && context.mounted) {
                            await menuProvider.cargarProductos(context);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onPressed: () => _showDeleteDialog(producto, menuProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Información del producto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        producto['nombre'] ?? 'Sin nombre',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Text(
                      '\$${menuProvider.formatearPrecio(producto['precio'])}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  producto['descripcion'] ?? 'Sin descripción',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          producto['activo'] == true ? Icons.check_circle : Icons.cancel,
                          color: producto['activo'] == true ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          producto['activo'] == true ? 'Activo' : 'Inactivo',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: producto['activo'] == true ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Botón de toggle para cambiar estado
                    GestureDetector(
                      onTap: () async {
                        final nuevoEstado = !(producto['activo'] == true);
                        try {
                          await menuProvider.cambiarEstadoProducto(
                            producto['id'].toString(),
                            nuevoEstado,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Producto ${nuevoEstado ? 'activado' : 'desactivado'} correctamente',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error al cambiar estado: $e',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: producto['activo'] == true 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: producto['activo'] == true ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              producto['activo'] == true ? Icons.toggle_on : Icons.toggle_off,
                              color: producto['activo'] == true ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              producto['activo'] == true ? 'Desactivar' : 'Activar',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: producto['activo'] == true ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: icon == Icons.edit ? 'Editar' : 'Eliminar',
      ),
    );
  }

  Widget _buildFloatingActionButton(MenuDuenioProvider menuProvider, String negocioId) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await menuProvider.mostrarFormularioProducto(
          context,
          negocioId,
        );
        if (result == true && context.mounted) {
          await menuProvider.cargarProductos(context);
        }
      },
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        'Agregar Producto',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      elevation: 4,
    );
  }

  void _showDeleteDialog(Map<String, dynamic> producto, MenuDuenioProvider menuProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar Producto',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${producto['nombre']}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await menuProvider.eliminarProducto(producto['id'].toString());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Producto eliminado',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al eliminar producto: $e',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
} 