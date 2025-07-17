import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'menu_screen.dart';
import 'carrito_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pantalla principal donde el cliente ve los negocios disponibles
class NegociosScreen extends StatefulWidget {
  const NegociosScreen({super.key});
  @override
  State<NegociosScreen> createState() => _NegociosScreenState();
}

class _NegociosScreenState extends State<NegociosScreen> {
  // Controladores para scroll y refresco
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

  // Lista de categorías disponibles
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

  // Obtiene los negocios desde Firestore, filtrando por categoría si aplica
  Stream<List<Map<String, dynamic>>> getNegociosStream() {
    Query query = FirebaseFirestore.instance.collection('negocios');
    if (_categoriaSeleccionada != null) {
      query = query.where('categoria', isEqualTo: _categoriaSeleccionada);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // Devuelve los 3 primeros negocios como destacados (para el slider)
  List<Map<String, dynamic>> getDestacados(List<Map<String, dynamic>> negocios) {
    return negocios.take(3).toList();
  }
  // Devuelve el resto de negocios para la lista principal
  List<Map<String, dynamic>> getRestantes(List<Map<String, dynamic>> negocios) {
    return negocios.skip(3).toList();
  }

  // Agrega un producto al carrito
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

  // Simula refresco (pull-to-refresh)
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // No hay estado para actualizar en Firestore, la lista es dinámica
    });
    _refreshController.refreshCompleted();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Negocios actualizados')),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentPage = 0;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  // Oculta la barra de categorías al hacer scroll
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
          // Botón del carrito en la barra superior
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
      // StreamBuilder escucha los cambios en la colección de negocios en Firestore
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getNegociosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar negocios'));
          }
          final negocios = snapshot.data ?? [];
          final destacados = getDestacados(negocios);
          final restantes = getRestantes(negocios);
          return SmartRefresher(
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
                // Slider de negocios destacados
                if (destacados.isNotEmpty)
                  SliverToBoxAdapter(
                    child: DestacadosSlider(
                      destacados: destacados,
                      onTap: (negocio) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuScreen(
                              restauranteId: negocio['id'] as String,
                              restaurante: negocio['nombre'] as String,
                              onAddToCart: _addToCart,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Barra de categorías horizontal
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
                // Lista de negocios restantes (no destacados)
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
                                    restauranteId: negocio['id'] as String,
                                    restaurante: negocio['nombre'] as String,
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
          );
        },
      ),
    );
  }
}

// Widget del slider de negocios destacados
class DestacadosSlider extends StatefulWidget {
  final List<Map<String, dynamic>> destacados;
  final void Function(Map<String, dynamic> negocio) onTap;
  const DestacadosSlider({super.key, required this.destacados, required this.onTap});

  @override
  State<DestacadosSlider> createState() => _DestacadosSliderState();
}

class _DestacadosSliderState extends State<DestacadosSlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: _pageController,
        itemCount: widget.destacados.length,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final realIndex = widget.destacados.isNotEmpty ? index % widget.destacados.length : 0;
          final negocio = widget.destacados[realIndex];
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
                onTap: () => widget.onTap(negocio),
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
    );
  }
} 