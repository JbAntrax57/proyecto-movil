// router.dart - Configuración de rutas con GoRouter
// Define la estructura de rutas de la app, permitiendo navegación por roles y rutas comunes.
// Para agregar rutas, edita el arreglo 'routes'.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../presentation/cliente/screens/negocios_screen.dart';
import '../presentation/cliente/screens/login_screen.dart';
import '../presentation/repartidor/screens/repartidor_home.dart';
import '../presentation/duenio/screens/duenio_home.dart';
import '../presentation/admin/screens/admin_home.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cliente',
      builder: (context, state) => const NegociosScreen(),
    ),
    GoRoute(
      path: '/repartidor',
      builder: (context, state) => const RepartidorHomeScreen(),
    ),
    GoRoute(
      path: '/duenio',
      builder: (context, state) => const DuenioHomeScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
    ),
  ],
);
// Fin de router.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 