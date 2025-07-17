// main.dart - Punto de entrada de la aplicación Flutter
// Esta app implementa un sistema multirol (Cliente, Repartidor, Dueño, Admin) con navegación dinámica y gestión de estado robusta.
// Aquí se inicializa Firebase y se definen las rutas principales para cada tipo de usuario.
// Cada pantalla principal está documentada y comentada para facilitar el onboarding de nuevos desarrolladores.

import 'package:flutter/material.dart';
import 'presentation/cliente/screens/login_screen.dart';
import 'presentation/cliente/screens/menu_screen.dart';
import 'presentation/cliente/screens/negocios_screen.dart';
import 'presentation/admin/screens/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Importa las pantallas principales de cada rol si existen
// Si no, usa un Scaffold temporal

// Función principal: inicializa Firebase y ejecuta la app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para inicializaciones asíncronas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Widget raíz de la aplicación. Define el MaterialApp y las rutas principales por rol.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Demo Multirol',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login', // Ruta inicial
      routes: {
        // Rutas principales por rol
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/cliente': (_) => const NegociosScreen(),
        '/repartidor': (_) => const RepartidorHomeScreen(),
        '/duenio': (_) => const DuenioHomeScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
      },
    );
  }
}

// Pantalla de registro temporal (placeholder para futuros flujos de registro de usuario)
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')), 
      body: const Center(child: Text('Pantalla de registro (por implementar)')),
    );
  }
}

// Pantalla principal temporal para repartidor (se reemplazará por la vista real de repartidor)
class RepartidorHomeScreen extends StatelessWidget {
  const RepartidorHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio Repartidor')), 
      body: const Center(child: Text('Vista principal Repartidor')), 
    );
  }
}
// Pantalla principal temporal para dueño de negocio (se reemplazará por la vista real de dueño)
class DuenioHomeScreen extends StatelessWidget {
  const DuenioHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio Dueño')), 
      body: const Center(child: Text('Vista principal Dueño')), 
    );
  }
}
// Pantalla principal temporal para admin (no se usa, se usa AdminDashboardScreen)
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio Admin')), 
      body: const Center(child: Text('Vista principal Admin')), 
    );
  }
}