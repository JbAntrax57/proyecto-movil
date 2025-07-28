import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget reutilizable para mostrar mensajes informativos en la parte superior
/// Similar al mensaje de leyenda del historial de pedidos
class TopInfoMessage extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Duration showDuration;
  final Duration animationDuration;
  final bool autoHide;
  final VoidCallback? onDismiss;

  const TopInfoMessage({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.showDuration = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 800),
    this.autoHide = true,
    this.onDismiss,
  });

  @override
  State<TopInfoMessage> createState() => _TopInfoMessageState();
}

class _TopInfoMessageState extends State<TopInfoMessage> {
  bool _mostrarMensaje = false;

  @override
  void initState() {
    super.initState();
    // Mostrar el mensaje con un pequeño delay para una entrada más suave
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _mostrarMensaje = true;
        });
      }
    });

    // Ocultar el mensaje después del tiempo especificado si autoHide es true
    if (widget.autoHide) {
      Future.delayed(widget.showDuration, () {
        if (mounted) {
          setState(() {
            _mostrarMensaje = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Colors.blue[50];
    final textColor = widget.textColor ?? Colors.blue[700];
    final iconColor = widget.iconColor ?? Colors.blue[700];

    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      height: _mostrarMensaje ? 60 : 0,
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: _mostrarMensaje ? 8 : 0,
      ),
      child: AnimatedOpacity(
        opacity: _mostrarMensaje ? 1.0 : 0.0,
        duration: Duration(milliseconds: widget.animationDuration.inMilliseconds ~/ 2),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: textColor?.withOpacity(0.3) ?? Colors.blue[200]!),
             boxShadow: [
               BoxShadow(
                 color: textColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                 blurRadius: 8,
                 offset: const Offset(0, 2),
               ),
             ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  child: Text(widget.message),
                ),
              ),
              if (widget.onDismiss != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarMensaje = false;
                    });
                    widget.onDismiss?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                                         decoration: BoxDecoration(
                       color: textColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(4),
                     ),
                    child: Icon(
                      Icons.close,
                      color: textColor,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Función helper para mostrar mensajes informativos en la parte superior
/// Se puede usar en cualquier parte de la app
void showTopInfoMessage(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? backgroundColor,
  Color? textColor,
  Color? iconColor,
  Duration? showDuration,
  Duration? animationDuration,
  bool? autoHide,
  VoidCallback? onDismiss,
}) {
  // Mostrar el mensaje usando un Overlay
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 60, // Debajo del AppBar
      left: 0,
      right: 0,
      child: TopInfoMessage(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        iconColor: iconColor,
        showDuration: showDuration ?? const Duration(seconds: 5),
        animationDuration: animationDuration ?? const Duration(milliseconds: 800),
        autoHide: autoHide ?? true,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss?.call();
        },
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Remover automáticamente después del tiempo especificado
  if (autoHide ?? true) {
    Future.delayed(showDuration ?? const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/*
EJEMPLOS DE USO:

1. Uso básico en un widget:
```dart
Column(
  children: [
    TopInfoMessage(
      message: 'Los pedidos están ordenados por estado',
    ),
    // Resto del contenido
  ],
);
```

2. Con colores personalizados:
```dart
TopInfoMessage(
  message: 'Información importante',
  backgroundColor: Colors.orange[50],
  textColor: Colors.orange[700],
  iconColor: Colors.orange[700],
);
```

3. Con función helper:
```dart
showTopInfoMessage(
  context,
  'Producto agregado al carrito exitosamente',
  icon: Icons.check_circle,
  backgroundColor: Colors.green[50],
  textColor: Colors.green[700],
);
```

4. Sin auto-ocultar:
```dart
TopInfoMessage(
  message: 'Mensaje permanente',
  autoHide: false,
  onDismiss: () => print('Mensaje cerrado'),
);
```

CARACTERÍSTICAS:
- ✅ Animación de entrada/salida suave
- ✅ Colores personalizables
- ✅ Icono personalizable
- ✅ Duración personalizable
- ✅ Auto-ocultar opcional
- ✅ Botón de cerrar opcional
- ✅ Función helper para uso global
- ✅ Diseño consistente con la app
*/ 