// localization.dart - Configuración de localización e idiomas soportados
// Define los idiomas disponibles y los delegados de localización para la app.
// Para agregar un nuevo idioma, edita 'supportedLocales' y 'localizationsDelegates'.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const supportedLocales = [Locale('es'), Locale('en')];
const localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
// Fin de localization.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 