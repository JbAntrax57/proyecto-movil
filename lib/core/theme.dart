// theme.dart - Configuración de temas claro y oscuro para la app
// Define los temas globales que se pueden personalizar según la identidad visual del proyecto.
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta de azules moderna inspirada en apps de delivery, reemplazando el naranja de Rappi
const Color azulPrincipal = Color(0xFF1976D2); // Azul fuerte
const Color azulClaro = Color(0xFFE3F0FF); // Fondo muy claro
const Color azulMedio = Color(0xFF64B5F6); // Azul medio para acentos
const Color azulOscuro = Color(0xFF0D47A1); // Azul muy oscuro para títulos
const Color azulBoton = Color(0xFF2196F3); // Botón principal
const Color azulCard = Color(0xFFF5FAFF); // Fondo de cards

// Tema claro personalizado con Montserrat y azules
final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: azulClaro,
  primaryColor: azulPrincipal,
  colorScheme: ColorScheme.light(
    primary: azulPrincipal,
    secondary: azulMedio,
    background: azulClaro,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: azulOscuro,
    onSurface: azulOscuro,
  ),
  textTheme: GoogleFonts.montserratTextTheme().copyWith(
    displayLarge: GoogleFonts.montserrat(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: azulOscuro,
    ),
    titleLarge: GoogleFonts.montserrat(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: azulOscuro,
    ),
    titleMedium: GoogleFonts.montserrat(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: azulPrincipal,
    ),
    bodyLarge: GoogleFonts.montserrat(
      fontSize: 16,
      color: azulOscuro,
    ),
    bodyMedium: GoogleFonts.montserrat(
      fontSize: 14,
      color: azulOscuro,
    ),
    labelLarge: GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: azulPrincipal,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: azulClaro,
    elevation: 0,
    iconTheme: const IconThemeData(color: azulPrincipal),
    titleTextStyle: GoogleFonts.montserrat(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: azulPrincipal,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: azulBoton,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      elevation: 2,
    ),
  ),
  // CardThemeData en vez de CardTheme para compatibilidad con ThemeData
  cardTheme: CardThemeData(
    color: azulCard,
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: azulMedio, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: azulMedio, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: azulPrincipal, width: 2),
    ),
    labelStyle: GoogleFonts.montserrat(
      color: azulPrincipal,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: GoogleFonts.montserrat(
      color: azulMedio,
      fontWeight: FontWeight.w400,
    ),
  ),
  iconTheme: const IconThemeData(color: azulPrincipal),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: azulBoton,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: azulPrincipal,
    unselectedItemColor: azulMedio,
    selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
    unselectedLabelStyle: GoogleFonts.montserrat(),
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: true,
  ),
);

// Tema oscuro (puedes personalizarlo igual si lo deseas)
final darkTheme = ThemeData.dark();
// Fin de theme.dart
// Todos los métodos, variables y widgets están documentados para facilitar el mantenimiento y la extensión. 