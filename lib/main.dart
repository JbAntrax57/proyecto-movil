import 'package:flutter/material.dart';
import 'presentation/cliente/screens/negocios_screen.dart';
import 'presentation/cliente/screens/menu_screen.dart';
import 'presentation/cliente/screens/carrito_screen.dart';
import 'presentation/cliente/screens/pedidos_screen.dart';
import 'presentation/repartidor/screens/pedidos_screen.dart';
import 'presentation/repartidor/screens/mapa_screen.dart';
import 'presentation/repartidor/screens/actualizar_estado_screen.dart';
import 'presentation/duenio/screens/pedidos_screen.dart';
import 'presentation/duenio/screens/menu_screen.dart';
import 'presentation/admin/screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Multirrol',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const RoleSelectorScreen(),
    );
  }
}

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un rol')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            title: const Text('Cliente'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const NegociosScreen(),
            )),
          ),
          ListTile(
            title: const Text('Repartidor'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const RepartidorDemoMenu(),
            )),
          ),
          ListTile(
            title: const Text('Dueño de negocio'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const DuenioDemoMenu(),
            )),
          ),
          ListTile(
            title: const Text('Administrador'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class ClienteDemoMenu extends StatelessWidget {
  const ClienteDemoMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cliente')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Ver negocios'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const NegociosScreen(),
            )),
          ),
          // Eliminar o comentar la opción de 'Ver menú' porque MenuScreen requiere argumentos obligatorios
          // ListTile(
          //   title: const Text('Ver menú'),
          //   onTap: () => Navigator.push(context, MaterialPageRoute(
          //     builder: (_) => const MenuScreen(),
          //   )),
          // ),
          ListTile(
            title: const Text('Carrito de compras'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const CarritoScreen(),
            )),
          ),
          ListTile(
            title: const Text('Mis pedidos'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ClientePedidosScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class RepartidorDemoMenu extends StatelessWidget {
  const RepartidorDemoMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repartidor')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Pedidos asignados'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const RepartidorPedidosScreen(),
            )),
          ),
          ListTile(
            title: const Text('Mapa de entrega'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const MapaScreen(),
            )),
          ),
          ListTile(
            title: const Text('Actualizar estado de pedido'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ActualizarEstadoScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class DuenioDemoMenu extends StatelessWidget {
  const DuenioDemoMenu({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dueño de negocio')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Pedidos recibidos'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const DuenioPedidosScreen(),
            )),
          ),
          ListTile(
            title: const Text('Menú del negocio'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const DuenioMenuScreen(),
            )),
          ),
        ],
      ),
    );
  }
}