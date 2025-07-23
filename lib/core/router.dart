// router.dart - Configuración de rutas con GoRouter
// Define la estructura de rutas de la app, permitiendo navegación por roles y rutas comunes.
// Para agregar rutas, edita el arreglo 'routes'.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:go_router/go_router.dart';
import '../presentation/cliente/screens/home_screen.dart';
import '../presentation/common/screens/login_screen.dart';
import '../presentation/duenio/screens/dashboard_screen.dart';
import '../presentation/admin/screens/admin_home.dart';
import '../presentation/cliente/screens/carrito_screen.dart';
import '../presentation/common/screens/splash_screen.dart';
import '../presentation/common/screens/register_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        print('🛣️ Router: Navegando a /splash');
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        print('🛣️ Router: Navegando a /login');
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        print('🛣️ Router: Navegando a /register');
        return const RegisterScreen();
      },
    ),
    GoRoute(
      path: '/cliente',
      builder: (context, state) {
        print('🛣️ Router: Navegando a /cliente - Cargando HomeScreen');
        print('🛣️ Router: Estado de la ruta: ${state.uri}');
        print('🛣️ Router: ⚠️ ⚠️ ⚠️ CARGANDO HOMESCREEN ⚠️ ⚠️ ⚠️');
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/cliente/carrito',
      builder: (context, state) {
        print('🛣️ Router: Navegando a /cliente/carrito');
        return const CarritoScreen();
      },
    ),
    GoRoute(
      path: '/duenio',
      builder: (context, state) => const DuenioDashboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
    ),
  ],
);
// Fin de router.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
