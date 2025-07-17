import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'menu_screen.dart';
import 'carrito_screen.dart';

class NegociosScreen extends StatefulWidget {
  const NegociosScreen({super.key});

  @override
  State<NegociosScreen> createState() => _NegociosScreenState();
}

class _NegociosScreenState extends State<NegociosScreen> {
  late final PageController _pageController;
  late final ScrollController _scrollController;
  final RefreshController _refreshController = RefreshController();
  int _currentPage = 0;
  String? _categoriaSeleccionada;
  final List<Map<String, dynamic>> _carrito = [];
  bool _showCategorias = true;
  double _lastOffset = 0;

  // Altura del slider + barra de categorías (aprox)
  static const double _alturaSlider = 220;
  static const double _alturaCategorias = 82; // 70 + padding
  static const double _umbralOcultar = _alturaSlider + _alturaCategorias - 20;

  List<Map<String, dynamic>> negocios = [
    {'nombre': 'Pizzería Don Juan', 'direccion': 'Calle 1 #123', 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'categoria': 'Pizza', 'menu': [
      {'nombre': 'Pizza Margarita', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Clásica con tomate y albahaca'},
      {'nombre': 'Pizza Pepperoni', 'precio': 140, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pepperoni y queso fundido'},
      {'nombre': 'Pizza Cuatro Quesos', 'precio': 150, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Mezcla de quesos gourmet'},
      {'nombre': 'Pizza Hawaiana', 'precio': 135, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Piña y jamón'},
      {'nombre': 'Refresco', 'precio': 30, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bebida fría'},
    ]},
    {'nombre': 'Sushi Express', 'direccion': 'Av. Central 45', 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'categoria': 'Sushi', 'menu': [
      {'nombre': 'Sushi Roll', 'precio': 90, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Roll clásico de salmón'},
      {'nombre': 'Nigiri', 'precio': 80, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bola de arroz y pescado'},
      {'nombre': 'Tempura', 'precio': 100, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Verduras y camarón fritos'},
      {'nombre': 'Sashimi', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Láminas de pescado fresco'},
      {'nombre': 'Té verde', 'precio': 25, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bebida tradicional'},
    ]},
    {'nombre': 'Tilines', 'direccion': 'Av. Central 45', 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'categoria': 'Sushi', 'menu': [
      {'nombre': 'Sushi Roll', 'precio': 90, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Roll clásico de salmón'},
      {'nombre': 'Nigiri', 'precio': 80, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bola de arroz y pescado'},
      {'nombre': 'Tempura', 'precio': 100, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Verduras y camarón fritos'},
      {'nombre': 'Sashimi', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Láminas de pescado fresco'},
      {'nombre': 'Té verde', 'precio': 25, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bebida tradicional'},
    ]},
    {'nombre': 'Tacos El Güero', 'direccion': 'Blvd. Norte 200', 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'categoria': 'Tacos', 'menu': [
      {'nombre': 'Taco Pastor', 'precio': 25, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Carne al pastor'},
      {'nombre': 'Taco Bistec', 'precio': 28, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bistec asado'},
      {'nombre': 'Taco Suadero', 'precio': 27, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Suadero suave'},
      {'nombre': 'Taco Campechano', 'precio': 30, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Mezcla de carnes'},
      {'nombre': 'Agua de Horchata', 'precio': 20, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bebida refrescante'},
    ]},
    {'nombre': 'Burger House', 'direccion': 'Calle 2 #456', 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'categoria': 'Hamburguesas', 'menu': [
      {'nombre': 'Hamburguesa Clásica', 'precio': 100, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Medallón de carne, queso, lechuga y tomate'},
      {'nombre': 'Hamburguesa Vegana', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Medallón de tofu, queso vegano, lechuga y tomate'},
      {'nombre': 'Hamburguesa BBQ', 'precio': 110, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Medallón de carne, queso, lechuga, cebolla y BBQ'},
      {'nombre': 'Refresco', 'precio': 30, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Bebida fría'},
    ]},
    {'nombre': 'La Parrilla', 'direccion': 'Av. Sur 100', 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'categoria': 'Parrilla', 'menu': [
      {'nombre': 'Churrasco de Pollo', 'precio': 150, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo a la parrilla con salsa BBQ'},
      {'nombre': 'Churrasco de Carne', 'precio': 200, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Carne de res a la parrilla con papas fritas'},
      {'nombre': 'Churrasco de Cerdo', 'precio': 180, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Cerdo a la parrilla con ensalada'},
      {'nombre': 'Churrasco de Pollo', 'precio': 150, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo a la parrilla con salsa BBQ'},
      {'nombre': 'Churrasco de Carne', 'precio': 200, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Carne de res a la parrilla con papas fritas'},
    ]},
    {'nombre': 'Veggie Life', 'direccion': 'Calle Verde 12', 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'categoria': 'Vegano', 'menu': [
      {'nombre': 'Ensalada Vegana', 'precio': 80, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Lechuga, tomate, cebolla roja, aceitunas, queso vegano y aderezo de limón'},
      {'nombre': 'Pasta Vegana', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pasta con salsa de tomate, ajo y albahaca'},
      {'nombre': 'Tofu a la Parrilla', 'precio': 150, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Tofu a la parrilla con salsa BBQ y verduras'},
      {'nombre': 'Ensalada Verde', 'precio': 90, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Lechuga, tomate, cebolla roja, aceitunas, queso vegano y aderezo de limón'},
      {'nombre': 'Pasta Vegana', 'precio': 120, 'img': 'https://images.unsplash.com/photo-1464306076886-debca5e8a6b0?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pasta con salsa de tomate, ajo y albahaca'},
    ]},
    {'nombre': 'Mariscos El Puerto', 'direccion': 'Malecón 200', 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'categoria': 'Mariscos', 'menu': [
      {'nombre': 'Ceviche de Pescado', 'precio': 180, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pescado fresco marinado en limón, cebolla y cilantro'},
      {'nombre': 'Ceviche de Camarón', 'precio': 200, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Camarón fresco marinado en limón, cebolla y cilantro'},
      {'nombre': 'Ceviche de Pulpo', 'precio': 190, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pulpo fresco marinado en limón, cebolla y cilantro'},
      {'nombre': 'Ceviche de Camarón', 'precio': 200, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Camarón fresco marinado en limón, cebolla y cilantro'},
      {'nombre': 'Ceviche de Pulpo', 'precio': 190, 'img': 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pulpo fresco marinado en limón, cebolla y cilantro'},
    ]},
    {'nombre': 'Café Central', 'direccion': 'Centro 1', 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'categoria': 'Café', 'menu': [
      {'nombre': 'Café Americano', 'precio': 30, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Café con leche'},
      {'nombre': 'Café Latte', 'precio': 45, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Café con leche y espuma de leche'},
      {'nombre': 'Café Mocha', 'precio': 50, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Café con chocolate y leche'},
      {'nombre': 'Café Americano', 'precio': 30, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Café con leche'},
      {'nombre': 'Café Latte', 'precio': 45, 'img': 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Café con leche y espuma de leche'},
    ]},
    {'nombre': 'Pollo Feliz', 'direccion': 'Av. Pollo 99', 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'categoria': 'Pollo', 'menu': [
      {'nombre': 'Pollo a la Parrilla', 'precio': 180, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo a la parrilla con salsa BBQ'},
      {'nombre': 'Pollo Frito', 'precio': 150, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo frito con papas fritas'},
      {'nombre': 'Pollo a la Crema', 'precio': 200, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo a la crema con verduras'},
      {'nombre': 'Pollo a la Parrilla', 'precio': 180, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo a la parrilla con salsa BBQ'},
      {'nombre': 'Pollo Frito', 'precio': 150, 'img': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80', 'descripcion': 'Pollo frito con papas fritas'},
    ]},
  ];

  final categorias = [
    {'nombre': 'Pizza', 'icon': Icons.local_pizza},
    {'nombre': 'Sushi', 'icon': Icons.rice_bowl},
    {'nombre': 'Tacos', 'icon': Icons.emoji_food_beverage},
    {'nombre': 'Hamburguesas', 'icon': Icons.lunch_dining},
    {'nombre': 'Parrilla', 'icon': Icons.outdoor_grill},
    {'nombre': 'Vegano', 'icon': Icons.eco},
    {'nombre': 'Mariscos', 'icon': Icons.set_meal},
    {'nombre': 'Café', 'icon': Icons.coffee},
    {'nombre': 'Pollo', 'icon': Icons.set_meal},
  ];

  List<Map<String, dynamic>> get destacados {
    final list = _categoriaSeleccionada == null
        ? negocios.take(3).toList()
        : negocios.where((n) => n['categoria'] == _categoriaSeleccionada).take(3).toList();
    return list;
  }
  List<Map<String, dynamic>> get restantes {
    final list = _categoriaSeleccionada == null
        ? negocios.skip(3).toList()
        : negocios.where((n) => n['categoria'] == _categoriaSeleccionada).skip(3).toList();
    return list;
  }

  void _addToCart(Map<String, dynamic> producto) {
    setState(() {
      final index = _carrito.indexWhere((item) => item['nombre'] == producto['nombre']);
      if (index != -1) {
        _carrito[index]['cantidad'] = (_carrito[index]['cantidad'] ?? 1) + (producto['cantidad'] ?? 1);
      } else {
        _carrito.add(producto);
      }
    });
    final cantidad = producto['cantidad'] ?? 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${producto['nombre']} x$cantidad añadido al carrito')),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      negocios = List<Map<String, dynamic>>.from(negocios);
    });
    _refreshController.refreshCompleted();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Negocios actualizados')),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000 * (destacados.isNotEmpty ? destacados.length : 1));
    _currentPage = 1000 * (destacados.isNotEmpty ? destacados.length : 1);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > _umbralOcultar && _showCategorias) {
      setState(() => _showCategorias = false);
    } else if (offset <= _umbralOcultar && !_showCategorias) {
      setState(() => _showCategorias = true);
    }
    _lastOffset = offset;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negocios'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  // Navegar a CarritoScreen y actualizar carrito al volver
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CarritoScreen(
                        carrito: List<Map<String, dynamic>>.from(_carrito),
                      ),
                    ),
                  );
                  if (result is List<Map<String, dynamic>>) {
                    setState(() {
                      _carrito
                        ..clear()
                        ..addAll(result);
                    });
                  }
                },
              ),
              if (_carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text('${_carrito.length}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: CustomHeader(
          builder: (context, mode) {
            Widget body;
            if (mode == RefreshStatus.idle) {
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: 0,
                      strokeWidth: 3,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Desliza para refrescar', style: TextStyle(color: Colors.blue)),
                ],
              );
            } else if (mode == RefreshStatus.canRefresh) {
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 3,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Suelta para refrescar', style: TextStyle(color: Colors.green)),
                ],
              );
            } else if (mode == RefreshStatus.refreshing) {
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(height: 8),
                  Text('Actualizando...', style: TextStyle(color: Colors.blue)),
                ],
              );
            } else if (mode == RefreshStatus.completed) {
              body = Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 36),
                  SizedBox(height: 8),
                  Text('¡Actualizado!', style: TextStyle(color: Colors.green)),
                ],
              );
            } else {
              body = const SizedBox.shrink();
            }
            return SizedBox(
              height: 80,
              child: Center(child: body),
            );
          },
        ),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (destacados.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final realIndex = destacados.isNotEmpty ? index % destacados.length : 0;
                      final negocio = destacados[realIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Card(
                          elevation: 10,
                          color: Colors.white,
                          shadowColor: Colors.blue.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            splashColor: Colors.blue.withOpacity(0.08),
                            highlightColor: Colors.blue.withOpacity(0.04),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MenuScreen(
                                    restaurante: negocio['nombre'] as String,
                                    productos: List<Map<String, dynamic>>.from(negocio['menu'] as List),
                                    onAddToCart: _addToCart,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    bottomLeft: Radius.circular(24),
                                  ),
                                  child: Image.network(
                                    negocio['img'] as String,
                                    width: 120,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 120,
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.store, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          negocio['nombre'] as String,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                negocio['direccion'] as String,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey[700]),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('★ Destacado', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _showCategorias ? Offset.zero : const Offset(0, -1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showCategorias ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categorias.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final cat = categorias[index];
                          final selected = _categoriaSeleccionada == cat['nombre'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _categoriaSeleccionada = selected ? null : cat['nombre'] as String;
                              });
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: selected ? Colors.blue : Colors.blue[50],
                                  child: Icon(cat['icon'] as IconData, color: selected ? Colors.white : Colors.blue, size: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(cat['nombre'] as String, style: TextStyle(fontSize: 12, color: selected ? Colors.blue : null)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final negocio = restantes[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + index * 100),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.blue.withOpacity(0.10),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        splashColor: Colors.blue.withOpacity(0.08),
                        highlightColor: Colors.blue.withOpacity(0.04),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MenuScreen(
                                restaurante: negocio['nombre'] as String,
                                productos: List<Map<String, dynamic>>.from(negocio['menu'] as List),
                                onAddToCart: _addToCart,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                              ),
                              child: Image.network(
                                negocio['img'] as String,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.store, size: 32, color: Colors.grey),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      negocio['nombre'] as String,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            negocio['direccion'] as String,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey[700]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: restantes.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 