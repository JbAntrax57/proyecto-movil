import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa Supabase
import 'carrito_screen.dart';

// menu_screen.dart - Pantalla de menú de un negocio para el cliente
// Muestra los productos del menú obtenidos en tiempo real desde Firestore.
// Permite agregar productos al carrito y ver detalles de cada producto.
class MenuScreen extends StatefulWidget {
  // Recibe el ID y nombre del restaurante, y un callback para agregar al carrito
  final String restauranteId;
  final String restaurante;
  final void Function(Map<String, dynamic> producto)? onAddToCart;

  const MenuScreen({
    super.key,
    required this.restauranteId,
    required this.restaurante,
    this.onAddToCart,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Obtiene el menú del restaurante en tiempo real desde Supabase
  Future<List<Map<String, dynamic>>> obtenerMenu(String restauranteId) async {
    final data = await Supabase.instance.client
        .from('productos')
        .select()
        .eq('negocioId', restauranteId);
    return List<Map<String, dynamic>>.from(data);
  }

  // 1. En MenuScreen, define un método para mostrar el MaterialBanner en el contexto del Scaffold principal
  void _showBanner(BuildContext context, String mensaje) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(mensaje),
        leading: const Icon(Icons.check_circle, color: Colors.green),
        backgroundColor: Colors.blue[50],
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  // Función reutilizable para mostrar el modal de agregar al carrito
  // 2. Pasa un callback onAddToCartBanner al modal
  Future<void> showAgregarCarritoModal({
    required BuildContext context,
    required Map<String, dynamic> producto,
    required void Function(Map<String, dynamic> productoConCantidad)
    onAddToCart,
    void Function(Map<String, dynamic> productoConCantidad)? onAddToCartBanner,
  }) async {
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
                      producto['img'] as String,
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
                    producto['nombre'] as String,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Descripción
                  Text(
                    producto['descripcion'] as String? ??
                        'Delicioso y recién hecho',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.blueGrey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Precio
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
                      '\$${producto['precio']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 22,
                      ),
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
                      ),
                      Text('$cantidad', style: const TextStyle(fontSize: 20)),
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
                        onAddToCart(productoConCantidad);
                        if (onAddToCartBanner != null)
                          onAddToCartBanner(productoConCantidad);
                        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: Text(widget.restaurante),
        centerTitle: true,
        actions: [
          // Botón del carrito en la barra superior
          Consumer<CarritoProvider>(
            builder: (context, carritoProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
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
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${carritoProvider.carrito.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
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
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          // Lista de productos
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerMenu(widget.restauranteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final productos = snapshot.data ?? [];
                if (productos.isEmpty) {
                  return const Center(
                    child: Text('No hay productos disponibles'),
                  );
                }
                
                // Filtrado por búsqueda
                final productosFiltrados = productos.where((producto) {
                  final nombre = (producto['nombre'] as String).toLowerCase();
                  final descripcion = (producto['descripcion'] as String? ?? '').toLowerCase();
                  final busqueda = _searchText.toLowerCase();
                  return nombre.contains(busqueda) || descripcion.contains(busqueda);
                }).toList();
                
                if (productosFiltrados.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron productos'),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto = productosFiltrados[index];
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          showAgregarCarritoModal(
                            context: context,
                            producto: producto,
                            onAddToCart: (productoConCantidad) {
                              // Agregar al carrito local
                              if (widget.onAddToCart != null) {
                                widget.onAddToCart!(productoConCantidad);
                              }
                              // Agregar al carrito global
                              context.read<CarritoProvider>().agregarProducto(
                                productoConCantidad,
                              );
                              // Mostrar banner
                              _showBanner(
                                context,
                                '${productoConCantidad['nombre']} agregado al carrito',
                              );
                            },
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen del producto
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  producto['img'] as String,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.fastfood,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Información del producto
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nombre del producto
                                    Text(
                                      producto['nombre'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Descripción
                                    Text(
                                      producto['descripcion'] as String? ??
                                          'Delicioso y recién hecho',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    // Precio
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '\$${producto['precio']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            fontSize: 18,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            final productoConCantidad =
                                                Map<String, dynamic>.from(
                                              producto,
                                            );
                                            productoConCantidad['cantidad'] = 1;
                                            if (widget.onAddToCart != null) {
                                              widget.onAddToCart!(
                                                productoConCantidad,
                                              );
                                            }
                                            context
                                                .read<CarritoProvider>()
                                                .agregarProducto(
                                                  productoConCantidad,
                                                );
                                            _showBanner(
                                              context,
                                              '${productoConCantidad['nombre']} agregado al carrito',
                                            );
                                          },
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
