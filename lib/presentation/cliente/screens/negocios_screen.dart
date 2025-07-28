// negocios_screen.dart - Pantalla principal del cliente para ver y explorar negocios
// Incluye slider de destacados, barra de categorías, lista de negocios y carrito.
// Implementa obtención de datos desde Supabase, filtrado por categoría y animaciones.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/negocios_provider.dart';

import 'menu_screen.dart';
import 'carrito_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/top_info_message.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode =
      FocusNode(); // FocusNode temporal para controlar el foco

  // Variables para el saludo personalizado
  String? _userName;
  String _saludoActual = '';
  String _fraseActual = '';
  bool _isLoadingUser = true;

  // Arreglos de saludos y frases motivacionales
  final List<String> _saludos = [
    'Hola',
    'Buen día',
    '¡Hola!',
    'Buenos días',
    '¡Hola!',
    'Saludos',
    '¡Qué tal!',
    'Hola de nuevo',
    '¡Buen día!',
    '¡Hola!',
  ];

  final List<String> _frases = [
    '¿Qué se te antoja hoy?',
    '¿Qué vamos a pedir?',
    '¿En busca de algo delicioso?',
    '¿Qué te gustaría comer?',
    '¿Hambriento? ¡Encuentra tu favorito!',
    '¿Qué tal un buen platillo?',
    '¿Listo para descubrir sabores?',
    '¿Qué te apetece hoy?',
    '¡Explora nuestros negocios!',
    '¿Qué vamos a comer hoy?',
  ];

  // Función para obtener el nombre del usuario
  Future<void> _cargarNombreUsuario() async {
    try {
      final userEmail = context.read<CarritoProvider>().userEmail;
      if (userEmail != null && userEmail.isNotEmpty) {
        final data = await Supabase.instance.client
            .from('usuarios')
            .select('name')
            .eq('email', userEmail)
            .single();

        setState(() {
          _userName = data['name']?.toString();
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  // Función para generar saludo aleatorio
  String _generarSaludo() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final saludo = _saludos[random % _saludos.length];
    return saludo;
  }

  // Función para generar frase motivacional aleatoria
  String _generarFrase() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final frase = _frases[random % _frases.length];
    return frase;
  }

  // Eliminar función de iconos, ya no se usa

  // Simula refresco (pull-to-refresh) - Actualiza TODO
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));

    // 1. Recargar datos desde el provider
    final negociosProvider = context.read<NegociosProvider>();
    await negociosProvider.refrescarDatos();

    // 2. Actualizar carrito del usuario (limpiar duplicados y recargar)
    final carritoProvider = context.read<CarritoProvider>();
    if (carritoProvider.userEmail != null &&
        carritoProvider.userEmail!.isNotEmpty) {
      await carritoProvider.limpiarCarritosDuplicados();
      await carritoProvider.cargarCarrito();
    }

    // 3. Resetear búsqueda
    _searchController.clear();

    // 4. Resetear scroll controllers (solo si están inicializados)
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    if (_scrollController != null && _scrollController!.hasClients) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // 5. Mostrar confirmación
    if (mounted) {
      showTopInfoMessage(
        context,
        '✅ Todo actualizado: negocios, categorías, carrito y filtros',
        icon: Icons.check_circle,
        backgroundColor: Colors.green[50],
        textColor: Colors.green[700],
        iconColor: Colors.green[700],
        showDuration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _scrollController = ScrollController();

    // Cargar datos desde el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final negociosProvider = context.read<NegociosProvider>();
      negociosProvider.cargarNegocios();
      negociosProvider.cargarCategorias();
      _cargarNombreUsuario(); // Cargar el nombre del usuario al iniciar

      // Generar saludo y frase iniciales
      setState(() {
        _saludoActual = _generarSaludo();
        _fraseActual = _generarFrase();
      });
    });
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
    final negociosProvider = context.watch<NegociosProvider>();
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
                  elevation: 0,
                  title: Text(
                    'Negocios destacados',
                    style: GoogleFonts.montserrat(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // El resto del contenido (slider, lista, etc.)
              Expanded(
                child: negociosProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      )
                    : negociosProvider.error != null
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
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  negociosProvider.cargarNegocios(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : negociosProvider.todosLosNegocios.isEmpty
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
                              style: GoogleFonts.montserrat(
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
                                // Obtener datos filtrados desde el provider
                                final destacados = negociosProvider
                                    .getDestacadosFiltrados();
                                final restantes = negociosProvider
                                    .getRestantesFiltrados();

                                return Column(
                                  children: [
                                    // Widget de saludo personalizado
                                    if (!_isLoadingUser)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          height: 160,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                Colors.grey[50]!,
                                              ],
                                            ),
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 15,
                                                offset: const Offset(0, 6),
                                              ),
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(0.05),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: 1),
                                            duration: const Duration(milliseconds: 600),
                                            builder: (context, value, child) => Opacity(
                                              opacity: value.clamp(0.0, 1.0),
                                              child: Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  30 * (1 - value),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '$_saludoActual ${_userName ?? 'Usuario'}',
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black87,
                                                        letterSpacing: -0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      _fraseActual,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.black54,
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Barra de búsqueda animada con botón de limpiar
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      color: Colors.transparent,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _searchController,
                                          autofocus: false,
                                          focusNode:
                                              _searchFocusNode, // Asignar el FocusNode
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            color: Colors.blueGrey[900],
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Buscar negocios...',
                                            hintStyle: GoogleFonts.montserrat(
                                              color: Colors.blueGrey[400],
                                              fontSize: 16,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              color: Colors.grey,
                                            ),
                                            suffixIcon:
                                                negociosProvider
                                                    .searchText
                                                    .isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      color: Colors.grey,
                                                    ),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      negociosProvider
                                                          .setSearchText('');
                                                      _searchFocusNode
                                                          .unfocus(); // Quitar foco al limpiar
                                                    },
                                                  )
                                                : null,
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 15,
                                                ),
                                          ),
                                          onChanged: (value) {
                                            negociosProvider.setSearchText(
                                              value,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Slider de negocios destacados (loop infinito y scroll automático)
                                    if (destacados.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: CarouselSlider(
                                          options: CarouselOptions(
                                            height: 200,
                                            autoPlay: true,
                                            autoPlayInterval: const Duration(
                                              seconds: 3,
                                            ),
                                            enlargeCenterPage: true,
                                            viewportFraction: 0.97,
                                            enableInfiniteScroll: true,
                                          ),
                                          items: destacados.map((negocio) {
                                            return Builder(
                                              builder: (context) {
                                                return GestureDetector(
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
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.10,
                                                              ),
                                                          blurRadius: 12,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      child: Stack(
                                                        children: [
                                                          Image.network(
                                                            negocio['img']
                                                                    ?.toString() ??
                                                                'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => Container(
                                                                  color: Colors
                                                                      .grey[300],
                                                                  child: const Icon(
                                                                    Icons.store,
                                                                    size: 64,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ),
                                                          ),
                                                          // Gradiente oscuro para el texto
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                begin: Alignment
                                                                    .topCenter,
                                                                end: Alignment
                                                                    .bottomCenter,
                                                                colors: [
                                                                  Colors
                                                                      .transparent,
                                                                  Colors.black
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
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
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  negocio['nombre']
                                                                          ?.toString() ??
                                                                      'Sin nombre',
                                                                  style: GoogleFonts.montserrat(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        22,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  negocio['direccion']
                                                                          ?.toString() ??
                                                                      'Sin dirección',
                                                                  style: GoogleFonts.montserrat(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.85,
                                                                        ),
                                                                    fontSize:
                                                                        14,
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
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 6,
                                                                  ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color: Colors
                                                                        .orange,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                  ),
                                                              child: Text(
                                                                'Destacado',
                                                                style: GoogleFonts.montserrat(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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
                                            );
                                          }).toList(),
                                        ),
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
                                              style: GoogleFonts.montserrat(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey[950],
                                              ),
                                            ),
                                          ),
                                          // En la barra de categorías horizontal
                                          negociosProvider.isLoadingCategorias
                                              ? const SizedBox(
                                                  height: 70,
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.blue),
                                                    ),
                                                  ),
                                                )
                                              : SizedBox(
                                                  height: 70,
                                                  child: ListView.separated(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: negociosProvider
                                                        .categorias
                                                        .length,
                                                    separatorBuilder: (_, __) =>
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                    itemBuilder: (context, index) {
                                                      final cat =
                                                          negociosProvider
                                                              .categorias[index];
                                                      final selected =
                                                          negociosProvider
                                                              .categoriaSeleccionada ==
                                                          cat['nombre'];
                                                      return ChoiceChip(
                                                        label: Text(
                                                          '${cat['icono'] ?? ''} ${cat['nombre'] ?? ''}',
                                                        ),
                                                        selected: selected,
                                                        backgroundColor:
                                                            Colors.white,
                                                        selectedColor: Colors
                                                            .lightBlueAccent[400],
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                18,
                                                              ),
                                                          side: BorderSide(
                                                            color: selected
                                                                ? Colors
                                                                      .blue[800]!
                                                                : Colors
                                                                      .blueGrey[100]!,
                                                            width: selected
                                                                ? 2
                                                                : 1,
                                                          ),
                                                        ),
                                                        elevation: selected
                                                            ? 2
                                                            : 0,
                                                        pressElevation: 4,
                                                        onSelected: (_) {
                                                          negociosProvider
                                                              .setCategoriaSeleccionada(
                                                                selected
                                                                    ? null
                                                                    : cat['nombre']
                                                                          as String,
                                                              );
                                                        },
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
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
                                                          style: GoogleFonts.montserrat(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .blueGrey[800],
                                                            fontSize: 16,
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
                                                                style: GoogleFonts.montserrat(
                                                                  color: Colors
                                                                      .blueGrey[700],
                                                                  fontSize: 13,
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
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  negocio['direccion']?.toString() ??
                                      'Sin dirección',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
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
                              child: Text(
                                'Destacado',
                                style: GoogleFonts.montserrat(
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
