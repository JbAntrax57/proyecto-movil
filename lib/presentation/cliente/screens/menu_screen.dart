// menu_screen.dart - Pantalla de menú de un negocio para el cliente
// Muestra los productos del menú obtenidos desde Supabase
// Permite agregar productos al carrito con un diseño sencillo y bonito

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'carrito_screen.dart';

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

class _MenuScreenState extends State<MenuScreen> {
  String _searchText = '';
  Timer? _timer;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Obtiene el menú del restaurante desde Supabase
  Future<List<Map<String, dynamic>>> obtenerMenu(String restauranteId) async {
    try {
      final data = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('restaurante_id', widget.restauranteId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error al obtener menú: $e');
      return [];
    }
  }

  // Mostrar modal para agregar al carrito
  Future<void> _mostrarModalAgregarCarrito(
    Map<String, dynamic> producto,
  ) async {
    int cantidad = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
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
                  // Imagen del producto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      producto['img']?.toString() ??
                          'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 180,
                        height: 180,
                        color: Colors.blue[50],
                        child: const Icon(
                          Icons.fastfood,
                          color: Colors.blueGrey,
                          size: 70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Nombre del producto
                  Text(
                    producto['nombre']?.toString() ?? 'Sin nombre',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    producto['descripcion']?.toString() ??
                        'Delicioso y recién hecho',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blueGrey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${producto['precio']?.toString() ?? '0'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        // Animación para el total y la flecha verde cuando cantidad > 1
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          transitionBuilder: (child, animation) =>
                              SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(
                                        0,
                                        0.5,
                                      ), // Empieza abajo
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve:
                                            Curves.bounceOut, // Efecto saltito
                                      ),
                                    ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child: cantidad > 1
                              ? Row(
                                  key: ValueKey(cantidad),
                                  children: [
                                    const Icon(
                                      Icons.arrow_circle_right_rounded,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '\$${(producto['precio'] * cantidad)?.toString() ?? '0'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Selector de cantidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: cantidad > 1
                            ? () => setState(() => cantidad--)
                            : null,
                        onLongPress: () => setState(() => cantidad = 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => cantidad++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Botón para agregar al carrito
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Agregar al carrito'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final productoConCantidad = Map<String, dynamic>.from(
                          producto,
                        );
                        productoConCantidad['cantidad'] = cantidad;
                        productoConCantidad['negocio_id'] =
                            widget.restauranteId; // Agregar negocio_id

                        context.read<CarritoProvider>().agregarProducto(
                          productoConCantidad,
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${producto['nombre']} x$cantidad agregado al carrito',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(
                              top: 60,
                              left: 16,
                              right: 16,
                            ), // Mostrar pegado arriba
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Determina si el producto es nuevo (menos de 1 mes desde created_at)
  bool _esNuevo(dynamic createdAt) {
    if (createdAt == null) return false;
    try {
      final fecha = DateTime.tryParse(createdAt.toString());
      if (fecha == null) return false;
      final ahora = DateTime.now();
      return ahora.difference(fecha).inDays < 30;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors
          .blue[50], // Fondo uniforme para toda la pantalla, incluyendo el área segura superior
      child: SafeArea(
        top:
            false, // Permite que el color de fondo cubra la parte superior (barra de estado)
        child: Scaffold(
          extendBody:
              true, // Permite que el contenido se extienda detrás de widgets flotantes
          backgroundColor:
              Colors.transparent, // El fondo lo pone el Container exterior
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 2,
            title: Text(
              widget.restaurante,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              // Botón del carrito
              Consumer<CarritoProvider>(
                builder: (context, carritoProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Colors.black87,
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
                      if (carritoProvider.carrito.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '${carritoProvider.carrito.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchText = '');
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
                    setState(() => _searchText = value);
                  },
                ),
              ),

              // Lista de productos
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: obtenerMenu(widget.restauranteId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
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
                              'Error al cargar el menú',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final productos = snapshot.data ?? [];
                    if (productos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filtrado por búsqueda
                    final productosFiltrados = productos.where((producto) {
                      final nombre = (producto['nombre']?.toString() ?? '')
                          .toLowerCase();
                      final descripcion =
                          (producto['descripcion']?.toString() ?? '')
                              .toLowerCase();
                      final busqueda = _searchText.toLowerCase();
                      return nombre.contains(busqueda) ||
                          descripcion.contains(busqueda);
                    }).toList();

                    if (productosFiltrados.isEmpty) {
                      return Center(
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
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: productosFiltrados.length,
                      itemBuilder: (context, index) {
                        final producto = productosFiltrados[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  _mostrarModalAgregarCarrito(producto),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    // Imagen del producto con badge 'Nuevo' encima si aplica
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            producto['img']?.toString() ??
                                                'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
                                            width: 100,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      width: 80,
                                                      height: 80,
                                                      color: Colors.grey[200],
                                                      child: Icon(
                                                        Icons.fastfood,
                                                        size: 32,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        if (_esNuevo(producto['created_at']))
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.55),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.08),
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

                                    const SizedBox(width: 16),

                                    // Información del producto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Nombre del producto
                                          Text(
                                            producto['nombre']?.toString() ??
                                                'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 4),

                                          // Descripción
                                          Text(
                                            producto['descripcion']
                                                    ?.toString() ??
                                                'Delicioso y recién hecho',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 8),

                                          // Precio y botón
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Precio
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '\$${producto['precio']?.toString() ?? '0'}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),

                                              // Botón agregar
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      _mostrarModalAgregarCarrito(
                                                        producto,
                                                      ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 90,
                                                        minHeight: 30,
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
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
