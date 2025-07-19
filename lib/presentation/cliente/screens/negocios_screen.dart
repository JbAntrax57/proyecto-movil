// negocios_screen.dart - Pantalla principal del cliente para ver y explorar negocios
// Incluye slider de destacados, barra de categorías, lista de negocios y carrito.
// Implementa obtención de datos desde Supabase, filtrado por categoría y animaciones.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_screen.dart';
import 'carrito_screen.dart';

// Pantalla principal donde el cliente ve los negocios disponibles
class NegociosScreen extends StatefulWidget {
  const NegociosScreen({super.key});
  
  @override
  State<NegociosScreen> createState() => _NegociosScreenState();
}

class _NegociosScreenState extends State<NegociosScreen> {
  // Controladores para scroll y refresco
  PageController? _pageController;
  ScrollController? _scrollController;
  int _currentPage = 0; // Página actual del slider
  String? _categoriaSeleccionada; // Categoría seleccionada para filtrar
  final List<Map<String, dynamic>> _carrito = []; // Carrito de compras
  bool _showCategorias = true; // Controla visibilidad de la barra de categorías

  // Controlador y focus para la barra de búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = '';

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

  // Obtiene los negocios desde Supabase, filtrando por categoría si aplica
  Future<List<Map<String, dynamic>>> obtenerNegocios({String? categoria}) async {
    try {
      final query = Supabase.instance.client.from('negocios').select();
      if (categoria != null && categoria.isNotEmpty) {
        query.eq('categoria', categoria);
      }
      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error al obtener negocios: $e');
      return [];
    }
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
          .where((n) => (n['categoria']?.toString() ?? '') == _categoriaSeleccionada)
          .toList();
    }
    return noDestacados.toList();
  }

  // Simula refresco (pull-to-refresh)
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // No hay estado para actualizar en Supabase, la lista es dinámica
    });
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
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _scrollController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>().carrito;
    
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarritoScreen()),
                  );
                },
              ),
              if (carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${carrito.length}',
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
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar negocios...',
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
          ),
          // El resto del contenido (slider, lista, etc.)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: obtenerNegocios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final negocios = snapshot.data ?? [];
                if (negocios.isEmpty) {
                  return const Center(child: Text('No hay negocios disponibles'));
                }
                
                // Filtrado por búsqueda (nombre, insensible a mayúsculas)
                final filtro = _searchText.trim().toLowerCase();
                final destacados = getDestacados(negocios)
                    .where(
                      (n) =>
                          filtro.isEmpty ||
                          (n['nombre']?.toString() ?? '').toLowerCase().contains(
                            filtro,
                          ),
                    )
                    .toList();
                final restantes = getRestantes(negocios)
                    .where(
                      (n) =>
                          filtro.isEmpty ||
                          (n['nombre']?.toString() ?? '').toLowerCase().contains(
                            filtro,
                          ),
                    )
                    .toList();
                
                // Widget de refresco y scroll
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Slider de negocios destacados (loop infinito y scroll automático)
                        if (destacados.isNotEmpty)
                          DestacadosSlider(
                            destacados: destacados,
                            onTap: (negocio) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MenuScreen(
                                    restauranteId: negocio['id']?.toString() ?? '',
                                    restaurante: negocio['nombre']?.toString() ?? 'Sin nombre',
                                  ),
                                ),
                              );
                            },
                          ),
                        // Barra de categorías horizontal
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
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
                        // Lista de negocios restantes (no destacados)
                        ...restantes.map((negocio) {
                          final index = restantes.indexOf(negocio);
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
                                        restauranteId: negocio['id']?.toString() ?? '',
                                        restaurante:
                                            negocio['nombre']?.toString() ?? 'Sin nombre',
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
                                        negocio['img']?.toString() ?? 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
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
                                              negocio['nombre']?.toString() ?? 'Sin nombre',
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
                                                        ?.toString() ?? 'Sin dirección',
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
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
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

// Widget para el slider de negocios destacados
class DestacadosSlider extends StatefulWidget {
  final List<Map<String, dynamic>> destacados;
  final Function(Map<String, dynamic>) onTap;

  const DestacadosSlider({
    super.key,
    required this.destacados,
    required this.onTap,
  });

  @override
  State<DestacadosSlider> createState() => _DestacadosSliderState();
}

class _DestacadosSliderState extends State<DestacadosSlider> {
  PageController? _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < widget.destacados.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController?.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: widget.destacados.length,
              itemBuilder: (context, index) {
                final negocio = widget.destacados[index];
                return GestureDetector(
                  onTap: () => widget.onTap(negocio),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Imagen de fondo
                          Image.network(
                            negocio['img']?.toString() ?? 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.store,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                          // Gradiente oscuro para el texto
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Contenido del negocio
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  negocio['nombre']?.toString() ?? 'Sin nombre',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  negocio['direccion']?.toString() ?? 'Sin dirección',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge de destacado
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Destacado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
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
          // Indicadores de página
          if (widget.destacados.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.destacados.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
