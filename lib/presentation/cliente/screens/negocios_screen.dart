// negocios_screen.dart - Pantalla principal del cliente para ver y explorar negocios
// Incluye slider de destacados, barra de categorías, lista de negocios y carrito.
// Implementa obtención de datos en tiempo real desde Firestore, filtrado por categoría y animaciones.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'menu_screen.dart';
import 'carrito_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// Pantalla principal donde el cliente ve los negocios disponibles
class NegociosScreen extends StatefulWidget {
  // Pantalla principal donde el cliente ve los negocios disponibles
  const NegociosScreen({super.key});
  @override
  State<NegociosScreen> createState() => _NegociosScreenState();
}

class _NegociosScreenState extends State<NegociosScreen> {
  // Controladores para scroll y refresco
  late final PageController _pageController;
  late final ScrollController _scrollController;
  final RefreshController _refreshController = RefreshController();
  int _currentPage = 0; // Página actual del slider
  String? _categoriaSeleccionada; // Categoría seleccionada para filtrar
  final List<Map<String, dynamic>> _carrito = []; // Carrito de compras
  bool _showCategorias = true; // Controla visibilidad de la barra de categorías
  double _lastOffset = 0; // Última posición de scroll

  // Controlador y focus para la barra de búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = '';

  // Altura del slider + barra de categorías (aprox)
  static const double _alturaSlider = 220;
  static const double _alturaCategorias = 82; // 70 + padding
  static const double _umbralOcultar = _alturaSlider + _alturaCategorias - 20;

  // Lista de categorías disponibles (nombre e ícono)
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

  // Agrego una llave de almacenamiento de página para preservar el scroll
  final PageStorageKey _categoriasKey = const PageStorageKey('categoriasList');
  final PageStorageKey _negociosKey = const PageStorageKey('negociosList');

