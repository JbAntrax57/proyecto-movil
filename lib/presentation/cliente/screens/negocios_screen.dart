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
  final FocusNode _searchFocusNode = FocusNode();
  int _currentSliderIndex = 0;

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

  // Función para generar frase aleatoria
  String _generarFrase() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final frase = _frases[random % _frases.length];
    return frase;
  }

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _saludoActual = _generarSaludo();
    _fraseActual = _generarFrase();

    // Cargar datos después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final negociosProvider = context.read<NegociosProvider>();
      negociosProvider.cargarNegocios();
      negociosProvider.cargarCategorias();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _scrollController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final negociosProvider = context.read<NegociosProvider>();
    await negociosProvider.refrescarDatosConFiltros();

    // Verificar si los controladores están activos antes de usarlos
    if (_pageController?.hasClients == true) {
      _pageController!.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_scrollController?.hasClients == true) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final negociosProvider = context.watch<NegociosProvider>();
    final showAppBar = widget.showAppBar ?? true;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Descubre',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: negociosProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          negociosProvider.error!,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => negociosProvider.refrescarDatos(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Widget de saludo personalizado
                        if (!_isLoadingUser)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            padding: const EdgeInsets.all(20),
                                                               decoration: BoxDecoration(
                                     gradient: LinearGradient(
                                       begin: Alignment.topLeft,
                                       end: Alignment.bottomRight,
                                       colors: [Colors.white, Colors.blue[50]!],
                                     ),
                                     borderRadius: BorderRadius.circular(16),
                                     boxShadow: [
                                       BoxShadow(
                                         color: Colors.black.withOpacity(0.08),
                                         blurRadius: 16,
                                         offset: const Offset(0, 6),
                                         spreadRadius: 2,
                                       ),
                                       BoxShadow(
                                         color: Colors.blue.withOpacity(0.1),
                                         blurRadius: 24,
                                         offset: const Offset(0, 8),
                                         spreadRadius: 1,
                                       ),
                                     ],
                                   ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, value, child) => Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.waving_hand,
                                              color: Colors.blue[700],
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '$_saludoActual ${_userName ?? 'Usuario'}',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _fraseActual,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Barra de búsqueda mejorada
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: false,
                              focusNode: _searchFocusNode,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                              decoration: InputDecoration(
                                hintText: 'Buscar restaurantes...',
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                suffixIcon:
                                    negociosProvider.searchText.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[500],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          negociosProvider.setSearchText('');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                negociosProvider.setSearchText(value);
                              },
                            ),
                          ),
                        ),
                        // Sección de destacados
                        if (negociosProvider
                            .getDestacadosFiltrados()
                            .isNotEmpty) ...[
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.orange[600],
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Destacados',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Container(
                                  height: 220,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                                                     child: CarouselSlider(
                                     options: CarouselOptions(
                                       height: 200,
                                       autoPlay: true,
                                       autoPlayInterval: const Duration(
                                         seconds: 4,
                                       ),
                                       enlargeCenterPage: true,
                                       viewportFraction: 0.85,
                                       enableInfiniteScroll: true,
                                       autoPlayCurve: Curves.easeInOut,
                                       autoPlayAnimationDuration: const Duration(
                                         milliseconds: 800,
                                       ),
                                       onPageChanged: (index, reason) {
                                         setState(() {
                                           _currentSliderIndex = index;
                                         });
                                       },
                                     ),
                                    items: negociosProvider.getDestacadosFiltrados().map((
                                      negocio,
                                    ) {
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
                                                    horizontal: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.12),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 8),
                                                    spreadRadius: 2,
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.orange
                                                        .withOpacity(0.1),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 12),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Stack(
                                                  children: [
                                                    // Imagen de fondo con overlay
                                                    Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.black
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            Colors.black
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                          ],
                                                        ),
                                                      ),
                                                      child: Image.network(
                                                        negocio['img']
                                                                ?.toString() ??
                                                            'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
                                                        width: double.infinity,
                                                        height: double.infinity,
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
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    // Badge de destacado
                                                    Positioned(
                                                      top: 12,
                                                      right: 12,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .orange[600],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.white,
                                                              size: 14,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Destacado',
                                                              style: GoogleFonts.montserrat(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Información del negocio
                                                    Positioned(
                                                      bottom: 0,
                                                      left: 0,
                                                      right: 0,
                                                      child: Container(
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
                                                                    0.8,
                                                                  ),
                                                            ],
                                                          ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              negocio['nombre']
                                                                      ?.toString() ??
                                                                  'Sin nombre',
                                                              style: GoogleFonts.montserrat(
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    -0.5,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .location_on,
                                                                  color: Colors
                                                                      .orange[300],
                                                                  size: 14,
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
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.9,
                                                                          ),
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
                              ),
                            ),
                          ),
                          // Indicadores de página
                          if (negociosProvider.getDestacadosFiltrados().length >
                              1)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                                                 children: List.generate(
                                   negociosProvider
                                       .getDestacadosFiltrados()
                                       .length,
                                   (index) => Container(
                                     width: 8,
                                     height: 8,
                                     margin: const EdgeInsets.symmetric(
                                       horizontal: 4,
                                     ),
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       color: index == _currentSliderIndex
                                           ? Colors.orange[600]
                                           : Colors.grey.withOpacity(0.3),
                                     ),
                                   ),
                                 ),
                              ),
                            ),
                        ],
                        // Sección de categorías
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    color: Colors.grey[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Categorías',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              negociosProvider.isLoadingCategorias
                                  ? const SizedBox(
                                      height: 80,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue,
                                              ),
                                        ),
                                      ),
                                    )
                                                                    : SizedBox(
                                      height: 120,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            negociosProvider.categorias.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 16),
                                        itemBuilder: (context, index) {
                                          final cat = negociosProvider
                                              .categorias[index];
                                          final selected =
                                              negociosProvider
                                                  .categoriaSeleccionada ==
                                              cat['nombre'];
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            width: 80,
                                            child: GestureDetector(
                                              onTap: () {
                                                // Si la categoría ya está seleccionada, la deseleccionamos
                                                if (negociosProvider.categoriaSeleccionada == cat['nombre']) {
                                                  negociosProvider.setCategoriaSeleccionada('');
                                                } else {
                                                  // Si no está seleccionada, la seleccionamos
                                                  negociosProvider.setCategoriaSeleccionada(cat['nombre'] ?? '');
                                                }
                                              },
                                                                                                                                            child: Column(
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                 children: [
                                                   // Icono grande
                                                   Text(
                                                     cat['icono'] ?? '🍽️',
                                                     style: TextStyle(
                                                       fontSize: 32,
                                                       color: selected ? Colors.blue[600] : Colors.grey[600],
                                                     ),
                                                   ),
                                                   const SizedBox(height: 8),
                                                   // Texto de categoría
                                                   Text(
                                                     cat['nombre'] ?? '',
                                                     style: GoogleFonts.montserrat(
                                                       fontSize: 12,
                                                       fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                                       color: selected ? Colors.blue[700] : Colors.grey[700],
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        // Lista de negocios restantes (no destacados)
                        ...negociosProvider.getRestantesFiltrados().map((
                          negocio,
                        ) {
                          final index = negociosProvider
                              .getRestantesFiltrados()
                              .indexOf(negocio);
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
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                splashColor: Colors.blue.withOpacity(0.08),
                                highlightColor: Colors.blue.withOpacity(0.04),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MenuScreen(
                                        restauranteId:
                                            negocio['id']?.toString() ?? '',
                                        restaurante:
                                            negocio['nombre']?.toString() ??
                                            'Sin nombre',
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    // Imagen del negocio
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        negocio['img']?.toString() ??
                                            'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?auto=format&fit=crop&w=400&q=80',
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
                                              negocio['nombre']?.toString() ??
                                                  'Sin nombre',
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    negocio['direccion']
                                                            ?.toString() ??
                                                        'Sin dirección',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 13,
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
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                                                 }).toList(),
                         const SizedBox(height: 80),
                       ],
                    ),
                  ),
          ),
                 ],
       ),
       
     );
   }
 }
