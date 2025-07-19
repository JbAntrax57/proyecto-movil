// menu_screen.dart - Pantalla de menú de un negocio para el cliente
// Muestra los productos del menú obtenidos desde Supabase
// Permite agregar productos al carrito con un diseño sencillo y bonito

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
          .eq('negocioid', restauranteId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error al obtener menú: $e');
      return [];
    }
  }

  // Agregar producto al carrito
  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final productoConCantidad = Map<String, dynamic>.from(producto);
    productoConCantidad['cantidad'] = 1;
    
    context.read<CarritoProvider>().agregarProducto(productoConCantidad);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['nombre']} agregado al carrito'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
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
                    icon: const Icon(Icons.shopping_cart, color: Colors.black87),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                  final nombre = (producto['nombre']?.toString() ?? '').toLowerCase();
                  final descripcion = (producto['descripcion']?.toString() ?? '').toLowerCase();
                  final busqueda = _searchText.toLowerCase();
                  return nombre.contains(busqueda) || descripcion.contains(busqueda);
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
                          onTap: () => _agregarAlCarrito(producto),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Imagen del producto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    producto['img']?.toString() ?? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
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
                                
                                const SizedBox(width: 16),
                                
                                // Información del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nombre del producto
                                      Text(
                                        producto['nombre']?.toString() ?? 'Sin nombre',
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
                                        producto['descripcion']?.toString() ?? 'Delicioso y recién hecho',
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Precio
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(20),
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
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed: () => _agregarAlCarrito(producto),
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 40,
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
    );
  }
}
