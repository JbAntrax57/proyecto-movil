// home_screen.dart - Pantalla de inicio para el cliente
// Muestra un mensaje de bienvenida o contenido principal del home del cliente.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'negocios_screen.dart';
import 'pedidos_screen.dart';
import 'carrito_screen.dart';

class ClienteHomeScreen extends StatefulWidget {
  // Pantalla de inicio para el cliente
  const ClienteHomeScreen({super.key});
  
  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _currentIndex = 0;
  
  // Lista de pantallas disponibles
  final List<Widget> _screens = [
    const NegociosScreen(),
    const ClientePedidosScreen(),
    const CarritoScreen(),
  ];
  
  // Lista de elementos del navbar
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.store),
      label: 'Negocios',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long),
      label: 'Mis Pedidos',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: 'Carrito',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userEmail = context.read<CarritoProvider>().userEmail;
    
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        actions: [
          // Botón de perfil/logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(userEmail),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
  
  // Obtiene el título de la AppBar según la pantalla actual
  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Negocios Destacados';
      case 1:
        return 'Mis Pedidos';
      case 2:
        return 'Carrito de Compras';
      default:
        return 'Cliente';
    }
  }
  
  // Función para cerrar sesión
  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // Limpiar el carrito
      context.read<CarritoProvider>().limpiarCarrito();
      // Navegar al login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
// Fin de home_screen.dart (cliente)
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 