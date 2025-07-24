// home_screen.dart - Pantalla principal del cliente con navbar redondeado
// Contiene la navegación entre las diferentes secciones
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para personalizar la barra de estado
import 'negocios_screen.dart';
import 'historial_pedidos_screen.dart';
import 'perfil_screen.dart';
import 'dart:ui'; // Added for ImageFilter
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences
import 'login_screen.dart';
import 'package:provider/provider.dart'; // Added for Provider
import '../../cliente/providers/carrito_provider.dart'; // Added for CarritoProvider

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

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.store, 'label': 'Negocios', 'color': Colors.blue},
    {'icon': Icons.receipt_long, 'label': 'Historial', 'color': Colors.green},
    {'icon': Icons.person, 'label': 'Perfil', 'color': Colors.purple},
  ];

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
              // Sin margen, pegado abajo
              decoration: const BoxDecoration(
                color: Colors.white, // Fondo blanco minimalista
                // Sin borderRadius ni sombra
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((entry) {
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item['color'].withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: item['color'], width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected
                                ? item['color']
                                : Colors.grey[600],
                            size: 28,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              item['label'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: item['color'],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
