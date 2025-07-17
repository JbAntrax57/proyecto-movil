import 'package:flutter/material.dart';
import 'presentation/cliente/screens/login_screen.dart';
import 'presentation/cliente/screens/menu_screen.dart';
import 'presentation/cliente/screens/negocios_screen.dart';
import 'presentation/admin/screens/dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Importa las pantallas principales de cada rol si existen
// Si no, usa un Scaffold temporal

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

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
      initialRoute: '/login',
      routes: {
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

// Pantalla de registro temporal
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

// Pantallas principales temporales para cada rol
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