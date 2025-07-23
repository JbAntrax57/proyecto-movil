// splash_screen.dart - Pantalla de carga inicial (splash)
// Muestra un mensaje de carga mientras se inicializa la app.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  // Pantalla de splash/carga inicial
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Espera 2 segundos y navega a login
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold principal con logo y mensaje de carga
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app (si no existe, muestra un icono de Flutter)
            SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 100),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cargando...',
              style: TextStyle(fontSize: 22, color: Colors.blueGrey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
// Fin de splash_screen.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 