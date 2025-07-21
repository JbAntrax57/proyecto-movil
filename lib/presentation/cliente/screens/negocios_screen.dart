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
  final bool? showAppBar;

  const NegociosScreen({super.key, this.showAppBar});

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
  final FocusNode _searchFocusNode =
      FocusNode(); // FocusNode temporal para controlar el foco
  String _searchText = '';

  // Cache de datos para evitar recargas
  List<Map<String, dynamic>> _todosLosNegocios = [];
  bool _isLoading = true;
  String? _error;

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
  Future<List<Map<String, dynamic>>> obtenerNegocios({
    String? categoria,
  }) async {
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

  // Cargar todos los negocios una sola vez
  Future<void> _cargarNegocios() async {
    if (_todosLosNegocios.isNotEmpty) return; // Ya están cargados

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await Supabase.instance.client.from('negocios').select();
      setState(() {
        _todosLosNegocios = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error al cargar negocios: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          .where(
            (n) => (n['categoria']?.toString() ?? '') == _categoriaSeleccionada,
          )
          .toList();
    }
    return noDestacados.toList();
  }

  // Simula refresco (pull-to-refresh)
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    await _cargarNegocios(); // Recargar datos
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Negocios actualizados')));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentPage = 0;
    _scrollController = ScrollController();
    _cargarNegocios(); // Cargar datos al inicializar
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _scrollController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose(); // Limpiar el FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>().carrito;
    final showAppBar = widget.showAppBar ?? true; // Asegurar que sea bool

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SafeArea(
        top:
            true, // Permite que el color de fondo cubra la parte superior (barra de estado)
        child: Scaffold(
          extendBody:
              true, // Permite que el contenido se extienda detrás de widgets flotantes
          backgroundColor:
              Colors.transparent, // El fondo lo pone el Container exterior
          appBar: showAppBar
              ? AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Negocios destacados'),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                    child: Text(
                                    carritoProvider.carrito.length > 99
                                        ? '99+'
                                        : '${carritoProvider.carrito.length}',
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
                )
              : null,
      body: Column(
        children: [
              // Título personalizado cuando no hay AppBar
              if (!showAppBar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                      const Icon(Icons.store, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Negocios destacados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      // Botón del carrito
                      Consumer<CarritoProvider>(
                        builder: (context, carritoProvider, child) {
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.blue,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      carritoProvider.carrito.length > 99
                                          ? '99+'
                                          : '${carritoProvider.carrito.length}',
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
            ),
              // Barra de búsqueda animada con botón de limpiar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.transparent,
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
                    autofocus: false,
                    focusNode: _searchFocusNode, // Asignar el FocusNode
                    decoration: InputDecoration(
                      hintText: 'Buscar negocios...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchText = '');
                                _searchFocusNode
                                    .unfocus(); // Quitar foco al limpiar
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
              ),
              // El resto del contenido (slider, lista, etc.)
              Expanded(
                child: _isLoading
                    ? const Center(
                              child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      )
                    : _error != null
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
                              'Error al cargar negocios',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _cargarNegocios,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _todosLosNegocios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_mall_directory,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay negocios disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 80,
                            ), // Padding inferior para evitar que el navbar tape el contenido
                            child: Builder(
                              builder: (context) {
                                // Filtrado por búsqueda (nombre, insensible a mayúsculas)
                                final filtro = _searchText.trim().toLowerCase();
                                final destacados =
                                    getDestacados(_todosLosNegocios)
                                        .where(
                                          (n) =>
                                              filtro.isEmpty ||
                                              (n['nombre']?.toString() ?? '')
                                                  .toLowerCase()
                                                  .contains(filtro),
                                        )
                                        .toList();
                                final restantes =
                                    getRestantes(_todosLosNegocios)
                                        .where(
                                          (n) =>
                                              filtro.isEmpty ||
                                              (n['nombre']?.toString() ?? '')
                                                  .toLowerCase()
                                                  .contains(filtro),
                                        )
                                        .toList();

                                return Column(
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
                                                restauranteId:
                                                    negocio['id']?.toString() ??
                                                    '',
                                                restaurante:
                                                    negocio['nombre']
                                                        ?.toString() ??
                                                    'Sin nombre',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                      _categoriaSeleccionada =
                                                          selected
                                                  ? null
                                                          : cat['nombre']
                                                                as String;
                                            });
                                          },
                                          child: Column(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                        backgroundColor:
                                                            selected
                                                            ? Colors
                                                                  .blueGrey[800]
                                                    : Colors.blue[50],
                                                child: Icon(
                                                          cat['icon']
                                                              as IconData,
                                                  color: selected
                                                      ? Colors.white
                                                              : Colors
                                                                    .blueGrey[800],
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
                                        duration: Duration(
                                          milliseconds: 400 + index * 100,
                                        ),
                                        builder: (context, value, child) =>
                                            Opacity(
                              opacity: value,
                              child: Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  30 * (1 - value),
                                                ),
                                child: child,
                              ),
                            ),
                            child: Card(
                              elevation: 6,
                              color: Colors.white,
                                          shadowColor: Colors.blue.withOpacity(
                                            0.10,
                                          ),
                              margin: const EdgeInsets.only(
                                bottom: 16,
                                left: 16,
                                right: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                              ),
                              child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            splashColor: Colors.blue
                                                .withOpacity(0.08),
                                            highlightColor: Colors.blue
                                                .withOpacity(0.04),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuScreen(
                                                    restauranteId:
                                                        negocio['id']
                                                            ?.toString() ??
                                                        '',
                                        restaurante:
                                                        negocio['nombre']
                                                            ?.toString() ??
                                                        'Sin nombre',
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    // Imagen del negocio
                                    ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(18),
                                                        bottomLeft:
                                                            Radius.circular(18),
                                      ),
                                      child: Image.network(
                                                    negocio['img']
                                                            ?.toString() ??
                                                        'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                  width: 80,
                                                  height: 80,
                                                          color:
                                                              Colors.grey[300],
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
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 18,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                          children: [
                                            Text(
                                                          negocio['nombre']
                                                                  ?.toString() ??
                                                              'Sin nombre',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .blueGrey[800],
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                              color: Colors
                                                                  .redAccent,
                                                ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                Expanded(
                                                  child: Text(
                                                    negocio['direccion']
                                                                        ?.toString() ??
                                                                    'Sin dirección',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors
                                                              .blueGrey[700],
                                                        ),
                                                    overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
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
                );
              },
                            ),
                          ),
                        ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

// Widget para el slider de negocios destacados con loop infinito real
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
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Inicializar en el medio para permitir scroll infinito
    _pageController = PageController(initialPage: 1000);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.destacados.isEmpty) return;

      // Simplemente ir a la siguiente página
      _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destacados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Expanded(
      child: PageView.builder(
        controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index % widget.destacados.length);
              },
        itemBuilder: (context, index) {
                // Usar módulo para obtener el índice real del negocio
                final realIndex = index % widget.destacados.length;
                final negocio = widget.destacados[realIndex];

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
                            negocio['img']?.toString() ??
                                'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
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
                                  negocio['direccion']?.toString() ??
                                      'Sin dirección',
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
