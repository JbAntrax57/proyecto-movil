// not_found_screen.dart - Pantalla para rutas no encontradas (404)
// Muestra un mensaje cuando la ruta no existe.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import '../../../core/localization.dart';

class NotFoundScreen extends StatelessWidget {
  // Pantalla de error 404
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Scaffold principal con mensaje de error
    return Scaffold(
      body: Center(child: Text(AppLocalizations.of(context).get('pagina_no_encontrada'))),
    );
  }
}
// Fin de not_found_screen.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 