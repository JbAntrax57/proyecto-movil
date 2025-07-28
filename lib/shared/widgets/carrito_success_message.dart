import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget reutilizable para mostrar mensajes de confirmación del carrito
/// Se usa cuando se agrega un producto al carrito exitosamente
class CarritoSuccessMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final Duration duration;

  const CarritoSuccessMessage({
    super.key,
    required this.message,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    GestureDetector(
                      onTap: onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.green[700],
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Función helper para mostrar el mensaje de éxito del carrito
/// Se puede usar en cualquier parte de la app
void showCarritoSuccessMessage(
  BuildContext context,
  String message, {
  Duration? duration,
  VoidCallback? onDismiss,
}) {
  // Remover mensajes anteriores si existen
  ScaffoldMessenger.of(context).clearSnackBars();
  
  // Mostrar el nuevo mensaje
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: CarritoSuccessMessage(
        message: message,
        onDismiss: onDismiss,
        duration: duration ?? const Duration(seconds: 3),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
    ),
  );
}

/*
EJEMPLOS DE USO:

1. Uso básico:
```dart
showCarritoSuccessMessage(
  context,
  'Hamburguesa x2 agregado al carrito',
);
```

2. Con duración personalizada:
```dart
showCarritoSuccessMessage(
  context,
  'Pizza x1 agregado al carrito',
  duration: Duration(seconds: 5),
);
```

3. Con callback de dismiss:
```dart
showCarritoSuccessMessage(
  context,
  'Producto agregado al carrito',
  onDismiss: () {
    // Acción cuando se cierra el mensaje
    print('Mensaje cerrado');
  },
);
```

4. Uso directo del widget:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: CarritoSuccessMessage(
      message: 'Producto agregado al carrito',
      onDismiss: () => Navigator.pop(context),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating,
  ),
);
```

CARACTERÍSTICAS:
- ✅ Animación de entrada suave
- ✅ Diseño consistente con la app
- ✅ Colores verdes para éxito
- ✅ Icono de check
- ✅ Botón de cerrar opcional
- ✅ Duración personalizable
- ✅ Reutilizable en toda la app
- ✅ Limpia mensajes anteriores automáticamente
*/ 