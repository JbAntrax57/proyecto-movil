// home_screen.dart - Pantalla principal del cliente con navbar redondeado
// Contiene la navegación entre las diferentes secciones
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para personalizar la barra de estado
import 'negocios_screen.dart';
import 'historial_pedidos_screen.dart';
import 'perfil_screen.dart';
import 'carrito_screen.dart';
import 'dart:ui'; // Added for ImageFilter
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'login_screen.dart';
import 'package:provider/provider.dart'; // Added for Provider
import '../providers/carrito_provider.dart'; // Added for CarritoProvider
import '../../../core/localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    print(
      '🏠 HomeScreen initState - Inicializando pantalla principal del cliente',
    );
    _restaurarEmail();
  }

  Future<void> _restaurarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail != null && userEmail.isNotEmpty) {
      final carritoProvider = Provider.of<CarritoProvider>(context, listen: false);
      carritoProvider.setUserEmail(userEmail);
      // Cargar el carrito explícitamente para asegurar que esté disponible
      await carritoProvider.cargarCarrito();
    }
  }

  final List<Widget> _pages = [
    const NegociosScreen(showAppBar: false),
    const HistorialPedidosScreen(showAppBar: false),
    const PerfilScreen(showAppBar: false),
  ];

  IconData _getSelectedIcon(IconData outlinedIcon) {
    if (outlinedIcon == Icons.home_outlined) return Icons.home;
    if (outlinedIcon == Icons.receipt_outlined) return Icons.receipt;
    if (outlinedIcon == Icons.person_outline) return Icons.person;
    return outlinedIcon;
  }

  List<Map<String, dynamic>> _getNavItems(BuildContext context) {
    return [
      {'icon': Icons.home_outlined, 'label': AppLocalizations.of(context).get('inicio'), 'color': Colors.blue},
      {'icon': Icons.receipt_outlined, 'label': AppLocalizations.of(context).get('pedidos'), 'color': Colors.green},
      {'icon': Icons.person_outline, 'label': AppLocalizations.of(context).get('perfil'), 'color': Colors.purple},
    ];
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 HomeScreen build - Current index: $_currentIndex');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:
            Colors.white, // Color de la barra de estado igual al fondo
        statusBarIconBrightness:
            Brightness.dark, // Iconos oscuros para fondo claro
        statusBarBrightness: Brightness.light, // iOS: texto oscuro
      ),
      child: Container(
        color: Colors.blue[50], // Fondo azul claro para toda la pantalla
        width: double.infinity, // Asegura que cubre todo el ancho
        height: double.infinity, // Asegura que cubre todo el alto
        child: SafeArea(
          top: true,
          child: Scaffold(
            backgroundColor:
                Colors.transparent, // El fondo lo pone el Container exterior
            extendBody: true,
            // Sin AppBar, el logout está solo en el perfil
            body: _pages[_currentIndex],
            bottomNavigationBar: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      // Botones de navegación
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _getNavItems(context).asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isSelected = _currentIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSelected ? 16 : 12,
                                  vertical: isSelected ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? item['color'].withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? _getSelectedIcon(item['icon']) : item['icon'],
                                      color: isSelected ? item['color'] : Colors.grey[400],
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['label'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected ? item['color'] : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Botón del carrito
                      const SizedBox(width: 16),
                      Consumer<CarritoProvider>(
                        builder: (context, carritoProvider, child) {
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CarritoScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  if (carritoProvider.carrito.isNotEmpty)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[600],
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          carritoProvider.carrito.length > 99
                                              ? '99+'
                                              : '${carritoProvider.carrito.length}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