  // Obtiene los negocios desde Firestore, filtrando por categoría si aplica
  Stream<List<Map<String, dynamic>>> getNegociosStream() {
    Query query = FirebaseFirestore.instance.collection('negocios');
    // El filtro de categoría solo se aplicará a los negocios NO destacados
    // Para el Stream general, no se filtra por categoría
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  // Devuelve los negocios destacados (campo 'destacado' == true) para el slider
  List<Map<String, dynamic>> getDestacados(
    List<Map<String, dynamic>> negocios,
  ) {
    return negocios.where((n) => n['destacado'] == true).toList();
  }

  // Devuelve el resto de negocios para la lista principal, aplicando filtro de categoría
  List<Map<String, dynamic>> getRestantes(List<Map<String, dynamic>> negocios) {
    final noDestacados = negocios.where((n) => n['destacado'] != true);
    if (_categoriaSeleccionada != null) {
      return noDestacados
          .where((n) => n['categoria'] == _categoriaSeleccionada)
          .toList();
    }
    return noDestacados.toList();
  }

  // Agrega un producto al carrito y muestra un SnackBar
  void _addToCart(Map<String, dynamic> producto) {
    setState(() {
      final index = _carrito.indexWhere(
        (item) => item['nombre'] == producto['nombre'],
      );
      if (index != -1) {
        _carrito[index]['cantidad'] =
            (_carrito[index]['cantidad'] ?? 1) + (producto['cantidad'] ?? 1);
      } else {
        _carrito.add(producto);
      }
    });
    final cantidad = producto['cantidad'] ?? 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['nombre']} x$cantidad añadido al carrito'),
      ),
    );
  }

  // Simula refresco (pull-to-refresh), aunque Firestore es reactivo
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // No hay estado para actualizar en Firestore, la lista es dinámica
    });
    _refreshController.refreshCompleted();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Negocios actualizados')));
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Elimino super.build(context); porque no es necesario ni válido
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Negocios destacados'),
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
                    child: Text(
                      '${_carrito.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda animada con botón de limpiar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Buscar negocios...',
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        // El icono de limpiar se agrega aparte
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                          // Aquí puedes filtrar la lista de negocios según el valor
                        });
                      },
                    ),
                  ),
                  if (_searchText.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchText = '';
                        });
                        _searchFocusNode.unfocus();
                      },
                    ),
                ],
              ),
            ),
          ),
          // El resto del contenido (slider, lista, etc.)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getNegociosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar negocios'));
                }
                final negocios = snapshot.data ?? [];
                // Filtrado por búsqueda (nombre, insensible a mayúsculas)
                final filtro = _searchText.trim().toLowerCase();
                final destacados = getDestacados(negocios)
                    .where(
                      (n) =>
                          filtro.isEmpty ||
                          (n['nombre'] as String).toLowerCase().contains(
                            filtro,
                          ),
                    )
                    .toList();
                final restantes = getRestantes(negocios)
                    .where(
                      (n) =>
                          filtro.isEmpty ||
                          (n['nombre'] as String).toLowerCase().contains(
                            filtro,
                          ),
                    )
                    .toList();
                // Widget de refresco y scroll
                return SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  header: CustomHeader(
                    builder: (context, mode) {
                      // Header personalizado para el pull-to-refresh
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
                            Text(
                              'Desliza para refrescar',
                              style: TextStyle(color: Colors.blue),
                            ),
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
                            Text(
                              'Suelta para refrescar',
                              style: TextStyle(color: Colors.green),
                            ),
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
                            Text(
                              'Actualizando...',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        );
                      } else if (mode == RefreshStatus.completed) {
                        body = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '¡Actualizado!',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        );
                      } else {
                        body = const SizedBox.shrink();
                      }
                      return SizedBox(height: 80, child: Center(child: body));
                    },
                  ),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Slider de negocios destacados (loop infinito y scroll automático)
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
                          offset: _showCategorias
                              ? Offset.zero
                              : const Offset(0, -1),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _showCategorias ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 8,
                                      bottom: 6,
                                    ),
                                    child: Text(
                                      'Categorías',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[950],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 70,
                                    child: ListView.separated(
                                      key: _categoriasKey, // <-- Aquí
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categorias.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final cat = categorias[index];
                                        final selected =
                                            _categoriaSeleccionada ==
                                            cat['nombre'];
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _categoriaSeleccionada = selected
                                                  ? null
                                                  : cat['nombre'] as String;
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: selected
                                                    ? Colors.blueGrey[800]
                                                    : Colors.blue[50],
                                                child: Icon(
                                                  cat['icon'] as IconData,
                                                  color: selected
                                                      ? Colors.white
                                                      : Colors.blueGrey[800],
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                cat['nombre'] as String,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: selected
                                                      ? Colors.blue
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Lista de negocios restantes (no destacados)
                      SliverList(
                        key: _negociosKey, // <-- Aquí
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final negocio = restantes[index];
                          // Animación de aparición para cada negocio
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
                              margin: const EdgeInsets.only(
                                bottom: 16,
                                left: 16,
                                right: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
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
                                        restaurante:
                                            negocio['nombre'] as String,
                                        onAddToCart: _addToCart,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    // Imagen del negocio
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
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.store,
                                                    size: 32,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    // Detalles del negocio
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 18,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              negocio['nombre'] as String,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueGrey[800],
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Colors.redAccent,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    negocio['direccion']
                                                        as String,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors
                                                              .blueGrey[700],
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: restantes.length),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget del slider de negocios destacados (loop infinito y scroll automático)
class DestacadosSlider extends StatefulWidget {
  // Lista de negocios destacados y callback al tocar un negocio
  final List<Map<String, dynamic>> destacados; // Lista de negocios destacados
  final void Function(Map<String, dynamic> negocio)
  onTap; // Callback al tocar un negocio
  const DestacadosSlider({
    super.key,
    required this.destacados,
    required this.onTap,
  });

  @override
  State<DestacadosSlider> createState() => _DestacadosSliderState();
}

class _DestacadosSliderState extends State<DestacadosSlider> {
  // Controlador de página y timer para scroll automático
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  static const int _initialPage = 1000; // Para simular loop infinito

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _currentPage = _initialPage;
    // Scroll automático cada 3 segundos
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.destacados.isNotEmpty && mounted) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destacados = widget.destacados;
    if (destacados.isEmpty) return const SizedBox.shrink();
    // Slider de negocios destacados con animación y scroll infinito
    return SizedBox(
      height: 220,
      child: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: _pageController,
        itemCount: null, // infinito
        physics: const ClampingScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (context, index) {
          final realIndex = destacados.isNotEmpty
              ? index % destacados.length
              : 0;
          final negocio = destacados[realIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Card(
              elevation: 10,
              color: Colors.white,
              shadowColor: Colors.blue.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.blue.withOpacity(0.08),
                highlightColor: Colors.blue.withOpacity(0.04),
                onTap: () => widget.onTap(negocio),
                child: Row(
                  children: [
                    // Imagen del negocio destacado
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
                          child: const Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    // Detalles del negocio destacado
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              negocio['nombre'] as String,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    negocio['direccion'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.blueGrey[700]),
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
