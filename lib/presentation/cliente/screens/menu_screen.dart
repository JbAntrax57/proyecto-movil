// menu_screen.dart - Pantalla de menú de un negocio para el cliente
// Muestra los productos del menú obtenidos desde Supabase
// Permite agregar productos al carrito con un diseño moderno y atractivo

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/menu_provider.dart';

import 'carrito_screen.dart';
import '../../../shared/widgets/custom_alert.dart';
import '../../../shared/widgets/carrito_success_message.dart';
import '../../../shared/widgets/top_info_message.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization.dart';

class MenuScreen extends StatefulWidget {
  final String restauranteId;
  final String restaurante;

  const MenuScreen({
    super.key,
    required this.restauranteId,
    required this.restaurante,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Cargar productos desde el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = context.read<MenuProvider>();
      menuProvider.cargarProductos(widget.restauranteId);
      _animationController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Función para refrescar datos
  Future<void> _onRefresh() async {
    final menuProvider = context.read<MenuProvider>();
    await menuProvider.cargarProductos(widget.restauranteId);
  }

  // Mostrar modal para agregar al carrito
  Future<void> _mostrarModalAgregarCarrito(
    Map<String, dynamic> producto,
  ) async {
    int cantidad = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Indicador de arrastre
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Imagen del producto con efecto de profundidad
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          producto['img']?.toString() ??
                              'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple[100]!,
                                  Colors.purple[200]!,
                                ],
                              ),
                            ),
                                                         child: Icon(
                               Icons.fastfood,
                               color: Colors.blue[600],
                               size: 80,
                             ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nombre y precio del producto
                    Text(
                      producto['nombre']?.toString() ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                                         Container(
                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [Colors.blue[400]!, Colors.blue[600]!],
                         ),
                         borderRadius: BorderRadius.circular(20),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.blue.withOpacity(0.3),
                             blurRadius: 8,
                             offset: const Offset(0, 4),
                           ),
                         ],
                       ),
                       child: Text(
                         '\$${producto['precio']?.toString() ?? '0.00'}',
                         style: GoogleFonts.poppins(
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                           color: Colors.white,
                         ),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                    const SizedBox(height: 20),

                    // Descripción del producto (si existe)
                    if (producto['descripcion'] != null && producto['descripcion'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          producto['descripcion'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (producto['descripcion'] != null && producto['descripcion'].toString().isNotEmpty)
                      const SizedBox(height: 20),

                                         // Selector de cantidad con diseño moderno
                     Container(
                       padding: const EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                           colors: [
                             Colors.blue[50]!,
                             Colors.blue[100]!,
                           ],
                         ),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.blue[200]!),
                       ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                                                     _buildQuantityButton(
                             icon: Icons.remove,
                             onPressed: cantidad > 1 ? () => setState(() => cantidad--) : null,
                             color: Colors.grey[600]!,
                           ),
                           Container(
                             margin: const EdgeInsets.symmetric(horizontal: 20),
                             padding: const EdgeInsets.symmetric(
                               horizontal: 32,
                               vertical: 16,
                             ),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(16),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.blue.withOpacity(0.2),
                                   blurRadius: 8,
                                   offset: const Offset(0, 4),
                                 ),
                               ],
                             ),
                             child: Text(
                               '$cantidad',
                               style: GoogleFonts.poppins(
                                 fontSize: 24,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.blue[700],
                               ),
                             ),
                           ),
                           _buildQuantityButton(
                             icon: Icons.add,
                             onPressed: () => setState(() => cantidad++),
                             color: Colors.blue[600]!,
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón para agregar al carrito
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart, size: 28),
                        label: Text(
                          '${AppLocalizations.of(context).get('agregar_carrito')} - \$${((double.tryParse(producto['precio']?.toString() ?? '0') ?? 0.0) * cantidad).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                                                 style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blue[600],
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 20),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(20),
                           ),
                           elevation: 8,
                           shadowColor: Colors.blue.withOpacity(0.4),
                         ),
                        onPressed: () {
                          final productoConCantidad = Map<String, dynamic>.from(
                            producto,
                          );
                          productoConCantidad['cantidad'] = cantidad;
                          productoConCantidad['negocio_id'] = widget.restauranteId;

                          context.read<CarritoProvider>().agregarProducto(
                            productoConCantidad,
                          );

                          Navigator.pop(context);

                          showTopInfoMessage(
                            context,
                            '${producto['nombre']} x$cantidad ${AppLocalizations.of(context).get('producto_agregado')}',
                            icon: Icons.check_circle,
                            backgroundColor: Colors.green[50],
                            textColor: Colors.green[700],
                            iconColor: Colors.green[700],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    
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
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                // Header con gradiente
                SliverToBoxAdapter(
                  child: _buildHeader(menuProvider),
                ),
                // Barra de búsqueda
                SliverToBoxAdapter(
                  child: _buildSearchSection(menuProvider),
                ),
                // Contenido principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildContentSection(menuProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MenuProvider menuProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Barra superior
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurante,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Descubre sabores únicos',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón del carrito
                Consumer<CarritoProvider>(
                  builder: (context, carritoProvider, child) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CarritoScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                                                 if (carritoProvider.carrito.isNotEmpty)
                           Positioned(
                             right: 8,
                             top: 8,
                             child: GestureDetector(
                               onTap: () async {
                                 await Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (_) => const CarritoScreen(),
                                   ),
                                 );
                               },
                               child: Container(
                                 padding: const EdgeInsets.all(4),
                                 decoration: BoxDecoration(
                                   color: Colors.orange[600],
                                   borderRadius: BorderRadius.circular(10),
                                   boxShadow: [
                                     BoxShadow(
                                       color: Colors.orange.withOpacity(0.4),
                                       blurRadius: 4,
                                       offset: const Offset(0, 2),
                                     ),
                                   ],
                                 ),
                                 constraints: const BoxConstraints(
                                   minWidth: 18,
                                   minHeight: 18,
                                 ),
                                 child: Text(
                                   '${carritoProvider.carrito.length}',
                                   style: GoogleFonts.poppins(
                                     fontSize: 10,
                                     color: Colors.white,
                                     fontWeight: FontWeight.bold,
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                               ),
                             ),
                           ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Estadísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    icon: Icons.restaurant_menu,
                    value: menuProvider.getProductosFiltrados().length.toString(),
                    label: 'Productos',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickStat(
                    icon: Icons.check_circle,
                    value: menuProvider.getProductosFiltrados()
                        .where((p) => p['activo'] == true)
                        .length
                        .toString(),
                    label: 'Disponibles',
                    color: Colors.white,
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(MenuProvider menuProvider) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).get('buscar_productos'),
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                     prefixIcon: Container(
             margin: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.blue[50],
               borderRadius: BorderRadius.circular(12),
             ),
             child: Icon(Icons.search, color: Colors.blue[600]),
           ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    menuProvider.setSearchText('');
                  },
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

  Widget _buildContentSection(MenuProvider menuProvider) {
    return menuProvider.isLoading
        ? _buildLoadingState()
        : menuProvider.error != null
            ? _buildErrorState(menuProvider)
            : menuProvider.getProductosFiltrados().isEmpty
                ? _buildEmptyState(menuProvider)
                : _buildProductosGrid(menuProvider);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                         Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.blue[50],
                 borderRadius: BorderRadius.circular(20),
               ),
               child: CircularProgressIndicator(
                 valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                 strokeWidth: 3,
               ),
             ),
            const SizedBox(height: 20),
            Text(
              'Cargando deliciosos productos...',
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

  Widget _buildErrorState(MenuProvider menuProvider) {
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
                  borderRadius: BorderRadius.circular(20),
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
                AppLocalizations.of(context).get('error_conexion'),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(
                  AppLocalizations.of(context).get('intentar_nuevamente'),
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

  Widget _buildEmptyState(MenuProvider menuProvider) {
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Icon(
                  Icons.fastfood,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).get('sin_productos'),
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
                    : 'Este negocio aún no tiene productos disponibles',
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

  Widget _buildProductosGrid(MenuProvider menuProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: menuProvider.getProductosFiltrados().length,
          itemBuilder: (context, index) {
            final producto = menuProvider.getProductosFiltrados()[index];
            return _buildProductoCard(producto, menuProvider);
          },
        ),
      ),
    );
  }

  Widget _buildProductoCard(
    Map<String, dynamic> producto,
    MenuProvider menuProvider,
  ) {
    final isNew = producto['created_at'] != null && 
        DateTime.parse(producto['created_at']).isAfter(DateTime.now().subtract(const Duration(days: 7)));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _mostrarModalAgregarCarrito(producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      width: double.infinity,
                      child: producto['img'] != null && producto['img'].toString().isNotEmpty
                          ? Image.network(
                              producto['img'],
                              fit: BoxFit.cover,
                                                             errorBuilder: (context, error, stackTrace) => Container(
                                 color: Colors.blue[100],
                                 child: Icon(
                                   Icons.fastfood,
                                   color: Colors.blue[400],
                                   size: 40,
                                 ),
                               ),
                             )
                           : Container(
                               color: Colors.blue[100],
                               child: Icon(
                                 Icons.fastfood,
                                 color: Colors.blue[400],
                                 size: 40,
                               ),
                             ),
                    ),
                  ),
                  // Badge Nuevo
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[400]!, Colors.orange[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
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
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  // Botón de agregar
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.add_shopping_cart,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        onPressed: () => _mostrarModalAgregarCarrito(producto),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                         // Información del producto
             Expanded(
               flex: 2,
               child: Padding(
                 padding: const EdgeInsets.all(10),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             producto['nombre'] ?? 'Sin nombre',
                             style: GoogleFonts.poppins(
                               fontSize: 13,
                               fontWeight: FontWeight.bold,
                               color: Colors.grey[800],
                             ),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                           const SizedBox(height: 2),
                           Text(
                             producto['descripcion'] ?? 'Sin descripción',
                             style: GoogleFonts.poppins(
                               fontSize: 10,
                               color: Colors.grey[600],
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 4),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Text(
                             '\$${producto['precio']?.toString() ?? '0.00'}',
                             style: GoogleFonts.poppins(
                               fontSize: 14,
                               fontWeight: FontWeight.bold,
                               color: Colors.blue[600],
                             ),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         const SizedBox(width: 4),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                           decoration: BoxDecoration(
                             color: producto['activo'] == true ? Colors.green[100] : Colors.red[100],
                             borderRadius: BorderRadius.circular(6),
                           ),
                           child: Text(
                             producto['activo'] == true ? 'Disponible' : 'No disponible',
                             style: GoogleFonts.poppins(
                               fontSize: 8,
                               color: producto['activo'] == true ? Colors.green[700] : Colors.red[700],
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
